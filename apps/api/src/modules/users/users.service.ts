import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, EntityManager, In } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes } from 'crypto';
import { User } from './entities/user.entity';
import { Role } from '../../common/enums/role.enum';
import { CryptoService } from '../../common/services/crypto.service';
import { InviteUserDto } from './dto/invite-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { TenantsService } from '../tenants/tenants.service';

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
  private readonly logger = new Logger(UsersService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly cryptoService: CryptoService,
    private readonly configService: ConfigService,
    private readonly tenantsService: TenantsService,
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
    actorRole: Role,
    dto: InviteUserDto,
  ): Promise<{ invited: true; email: string; warning?: string }> {
    if (dto.role === Role.OWNER && actorRole !== Role.OWNER) {
      throw new ForbiddenException('Only owners can invite other owners');
    }

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

    const tenant = await this.tenantsService.findById(tenantId);
    const tenantName = tenant?.name ?? 'your organization';
    const appUrl = (this.configService.get<string>('APP_URL') ?? 'http://localhost:3000').replace(
      /\/$/,
      '',
    );
    const inviteLink = `${appUrl}/accept-invite?token=${inviteToken}`;

    const emailed = await this.sendInviteEmailViaResend({
      to: dto.email,
      tenantName,
      inviteLink,
    });

    // TODO: audit log
    if (!emailed) {
      return {
        invited: true,
        email: dto.email,
        warning: 'Email delivery failed',
      };
    }

    return { invited: true, email: dto.email };
  }

  async findByInviteTokenHash(inviteTokenHash: string): Promise<User | null> {
    return this.userRepository.findOne({ where: { inviteToken: inviteTokenHash } });
  }

  async completeInvite(userId: string, passwordHash: string): Promise<User> {
    await this.userRepository.update(userId, {
      passwordHash,
      isActive: true,
      status: 'active',
      inviteToken: null,
    });
    const user = await this.findById(userId);
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return user;
  }

  private async sendInviteEmailViaResend(params: {
    to: string;
    tenantName: string;
    inviteLink: string;
  }): Promise<boolean> {
    const apiKey = this.configService.get<string>('RESEND_API_KEY');
    if (!apiKey || apiKey.trim() === '') {
      this.logger.warn('RESEND_API_KEY is not set; invite email skipped');
      return false;
    }

    const from =
      this.configService.get<string>('EMAIL_FROM')?.trim() || 'onboarding@resend.dev';

    const html = `
<!DOCTYPE html>
<html>
<body style="font-family: system-ui, sans-serif; line-height: 1.5; color: #111;">
  <p>Hello,</p>
  <p>You have been invited to join <strong>${this.escapeHtml(params.tenantName)}</strong> on Vaulted.</p>
  <p>Click the button below to accept your invitation and set your password.</p>
  <p style="margin: 24px 0;">
    <a href="${this.escapeHtml(params.inviteLink)}" style="display: inline-block; padding: 12px 24px; background: #1a1a2e; color: #fff; text-decoration: none; border-radius: 8px;">Accept invitation</a>
  </p>
  <p style="font-size: 12px; color: #666;">If you did not expect this email, you can ignore it.</p>
</body>
</html>`;

    try {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from,
          to: [params.to],
          subject: "You've been invited to Vaulted",
          html,
        }),
      });

      if (!response.ok) {
        const bodyText = await response.text();
        this.logger.error(`Resend invite email failed: ${response.status} ${bodyText}`);
        return false;
      }

      return true;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`Resend invite email error: ${message}`);
      return false;
    }
  }

  private escapeHtml(text: string): string {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
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
