import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

export type CoverageType = 'all-risk' | 'named-peril' | 'liability' | 'scheduled';
export type PolicyStatus = 'active' | 'expired' | 'cancelled';

@Entity('insurance_policies')
export class InsurancePolicy {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ name: 'tenant_id' })
  @Index()
  tenantId!: string;

  @Column({ length: 255 })
  provider!: string;

  @Column({ name: 'policy_number', length: 100 })
  policyNumber!: string;

  @Column({
    name: 'coverage_type',
    type: 'enum',
    enum: ['all-risk', 'named-peril', 'liability', 'scheduled'],
  })
  coverageType!: CoverageType;

  @Column({ name: 'total_coverage_amount', type: 'numeric', precision: 15, scale: 2 })
  totalCoverageAmount!: number;

  @Column({ type: 'numeric', precision: 15, scale: 2, nullable: true })
  premium!: number | null;

  @Column({ default: 'USD', length: 3 })
  currency!: string;

  @Column({ name: 'start_date', type: 'timestamptz' })
  startDate!: Date;

  @Column({ name: 'expires_at', type: 'timestamptz' })
  expiresAt!: Date;

  @Column({
    type: 'enum',
    enum: ['active', 'expired', 'cancelled'],
    default: 'active',
  })
  status!: PolicyStatus;

  @Column({ type: 'text', nullable: true })
  notes!: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt!: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt!: Date;
}
