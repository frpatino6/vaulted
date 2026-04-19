import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { InsuranceService } from './insurance.service';
import { InsurancePolicy } from './entities/insurance-policy.entity';
import { InsuredItem } from './entities/insured-item.entity';
import { Item } from '../inventory/schemas/item.schema';
import { AuditService } from '../audit/audit.service';
import { AccessControlService } from '../../common/services/access-control.service';
import { Role } from '../../common/enums/role.enum';
import { toValueRange } from '../../common/utils/value-range.util';

describe('InsuranceService', () => {
  let service: InsuranceService;

  const policyRepo = {
    createQueryBuilder: jest.fn(),
    findOne: jest.fn(),
    find: jest.fn(),
  };

  const insuredItemRepo = {
    find: jest.fn(),
  };

  const itemModelFindChain = {
    select: jest.fn().mockReturnThis(),
    lean: jest.fn().mockReturnThis(),
    exec: jest.fn(),
  };

  const itemModel = {
    find: jest.fn(() => itemModelFindChain),
  };

  const auditService = {
    log: jest.fn(),
  };

  const accessControl = {
    stripValuation: jest.fn((doc: object) => {
      const copy = { ...doc };
      delete (copy as { valuation?: unknown }).valuation;
      return copy;
    }),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const qb = {
      select: jest.fn().mockReturnThis(),
      where: jest.fn().mockReturnThis(),
      andWhere: jest.fn().mockReturnThis(),
      orderBy: jest.fn().mockReturnThis(),
      update: jest.fn().mockReturnThis(),
      set: jest.fn().mockReturnThis(),
      whereInIds: jest.fn().mockReturnThis(),
      getMany: jest.fn().mockResolvedValue([]),
      execute: jest.fn().mockResolvedValue({}),
    };
    policyRepo.createQueryBuilder.mockReturnValue(qb);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InsuranceService,
        { provide: getRepositoryToken(InsurancePolicy), useValue: policyRepo },
        { provide: getRepositoryToken(InsuredItem), useValue: insuredItemRepo },
        { provide: getModelToken(Item.name), useValue: itemModel },
        { provide: AuditService, useValue: auditService },
        { provide: AccessControlService, useValue: accessControl },
      ],
    }).compile();

    service = module.get<InsuranceService>(InsuranceService);
  });

  it('findPolicyById() returns policy with itemName populated from MongoDB', async () => {
    const expiresAt = new Date('2025-12-31');
    policyRepo.findOne.mockResolvedValue({
      id: 'pol-1',
      tenantId: 'tenant-1',
      provider: 'Acme',
      policyNumber: 'P-001',
      coverageType: 'all-risk',
      totalCoverageAmount: 100_000,
      currency: 'USD',
      status: 'active',
      startDate: new Date('2024-01-01'),
      expiresAt,
    });

    insuredItemRepo.find.mockResolvedValue([
      { itemId: 'item-1', policyId: 'pol-1', coveredValue: 50_000, currency: 'USD' },
      { itemId: 'item-2', policyId: 'pol-1', coveredValue: 25_000, currency: 'USD' },
    ]);

    itemModelFindChain.exec.mockResolvedValue([
      { _id: 'item-1', name: 'Diamond Ring' },
      { _id: 'item-2', name: 'Pearl Necklace' },
    ]);

    const result = await service.findPolicyById('tenant-1', 'pol-1');

    expect(result.insuredItems).toHaveLength(2);
    expect(result.insuredItems[0].itemName).toBe('Diamond Ring');
    expect(result.insuredItems[1].itemName).toBe('Pearl Necklace');
    expect(itemModel.find).toHaveBeenCalled();
  });

  it('findPolicyById() falls back to itemId when MongoDB item not found', async () => {
    const expiresAt = new Date('2025-12-31');
    policyRepo.findOne.mockResolvedValue({
      id: 'pol-1',
      tenantId: 'tenant-1',
      provider: 'Acme',
      policyNumber: 'P-001',
      coverageType: 'all-risk',
      totalCoverageAmount: 100_000,
      currency: 'USD',
      status: 'active',
      startDate: new Date('2024-01-01'),
      expiresAt,
    });

    insuredItemRepo.find.mockResolvedValue([
      { itemId: 'item-unknown', policyId: 'pol-1', coveredValue: 10_000, currency: 'USD' },
    ]);

    itemModelFindChain.exec.mockResolvedValue([]);

    const result = await service.findPolicyById('tenant-1', 'pol-1');

    expect(result.insuredItems[0].itemName).toBe('item-unknown');
  });

  it('findPolicyById() returns empty array when no insured items', async () => {
    const expiresAt = new Date('2025-12-31');
    policyRepo.findOne.mockResolvedValue({
      id: 'pol-1',
      tenantId: 'tenant-1',
      provider: 'Acme',
      policyNumber: 'P-001',
      coverageType: 'all-risk',
      totalCoverageAmount: 100_000,
      currency: 'USD',
      status: 'active',
      startDate: new Date('2024-01-01'),
      expiresAt,
    });

    insuredItemRepo.find.mockResolvedValue([]);
    itemModelFindChain.exec.mockResolvedValue([]);

    const result = await service.findPolicyById('tenant-1', 'pol-1');

    expect(result.insuredItems).toHaveLength(0);
  });

  it('getCoverageGaps() returns full numeric report for manager and logs range metadata', async () => {
    insuredItemRepo.find.mockResolvedValue([]);
    itemModelFindChain.exec.mockResolvedValue([
      {
        _id: 'item-1',
        name: 'Watch',
        category: 'jewelry',
        valuation: { currentValue: 50_000, currency: 'USD' },
        status: 'active',
      },
    ]);

    const result = await service.getCoverageGaps('tenant-1', 'user-1', Role.MANAGER);

    expect(result).toMatchObject({
      totalUncoveredValue: 50_000,
      totalUnderinsuredGap: 0,
    });
    expect(auditService.log).toHaveBeenCalledWith({
      tenantId: 'tenant-1',
      userId: 'user-1',
      action: 'insurance.coverage_gaps.view',
      entityType: 'coverage_gap_report',
      metadata: {
        uncoveredCount: 1,
        underinsuredCount: 0,
        expiredPoliciesCount: 0,
        totalUncoveredRange: toValueRange(50_000),
        totalUnderinsuredRange: toValueRange(0),
      },
    });
  });

  it('getCoverageGaps() returns auditor report without exact totals and strips item valuation', async () => {
    insuredItemRepo.find.mockResolvedValue([]);
    itemModelFindChain.exec.mockResolvedValue([
      {
        _id: 'item-1',
        name: 'Watch',
        category: 'jewelry',
        valuation: { currentValue: 50_000, currency: 'USD' },
        status: 'active',
      },
    ]);

    const result = await service.getCoverageGaps('tenant-1', 'user-1', Role.AUDITOR);

    expect('totalUncoveredValue' in result).toBe(false);
    expect(result).toMatchObject({
      totalUncoveredValueRange: toValueRange(50_000),
      totalUnderinsuredGapRange: toValueRange(0),
    });
    expect(accessControl.stripValuation).toHaveBeenCalled();
    const auditor = result as { uncovered: { gap: string }[] };
    expect(auditor.uncovered[0].gap).toBe('high');
  });
});
