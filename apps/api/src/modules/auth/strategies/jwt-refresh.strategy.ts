import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { JwtPayload } from './jwt.strategy';

export interface JwtRefreshPayload extends JwtPayload {
  typ?: 'refresh';
  refreshTokenId: string;
}

/**
 * Validates refresh token signature and cookie presence only.
 * Blacklist + replay detection is handled in AuthService.refresh()
 * so that replay attacks can trigger full session invalidation.
 */
@Injectable()
export class JwtRefreshStrategy extends PassportStrategy(Strategy, 'jwt-refresh') {
  constructor(config: ConfigService) {
    super({
      jwtFromRequest: ExtractJwt.fromExtractors([
        (req: Request) => req.cookies?.['refresh_token'] as string | null ?? null,
      ]),
      secretOrKey: config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      algorithms: ['HS256'],
      passReqToCallback: true,
    });
  }

  validate(req: Request, payload: JwtRefreshPayload): JwtRefreshPayload {
    if (!req.cookies?.['refresh_token']) {
      throw new UnauthorizedException('Refresh token not found');
    }
    if (
      payload.typ !== 'refresh' ||
      !payload.refreshTokenId ||
      !payload.sub ||
      !payload.tenantId ||
      !payload.email ||
      !payload.role ||
      typeof payload.mfaVerified !== 'boolean'
    ) {
      throw new UnauthorizedException('Invalid refresh token claims');
    }
    return payload;
  }
}
