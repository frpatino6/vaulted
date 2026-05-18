import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

export type NotificationType =
  | 'maintenance_due'
  | 'dry_cleaning_overdue'
  | 'item_added'
  | 'orchestrator_assigned'
  | 'orchestrator_completed'
  | 'general';

@Entity('notification_logs')
export class NotificationLog {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'tenant_id' })
  @Index()
  tenantId!: string;

  @Column({ name: 'user_id' })
  @Index()
  userId!: string;

  @Column({ type: 'varchar', length: 50 })
  type!: NotificationType;

  @Column()
  title!: string;

  @Column({ type: 'text' })
  body!: string;

  @Column({ type: 'jsonb', nullable: true, default: null })
  data!: Record<string, string> | null;

  @Column({ name: 'read_at', nullable: true, default: null, type: 'timestamptz' })
  readAt!: Date | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;
}
