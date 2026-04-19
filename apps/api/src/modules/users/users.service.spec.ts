import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConflictException, ForbiddenException, BadRequestException, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { UsersService } from './users.service';
import { User } from './entities/user.entity';
import { TenantsService } from '../tenants/tenants.service';
import { CryptoService } from '../../common/services/crypto.service';
import { Role } from '../../common/enums/role.enum';

describe('UsersService', () => {
  let service: UsersService;
  let userRepository: { findOne: jest.Mock; create: jest.Mock; save: jest.Mock; update: jest.Mock; find: jest.Mock };
  let cryptoService: { encrypt: jest.Mock; decrypt: jest.Mock };
  let configService: { get: jest.Mock };
  let tenantsService: { findById: jest.Mock };

  beforeEach(async () => {
    userRepository = {
      findOne: jest.fn(),
      create: jest.Mock(),
      save: jest.fn(),
      update: jest.fn(),
      find: jest.fn(),
    };

    cryptoService = {
      encrypt: jest.fn().mockReturnValue('encrypted'),
      decrypt: jest.fn().mockReturnValue('decrypted'),
    };

    configService = {
      get: jest.fn(),
    };

    tenantsService = {
      findById: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: getRepositoryToken(User), useValue: userRepository },
        { provide: CryptoService, useValue: cryptoService },
        { provide: ConfigService, useValue: configService },
        { provide: TenantsService, useValue: tenantsService },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  it('inviteUser creates pending user and sends invitation', async () => {
    userRepository.findOne.mockResolvedValue(null);
    userRepository.create.mockImplementation((data) => data);
    userRepository.save.mockResolvedValue({
      id: 'user-new',
      tenantId: 'tenant-1',
      email: 'new@vaulted.com',
      status: 'invited',
    });
    configService.get.mockReturnValue(null);
    tenantsService.findById.mockResolvedValue({ name: 'Test Tenant' });

    const result = await service.invite('tenant-1', 'owner-1', Role.OWNER, {
      email: 'new@vaulted.com',
      role: Role.MANAGER,
    });

    expect(result.invited).toBe(true);
  });

  it('inviteUser throws ConflictException if email already exists in tenant', async () => {
    userRepository.findOne.mockResolvedValue({ email: 'existing@vaulted.com' });

    await expect(
      service.invite('tenant-1', 'owner-1', Role.OWNER, { email: 'existing@vaulted.com', role: Role.STAFF }),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('acceptInvitation sets password, activates user', async () => {
    userRepository.findOne.mockResolvedValueOnce({
      id: 'user-1',
      status: 'invited',
      inviteToken: 'hash',
    });
    userRepository.findOne.mockResolvedValueOnce({
      id: 'user-1',
      isActive: true,
    });
    userRepository.update.mockResolvedValue({});
    userRepository.findOne.mockResolvedValue({
      id: 'user-1',
      email: 'user@vaulted.com',
      isActive: true,
    });

    const result = await service.completeInvite('user-1', 'hashed-password');

    expect(userRepository.update).toHaveBeenCalled();
  });

  it('acceptInvitation throws BadRequestException if token expired', async () => {
    userRepository.findOne.mockResolvedValue(null);

    await expect(
      service.completeInvite('user-1', 'hashed-password'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('updateRole throws ForbiddenException if caller is not OWNER', async () => {
    userRepository.findOne.mockResolvedValue({ id: 'user-target', tenantId: 'tenant-1' });

    await expect(
      service.updateUser('tenant-1', 'user-manager', 'user-target', { role: Role.OWNER }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('updateRole throws BadRequestException if trying to set own role', async () => {
    userRepository.findOne.mockResolvedValueOnce({ id: 'owner-1', tenantId: 'tenant-1', role: Role.OWNER });
    userRepository.findOne.mockResolvedValueOnce(null);

    await expect(
      service.updateUser('tenant-1', 'owner-1', 'owner-1', { role: Role.MANAGER }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('findByEmail returns user by email', async () => {
    const mockUser = { id: 'user-1', email: 'test@vaulted.com' };
    userRepository.findOne.mockResolvedValue(mockUser);

    const result = await service.findByEmail('test@vaulted.com');

    expect(result).toEqual(mockUser);
  });

  it('verifyPassword returns true for valid password', async () => {
    userRepository.findOne.mockResolvedValue({ passwordHash: '$2b$12$hash' });

    const result = await service.verifyPassword('password', '$2b$12$hash');

    expect(result).toBe(true);
  });
});