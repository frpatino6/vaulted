import {
  Controller,
  Post,
  Body,
  Req,
  Res,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { Request, Response } from 'express';
import { AuthGuard } from '@nestjs/passport';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { VerifyMfaDto } from './dto/verify-mfa.dto';
import { AcceptInviteDto } from './dto/accept-invite.dto';
import { Public } from '../../common/decorators/public.decorator';
import { SkipMfa } from '../../common/decorators/skip-mfa.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from './strategies/jwt.strategy';
import { JwtRefreshPayload } from './strategies/jwt-refresh.strategy';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiUnauthorizedResponse,
  ApiForbiddenResponse,
} from '@nestjs/swagger';

const REFRESH_COOKIE_OPTIONS = {
  httpOnly: true,
  secure: process.env['NODE_ENV'] === 'production',
  // SameSite=Lax works because the web app (vaulted.casacam.net) and API
  // are now on the same domain — Caddy proxies /api/* to the NestJS container.
  // Safari blocks SameSite=None cookies via ITP, so Lax is required for Safari.
  sameSite: 'lax' as const,
  maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days in ms
  path: '/api/auth/refresh',
};

const CLEAR_COOKIE_OPTIONS = {
  httpOnly: true,
  secure: process.env['NODE_ENV'] === 'production',
  sameSite: 'lax' as const,
  path: '/api/auth/refresh',
};

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('register')
  @ApiOperation({ summary: 'Register a new tenant and owner account' })
  @ApiResponse({
    status: 201,
    description: 'Registration successful, returns access token',
  })
  @ApiResponse({ status: 400, description: 'Invalid input' })
  @ApiResponse({ status: 409, description: 'Email already registered' })
  async register(
    @Body() dto: RegisterDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const ip = req.ip ?? 'unknown';
    const { accessToken, refreshToken } = await this.authService.register(
      dto.tenantName,
      dto.email,
      dto.password,
      ip,
    );

    res.cookie('refresh_token', refreshToken, REFRESH_COOKIE_OPTIONS);
    return { accessToken };
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with email and password' })
  @ApiResponse({
    status: 200,
    description: 'Login successful, returns access token and mfaRequired flag',
  })
  @ApiResponse({ status: 401, description: 'Invalid credentials' })
  async login(
    @Body() dto: LoginDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const ip = req.ip ?? 'unknown';
    const { accessToken, refreshToken, mfaRequired, mfaSetupRequired } =
      await this.authService.login(dto.email, dto.password, ip);

    res.cookie('refresh_token', refreshToken, REFRESH_COOKIE_OPTIONS);
    return { accessToken, mfaRequired, mfaSetupRequired };
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('accept-invite')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept an invitation and create account' })
  @ApiResponse({ status: 201, description: 'Invitation accepted successfully' })
  @ApiResponse({ status: 400, description: 'Invalid or expired token' })
  async acceptInvite(
    @Body() dto: AcceptInviteDto,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const ip = req.ip ?? 'unknown';
    const { accessToken, refreshToken, mfaRequired, mfaSetupRequired } =
      await this.authService.acceptInvite(dto, ip);

    res.cookie('refresh_token', refreshToken, REFRESH_COOKIE_OPTIONS);
    return { accessToken, mfaRequired, mfaSetupRequired };
  }

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @UseGuards(AuthGuard('jwt-refresh'))
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Refresh access token using refresh token cookie' })
  @ApiResponse({ status: 200, description: 'Token refreshed successfully' })
  @ApiResponse({ status: 401, description: 'Invalid or expired refresh token' })
  async refresh(
    @CurrentUser() payload: JwtRefreshPayload,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const ip = req.ip ?? 'unknown';
    const { accessToken, refreshToken } = await this.authService.refresh(
      payload,
      ip,
    );

    res.cookie('refresh_token', refreshToken, REFRESH_COOKIE_OPTIONS);
    return { accessToken };
  }

  @SkipMfa()
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Logout current session' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Logout successful' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async logout(
    @CurrentUser() payload: JwtPayload,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const accessToken = req.headers.authorization?.replace('Bearer ', '') ?? '';
    const refreshCookie = req.cookies?.['refresh_token'] as string | undefined;
    const ip = req.ip ?? 'unknown';

    await this.authService.logout(accessToken, payload, refreshCookie, ip);

    res.clearCookie('refresh_token', CLEAR_COOKIE_OPTIONS);
    return { message: 'Logged out successfully' };
  }

  @SkipMfa()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('logout-all')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Logout all sessions across devices' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'All sessions terminated' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async logoutAll(
    @CurrentUser() payload: JwtPayload,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const accessToken = req.headers.authorization?.replace('Bearer ', '') ?? '';
    const ip = req.ip ?? 'unknown';

    await this.authService.logoutAll(
      payload.sub,
      payload.tenantId,
      accessToken,
      ip,
    );

    res.clearCookie('refresh_token', CLEAR_COOKIE_OPTIONS);
    return { message: 'All sessions have been terminated' };
  }

  @SkipMfa()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('mfa/setup')
  @ApiOperation({ summary: 'Setup MFA for the account' })
  @ApiBearerAuth()
  @ApiResponse({
    status: 201,
    description: 'MFA setup successful, returns QR code',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  async setupMfa(@CurrentUser() user: JwtPayload) {
    return this.authService.setupMfa(user.sub, user.tenantId, user.email);
  }

  @SkipMfa()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('mfa/verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify and enable MFA' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'MFA verified and enabled' })
  @ApiResponse({ status: 401, description: 'Invalid MFA code' })
  async verifyMfa(
    @Body() dto: VerifyMfaDto,
    @CurrentUser() user: JwtPayload,
    @Req() req: Request,
    @Res({ passthrough: true }) res: Response,
  ) {
    const ip = req.ip ?? 'unknown';
    const { accessToken, refreshToken } = await this.authService.verifyMfa(
      user.sub,
      user.tenantId,
      dto.code,
      ip,
    );

    res.cookie('refresh_token', refreshToken, REFRESH_COOKIE_OPTIONS);
    return { accessToken };
  }
}
