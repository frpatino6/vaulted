import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model, Types } from 'mongoose';
import Redis from 'ioredis';
import { InjectRedis } from '../../common/decorators/inject-redis.decorator';
import { InventoryService } from '../inventory/inventory.service';
import { Item, ItemDocument } from '../inventory/schemas/item.schema';
import { CreateDryCleaningDto } from './dto/create-dry-cleaning.dto';
import { CreateOutfitDto } from './dto/create-outfit.dto';
import { UpdateOutfitDto } from './dto/update-outfit.dto';
import {
  DryCleaningRecord,
  DryCleaningRecordDocument,
} from './schemas/dry-cleaning-record.schema';
import { Outfit, OutfitDocument } from './schemas/outfit.schema';

export interface WardrobeStatsResponse {
  totalItems: number;
  byType: Record<string, number>;
  byCleaning: Record<string, number>;
  bySeason: Record<string, number>;
  outfitsCount: number;
  itemsWithOutfits: number;
}

@Injectable()
export class WardrobeService {
  constructor(
    @InjectModel(Outfit.name)
    private readonly outfitModel: Model<OutfitDocument>,
    @InjectModel(DryCleaningRecord.name)
    private readonly dryCleaningRecordModel: Model<DryCleaningRecordDocument>,
    @InjectModel(Item.name)
    private readonly itemModel: Model<ItemDocument>,
    private readonly inventoryService: InventoryService,
    @InjectRedis() private readonly redis: Redis,
  ) {}

  async createOutfit(
    tenantId: string,
    userId: string,
    dto: CreateOutfitDto,
  ): Promise<Outfit> {
    await this.validateWardrobeItemsBelongToTenant(tenantId, dto.itemIds);
    const outfit = await this.outfitModel.create({
      tenantId,
      name: dto.name,
      description: dto.description,
      itemIds: dto.itemIds,
      season: dto.season,
      occasion: dto.occasion,
      photos: dto.photos ?? [],
      createdBy: userId,
    });
    await this.clearStatsCache(tenantId);
    return outfit;
  }

  async listOutfits(tenantId: string): Promise<Outfit[]> {
    return this.outfitModel.find({ tenantId }).sort({ createdAt: -1 }).exec();
  }

  async getOutfitWithItems(
    tenantId: string,
    outfitId: string,
  ): Promise<Record<string, unknown>> {
    const outfit = await this.findOutfitOrThrow(tenantId, outfitId);
    const items = await this.itemModel
      .find({ _id: { $in: outfit.itemIds }, tenantId })
      .select(
        '_id name photos category attributes.type attributes.cleaningStatus',
      )
      .exec();

    return {
      ...outfit.toObject(),
      items: items.map((item) => ({
        id: String(item._id),
        name: item.name,
        photo: item.photos[0] ?? null,
        category: item.category,
        type: (item.attributes?.type as string | undefined) ?? null,
        cleaningStatus:
          (item.attributes?.cleaningStatus as string | undefined) ?? null,
      })),
    };
  }

  async updateOutfit(
    tenantId: string,
    outfitId: string,
    dto: UpdateOutfitDto,
  ): Promise<Outfit> {
    await this.findOutfitOrThrow(tenantId, outfitId);

    if (dto.itemIds) {
      await this.validateWardrobeItemsBelongToTenant(tenantId, dto.itemIds);
    }

    const outfit = await this.outfitModel
      .findOneAndUpdate(
        { _id: outfitId, tenantId },
        {
          $set: {
            ...(dto.name !== undefined ? { name: dto.name } : {}),
            ...(dto.description !== undefined
              ? { description: dto.description }
              : {}),
            ...(dto.itemIds !== undefined ? { itemIds: dto.itemIds } : {}),
            ...(dto.season !== undefined ? { season: dto.season } : {}),
            ...(dto.occasion !== undefined ? { occasion: dto.occasion } : {}),
            ...(dto.photos !== undefined ? { photos: dto.photos } : {}),
          },
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!outfit) {
      throw new NotFoundException('Outfit not found');
    }

    await this.clearStatsCache(tenantId);
    return outfit;
  }

  async deleteOutfit(
    tenantId: string,
    outfitId: string,
  ): Promise<{ deleted: true }> {
    await this.findOutfitOrThrow(tenantId, outfitId);
    await this.outfitModel.deleteOne({ _id: outfitId, tenantId }).exec();
    await this.clearStatsCache(tenantId);
    return { deleted: true };
  }

  async addItemToOutfit(
    tenantId: string,
    outfitId: string,
    itemId: string,
  ): Promise<Outfit> {
    await this.validateWardrobeItemsBelongToTenant(tenantId, [itemId]);
    const outfit = await this.findOutfitOrThrow(tenantId, outfitId);
    if (outfit.itemIds.includes(itemId)) {
      return outfit;
    }

    const updated = await this.outfitModel
      .findOneAndUpdate(
        { _id: outfitId, tenantId },
        { $addToSet: { itemIds: itemId } },
        { new: true, runValidators: true },
      )
      .exec();

    if (!updated) {
      throw new NotFoundException('Outfit not found');
    }

    await this.clearStatsCache(tenantId);
    return updated;
  }

  async removeItemFromOutfit(
    tenantId: string,
    outfitId: string,
    itemId: string,
  ): Promise<Outfit> {
    await this.findOutfitOrThrow(tenantId, outfitId);

    const updated = await this.outfitModel
      .findOneAndUpdate(
        { _id: outfitId, tenantId },
        { $pull: { itemIds: itemId } },
        { new: true, runValidators: true },
      )
      .exec();

    if (!updated) {
      throw new NotFoundException('Outfit not found');
    }

    await this.clearStatsCache(tenantId);
    return updated;
  }

  async createDryCleaningRecord(
    tenantId: string,
    userId: string,
    itemId: string,
    dto: CreateDryCleaningDto,
  ): Promise<DryCleaningRecord> {
    await this.validateWardrobeItemsBelongToTenant(tenantId, [itemId]);

    const record = await this.dryCleaningRecordModel.create({
      tenantId,
      itemId,
      sentDate: dto.sentDate,
      cleanerName: dto.cleanerName,
      cost: dto.cost,
      currency: dto.currency ?? 'USD',
      notes: dto.notes,
      createdBy: userId,
    });
    await this.clearStatsCache(tenantId);
    return record;
  }

  async listDryCleaningHistory(
    tenantId: string,
    itemId: string,
  ): Promise<DryCleaningRecord[]> {
    await this.validateWardrobeItemsBelongToTenant(tenantId, [itemId]);
    return this.dryCleaningRecordModel
      .find({ tenantId, itemId })
      .sort({ sentDate: -1, createdAt: -1 })
      .exec();
  }

  async markDryCleaningReturned(
    tenantId: string,
    recordId: string,
  ): Promise<DryCleaningRecord> {
    const record = await this.dryCleaningRecordModel
      .findOne({ _id: recordId, tenantId })
      .exec();

    if (!record) {
      throw new NotFoundException('Dry cleaning record not found');
    }

    if (record.returnedDate) {
      return record;
    }

    const updatedRecord = await this.dryCleaningRecordModel
      .findOneAndUpdate(
        { _id: recordId, tenantId, returnedDate: null },
        { $set: { returnedDate: new Date() } },
        { new: true },
      )
      .exec();

    if (!updatedRecord) {
      throw new NotFoundException('Dry cleaning record not found');
    }

    const item = await this.inventoryService.findById(tenantId, record.itemId);
    const nextAttributes = {
      ...(item.attributes ?? {}),
      cleaningStatus: 'clean',
    };

    await this.inventoryService.update(tenantId, record.itemId, {
      attributes: nextAttributes,
    });

    await this.clearStatsCache(tenantId);
    return updatedRecord;
  }

  async getStats(tenantId: string): Promise<WardrobeStatsResponse> {
    const cacheKey = `wardrobe:stats:${tenantId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) {
      return JSON.parse(cached) as WardrobeStatsResponse;
    }

    const [
      totalItems,
      typeAgg,
      cleaningAgg,
      seasonAgg,
      outfitsCount,
      outfitItemIds,
    ] = await Promise.all([
      this.itemModel.countDocuments({ tenantId, category: 'wardrobe' }).exec(),
      this.aggregateAttributeCounts(tenantId, 'type'),
      this.aggregateAttributeCounts(tenantId, 'cleaningStatus'),
      this.aggregateAttributeCounts(tenantId, 'season'),
      this.outfitModel.countDocuments({ tenantId }).exec(),
      this.outfitModel.distinct('itemIds', { tenantId }),
    ]);

    const response: WardrobeStatsResponse = {
      totalItems,
      byType: {
        clothing: typeAgg.clothing ?? 0,
        footwear: typeAgg.footwear ?? 0,
        accessories: typeAgg.accessories ?? 0,
        jewelry_watches: typeAgg.jewelry_watches ?? 0,
        unknown: typeAgg.unknown ?? 0,
      },
      byCleaning: {
        clean: cleaningAgg.clean ?? 0,
        needs_cleaning: cleaningAgg.needs_cleaning ?? 0,
        at_dry_cleaner: cleaningAgg.at_dry_cleaner ?? 0,
        unknown: cleaningAgg.unknown ?? 0,
      },
      bySeason: {
        spring_summer: seasonAgg.spring_summer ?? 0,
        fall_winter: seasonAgg.fall_winter ?? 0,
        all_season: seasonAgg.all_season ?? 0,
        unknown: seasonAgg.unknown ?? 0,
      },
      outfitsCount,
      itemsWithOutfits: new Set(outfitItemIds.map((value) => String(value)))
        .size,
    };

    await this.redis.set(cacheKey, JSON.stringify(response), 'EX', 300);

    return response;
  }

  private async validateWardrobeItemsBelongToTenant(
    tenantId: string,
    itemIds: string[],
  ): Promise<void> {
    if (itemIds.length === 0) {
      return;
    }

    const hasInvalidId = itemIds.some(
      (itemId) => !Types.ObjectId.isValid(itemId),
    );
    if (hasInvalidId) {
      throw new BadRequestException('One or more itemIds are invalid');
    }

    const count = await this.itemModel
      .countDocuments({ _id: { $in: itemIds }, tenantId, category: 'wardrobe' })
      .exec();

    if (count !== itemIds.length) {
      throw new BadRequestException(
        'One or more items were not found in this tenant wardrobe',
      );
    }
  }

  private async findOutfitOrThrow(
    tenantId: string,
    outfitId: string,
  ): Promise<OutfitDocument> {
    const outfit = await this.outfitModel
      .findOne({ _id: outfitId, tenantId })
      .exec();
    if (!outfit) {
      throw new NotFoundException('Outfit not found');
    }

    return outfit;
  }

  private async clearStatsCache(tenantId: string): Promise<void> {
    await this.redis.del(`wardrobe:stats:${tenantId}`);
  }

  private async aggregateAttributeCounts(
    tenantId: string,
    field: 'type' | 'cleaningStatus' | 'season',
  ): Promise<Record<string, number>> {
    const path = `$attributes.${field}`;
    const rows = await this.itemModel
      .aggregate<{ _id: string; count: number }>([
        { $match: { tenantId, category: 'wardrobe' } },
        {
          $group: {
            _id: {
              $ifNull: [path, 'unknown'],
            },
            count: { $sum: 1 },
          },
        },
      ])
      .exec();

    return rows.reduce<Record<string, number>>((acc, row) => {
      const key = row._id || 'unknown';
      acc[key] = row.count;
      return acc;
    }, {});
  }
}
