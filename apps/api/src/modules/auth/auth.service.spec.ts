import { ConflictException, UnauthorizedException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
import * as speakeasy from 'speakeasy';

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

    expect(redisClient.setex).toHaveBeenNthCalledWith(
      1,
      'blacklist:access-token',
      15 * 60,
      '1',
    );
    expect(redisClient.setex).toHaveBeenNthCalledWith(
      2,
      'blacklist:refresh:refresh-id-1',
      7 * 24 * 60 * 60,
      '1',
    );
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
});
