import { Inject, Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Redis } from 'ioredis';
import { REDIS_CLIENT } from '../../common/decorators/inject-redis.decorator';
import { Role } from '../../common/enums/role.enum';
import { Item, ItemDocument } from '../inventory/schemas/item.schema';
import { AuditService } from '../audit/audit.service';
import { toValueRange } from '../../common/utils/value-range.util';

const DASHBOARD_CACHE_TTL_SECONDS = 120;

interface GroupCount {
  _id: string | null;
  count: number;
}

interface ValuationTotal {
  total: number | null;
}

interface DashboardAggregationResult {
  itemsByStatus: GroupCount[];
  itemsByCategory: GroupCount[];
  valuation: ValuationTotal[];
}

export interface DashboardResponse {
  totalProperties: number;
  totalItems: number;
  itemsByStatus: Record<string, number>;
  itemsByCategory: Record<string, number>;
  totalValuation: number;
  currency: string;
}

@Injectable()
export class DashboardService {
  constructor(
    @InjectModel(Item.name)
    private readonly itemModel: Model<ItemDocument>,
    @Inject(REDIS_CLIENT)
    private readonly redis: Redis,
    private readonly audit: AuditService,
  ) {}

  async getDashboard(tenantId: string, userId: string, role: Role, propertyIds: string[]): Promise<DashboardResponse> {
    const cacheKey = role === Role.OWNER ? `dashboard:${tenantId}` : `dashboard:${tenantId}:${userId}`;
    const cached = await this.redis.get(cacheKey);

    if (cached) {
      const cachedResponse = JSON.parse(cached) as DashboardResponse;
      void this.audit.log({
        tenantId,
        userId,
        action: 'dashboard.valuation.view',
        entityType: 'dashboard',
        metadata: {
          totalItems: cachedResponse.totalItems,
          totalProperties: cachedResponse.totalProperties,
          valuationRange: toValueRange(cachedResponse.totalValuation),
        },
      });
      return cachedResponse;
    }

    const [aggregation] = await this.itemModel.aggregate<DashboardAggregationResult>([
      {
        $match: {
          tenantId,
          ...(role !== Role.OWNER && { propertyId: { $in: propertyIds } }),
        },
      },
      {
        $facet: {
          itemsByStatus: [
            { $group: { _id: '$status', count: { $sum: 1 } } },
          ],
          itemsByCategory: [
            { $group: { _id: '$category', count: { $sum: 1 } } },
          ],
          valuation: [
            {
              $group: {
                _id: null,
                total: {
                  $sum: { $ifNull: ['$valuation.currentValue', 0] },
                },
              },
            },
          ],
          totalProperties: [
            { $group: { _id: '$propertyId' } },
            { $count: 'count' },
          ],
          totalItems: [
            { $count: 'count' },
          ],
        },
      },
    ]).exec();

    const itemsByStatus = this.toCountMap(aggregation?.itemsByStatus ?? []);
    const itemsByCategory = this.toCountMap(aggregation?.itemsByCategory ?? []);
    const totalValuation = aggregation?.valuation[0]?.total ?? 0;
    const totalProperties = this.getFacetCount(aggregation, 'totalProperties');
    const totalItems = this.getFacetCount(aggregation, 'totalItems');

    const response: DashboardResponse = {
      totalProperties,
      totalItems,
      itemsByStatus: {
        active: itemsByStatus.active ?? 0,
        loaned: itemsByStatus.loaned ?? 0,
        repair: itemsByStatus.repair ?? 0,
        storage: itemsByStatus.storage ?? 0,
        disposed: itemsByStatus.disposed ?? 0,
      },
      itemsByCategory,
      totalValuation,
      currency: 'USD',
    };

    await this.redis.setex(
      cacheKey,
      DASHBOARD_CACHE_TTL_SECONDS,
      JSON.stringify(response),
    );

    void this.audit.log({
      tenantId,
      userId,
      action: 'dashboard.valuation.view',
      entityType: 'dashboard',
      metadata: {
        totalItems: response.totalItems,
        totalProperties: response.totalProperties,
        valuationRange: toValueRange(response.totalValuation),
      },
    });

    return response;
  }

  private toCountMap(entries: GroupCount[]): Record<string, number> {
    return entries.reduce<Record<string, number>>((accumulator, entry) => {
      if (entry._id) {
        accumulator[entry._id] = entry.count;
      }

      return accumulator;
    }, {});
  }

  private getFacetCount(
    aggregation: DashboardAggregationResult & {
      totalProperties?: Array<{ count: number }>;
      totalItems?: Array<{ count: number }>;
    },
    key: 'totalProperties' | 'totalItems',
  ): number {
    return aggregation[key]?.[0]?.count ?? 0;
  }
}
