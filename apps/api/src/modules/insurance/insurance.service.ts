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
import { CryptoService } from '../../common/services/crypto.service';
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

export interface InsuredItemWithName extends InsuredItem {
  itemName: string;
}

export interface PolicyWithItems extends InsurancePolicy {
  insuredItems: InsuredItemWithName[];
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
    private readonly crypto: CryptoService,
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

    const encrypted = this.encryptPolicyFields(dto, tenantId);

    const policy = this.policyRepo.create({
      tenantId,
      provider: encrypted.provider,
      policyNumber: encrypted.policyNumber,
      coverageType: dto.coverageType,
      totalCoverageAmount: encrypted.totalCoverageAmount,
      premium: encrypted.premium,
      currency: dto.currency ?? 'USD',
      startDate: start,
      expiresAt: expires,
      status: 'active',
      notes: encrypted.notes,
    });

    const saved = await this.policyRepo.save(policy);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'insurance.policy.create',
      entityType: 'insurance_policy',
      entityId: saved.id,
    });

    return this.decryptPolicyFields(saved, tenantId);
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

    await this.syncExpiredStatuses(policies);

    return policies.map((p) => this.decryptPolicyFields(p, tenantId));
  }

  async findPolicyById(tenantId: string, policyId: string): Promise<PolicyWithItems> {
    const policy = await this.findOwnedPolicyOrThrow(tenantId, policyId);
    const insuredItems = await this.insuredItemRepo.find({
      where: { policyId, tenantId },
      order: { createdAt: 'DESC' },
    });

    await this.syncExpiredStatuses([policy]);

    const decryptedPolicy = this.decryptPolicyFields(policy, tenantId);
    const decryptedItems = insuredItems.map((i) => this.decryptInsuredItemFields(i, tenantId));

    const itemIds = insuredItems.map((i) => i.itemId);
    const mongoItems = await this.itemModel
      .find({ _id: { $in: itemIds }, tenantId })
      .select('_id name')
      .lean()
      .exec();

    const nameMap = new Map(mongoItems.map((i) => [String(i._id), i.name as string]));

    const insuredItemsWithName: InsuredItemWithName[] = decryptedItems.map((i) => ({
      ...i,
      itemName: nameMap.get(i.itemId) ?? i.itemId,
    }));

    return { ...decryptedPolicy, insuredItems: insuredItemsWithName };
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
    let resolvedStatus: InsurancePolicy['status'] | undefined = dto.status;
    if (dto.status !== 'cancelled' && expires > now && policy.status === 'expired') {
      resolvedStatus = 'active';
    }

    const encrypted = this.encryptPolicyFields(dto, tenantId);

    const updatePayload: Partial<InsurancePolicy> = {
      ...(dto.provider !== undefined ? { provider: encrypted.provider } : {}),
      ...(dto.policyNumber !== undefined ? { policyNumber: encrypted.policyNumber } : {}),
      ...(dto.coverageType !== undefined ? { coverageType: dto.coverageType } : {}),
      ...(dto.totalCoverageAmount !== undefined
        ? { totalCoverageAmount: encrypted.totalCoverageAmount }
        : {}),
      ...(dto.premium !== undefined ? { premium: encrypted.premium } : {}),
      ...(dto.startDate !== undefined ? { startDate: start } : {}),
      ...(dto.expiresAt !== undefined ? { expiresAt: expires } : {}),
      ...(resolvedStatus !== undefined ? { status: resolvedStatus } : {}),
      ...(dto.notes !== undefined ? { notes: encrypted.notes } : {}),
    };

    await this.policyRepo.update({ id: policyId, tenantId }, updatePayload);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'insurance.policy.update',
      entityType: 'insurance_policy',
      entityId: policyId,
    });

    const updated = await this.findOwnedPolicyOrThrow(tenantId, policyId);
    return this.decryptPolicyFields(updated, tenantId);
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

    const existing = await this.insuredItemRepo.findOne({
      where: { policyId, itemId: dto.itemId, tenantId },
    });

    if (existing) {
      throw new ConflictException('Item is already attached to this policy');
    }

    const encrypted = this.encryptInsuredItemFields(dto, tenantId);

    const insuredItem = this.insuredItemRepo.create({
      tenantId,
      policyId,
      itemId: dto.itemId,
      coveredValue: encrypted.coveredValue,
      currency: dto.currency ?? policy.currency,
    });

    const saved = await this.insuredItemRepo.save(insuredItem);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'insurance.item.attach',
      entityType: 'insured_item',
      entityId: saved.id,
      metadata: {
        policyId,
        itemId: dto.itemId,
        coveredValueRange: toValueRange(dto.coveredValue),
      },
    });

    return this.decryptInsuredItemFields(saved, tenantId);
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
    const allInsuredItems = await this.insuredItemRepo.find({ where: { tenantId } });

    const coverageMap = new Map<string, number>();
    for (const ii of allInsuredItems) {
      const decrypted = this.decryptInsuredItemFields(ii, tenantId);
      const value = Number(decrypted.coveredValue ?? 0);
      const current = coverageMap.get(decrypted.itemId) ?? 0;
      coverageMap.set(decrypted.itemId, current + value);
    }

    const mongoItems = await this.itemModel
      .find({ tenantId, status: { $ne: 'disposed' } })
      .select('_id name category valuation status')
      .lean()
      .exec();

    const uncovered: CoverageGapItem[] = [];
    const underinsured: CoverageGapItem[] = [];

    for (const item of mongoItems) {
      const currentValue =
        Number(item.valuation?.currentValue ?? item.valuation?.purchasePrice ?? 0);

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

    const now = new Date();
    const expiredPolicies = await this.policyRepo
      .createQueryBuilder('p')
      .select(['p.id', 'p.provider', 'p.policyNumber', 'p.expiresAt'])
      .where('p.tenantId = :tenantId', { tenantId })
      .andWhere('p.expiresAt < :now', { now })
      .andWhere('p.status != :cancelled', { cancelled: 'cancelled' })
      .orderBy('p.expiresAt', 'ASC')
      .getMany();

    const decryptedExpired = expiredPolicies.map((p) => {
      const d = this.decryptPolicyFields(p, tenantId);
      return {
        id: d.id,
        provider: d.provider,
        policyNumber: d.policyNumber,
        expiresAt: d.expiresAt,
      };
    });

    const report: CoverageGapReport = {
      uncovered,
      underinsured,
      expiredPolicies: decryptedExpired,
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

  // ── Field-Level Encryption helpers ───────────────────────────────────────

  private encryptPolicyFields(
    dto: CreatePolicyDto | UpdatePolicyDto,
    tenantId: string,
  ): {
    provider?: string;
    policyNumber?: string;
    totalCoverageAmount?: string;
    premium?: string | null;
    notes?: string | null;
  } {
    return {
      ...(dto.provider !== undefined
        ? { provider: this.crypto.encryptField(dto.provider, tenantId) }
        : {}),
      ...(dto.policyNumber !== undefined
        ? { policyNumber: this.crypto.encryptField(dto.policyNumber, tenantId) }
        : {}),
      ...(dto.totalCoverageAmount !== undefined
        ? { totalCoverageAmount: this.crypto.encryptField(String(dto.totalCoverageAmount), tenantId) }
        : {}),
      ...(dto.premium !== undefined
        ? { premium: dto.premium !== null ? this.crypto.encryptField(String(dto.premium), tenantId) : null }
        : {}),
      ...(dto.notes !== undefined
        ? { notes: dto.notes !== null ? this.crypto.encryptField(dto.notes, tenantId) : null }
        : {}),
    };
  }

  private decryptPolicyFields(
    raw: InsurancePolicy,
    tenantId: string,
  ): InsurancePolicy {
    const rawObj = raw as unknown as Record<string, unknown>;
    const provider = this.decryptFleField<string>(rawObj, 'provider', tenantId, (s) => s);
    const policyNumber = this.decryptFleField<string>(rawObj, 'policyNumber', tenantId, (s) => s);
    const totalCoverageAmount = this.decryptFleField<number>(
      rawObj,
      'totalCoverageAmount',
      tenantId,
      parseFloat,
    );
    const premium = this.decryptFleField<number | null>(
      rawObj,
      'premium',
      tenantId,
      (s) => (s ? parseFloat(s) : null),
    );
    const notes = this.decryptFleField<string | null>(rawObj, 'notes', tenantId, (s) => s);

    const result: InsurancePolicy = {
      ...raw,
      provider: provider ?? raw.provider,
      policyNumber: policyNumber ?? raw.policyNumber,
      totalCoverageAmount: (totalCoverageAmount ?? parseFloat(raw.totalCoverageAmount as string)) as never,
      premium: (premium ?? raw.premium as unknown as number) as never,
      notes: notes ?? raw.notes,
    };
    return result;
  }

  private encryptInsuredItemFields(
    dto: AttachItemDto,
    tenantId: string,
  ): { coveredValue: string } {
    return {
      coveredValue: this.crypto.encryptField(String(dto.coveredValue), tenantId),
    };
  }

  private decryptInsuredItemFields(
    raw: InsuredItem,
    tenantId: string,
  ): InsuredItem {
    const rawObj = raw as unknown as Record<string, unknown>;
    const coveredValue = this.decryptFleField<number>(
      rawObj,
      'coveredValue',
      tenantId,
      parseFloat,
    );

    const result: InsuredItem = {
      ...raw,
      coveredValue: (coveredValue ?? parseFloat(raw.coveredValue)) as never,
    };
    return result;
  }

  private decryptFleField<T>(
    raw: Record<string, unknown>,
    field: string,
    tenantId: string,
    transform: (plaintext: string) => T,
  ): T | undefined {
    const value = raw[field];
    if (value === undefined) return undefined;
    if (!this.crypto.isEncryptedField(value)) {
      if (typeof value === 'string') return transform(value);
      return value as T | undefined;
    }
    return transform(this.crypto.decryptField(value as string, tenantId));
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
