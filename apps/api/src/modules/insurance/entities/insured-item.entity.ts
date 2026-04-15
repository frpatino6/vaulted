import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

@Entity('insured_items')
export class InsuredItem {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'tenant_id' })
  @Index()
  tenantId!: string;

  @Column({ name: 'policy_id' })
  @Index()
  policyId!: string;

  // MongoDB ObjectId stored as string — intentionally not a FK to allow
  // PostgreSQL and MongoDB to remain decoupled
  @Column({ name: 'item_id', length: 24 })
  @Index()
  itemId!: string;

  @Column({ name: 'covered_value', type: 'numeric', precision: 15, scale: 2 })
  coveredValue!: number;

  @Column({ default: 'USD', length: 3 })
  currency!: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
