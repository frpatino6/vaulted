import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';
import { InjectRedis } from '../../common/decorators/inject-redis.decorator';
import { Redis } from 'ioredis';
import * as speakeasy from 'speakeasy';
import * as QRCode from 'qrcode';
import { v4 as uuidv4 } from 'uuid';
import { UsersService } from '../users/users.service';
import { TenantsService } from '../tenants/tenants.service';
import { AuditService } from '../audit/audit.service';
import { Role, MFA_REQUIRED_ROLES } from '../../common/enums/role.enum';
import { JwtPayload } from './strategies/jwt.strategy';
import { JwtRefreshPayload } from './strategies/jwt-refresh.strategy';
import { User } from '../users/entities/user.entity';
import { Tenant } from '../tenants/entities/tenant.entity';

const ACCESS_TOKEN_TTL_SECONDS = 15 * 60;
const REFRESH_TOKEN_TTL_SECONDS = 7 * 24 * 60 * 60;

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly tenantsService: TenantsService,
    private readonly auditService: AuditService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    @InjectDataSource() private readonly dataSource: DataSource,
    @InjectRedis() private readonly redis: Redis,
  ) {}

  async register(
    tenantName: string,
    email: string,
    password: string,
    ipAddress: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    // Atomic transaction: tenant + user created together or not at all
    const { tenant, user } = await this.dataSource.transaction(async (manager) => {
      const tenantRepo = manager.getRepository(Tenant);
      const tenant = tenantRepo.create({ name: tenantName });
      const savedTenant = await tenantRepo.save(tenant);

      const savedUser = await this.usersService.create(
        { tenantId: savedTenant.id, email, password, role: Role.OWNER },
        manager,
      );

      return { tenant: savedTenant, user: savedUser };
    });

    await this.auditService.log({
      tenantId: tenant.id,
      userId: user.id,
      action: 'user.register',
      entityType: 'user',
      entityId: user.id,
      ipAddress,
    });

    return this.generateTokenPair(user);
  }

  async login(
    email: string,
    password: string,
    ipAddress: string,
  ): Promise<{ accessToken: string; refreshToken: string; mfaRequired: boolean }> {
    const user = await this.usersService.findByEmail(email);

    if (!user || !user.isActive) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const passwordValid = await this.usersService.verifyPassword(password, user.passwordHash);
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    await this.usersService.updateLastLogin(user.id);

    // Require MFA only if role is in MFA_REQUIRED_ROLES AND user has MFA enabled
    const roleRequiresMfa =
      MFA_REQUIRED_ROLES.includes(user.role) && user.mfaEnabled;
    const mfaRequired = roleRequiresMfa;

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.id,
      action: 'user.login',
      entityType: 'user',
      entityId: user.id,
      ipAddress,
    });

    // mfaVerified=false for MFA-required roles — MfaVerifiedGuard blocks further access
    // until /auth/mfa/verify is called successfully
    const tokens = await this.generateTokenPair(user, {
      mfaVerified: !roleRequiresMfa,
    });

    return { ...tokens, mfaRequired };
  }

  async refresh(
    payload: JwtRefreshPayload,
    ipAddress: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const { refreshTokenId, sub: userId } = payload;
    const blacklistKey = `blacklist:refresh:${refreshTokenId}`;

    // If this token is already blacklisted it means it was already rotated.
    // A second use = replay attack → immediately nuke ALL sessions for this user.
    const isBlacklisted = await this.redis.get(blacklistKey);
    if (isBlacklisted) {
      await this.invalidateAllSessions(userId);
      await this.auditService.log({
        tenantId: payload.tenantId,
        userId,
        action: 'user.token_replay_detected',
        entityType: 'user',
        entityId: userId,
        ipAddress,
      });
      throw new UnauthorizedException(
        'Token replay detected — all sessions have been invalidated',
      );
    }

    // Revoke the used token and remove it from the active sessions set
    await Promise.all([
      this.redis.setex(blacklistKey, REFRESH_TOKEN_TTL_SECONDS, '1'),
      this.redis.srem(`sessions:${userId}`, refreshTokenId),
    ]);

    const user = await this.usersService.findById(userId);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('User not found or inactive');
    }

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.id,
      action: 'user.token_refresh',
      entityType: 'user',
      entityId: user.id,
      ipAddress,
    });

    return this.generateTokenPair(user, { mfaVerified: payload.mfaVerified });
  }

  async logout(
    accessToken: string,
    payload: JwtPayload,
    refreshCookie: string | undefined,
    ipAddress: string,
  ): Promise<void> {
    const ops: Promise<unknown>[] = [
      this.redis.setex(`blacklist:${accessToken}`, ACCESS_TOKEN_TTL_SECONDS, '1'),
    ];

    // Decode (not verify) the refresh cookie to extract the jti and blacklist it
    if (refreshCookie) {
      const refreshPayload = this.decodeRefreshToken(refreshCookie);
      if (refreshPayload?.refreshTokenId) {
        ops.push(
          this.redis.setex(
            `blacklist:refresh:${refreshPayload.refreshTokenId}`,
            REFRESH_TOKEN_TTL_SECONDS,
            '1',
          ),
          this.redis.srem(`sessions:${payload.sub}`, refreshPayload.refreshTokenId),
        );
      }
    }

    await Promise.all(ops);

    await this.auditService.log({
      tenantId: payload.tenantId,
      userId: payload.sub,
      action: 'user.logout',
      entityType: 'user',
      entityId: payload.sub,
      ipAddress,
    });
  }

  async logoutAll(
    userId: string,
    tenantId: string,
    accessToken: string,
    ipAddress: string,
  ): Promise<void> {
    await Promise.all([
      this.invalidateAllSessions(userId),
      // Also blacklist the current access token
      this.redis.setex(`blacklist:${accessToken}`, ACCESS_TOKEN_TTL_SECONDS, '1'),
    ]);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'user.logout_all',
      entityType: 'user',
      entityId: userId,
      ipAddress,
    });
  }

  async setupMfa(
    userId: string,
    tenantId: string,
    email: string,
  ): Promise<{ secret: string; qrCode: string }> {
    const secret = speakeasy.generateSecret({
      name: `Vaulted:${email}`,
      length: 32,
    });

    if (!secret.base32 || !secret.otpauth_url) {
      throw new Error('Failed to generate MFA secret');
    }

    // Store pending secret in Redis — only persisted after first successful verify
    await this.redis.setex(`mfa:pending:${userId}`, 10 * 60, secret.base32);

    const qrCode = await QRCode.toDataURL(secret.otpauth_url);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'user.mfa_setup_initiated',
      entityType: 'user',
      entityId: userId,
    });

    return { secret: secret.base32, qrCode };
  }

  async verifyMfa(
    userId: string,
    tenantId: string,
    code: string,
    ipAddress: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const user = await this.usersService.findById(userId);
    if (!user) throw new UnauthorizedException('User not found');

    const pendingSecret = await this.redis.get(`mfa:pending:${userId}`);

    // Pending = first-time setup; otherwise use stored (encrypted) secret
    const secretToVerify = pendingSecret ?? (await this.usersService.getMfaSecret(user));

    if (!secretToVerify) {
      throw new ForbiddenException('MFA not configured');
    }

    const isValid = speakeasy.totp.verify({
      secret: secretToVerify,
      encoding: 'base32',
      token: code,
      window: 1,
    });

    if (!isValid) {
      throw new UnauthorizedException('Invalid MFA code');
    }

    if (pendingSecret) {
      // Persist secret encrypted at rest
      await this.usersService.saveMfaSecret(userId, pendingSecret);
      await this.redis.del(`mfa:pending:${userId}`);
    }

    await this.auditService.log({
      tenantId,
      userId,
      action: 'user.mfa_verified',
      entityType: 'user',
      entityId: userId,
      ipAddress,
    });

    return this.generateTokenPair(user, { mfaVerified: true });
  }

  // ─── Private helpers ────────────────────────────────────────────────────────

  private async generateTokenPair(
    user: User,
    options: { mfaVerified?: boolean } = {},
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const refreshTokenId = uuidv4();

    const payload: JwtPayload = {
      sub: user.id,
      tenantId: user.tenantId,
      email: user.email,
      role: user.role,
      mfaVerified: options.mfaVerified ?? false,
    };

    const refreshPayload: JwtRefreshPayload = { ...payload, refreshTokenId };

    const [accessToken, refreshToken] = await Promise.all([
      this.jwtService.signAsync(payload, {
        secret: this.config.getOrThrow<string>('JWT_SECRET'),
        expiresIn: '15m',
      }),
      this.jwtService.signAsync(refreshPayload, {
        secret: this.config.getOrThrow<string>('JWT_REFRESH_SECRET'),
        expiresIn: '7d',
      }),
    ]);

    // Track this session so logout-all and replay escalation can find it
    await this.redis.sadd(`sessions:${user.id}`, refreshTokenId);
    await this.redis.expire(`sessions:${user.id}`, REFRESH_TOKEN_TTL_SECONDS);

    return { accessToken, refreshToken };
  }

  /**
   * Blacklists every active refresh token for a user and deletes the session set.
   * Called on logout-all and on replay attack detection.
   */
  private async invalidateAllSessions(userId: string): Promise<void> {
    const sessionKey = `sessions:${userId}`;
    const activeTokenIds = await this.redis.smembers(sessionKey);

    if (activeTokenIds.length > 0) {
      const pipeline = this.redis.pipeline();
      for (const jti of activeTokenIds) {
        pipeline.setex(`blacklist:refresh:${jti}`, REFRESH_TOKEN_TTL_SECONDS, '1');
      }
      pipeline.del(sessionKey);
      await pipeline.exec();
    } else {
      // Set may be empty but the key might still exist
      await this.redis.del(sessionKey);
    }
  }

  /**
   * Decodes a refresh token without verifying its signature.
   * Used only to extract the jti on logout (user is already authenticated via access token).
   */
  private decodeRefreshToken(token: string): JwtRefreshPayload | null {
    try {
      return this.jwtService.decode(token) as JwtRefreshPayload | null;
    } catch {
      return null;
    }
  }
}
