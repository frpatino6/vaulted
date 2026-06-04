import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';
import { Role } from '../../../common/enums/role.enum';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'tenant_id' })
  @Index()
  tenantId!: string;

  @Column({ unique: true, length: 255 })
  @Index()
  email!: string;

  @Column({ name: 'password_hash', select: false })
  passwordHash!: string;

  @Column({ type: 'enum', enum: Role, default: Role.STAFF })
  role!: Role;

  @Column({ name: 'mfa_enabled', default: false })
  mfaEnabled!: boolean;

  @Column({ name: 'mfa_secret', nullable: true, type: 'varchar', select: false })
  mfaSecret!: string | null;

  @Column({ name: 'is_active', default: true })
  isActive!: boolean;

  @Column({ name: 'property_ids', type: 'simple-array', nullable: true })
  propertyIds!: string[] | null;

  @Column({ name: 'invite_token', nullable: true, type: 'varchar', length: 64 })
  inviteToken!: string | null;

  @Column({ default: 'active', length: 32 })
  status!: string;

  @Column({ name: 'expires_at', nullable: true, type: 'timestamptz' })
  expiresAt!: Date | null;

  @Column({ name: 'last_login', nullable: true, type: 'timestamptz' })
  lastLogin!: Date | null;

  @Column({ name: 'failed_login_attempts', default: 0 })
  failedLoginAttempts!: number;

  @Column({ name: 'locked_until', nullable: true, type: 'timestamptz' })
  lockedUntil!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
