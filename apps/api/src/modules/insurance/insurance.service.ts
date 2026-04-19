import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Role } from '../../common/enums/role.enum';
import { AccessControlService } from '../../common/services/access-control.service';
import { AuditService } from '../audit/audit.service';
import { toValueRange } from '../../common/utils/value-range.util';
import { InsurancePolicy, PolicyStatus } from './entities/insurance-policy.entity';
import { InsuredItem } from './entities/insured-item.entity';
import { Item, ItemDocument } from '../inventory/schemas/item.schema';
import { CreatePolicyDto } from './dto/create-policy.dto';
import { UpdatePolicyDto } from './dto/update-policy.dto';
import { AttachItemDto } from './dto/attach-item.dto';

const GAP_SEVERITY_LOW_RATIO = 0.1;
const GAP_SEVERITY_MEDIUM_RATIO = 0.4;

export interface PolicyWithItems extends InsurancePolicy {
  insuredItems: InsuredItem[];
}

export interface CoverageGapItem {
  itemId: string;
  name: string;
  category: string;
  currentValue: number;
  coveredValue: number;
  gap: number;
  currency: string;
}

export interface CoverageGapReport {
  uncovered: CoverageGapItem[];   // Items with no insurance coverage at all
  underinsured: CoverageGapItem[]; // Items where coveredValue < currentValue
  expiredPolicies: Pick<InsurancePolicy, 'id' | 'provider' | 'policyNumber' | 'expiresAt'>[];
  totalUncoveredValue: number;
  totalUnderinsuredGap: number;
}

export type AuditorCoverageGapSeverity = 'low' | 'medium' | 'high';

export interface CoverageGapAuditorItem {
  itemId: string;
  name: string;
  category: string;
  coverageStatus: 'underinsured' | 'adequate';
  coveredPercentage: number;
  gap: AuditorCoverageGapSeverity;
}

/** Financial amounts redacted — use with {@link Role.AUDITOR} only. */
export interface CoverageGapAuditorReport {
  uncovered: CoverageGapAuditorItem[];
  underinsured: CoverageGapAuditorItem[];
  expiredPolicies: CoverageGapReport['expiredPolicies'];
  totalUncoveredValueRange: string;
  totalUnderinsuredGapRange: string;
}

@Injectable()
export class InsuranceService {
  constructor(
    @InjectRepository(InsurancePolicy)
    private readonly policyRepo: Repository<InsurancePolicy>,
    @InjectRepository(InsuredItem)
    private readonly insuredItemRepo: Repository<InsuredItem>,
    @InjectModel(Item.name)
    private readonly itemModel: Model<ItemDocument>,
    private readonly auditService: AuditService,
    private readonly accessControl: AccessControlService,
  ) {}

  // ─── Policies ────────────────────────────────────────────────────────────────

  async createPolicy(
    tenantId: string,
    userId: string,
    dto: CreatePolicyDto,
  ): Promise<InsurancePolicy> {
    const start = new Date(dto.startDate);
    const expires = new Date(dto.expiresAt);

    if (expires <= start) {
      throw new BadRequestException('expiresAt must be after startDate');
    }

    const policy = this.policyRepo.create({
      tenantId,
      provider: dto.provider,
      policyNumber: dto.policyNumber,
      coverageType: dto.coverageType,
      totalCoverageAmount: dto.totalCoverageAmount,
      premium: dto.premium ?? null,
      currency: dto.currency ?? 'USD',
      startDate: start,
      expiresAt: expires,
      status: 'active',
      notes: dto.notes ?? null,
    });

    const saved = await this.policyRepo.save(policy);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'insurance.policy.create',
      entityType: 'insurance_policy',
      entityId: saved.id,
    });

    return saved;
  }

  async findAllPolicies(
    tenantId: string,
    filters: { status?: PolicyStatus } = {},
  ): Promise<InsurancePolicy[]> {
    const where: Record<string, unknown> = { tenantId };
    if (filters.status) where['status'] = filters.status;

    const policies = await this.policyRepo.find({
      where,
      order: { createdAt: 'DESC' },
    });

    // Lazy expiration: mark as expired on read, persist in background
    await this.syncExpiredStatuses(policies);

    return policies;
  }

  async findPolicyById(tenantId: string, policyId: string): Promise<PolicyWithItems> {
    const policy = await this.findOwnedPolicyOrThrow(tenantId, policyId);
    const insuredItems = await this.insuredItemRepo.find({
      where: { policyId, tenantId },
      order: { createdAt: 'DESC' },
    });

    await this.syncExpiredStatuses([policy]);

    return { ...policy, insuredItems };
  }

  async updatePolicy(
    tenantId: string,
    policyId: string,
    userId: string,
    dto: UpdatePolicyDto,
  ): Promise<InsurancePolicy> {
    const policy = await this.findOwnedPolicyOrThrow(tenantId, policyId);

    if (policy.status === 'cancelled') {
      throw new BadRequestException('Cancelled policies cannot be modified');
    }

    const start = dto.startDate ? new Date(dto.startDate) : policy.startDate;
    const expires = dto.expiresAt ? new Date(dto.expiresAt) : policy.expiresAt;

    if (expires <= start) {
      throw new BadRequestException('expiresAt must be after startDate');
    }

    const now = new Date();
    // Date takes precedence: future expiresAt always means active (unless explicitly cancelling).
    // This handles the case where the form sends the stale status='expired' alongside a future date.
    let resolvedStatus: InsurancePolicy['status'] | undefined = dto.status;
    if (dto.status !== 'cancelled' && expires > now && policy.status === 'expired') {
      resolvedStatus = 'active';
    }

    const updatePayload: Partial<InsurancePolicy> = {
      ...(dto.provider !== undefined ? { provider: dto.provider } : {}),
      ...(dto.policyNumber !== undefined ? { policyNumber: dto.policyNumber } : {}),
      ...(dto.coverageType !== undefined ? { coverageType: dto.coverageType } : {}),
      ...(dto.totalCoverageAmount !== undefined
        ? { totalCoverageAmount: dto.totalCoverageAmount }
        : {}),
      ...(dto.premium !== undefined ? { premium: dto.premium } : {}),
      ...(dto.startDate !== undefined ? { startDate: start } : {}),
      ...(dto.expiresAt !== undefined ? { expiresAt: expires } : {}),
      ...(resolvedStatus !== undefined ? { status: resolvedStatus } : {}),
      ...(dto.notes !== undefined ? { notes: dto.notes } : {}),
    };

    await this.policyRepo.update({ id: policyId, tenantId }, updatePayload);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'insurance.policy.update',
      entityType: 'insurance_policy',
      entityId: policyId,
    });

    return this.findOwnedPolicyOrThrow(tenantId, policyId);
  }

  async deletePolicy(
    tenantId: string,
    policyId: string,
    userId: string,
  ): Promise<void> {
    await this.findOwnedPolicyOrThrow(tenantId, policyId);

    // Cascade: delete insured items first, then the policy
    await this.insuredItemRepo.delete({ policyId, tenantId });
    await this.policyRepo.delete({ id: policyId, tenantId });

    await this.auditService.log({
      tenantId,
      userId,
      action: 'insurance.policy.delete',
      entityType: 'insurance_policy',
      entityId: policyId,
    });
  }

  // ─── Item attachment ──────────────────────────────────────────────────────────

  async attachItem(
    tenantId: string,
    policyId: string,
    userId: string,
    dto: AttachItemDto,
  ): Promise<InsuredItem> {
    const policy = await this.findOwnedPolicyOrThrow(tenantId, policyId);

    if (policy.status === 'cancelled' || policy.status === 'expired') {
      throw new BadRequestException('Items can only be attached to active policies');
    }

    // Verify the item exists in MongoDB and belongs to this tenant
    const item = await this.itemModel
      .findOne({ _id: dto.itemId, tenantId })
      .select('_id name status')
      .lean()
      .exec();

    if (!item) {
      throw new NotFoundException('Item not found');
    }

    if (item.status === 'disposed') {
      throw new BadRequestException('Disposed items cannot be insured');
    }

    // Prevent duplicate attachment to same policy
    const existing = await this.insuredItemRepo.findOne({
      where: { policyId, itemId: dto.itemId, tenantId },
    });

    if (existing) {
      throw new ConflictException('Item is already attached to this policy');
    }

    const insuredItem = this.insuredItemRepo.create({
      tenantId,
      policyId,
      itemId: dto.itemId,
      coveredValue: dto.coveredValue,
      currency: dto.currency ?? policy.currency,
    });

    const saved = await this.insuredItemRepo.save(insuredItem);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'insurance.item.attach',
      entityType: 'insured_item',
      entityId: saved.id,
      metadata: { policyId, itemId: dto.itemId, coveredValue: dto.coveredValue },
    });

    return saved;
  }

  async detachItem(
    tenantId: string,
    policyId: string,
    itemId: string,
    userId: string,
  ): Promise<void> {
    await this.findOwnedPolicyOrThrow(tenantId, policyId);

    const insuredItem = await this.insuredItemRepo.findOne({
      where: { policyId, itemId, tenantId },
    });

    if (!insuredItem) {
      throw new NotFoundException('Item is not attached to this policy');
    }

    await this.insuredItemRepo.delete({ id: insuredItem.id, tenantId });

    await this.auditService.log({
      tenantId,
      userId,
      action: 'insurance.item.detach',
      entityType: 'insured_item',
      entityId: insuredItem.id,
      metadata: { policyId, itemId },
    });
  }

  // ─── Coverage analysis ────────────────────────────────────────────────────────

  async getCoverageGaps(
    tenantId: string,
    userId: string,
    role: Role,
  ): Promise<CoverageGapReport | CoverageGapAuditorReport> {
    // 1. All insured items for this tenant (across all policies)
    const allInsuredItems = await this.insuredItemRepo.find({ where: { tenantId } });

    // 2. Build map: itemId → total covered value (item may appear in multiple policies)
    const coverageMap = new Map<string, number>();
    for (const ii of allInsuredItems) {
      const current = coverageMap.get(ii.itemId) ?? 0;
      coverageMap.set(ii.itemId, current + Number(ii.coveredValue));
    }

    // 3. All active (non-disposed) items from MongoDB for this tenant
    const mongoItems = await this.itemModel
      .find({ tenantId, status: { $ne: 'disposed' } })
      .select('_id name category valuation status')
      .lean()
      .exec();

    // 4. Classify items
    const uncovered: CoverageGapItem[] = [];
    const underinsured: CoverageGapItem[] = [];

    for (const item of mongoItems) {
      const currentValue =
        Number(item.valuation?.currentValue ?? item.valuation?.purchasePrice ?? 0);

      // Skip items with no recorded valuation — cannot determine gap
      if (currentValue === 0) continue;

      const coveredValue = coverageMap.get(String(item._id)) ?? 0;
      const currency = item.valuation?.currency ?? 'USD';

      if (coveredValue === 0) {
        uncovered.push({
          itemId: String(item._id),
          name: item.name,
          category: item.category,
          currentValue,
          coveredValue: 0,
          gap: currentValue,
          currency,
        });
      } else if (coveredValue < currentValue) {
        underinsured.push({
          itemId: String(item._id),
          name: item.name,
          category: item.category,
          currentValue,
          coveredValue,
          gap: currentValue - coveredValue,
          currency,
        });
      }
    }

    // 5. Expired policies (any policy past expiresAt, regardless of recorded status)
    const now = new Date();
    const expiredPolicies = await this.policyRepo
      .createQueryBuilder('p')
      .select(['p.id', 'p.provider', 'p.policyNumber', 'p.expiresAt'])
      .where('p.tenantId = :tenantId', { tenantId })
      .andWhere('p.expiresAt < :now', { now })
      .andWhere('p.status != :cancelled', { cancelled: 'cancelled' })
      .orderBy('p.expiresAt', 'ASC')
      .getMany();

    const report: CoverageGapReport = {
      uncovered,
      underinsured,
      expiredPolicies: expiredPolicies.map((p) => ({
        id: p.id,
        provider: p.provider,
        policyNumber: p.policyNumber,
        expiresAt: p.expiresAt,
      })),
      totalUncoveredValue: uncovered.reduce((sum, i) => sum + i.gap, 0),
      totalUnderinsuredGap: underinsured.reduce((sum, i) => sum + i.gap, 0),
    };

    await this.auditService.log({
      tenantId,
      userId,
      action: 'insurance.coverage_gaps.view',
      entityType: 'coverage_gap_report',
      metadata: {
        uncoveredCount: uncovered.length,
        underinsuredCount: underinsured.length,
        expiredPoliciesCount: expiredPolicies.length,
        totalUncoveredRange: toValueRange(
          uncovered.reduce((s, i) => s + i.gap, 0),
        ),
        totalUnderinsuredRange: toValueRange(
          underinsured.reduce((s, i) => s + i.gap, 0),
        ),
      },
    });

    if (role === Role.AUDITOR) {
      const itemById = new Map<string, object>(
        mongoItems.map((doc) => [String(doc._id), doc as object]),
      );
      return this.toAuditorCoverageReport(report, itemById);
    }

    return report;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────────

  private gapSeverityForAuditor(
    gapAmount: number,
    basisValue: number,
  ): AuditorCoverageGapSeverity {
    if (basisValue <= 0) return 'low';
    const ratio = gapAmount / basisValue;
    if (ratio <= GAP_SEVERITY_LOW_RATIO) return 'low';
    if (ratio <= GAP_SEVERITY_MEDIUM_RATIO) return 'medium';
    return 'high';
  }

  private coveredPercentageForAuditor(coveredValue: number, currentValue: number): number {
    if (currentValue <= 0) return 0;
    return Math.min(100, Math.round((coveredValue / currentValue) * 1000) / 10);
  }

  private toAuditorGapItem(
    gap: CoverageGapItem,
    itemById: Map<string, object>,
  ): CoverageGapAuditorItem {
    const doc = itemById.get(gap.itemId);
    const stripped = doc
      ? this.accessControl.stripValuation({ ...doc } as unknown as Item)
      : null;
    const name =
      stripped && 'name' in stripped && stripped.name !== undefined
        ? String(stripped.name)
        : gap.name;
    const category =
      stripped && 'category' in stripped && stripped.category !== undefined
        ? String(stripped.category)
        : gap.category;
    const coverageStatus: CoverageGapAuditorItem['coverageStatus'] =
      gap.coveredValue >= gap.currentValue ? 'adequate' : 'underinsured';
    return {
      itemId: gap.itemId,
      name,
      category,
      coverageStatus,
      coveredPercentage: this.coveredPercentageForAuditor(gap.coveredValue, gap.currentValue),
      gap: this.gapSeverityForAuditor(gap.gap, gap.currentValue),
    };
  }

  private toAuditorCoverageReport(
    full: CoverageGapReport,
    itemById: Map<string, object>,
  ): CoverageGapAuditorReport {
    return {
      uncovered: full.uncovered.map((g) => this.toAuditorGapItem(g, itemById)),
      underinsured: full.underinsured.map((g) => this.toAuditorGapItem(g, itemById)),
      expiredPolicies: full.expiredPolicies,
      totalUncoveredValueRange: toValueRange(
        full.uncovered.reduce((s, i) => s + i.gap, 0),
      ),
      totalUnderinsuredGapRange: toValueRange(
        full.underinsured.reduce((s, i) => s + i.gap, 0),
      ),
    };
  }

  private async findOwnedPolicyOrThrow(
    tenantId: string,
    policyId: string,
  ): Promise<InsurancePolicy> {
    const policy = await this.policyRepo.findOne({
      where: { id: policyId, tenantId },
    });

    if (!policy) {
      throw new NotFoundException('Insurance policy not found');
    }

    return policy;
  }

  /**
   * Marks policies as expired if their expiresAt date has passed.
   * Updates the DB in background — does not block the response.
   */
  private syncExpiredStatuses(policies: InsurancePolicy[]): Promise<void> {
    const now = new Date();
    const toExpire = policies.filter(
      (p) => p.status === 'active' && p.expiresAt < now,
    );

    if (toExpire.length === 0) return Promise.resolve();

    // Update in-memory immediately so the response is accurate
    for (const p of toExpire) {
      p.status = 'expired';
    }

    // Persist asynchronously — fire and forget (non-critical path)
    void this.policyRepo
      .createQueryBuilder()
      .update(InsurancePolicy)
      .set({ status: 'expired' })
      .whereInIds(toExpire.map((p) => p.id))
      .execute()
      .catch(() => {
        // Silently ignore — next read will retry
      });

    return Promise.resolve();
  }
}
