import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, EntityManager, In } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes } from 'crypto';
import { User } from './entities/user.entity';
import { Role } from '../../common/enums/role.enum';
import { CryptoService } from '../../common/services/crypto.service';
import { InviteUserDto } from './dto/invite-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

const BCRYPT_ROUNDS = 12;

export interface SanitizedUser {
  id: string;
  tenantId: string;
  email: string;
  role: Role;
  mfaEnabled: boolean;
  isActive: boolean;
  propertyIds: string[];
  status: string;
  expiresAt: Date | null;
  lastLogin: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly cryptoService: CryptoService,
  ) {}

  async create(
    params: { tenantId: string; email: string; password: string; role: Role },
    manager?: EntityManager,
  ): Promise<User> {
    const repo = manager ? manager.getRepository(User) : this.userRepository;

    const existing = await repo.findOne({ where: { email: params.email } });
    if (existing) {
      throw new ConflictException('Email already registered');
    }

    const passwordHash = await bcrypt.hash(params.password, BCRYPT_ROUNDS);
    const user = repo.create({
      tenantId: params.tenantId,
      email: params.email,
      passwordHash,
      role: params.role,
    });

    return repo.save(user);
  }

  async invite(
    tenantId: string,
    _invitedByUserId: string,
    dto: InviteUserDto,
  ): Promise<{ invited: true; email: string }> {
    const existing = await this.userRepository.findOne({
      where: { tenantId, email: dto.email },
    });

    if (existing) {
      throw new ConflictException('Email already registered for this tenant');
    }

    const inviteToken = randomBytes(32).toString('hex');
    const inviteTokenHash = createHash('sha256').update(inviteToken).digest('hex');
    const placeholderPasswordHash = await bcrypt.hash(
      randomBytes(32).toString('hex'),
      BCRYPT_ROUNDS,
    );

    const invitedUser = this.userRepository.create({
      tenantId,
      email: dto.email,
      passwordHash: placeholderPasswordHash,
      role: dto.role,
      isActive: false,
      propertyIds: dto.propertyIds,
      inviteToken: inviteTokenHash,
      status: 'invited',
      expiresAt: dto.expiresAt ?? null,
    });

    await this.userRepository.save(invitedUser);

    // TODO: wire NotificationsService — send invite email with token to dto.email
    // TODO: audit log
    return { invited: true, email: dto.email };
  }

  async findAllByTenant(tenantId: string): Promise<SanitizedUser[]> {
    const users = await this.userRepository.find({
      where: { tenantId },
      order: { createdAt: 'DESC' },
    });

    return users.map((user) => this.sanitizeUser(user));
  }

  async findSanitizedById(tenantId: string, userId: string): Promise<SanitizedUser> {
    const user = await this.findOwnedUserOrThrow(tenantId, userId);
    return this.sanitizeUser(user);
  }

  /** Batch lookup for presence / RBAC (same tenant scope). */
  async findSanitizedByIds(tenantId: string, userIds: string[]): Promise<Map<string, SanitizedUser>> {
    if (userIds.length === 0) {
      return new Map();
    }
    const users = await this.userRepository.find({
      where: { tenantId, id: In(userIds) },
    });
    return new Map(users.map((u) => [u.id, this.sanitizeUser(u)]));
  }

  async updateUser(
    tenantId: string,
    actorUserId: string,
    userId: string,
    dto: UpdateUserDto,
  ): Promise<SanitizedUser> {
    if (actorUserId === userId && dto.role !== undefined) {
      throw new BadRequestException('You cannot change your own role');
    }

    if (actorUserId === userId && dto.isActive === false) {
      throw new BadRequestException('You cannot deactivate your own account');
    }

    await this.findOwnedUserOrThrow(tenantId, userId);

    const updatePayload: Partial<User> = {
      ...(dto.role !== undefined ? { role: dto.role } : {}),
      ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      ...(dto.propertyIds !== undefined ? { propertyIds: dto.propertyIds } : {}),
    };

    if (dto.isActive === false) {
      updatePayload.status = 'inactive';
    }

    if (dto.isActive === true) {
      updatePayload.status = 'active';
    }

    await this.userRepository.update({ id: userId, tenantId }, updatePayload);

    const updatedUser = await this.findOwnedUserOrThrow(tenantId, userId);

    // TODO: audit log
    return this.sanitizeUser(updatedUser);
  }

  async deactivateUser(
    tenantId: string,
    actorUserId: string,
    userId: string,
  ): Promise<{ deactivated: true }> {
    if (actorUserId === userId) {
      throw new BadRequestException('You cannot deactivate your own account');
    }

    await this.findOwnedUserOrThrow(tenantId, userId);

    await this.userRepository.update(
      { id: userId, tenantId },
      {
        isActive: false,
        status: 'inactive',
      },
    );

    // TODO: audit log
    return { deactivated: true };
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { email } });
  }

  async findById(id: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { id } });
  }

  async verifyPassword(plain: string, hash: string): Promise<boolean> {
    return bcrypt.compare(plain, hash);
  }

  async updateLastLogin(userId: string): Promise<void> {
    await this.userRepository.update(userId, { lastLogin: new Date() });
  }

  async saveMfaSecret(userId: string, plaintextSecret: string): Promise<void> {
    const encryptedSecret = this.cryptoService.encrypt(plaintextSecret);
    await this.userRepository.update(userId, {
      mfaSecret: encryptedSecret,
      mfaEnabled: true,
    });
  }

  async getMfaSecret(user: User): Promise<string | null> {
    if (!user.mfaSecret) return null;
    return this.cryptoService.decrypt(user.mfaSecret);
  }

  async disableMfa(userId: string): Promise<void> {
    await this.userRepository.update(userId, {
      mfaSecret: null,
      mfaEnabled: false,
    });
  }

  canAccessProperty(user: User, propertyId: string): boolean {
    if (user.role === Role.OWNER || user.role === Role.MANAGER) {
      return true;
    }

    return (user.propertyIds ?? []).includes(propertyId);
  }

  private async findOwnedUserOrThrow(
    tenantId: string,
    userId: string,
  ): Promise<User> {
    const user = await this.userRepository.findOne({
      where: { id: userId, tenantId },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return user;
  }

  private sanitizeUser(user: User): SanitizedUser {
    return {
      id: user.id,
      tenantId: user.tenantId,
      email: user.email,
      role: user.role,
      mfaEnabled: user.mfaEnabled,
      isActive: user.isActive,
      propertyIds: user.propertyIds ?? [],
      status: user.status,
      expiresAt: user.expiresAt,
      lastLogin: user.lastLogin,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    };
  }
}
