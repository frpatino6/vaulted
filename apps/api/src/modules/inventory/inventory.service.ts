import { Injectable, Logger, NotFoundException, Optional } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { DataSource } from 'typeorm';
import { InjectDataSource } from '@nestjs/typeorm';
import * as QRCode from 'qrcode';
import { CreateItemDto, ItemStatus } from './dto/create-item.dto';
import { LoanItemDto } from './dto/loan-item.dto';
import { MoveItemDto } from './dto/move-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { Item, ItemDocument } from './schemas/item.schema';
import { ItemHistory, ItemHistoryDocument } from './schemas/item-history.schema';
import { Property, PropertyDocument } from '../properties/schemas/property.schema';
import { EmbeddingService } from '../ai/shared/embedding.service';
import { Role } from '../../common/enums/role.enum';
import { AccessControlService } from '../../common/services/access-control.service';

interface InventoryFilters {
  propertyId?: string;
  roomId?: string;
  category?: string;
  status?: string;
  unlocated?: boolean;
  limit?: number;
}

interface InventorySearchFilters {
  query?: string;
  category?: string;
  propertyId?: string;
  status?: string;
  page?: number;
  limit?: number;
}

export interface InventorySearchResponse {
  items: Array<ItemDocument & { propertyName: string | null; roomName: string | null }>;
  total: number;
  page: number;
  limit: number;
}

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

@Injectable()
export class InventoryService {
  private readonly logger = new Logger(InventoryService.name);

  constructor(
    @InjectModel(Item.name)
    private readonly itemModel: Model<ItemDocument>,
    @InjectModel(ItemHistory.name)
    private readonly itemHistoryModel: Model<ItemHistoryDocument>,
    @InjectModel(Property.name)
    private readonly propertyModel: Model<PropertyDocument>,
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly accessControl: AccessControlService,
    @Optional() private readonly embeddingService?: EmbeddingService,
  ) {}

  async create(tenantId: string, userId: string, dto: CreateItemDto): Promise<Item> {
    const item = await this.itemModel.create({
      tenantId,
      propertyId: dto.propertyId,
      roomId: dto.roomId,
      name: dto.name,
      category: dto.category,
      subcategory: dto.subcategory,
      attributes: dto.attributes,
      valuation: dto.valuation,
      status: dto.status ?? ItemStatus.ACTIVE,
      photos: dto.photos ?? [],
      documents: dto.documents ?? [],
      tags: dto.tags ?? [],
      serialNumber: dto.serialNumber,
      locationDetail: dto.locationDetail,
      sectionId: dto.sectionId ?? null,
      createdBy: userId,
    });

    const qrCode = await QRCode.toDataURL(`vaulted://items/${String(item._id)}`);
    item.qrCode = qrCode;
    await item.save();

    void this.indexItemEmbedding(item);

    return item;
  }

  async findAll(
    tenantId: string,
    filters: InventoryFilters,
    role: Role,
    userId: string,
  ): Promise<Item[]> {
    const query: Record<string, unknown> = { tenantId };
    const allowedPropertyIds = await this.accessControl.getAllowedPropertyIds(userId, role);

    if (allowedPropertyIds !== null) {
      if (allowedPropertyIds.length === 0) return [];
      if (filters.propertyId) {
        if (!allowedPropertyIds.includes(filters.propertyId)) return [];
        query.propertyId = filters.propertyId;
      } else {
        query.propertyId = { $in: allowedPropertyIds };
      }
    } else {
      if (filters.propertyId) query.propertyId = filters.propertyId;
    }

    if (filters.unlocated) {
      if (filters.propertyId) {
        const property = await this.propertyModel.findOne({ _id: filters.propertyId, tenantId });
        const validRoomIds = (property?.floors ?? [])
          .flatMap((f) => f.rooms.map((r) => r.roomId))
          .filter(Boolean);
        query.roomId = { $nin: validRoomIds };
      } else {
        query.roomId = { $in: [null, ''] };
      }
      query.status = { $ne: 'disposed' };
    } else if (filters.roomId) {
      query.roomId = filters.roomId;
    }

    if (filters.category) {
      query.category = filters.category;
    }

    if (filters.status) {
      query.status = filters.status;
    }

    const q = this.itemModel.find(query).sort({ createdAt: -1 });
    if (filters.limit && filters.limit > 0) q.limit(filters.limit);
    const items = await q.exec();
    if (role === Role.OWNER) return items;
    return items.map((item) => this.accessControl.stripValuation(item.toObject()) as Item);
  }

  async findById(
    tenantId: string,
    itemId: string,
    role: Role = Role.OWNER,
    userId = '',
  ): Promise<Item> {
    const item = await this.findOwnedItemOrThrow(tenantId, itemId);
    if (userId) {
      const allowedPropertyIds = await this.accessControl.getAllowedPropertyIds(userId, role);
      if (allowedPropertyIds !== null && !allowedPropertyIds.includes(String(item.propertyId))) {
        throw new NotFoundException('Item not found');
      }
    }
    if (role === Role.OWNER) return item;
    return this.accessControl.stripValuation(item.toObject()) as Item;
  }

  async update(tenantId: string, itemId: string, dto: UpdateItemDto): Promise<Item> {
    await this.findOwnedItemOrThrow(tenantId, itemId);

    const item = await this.itemModel
      .findOneAndUpdate(
        { _id: itemId, tenantId },
        {
          $set: {
            ...(dto.propertyId !== undefined ? { propertyId: dto.propertyId } : {}),
            ...(dto.roomId !== undefined ? { roomId: dto.roomId } : {}),
            ...(dto.name !== undefined ? { name: dto.name } : {}),
            ...(dto.category !== undefined ? { category: dto.category } : {}),
            ...(dto.subcategory !== undefined ? { subcategory: dto.subcategory } : {}),
            ...(dto.attributes !== undefined ? { attributes: dto.attributes } : {}),
            ...(dto.valuation !== undefined ? { valuation: dto.valuation } : {}),
            ...(dto.status !== undefined ? { status: dto.status } : {}),
            ...(dto.photos !== undefined ? { photos: dto.photos } : {}),
            ...(dto.documents !== undefined ? { documents: dto.documents } : {}),
            ...(dto.tags !== undefined ? { tags: dto.tags } : {}),
            ...(dto.serialNumber !== undefined ? { serialNumber: dto.serialNumber } : {}),
            ...(dto.locationDetail !== undefined ? { locationDetail: dto.locationDetail } : {}),
            ...(dto.sectionId !== undefined ? { sectionId: dto.sectionId } : {}),
          },
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!item) {
      throw new NotFoundException('Item not found');
    }

    void this.indexItemEmbedding(item);

    return item;
  }

  async delete(tenantId: string, itemId: string): Promise<Item> {
    await this.findOwnedItemOrThrow(tenantId, itemId);

    const item = await this.itemModel
      .findOneAndUpdate(
        { _id: itemId, tenantId },
        { $set: { status: ItemStatus.DISPOSED } },
        { new: true, runValidators: true },
      )
      .exec();

    if (!item) {
      throw new NotFoundException('Item not found');
    }

    await this.itemHistoryModel.create({
      itemId,
      tenantId,
      action: 'status_changed',
      performedBy: 'system',
      notes: 'Soft deleted by setting status to disposed',
    });

    return item;
  }

  async move(
    tenantId: string,
    itemId: string,
    userId: string,
    dto: MoveItemDto,
  ): Promise<Item> {
    const item = await this.findOwnedItemOrThrow(tenantId, itemId);

    const updatedItem = await this.itemModel
      .findOneAndUpdate(
        { _id: itemId, tenantId },
        {
          $set: {
            propertyId: dto.toPropertyId,
            roomId: dto.toRoomId,
          },
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!updatedItem) {
      throw new NotFoundException('Item not found');
    }

    await this.itemHistoryModel.create({
      itemId,
      tenantId,
      action: 'moved',
      fromPropertyId: item.propertyId,
      toPropertyId: dto.toPropertyId,
      fromRoomId: item.roomId ?? undefined,
      toRoomId: dto.toRoomId,
      performedBy: userId,
      notes: dto.notes,
    });

    return updatedItem;
  }

  async loan(
    tenantId: string,
    itemId: string,
    userId: string,
    dto: LoanItemDto,
  ): Promise<Item> {
    const item = await this.findOwnedItemOrThrow(tenantId, itemId);
    const nextAttributes = {
      ...(item.attributes ?? {}),
      loan: {
        borrowerName: dto.borrowerName,
        borrowerContact: dto.borrowerContact,
        expectedReturnDate: dto.expectedReturnDate,
        notes: dto.notes,
      },
    };

    const updatedItem = await this.itemModel
      .findOneAndUpdate(
        { _id: itemId, tenantId },
        {
          $set: {
            status: ItemStatus.LOANED,
            attributes: nextAttributes,
          },
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!updatedItem) {
      throw new NotFoundException('Item not found');
    }

    await this.itemHistoryModel.create({
      itemId,
      tenantId,
      action: 'loaned',
      fromPropertyId: item.propertyId,
      fromRoomId: item.roomId ?? undefined,
      performedBy: userId,
      notes: dto.notes,
    });

    return updatedItem;
  }

  async getHistory(tenantId: string, itemId: string): Promise<ItemHistory[]> {
    await this.findOwnedItemOrThrow(tenantId, itemId);
    return this.itemHistoryModel
      .find({ tenantId, itemId })
      .sort({ timestamp: -1 })
      .exec();
  }

  async search(
    tenantId: string,
    filters: InventorySearchFilters,
    role: Role,
    userId: string,
  ): Promise<InventorySearchResponse> {
    const page = Math.max(filters.page ?? 1, 1);
    const limit = Math.min(Math.max(filters.limit ?? 20, 1), 100);
    const skip = (page - 1) * limit;

    const query: Record<string, unknown> = { tenantId };
    const normalizedQuery = filters.query?.trim();
    const allowedPropertyIds = await this.accessControl.getAllowedPropertyIds(userId, role);

    if (allowedPropertyIds !== null) {
      if (allowedPropertyIds.length === 0) {
        return { items: [], total: 0, page: 1, limit: 20 };
      }
      query.propertyId = { $in: allowedPropertyIds };
    }

    if (normalizedQuery) {
      const searchRegex = new RegExp(escapeRegex(normalizedQuery), 'i');
      query.$or = [
        { name: searchRegex },
        { subcategory: searchRegex },
        { tags: searchRegex },
        { serialNumber: searchRegex },
      ];
    }

    if (filters.category) {
      query.category = filters.category;
    }

    if (filters.propertyId && allowedPropertyIds === null) {
      query.propertyId = filters.propertyId;
    }

    if (filters.status) {
      query.status = filters.status;
    }

    const itemQuery = this.itemModel.find(query);

    itemQuery.sort({ createdAt: -1 });

    const [items, total] = await Promise.all([
      itemQuery.skip(skip).limit(limit).exec(),
      this.itemModel.countDocuments(query).exec(),
    ]);

    const propertyIds = [...new Set(items.map((item) => String(item.propertyId)))];

    const properties = await this.propertyModel
      .find({ _id: { $in: propertyIds }, tenantId })
      .select('_id name floors')
      .exec();

    const propertyMap = new Map(properties.map((property) => [String(property._id), property]));

    const enrichedItems = items.map((item) => {
      const property = propertyMap.get(String(item.propertyId));
      const propertyName = property?.name ?? null;

      let roomName: string | null = null;
      if (property && item.roomId) {
        for (const floor of property.floors ?? []) {
          const room = floor.rooms?.find((candidate) => candidate.roomId === String(item.roomId));
          if (room) {
            roomName = room.name;
            break;
          }
        }
      }

      return {
        ...item.toObject(),
        propertyName,
        roomName,
      } as ItemDocument & { propertyName: string | null; roomName: string | null };
    });

    const finalItems = role === Role.OWNER
      ? enrichedItems
      : enrichedItems.map((item) => this.accessControl.stripValuation(item));

    return {
      items: finalItems as InventorySearchResponse['items'],
      total,
      page,
      limit,
    };
  }

  private async findOwnedItemOrThrow(
    tenantId: string,
    itemId: string,
  ): Promise<ItemDocument> {
    const item = await this.itemModel.findOne({ _id: itemId, tenantId }).exec();

    if (!item) {
      throw new NotFoundException('Item not found');
    }

    return item;
  }

  private indexItemEmbedding(item: ItemDocument): void {
    if (!this.embeddingService) return;
    const svc = this.embeddingService;
    const ds = this.dataSource;
    const logger = this.logger;
    const text = svc.buildItemText(item);
    const itemId = String(item._id);
    const tenantId = String(item.tenantId);
    svc.generateEmbedding(text).then((embedding) => {
      const vector = `[${embedding.join(',')}]`;
      const upsertSql = [
        'INSERT INTO item_embeddings (item_id, tenant_id, embedding, updated_at)',
        'VALUES ($1, $2, $3::vector, NOW())',
        'ON CONFLICT (item_id) DO UPDATE SET embedding = EXCLUDED.embedding, updated_at = NOW()',
      ].join(' ');
      return ds.query(upsertSql, [itemId, tenantId, vector]);
    }).catch((err: unknown) => {
      logger.error(`Embedding index failed for item ${itemId}`, err);
    });
  }
}
