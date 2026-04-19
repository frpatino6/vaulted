import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { DashboardService, DashboardResponse } from './dashboard.service';
import { Item } from '../inventory/schemas/item.schema';
import { REDIS_CLIENT } from '../../common/decorators/inject-redis.decorator';
import { AuditService } from '../audit/audit.service';
import { Role } from '../../common/enums/role.enum';
import { toValueRange } from '../../common/utils/value-range.util';

describe('DashboardService', () => {
  let service: DashboardService;

  const aggregateExec = jest.fn();
  const itemModel = {
    aggregate: jest.fn(() => ({ exec: aggregateExec })),
  };

  const redis = {
    get: jest.fn(),
    setex: jest.fn(),
  };

  const audit = {
    log: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        DashboardService,
        { provide: getModelToken(Item.name), useValue: itemModel },
        { provide: REDIS_CLIENT, useValue: redis },
        { provide: AuditService, useValue: audit },
      ],
    }).compile();

    service = module.get<DashboardService>(DashboardService);
  });

  it('getDashboard() returns cached payload and logs valuation range audit for owner', async () => {
    const cached: DashboardResponse = {
      totalProperties: 2,
      totalItems: 10,
      itemsByStatus: {
        active: 8,
        loaned: 1,
        repair: 0,
        storage: 1,
        disposed: 0,
      },
      itemsByCategory: { art: 3 },
      totalValuation: 75_000,
      currency: 'USD',
    };
    redis.get.mockResolvedValue(JSON.stringify(cached));

    const result = await service.getDashboard('tenant-1', 'user-1', Role.OWNER, []);

    expect(result).toEqual(cached);
    expect(itemModel.aggregate).not.toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith({
      tenantId: 'tenant-1',
      userId: 'user-1',
      action: 'dashboard.valuation.view',
      entityType: 'dashboard',
      metadata: {
        totalItems: cached.totalItems,
        totalProperties: cached.totalProperties,
        valuationRange: toValueRange(cached.totalValuation),
      },
    });
  });

  it('getDashboard() uses per-user cache key when role is not owner', async () => {
    redis.get.mockResolvedValue(null);
    aggregateExec.mockResolvedValue([
      {
        itemsByStatus: [],
        itemsByCategory: [],
        valuation: [{ total: 0 }],
        totalProperties: [{ count: 0 }],
        totalItems: [{ count: 0 }],
      },
    ]);

    await service.getDashboard('tenant-1', 'user-2', Role.MANAGER, ['p1']);

    expect(redis.get).toHaveBeenCalledWith('dashboard:tenant-1:user-2');
    expect(itemModel.aggregate).toHaveBeenCalled();
    const pipeline = (itemModel.aggregate as jest.Mock).mock.calls[0][0] as unknown[];
    const matchStage = pipeline[0] as { $match: Record<string, unknown> };
    expect(matchStage.$match).toEqual({
      tenantId: 'tenant-1',
      propertyId: { $in: ['p1'] },
    });
  });

  it('getDashboard() owner match does not filter by propertyIds', async () => {
    redis.get.mockResolvedValue(null);
    aggregateExec.mockResolvedValue([
      {
        itemsByStatus: [],
        itemsByCategory: [],
        valuation: [{ total: 0 }],
        totalProperties: [{ count: 0 }],
        totalItems: [{ count: 0 }],
      },
    ]);

    await service.getDashboard('tenant-1', 'user-1', Role.OWNER, ['ignored']);

    const pipelineOwner = (itemModel.aggregate as jest.Mock).mock.calls[0][0] as unknown[];
    const matchStageOwner = pipelineOwner[0] as { $match: Record<string, unknown> };
    expect(matchStageOwner.$match).toEqual({ tenantId: 'tenant-1' });
  });

  it('getDashboard() persists fresh aggregation and logs audit with valuation range', async () => {
    redis.get.mockResolvedValue(null);
    aggregateExec.mockResolvedValue([
      {
        itemsByStatus: [{ _id: 'active', count: 2 }],
        itemsByCategory: [{ _id: 'furniture', count: 2 }],
        valuation: [{ total: 12_500 }],
        totalProperties: [{ count: 1 }],
        totalItems: [{ count: 2 }],
      },
    ]);

    const result = await service.getDashboard('tenant-1', 'user-1', Role.OWNER, []);

    expect(result.totalValuation).toBe(12_500);
    expect(redis.setex).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith({
      tenantId: 'tenant-1',
      userId: 'user-1',
      action: 'dashboard.valuation.view',
      entityType: 'dashboard',
      metadata: {
        totalItems: 2,
        totalProperties: 1,
        valuationRange: toValueRange(12_500),
      },
    });
  });
});
