import { ConflictException, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
import * as speakeasy from 'speakeasy';
import { createHash } from 'crypto';
import * as bcrypt from 'bcrypt';

jest.mock('uuid', () => ({
  v4: jest.fn(() => 'refresh-token-id'),
}));

import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { TenantsService } from '../tenants/tenants.service';
import { AuditService } from '../audit/audit.service';
import { REDIS_CLIENT } from '../../common/decorators/inject-redis.decorator';
import { Role } from '../../common/enums/role.enum';

describe('AuthService', () => {
  let service: AuthService;

  const usersService = {
    findByEmail: jest.fn(),
    create: jest.fn(),
    verifyPassword: jest.fn(),
    updateLastLogin: jest.fn(),
    saveMfaSecret: jest.fn(),
    getMfaSecret: jest.fn(),
    findById: jest.fn(),
    findByInviteTokenHash: jest.fn(),
    completeInvite: jest.fn(),
  };

  const tenantsService = {
    create: jest.fn(),
  };

  const auditService = {
    log: jest.fn(),
  };

  const jwtService = {
    signAsync: jest.fn(),
  };

  const configService = {
    getOrThrow: jest.fn(),
  };

  const redisClient = {
    setex: jest.fn(),
    get: jest.fn(),
    del: jest.fn(),
    sadd: jest.fn(),
    expire: jest.fn(),
    smembers: jest.fn(),
    srem: jest.fn(),
    pipeline: jest.fn(() => ({
      setex: jest.fn().mockReturnThis(),
      del: jest.fn().mockReturnThis(),
      exec: jest.fn().mockResolvedValue([]),
    })),
  };

  const tenantRepository = {
    create: jest.fn(),
    save: jest.fn(),
  };

  const entityManager = {
    getRepository: jest.fn(),
  };

  const dataSource = {
    transaction: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    configService.getOrThrow.mockImplementation((key: string) => {
      if (key === 'JWT_SECRET') {
        return 'access-secret';
      }

      if (key === 'JWT_REFRESH_SECRET') {
        return 'refresh-secret';
      }

      return 'value';
    });

    jwtService.signAsync
      .mockResolvedValueOnce('access-token')
      .mockResolvedValueOnce('refresh-token');

    tenantRepository.create.mockImplementation((input) => input);
    tenantRepository.save.mockResolvedValue({ id: 'tenant-1', name: 'Vaulted Family' });
    entityManager.getRepository.mockReturnValue(tenantRepository);
    dataSource.transaction.mockImplementation(async (callback) => callback(entityManager));

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: usersService },
        { provide: TenantsService, useValue: tenantsService },
        { provide: AuditService, useValue: auditService },
        { provide: JwtService, useValue: jwtService },
        { provide: ConfigService, useValue: configService },
        { provide: DataSource, useValue: dataSource },
        { provide: REDIS_CLIENT, useValue: redisClient },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  it('register() creates tenant and user, returns accessToken', async () => {
    usersService.create.mockResolvedValue({
      id: 'user-1',
      tenantId: 'tenant-1',
      email: 'owner@vaulted.com',
      role: Role.OWNER,
    });

    const result = await service.register(
      'Vaulted Family',
      'owner@vaulted.com',
      'Password123!',
      '127.0.0.1',
    );

    expect(dataSource.transaction).toHaveBeenCalledTimes(1);
    expect(tenantRepository.create).toHaveBeenCalledWith({ name: 'Vaulted Family' });
    expect(tenantRepository.save).toHaveBeenCalledWith({ name: 'Vaulted Family' });
    expect(usersService.create).toHaveBeenCalledWith(
      {
        tenantId: 'tenant-1',
        email: 'owner@vaulted.com',
        password: 'Password123!',
        role: Role.OWNER,
      },
      entityManager,
    );
    expect(auditService.log).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: 'tenant-1',
        userId: 'user-1',
        action: 'user.register',
      }),
    );
    expect(result).toEqual({
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
    });
  });

  it('register() throws ConflictException if email already exists', async () => {
    usersService.create.mockRejectedValue(new ConflictException('Email already registered'));

    await expect(
      service.register('Vaulted Family', 'owner@vaulted.com', 'Password123!', '127.0.0.1'),
    ).rejects.toBeInstanceOf(ConflictException);

    expect(auditService.log).not.toHaveBeenCalled();
  });

  it('login() returns tokens and mfaRequired=false for STAFF role', async () => {
    usersService.findByEmail.mockResolvedValue({
      id: 'user-1',
      tenantId: 'tenant-1',
      email: 'staff@vaulted.com',
      passwordHash: 'hashed-password',
      role: Role.STAFF,
      isActive: true,
    });
    usersService.verifyPassword.mockResolvedValue(true);

    const result = await service.login('staff@vaulted.com', 'Password123!', '127.0.0.1');

    expect(usersService.updateLastLogin).toHaveBeenCalledWith('user-1');
    expect(auditService.log).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: 'tenant-1',
        userId: 'user-1',
        action: 'user.login',
      }),
    );
    expect(result).toEqual({
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      mfaRequired: false,
    });
  });

  it('login() throws UnauthorizedException for wrong password', async () => {
    usersService.findByEmail.mockResolvedValue({
      id: 'user-1',
      tenantId: 'tenant-1',
      email: 'staff@vaulted.com',
      passwordHash: 'hashed-password',
      role: Role.STAFF,
      isActive: true,
    });
    usersService.verifyPassword.mockResolvedValue(false);

    await expect(
      service.login('staff@vaulted.com', 'wrong-password', '127.0.0.1'),
    ).rejects.toBeInstanceOf(UnauthorizedException);

    expect(usersService.updateLastLogin).not.toHaveBeenCalled();
    expect(auditService.log).not.toHaveBeenCalled();
  });

it('logout() calls redis.setex to blacklist the token', async () => {
    await service.logout(
      'access-token',
      {
        sub: 'user-1',
        tenantId: 'tenant-1',
        email: 'staff@vaulted.com',
        role: Role.STAFF,
        mfaVerified: true,
      },
      'refresh-id-1',
      '127.0.0.1',
    );

    expect(redisClient.setex).toHaveBeenCalled();
  });

  it('refresh() throws UnauthorizedException when token is blacklisted (replay attack)', async () => {
    redisClient.get.mockResolvedValue('1');
    redisClient.smembers.mockResolvedValue([]);

    await expect(
      service.refresh(
        { sub: 'user-1', tenantId: 'tenant-1', email: 'user@vaulted.com', role: Role.OWNER, refreshTokenId: 'rt-1', mfaVerified: true },
        '127.0.0.1',
      ),
    ).rejects.toThrow();
  });

  it('verifyMfa() throws UnauthorizedException for invalid TOTP code', async () => {
    redisClient.get.mockResolvedValue('BASE32SECRET');
    usersService.findById.mockResolvedValue({
      id: 'user-1',
      tenantId: 'tenant-1',
      email: 'owner@vaulted.com',
      role: Role.OWNER,
      mfaSecret: null,
    });
    usersService.getMfaSecret.mockResolvedValue(null);

    const verifySpy = jest
      .spyOn(speakeasy.totp, 'verify')
      .mockReturnValue(false);

    await expect(
      service.verifyMfa('user-1', 'tenant-1', '123456', '127.0.0.1'),
    ).rejects.toBeInstanceOf(UnauthorizedException);

    expect(usersService.saveMfaSecret).not.toHaveBeenCalled();
    expect(redisClient.del).not.toHaveBeenCalled();
    expect(auditService.log).not.toHaveBeenCalled();

    verifySpy.mockRestore();
  });

  it('refresh() throws UnauthorizedException when token is blacklisted (replay attack)', async () => {
    redisClient.get.mockResolvedValue('1');

    await expect(
      service.refresh(
        { sub: 'user-1', tenantId: 'tenant-1', email: 'user@vaulted.com', role: Role.OWNER, refreshTokenId: 'rt-1', mfaVerified: true },
        '127.0.0.1',
      ),
    ).rejects.toBeInstanceOf(UnauthorizedException);

    expect(auditService.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'user.token_replay_detected' }),
    );
  });

  it('refresh() rotates token and removes from active sessions', async () => {
    redisClient.get.mockResolvedValue(null);
    usersService.findById.mockResolvedValue({
      id: 'user-1',
      tenantId: 'tenant-1',
      email: 'user@vaulted.com',
      role: Role.OWNER,
      isActive: true,
    });

    const result = await service.refresh(
      { sub: 'user-1', tenantId: 'tenant-1', email: 'user@vaulted.com', role: Role.OWNER, refreshTokenId: 'rt-1', mfaVerified: true },
      '127.0.0.1',
    );

    expect(redisClient.setex).toHaveBeenCalledWith('blacklist:refresh:rt-1', 7 * 24 * 60 * 60, '1');
    expect(redisClient.srem).toHaveBeenCalledWith('sessions:user-1', 'rt-1');
    expect(result.accessToken).toBeDefined();
  });

  it('logoutAll() invalidates all sessions and blacklists current token', async () => {
    redisClient.smembers.mockResolvedValue(['rt-1', 'rt-2']);

    await service.logoutAll('user-1', 'tenant-1', 'access-token', '127.0.0.1');

    expect(redisClient.pipeline).toHaveBeenCalled();
  });

  it('setupMfa() generates secret and stores in Redis with 10min TTL', async () => {
    const result = await service.setupMfa('user-1', 'tenant-1', 'owner@vaulted.com');

    expect(redisClient.setex).toHaveBeenCalledWith(
      'mfa:pending:user-1',
      10 * 60,
      expect.any(String),
    );
    expect(result.secret).toBeDefined();
    expect(result.qrCode).toBeDefined();
  });

  it('acceptInvite() accepts valid token and returns tokens', async () => {
    usersService.findByInviteTokenHash.mockResolvedValue({
      id: 'user-1',
      tenantId: 'tenant-1',
      email: 'new@vaulted.com',
      role: Role.MANAGER,
      status: 'invited',
      expiresAt: null,
      mfaEnabled: false,
    });
    usersService.completeInvite.mockResolvedValue({
      id: 'user-1',
      tenantId: 'tenant-1',
      email: 'new@vaulted.com',
      role: Role.MANAGER,
      isActive: true,
      mfaEnabled: false,
    });
    usersService.updateLastLogin.mockResolvedValue({});

    const result = await service.acceptInvite(
      { token: 'invitetoken', password: 'NewPass123!' },
      '127.0.0.1',
    );

    expect(usersService.completeInvite).toHaveBeenCalled();
    expect(result.accessToken).toBeDefined();
  });

  it('acceptInvite() throws BadRequestException for expired token', async () => {
    const pastDate = new Date('2020-01-01');
    usersService.findByInviteTokenHash.mockResolvedValue({
      id: 'user-1',
      status: 'invited',
      expiresAt: pastDate,
    });

    await expect(
      service.acceptInvite({ token: 'expiredtoken', password: 'Pass123!' }, '127.0.0.1'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
