import {
  Injectable,
  UnauthorizedException,
  ForbiddenException,
  BadRequestException,
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
import { createHash } from 'crypto';
import * as https from 'https';
import * as bcrypt from 'bcrypt';
import { UsersService } from '../users/users.service';
import { TenantsService } from '../tenants/tenants.service';
import { AuditService } from '../audit/audit.service';
import { Role, MFA_REQUIRED_ROLES } from '../../common/enums/role.enum';
import { JwtPayload } from './strategies/jwt.strategy';
import { JwtRefreshPayload } from './strategies/jwt-refresh.strategy';
import { User } from '../users/entities/user.entity';
import { Tenant } from '../tenants/entities/tenant.entity';
import { AcceptInviteDto } from './dto/accept-invite.dto';

const ACCESS_TOKEN_TTL_SECONDS = 15 * 60;
const BCRYPT_ROUNDS = 12;
const REFRESH_TOKEN_TTL_SECONDS = 7 * 24 * 60 * 60;
const MAX_LOGIN_ATTEMPTS = 10;
const LOCKOUT_DURATION_MINUTES = 15;

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
    const isBreached = await this.checkBreachedPassword(password);
    if (isBreached) {
      throw new BadRequestException(
        'This password has appeared in a known data breach. Please choose a different password.',
      );
    }

    // Atomic transaction: tenant + user created together or not at all
    const { tenant, user } = await this.dataSource.transaction(
      async (manager) => {
        const tenantRepo = manager.getRepository(Tenant);
        const tenant = tenantRepo.create({ name: tenantName });
        const savedTenant = await tenantRepo.save(tenant);

        const savedUser = await this.usersService.create(
          { tenantId: savedTenant.id, email, password, role: Role.OWNER },
          manager,
        );

        return { tenant: savedTenant, user: savedUser };
      },
    );

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
  ): Promise<{
    accessToken: string;
    refreshToken: string;
    mfaRequired: boolean;
    mfaSetupRequired: boolean;
  }> {
    const user = await this.usersService.findByEmail(email);

    if (user) {
      const lockedUntil = user.lockedUntil ? new Date(user.lockedUntil) : null;
      if (lockedUntil && lockedUntil > new Date()) {
        const remaining = Math.ceil((lockedUntil.getTime() - Date.now()) / 1000 / 60);
        throw new UnauthorizedException(`Account locked. Try again in ${remaining} minutes`);
      }
    }

    const dummyHash = '$2b$12$00000000000000000000000000000000000000000000000000';
    const passwordHash = user?.passwordHash ?? dummyHash;
    const passwordValid = await this.usersService.verifyPassword(password, passwordHash);

    if (!user || !user.isActive || !passwordValid) {
      if (user) {
        await this.usersService.incrementFailedLogins(user.id);
        const attempts = (user.failedLoginAttempts ?? 0) + 1;
        if (attempts >= MAX_LOGIN_ATTEMPTS) {
          await this.usersService.lockAccount(user.id, LOCKOUT_DURATION_MINUTES);
        }
      }
      throw new UnauthorizedException('Invalid credentials');
    }

    await this.usersService.resetFailedLogins(user.id);
    await this.usersService.updateLastLogin(user.id);

    const roleRequiresMfa = MFA_REQUIRED_ROLES.includes(user.role);
    const mfaRequired = roleRequiresMfa;
    const mfaSetupRequired = roleRequiresMfa && !user.mfaEnabled;

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

    return { ...tokens, mfaRequired, mfaSetupRequired };
  }

  async refresh(
    payload: JwtRefreshPayload,
    ipAddress: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const { refreshTokenId, sub: userId } = payload;
    const blacklistKey = `blacklist:refresh:${refreshTokenId}`;

    const consumed = await this.redis.eval(
      `
      local sessionKey = KEYS[1]
      local blacklistKey = KEYS[2]
      local jti = ARGV[1]
      local ttl = tonumber(ARGV[2])

      if redis.call('GET', blacklistKey) then return 0 end
      if redis.call('SISMEMBER', sessionKey, jti) ~= 1 then return 0 end

      redis.call('SREM', sessionKey, jti)
      redis.call('SETEX', blacklistKey, ttl, '1')
      return 1
      `,
      2,
      `sessions:${userId}`,
      blacklistKey,
      refreshTokenId,
      REFRESH_TOKEN_TTL_SECONDS,
    );

    if (consumed !== 1) {
      await this.auditService.log({
        tenantId: payload.tenantId,
        userId,
        action: 'user.token_replay_detected',
        entityType: 'user',
        entityId: userId,
        ipAddress,
      });
      await this.invalidateAllSessions(userId);
      throw new UnauthorizedException(
        'Session has been revoked. Please log in again.',
      );
    }

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
    const tokenHash = createHash('sha256').update(accessToken).digest('hex');
    const ops: Promise<unknown>[] = [
      this.redis.setex(
        `blacklist:${tokenHash}`,
        ACCESS_TOKEN_TTL_SECONDS,
        '1',
      ),
    ];

    if (refreshCookie) {
      const refreshPayload = await this.verifyRefreshToken(refreshCookie);
      if (refreshPayload?.refreshTokenId) {
        ops.push(
          this.redis.setex(
            `blacklist:refresh:${refreshPayload.refreshTokenId}`,
            REFRESH_TOKEN_TTL_SECONDS,
            '1',
          ),
          this.redis.srem(
            `sessions:${payload.sub}`,
            refreshPayload.refreshTokenId,
          ),
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
    const tokenHash = createHash('sha256').update(accessToken).digest('hex');
    await Promise.all([
      this.invalidateAllSessions(userId),
      this.redis.setex(
        `blacklist:${tokenHash}`,
        ACCESS_TOKEN_TTL_SECONDS,
        '1',
      ),
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
    password: string,
  ): Promise<{ secret: string; qrCode: string }> {
    const user = await this.usersService.findById(userId);
    if (!user || user.tenantId !== tenantId) {
      throw new UnauthorizedException('User not found');
    }
    if (user.mfaEnabled) {
      throw new ForbiddenException('MFA is already configured');
    }

    const passwordValid = await this.usersService.verifyPassword(
      password,
      user.passwordHash,
    );
    if (!passwordValid) {
      throw new UnauthorizedException('Invalid password');
    }

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

    await this.invalidateAllSessions(userId);

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
    if (!user || user.tenantId !== tenantId) {
      throw new UnauthorizedException('User not found');
    }

    const pendingSecret = await this.redis.get(`mfa:pending:${userId}`);
    const storedSecret = await this.usersService.getMfaSecret(user);

    // Existing MFA must always verify against the stored secret. Pending setup
    // secrets are only valid for first-time MFA enrollment.
    const secretToVerify = user.mfaEnabled
      ? storedSecret
      : pendingSecret ?? storedSecret;

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

    // Consume the code — prevent replay within the valid window
    const replayKey = `mfa:used:${userId}:${code}`;
    const alreadyUsed = await this.redis.set(replayKey, '1', 'EX', 180, 'NX');
    if (alreadyUsed === null) {
      throw new UnauthorizedException('Invalid MFA code');
    }

    if (pendingSecret && !user.mfaEnabled) {
      // Persist secret encrypted at rest
      await this.usersService.saveMfaSecret(userId, pendingSecret);
      await this.redis.del(`mfa:pending:${userId}`);
    } else if (pendingSecret && user.mfaEnabled) {
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
      typ: 'access',
      sub: user.id,
      tenantId: user.tenantId,
      email: user.email,
      role: user.role,
      mfaVerified: options.mfaVerified ?? false,
      propertyIds: user.propertyIds ?? undefined,
    };

    const refreshPayload: JwtRefreshPayload = {
      ...payload,
      typ: 'refresh',
      refreshTokenId,
    };

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

  async acceptInvite(
    dto: AcceptInviteDto,
    ipAddress: string,
  ): Promise<{
    accessToken: string;
    refreshToken: string;
    mfaRequired: boolean;
    mfaSetupRequired: boolean;
  }> {
    const tokenHash = createHash('sha256').update(dto.token).digest('hex');
    const user = await this.usersService.findByInviteTokenHash(tokenHash);

    if (!user) {
      throw new BadRequestException('Invalid or expired invite token');
    }

    if (user.expiresAt && user.expiresAt < new Date()) {
      throw new BadRequestException('Invite has expired');
    }

    if (user.status !== 'invited') {
      throw new BadRequestException('Invite already used');
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const updatedUser = await this.usersService.completeInvite(
      user.id,
      passwordHash,
    );

    await this.usersService.updateLastLogin(updatedUser.id);

    await this.auditService.log({
      tenantId: updatedUser.tenantId,
      userId: updatedUser.id,
      action: 'user.invite_accepted',
      entityType: 'user',
      entityId: updatedUser.id,
      ipAddress,
    });

    const roleRequiresMfa = MFA_REQUIRED_ROLES.includes(updatedUser.role);
    const tokens = await this.generateTokenPair(updatedUser, {
      mfaVerified: !roleRequiresMfa,
    });

    return {
      ...tokens,
      mfaRequired: roleRequiresMfa,
      mfaSetupRequired: roleRequiresMfa && !updatedUser.mfaEnabled,
    };
  }

  private async invalidateAllSessions(userId: string): Promise<void> {
    const sessionKey = `sessions:${userId}`;
    const activeTokenIds = await this.redis.smembers(sessionKey);

    if (activeTokenIds.length > 0) {
      const pipeline = this.redis.pipeline();
      for (const jti of activeTokenIds) {
        pipeline.setex(
          `blacklist:refresh:${jti}`,
          REFRESH_TOKEN_TTL_SECONDS,
          '1',
        );
      }
      pipeline.del(sessionKey);
      await pipeline.exec();
    } else {
      await this.redis.del(sessionKey);
    }
  }

  private async checkBreachedPassword(password: string): Promise<boolean> {
    const sha1 = createHash('sha1').update(password).digest('hex').toUpperCase();
    const prefix = sha1.slice(0, 5);
    const suffix = sha1.slice(5);

    return new Promise((resolve) => {
      const url = `https://api.pwnedpasswords.com/range/${prefix}`;
      const req = https.get(url, (res) => {
        let data = '';
        res.on('data', (chunk: string) => { data += chunk; });
        res.on('end', () => {
          const hashes = data.split('\n').map((line) => line.split(':')[0]);
          resolve(hashes.includes(suffix));
        });
      });
      req.on('error', (err) => {
        this.logger.warn('HIBP API call failed', err);
        resolve(false);
      });
      req.end();
    });
  }

  private async verifyRefreshToken(token: string): Promise<JwtRefreshPayload | null> {
    try {
      const refreshSecret = this.config.getOrThrow<string>('JWT_REFRESH_SECRET');
      return await this.jwtService.verifyAsync<JwtRefreshPayload>(token, { secret: refreshSecret });
    } catch {
      return null;
    }
  }
}
