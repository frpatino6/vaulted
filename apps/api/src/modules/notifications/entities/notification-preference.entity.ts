import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

@Entity('notification_preferences')
export class NotificationPreference {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'user_id', unique: true })
  userId!: string;

  @Column({ name: 'tenant_id' })
  @Index()
  tenantId!: string;

  @Column({ name: 'push_enabled', default: true })
  pushEnabled!: boolean;

  @Column({ name: 'email_enabled', default: true })
  emailEnabled!: boolean;

  @Column({ name: 'dry_cleaning_overdue', default: true })
  dryCleaningOverdue!: boolean;

  @Column({ name: 'maintenance_due', default: true })
  maintenanceDue!: boolean;

  @Column({ name: 'item_added', default: false })
  itemAdded!: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
