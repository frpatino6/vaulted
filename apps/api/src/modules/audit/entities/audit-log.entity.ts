import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  Index,
} from 'typeorm';

// WRITE-ONLY table — no UPDATE or DELETE ever allowed
@Entity('audit_logs')
export class AuditLog {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'tenant_id' })
  @Index()
  tenantId!: string;

  @Column({ name: 'user_id', nullable: true, type: 'varchar' })
  userId!: string | null;

  @Column({ length: 100 })
  action!: string;

  @Column({ name: 'entity_type', length: 100 })
  entityType!: string;

  @Column({ name: 'entity_id', nullable: true, type: 'varchar' })
  entityId!: string | null;

  @Column({ type: 'jsonb', nullable: true })
  metadata!: Record<string, unknown> | null;

  @Column({ name: 'ip_address', nullable: true, type: 'varchar', length: 45 })
  ipAddress!: string | null;

  @CreateDateColumn({ name: 'created_at' })
  @Index()
  createdAt!: Date;
}
