import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { DataSource } from 'typeorm';
import { InjectDataSource } from '@nestjs/typeorm';
import Redis from 'ioredis';
import * as QRCode from 'qrcode';
import { InjectRedis } from '../../common/decorators/inject-redis.decorator';
import { CreateItemDto, ItemStatus } from './dto/create-item.dto';
import { LoanItemDto } from './dto/loan-item.dto';
import { MoveItemDto } from './dto/move-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { Item, ItemDocument, ItemValuation } from './schemas/item.schema';
import {
  ItemHistory,
  ItemHistoryDocument,
} from './schemas/item-history.schema';
import {
  Movement,
  MovementDocument,
  MovementStatus,
  MovementType,
  MovementItemStatus,
} from '../movements/schemas/movement.schema';
import {
  Property,
  PropertyDocument,
} from '../properties/schemas/property.schema';
import { EmbeddingService } from '../ai/shared/embedding.service';
import { Role } from '../../common/enums/role.enum';
import { AccessControlService } from '../../common/services/access-control.service';
import { CryptoService } from '../../common/services/crypto.service';
import { AuditService } from '../audit/audit.service';
import { MediaService } from '../media/media.service';
import { NotificationsService } from '../notifications/notifications.service';
import { toValueRange } from '../../common/utils/value-range.util';

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
  items: Array<
    ItemDocument & {
      propertyName: string | null;
      roomName: string | null;
      sectionPhoto: string | null;
    }
  >;
  total: number;
  page: number;
  limit: number;
}

function escapeRegex(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function assertSafeFlexibleObject(
  value: unknown,
  path = 'attributes',
  depth = 0,
): void {
  if (depth > 5) {
    throw new BadRequestException(`${path} exceeds maximum nesting depth`);
  }

  if (Array.isArray(value)) {
    if (value.length > 100) {
      throw new BadRequestException(`${path} exceeds maximum array size`);
    }
    value.forEach((entry, index) =>
      assertSafeFlexibleObject(entry, `${path}[${index}]`, depth + 1),
    );
    return;
  }

  if (value === null || typeof value !== 'object') {
    if (typeof value === 'string' && value.length > 2000) {
      throw new BadRequestException(`${path} exceeds maximum string length`);
    }
    return;
  }

  for (const [key, child] of Object.entries(value)) {
    if (
      key.startsWith('$') ||
      key.includes('.') ||
      key === '__proto__' ||
      key === 'constructor' ||
      key === 'prototype'
    ) {
      throw new BadRequestException(`${path} contains an unsafe key`);
    }
    assertSafeFlexibleObject(child, `${path}.${key}`, depth + 1);
  }
}

@Injectable()
export class InventoryService {
  private readonly logger = new Logger(InventoryService.name);
  private readonly appUrl: string;

  constructor(
    @InjectModel(Item.name)
    private readonly itemModel: Model<ItemDocument>,
    @InjectModel(ItemHistory.name)
    private readonly itemHistoryModel: Model<ItemHistoryDocument>,
    @InjectModel(Property.name)
    private readonly propertyModel: Model<PropertyDocument>,
    @InjectModel(Movement.name)
    private readonly movementModel: Model<MovementDocument>,
    @InjectDataSource() private readonly dataSource: DataSource,
    private readonly accessControl: AccessControlService,
    private readonly crypto: CryptoService,
    private readonly audit: AuditService,
    private readonly configService: ConfigService,
    private readonly mediaService: MediaService,
    @Optional() private readonly embeddingService?: EmbeddingService,
    @Optional() private readonly notificationsService?: NotificationsService,
    @InjectRedis() private readonly redis?: Redis,
  ) {
    this.appUrl = (
      this.configService.get<string>('APP_URL') ?? 'http://localhost:3000'
    ).replace(/\/+$/, '');
  }

  async create(
    tenantId: string,
    userId: string,
    dto: CreateItemDto,
  ): Promise<Item> {
    if (dto.attributes !== undefined) {
      assertSafeFlexibleObject(dto.attributes);
    }

    const item = await this.itemModel.create({
      tenantId,
      propertyId: dto.propertyId,
      roomId: dto.roomId,
      name: dto.name,
      category: dto.category,
      subcategory: dto.subcategory,
      attributes: dto.attributes,
      valuation: this.encryptValuation(dto.valuation, tenantId),
      status: dto.status ?? ItemStatus.ACTIVE,
      photos: (dto.photos ?? []).map((u) =>
        this.mediaService.normalizeTenantKey(u, tenantId),
      ),
      documents: (dto.documents ?? []).map((u) =>
        this.mediaService.normalizeTenantKey(u, tenantId),
      ),
      tags: dto.tags ?? [],
      serialNumber: dto.serialNumber,
      locationDetail: dto.locationDetail,
      sectionId: dto.sectionId ?? null,
      quantity: dto.quantity ?? 1,
      createdBy: userId,
    });

    const qrCode = await QRCode.toDataURL(
      `vaulted://items/${String(item._id)}`,
    );
    item.qrCode = qrCode;
    await item.save();

    void this.indexItemEmbedding(item);
    void this.recordCreationMovement(item, tenantId, userId);
    void this.notifyItemAdded(item, tenantId);

    const plain = item.toObject();
    plain.valuation = this.decryptValuation(plain.valuation, tenantId);
    return plain as Item;
  }

  private async notifyItemAdded(
    item: ItemDocument,
    tenantId: string,
  ): Promise<void> {
    if (!this.notificationsService) return;
    try {
      await this.notificationsService.notifyTenantRoles({
        tenantId,
        roles: [Role.OWNER, Role.MANAGER],
        type: 'item_added',
        title: 'New item cataloged',
        body: `${item.name} has been added to your inventory.`,
        data: { itemId: String(item._id), category: item.category ?? '' },
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.warn(`itemAdded notification failed: ${message}`);
    }
  }

  private async recordCreationMovement(
    item: ItemDocument,
    tenantId: string,
    userId: string,
  ): Promise<void> {
    try {
      const now = new Date();
      await this.movementModel.create({
        tenantId,
        propertyId: item.propertyId ?? '',
        operationType: MovementType.CREATION,
        status: MovementStatus.COMPLETED,
        title: `Item cataloged: ${item.name}`,
        description: '',
        destination: '',
        destinationPropertyId: '',
        destinationRoomId: '',
        destinationPropertyName: '',
        destinationRoomName: '',
        items: [
          {
            itemId: String(item._id),
            itemName: item.name,
            itemCategory: item.category ?? '',
            itemPhoto: item.photos?.[0] ?? '',
            fromPropertyId: item.propertyId ?? '',
            fromRoomId: item.roomId ?? '',
            fromPropertyName: '',
            fromRoomName: '',
            scannedAt: now,
            checkedInAt: null,
            checkedInBy: null,
            status: MovementItemStatus.OUT,
          },
        ],
        createdBy: userId,
        activatedAt: now,
        completedAt: now,
        dueDate: null,
        notes: '',
      });

      await this.itemHistoryModel.create({
        itemId: String(item._id),
        tenantId,
        action: 'created',
        toPropertyId: item.propertyId ?? '',
        toRoomId: item.roomId ?? '',
        performedBy: userId,
      });
    } catch (err) {
      this.logger.error(
        `Failed to record creation movement for item ${String(item._id)}`,
        err,
      );
    }
  }

  async findAll(
    tenantId: string,
    filters: InventoryFilters,
    role: Role,
    userId: string,
  ): Promise<Item[]> {
    const query: Record<string, unknown> = { tenantId };
    const allowedPropertyIds = await this.accessControl.getAllowedPropertyIds(
      userId,
      role,
    );

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
        const property = await this.propertyModel.findOne({
          _id: filters.propertyId,
          tenantId,
        });
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

    query.status = filters.status ?? { $ne: 'disposed' };

    const q = this.itemModel.find(query).sort({ createdAt: -1 });
    if (filters.limit && filters.limit > 0) q.limit(filters.limit);
    const items = await q.exec();
    if (role === Role.OWNER || role === Role.AUDITOR) {
      const result = items.map((item) => {
        const plain = item.toObject();
        plain.valuation = this.decryptValuation(plain.valuation, tenantId);
        return this.withSignedUrls(plain as Item, userId, tenantId);
      });
      void this.audit.log({
        tenantId,
        userId,
        action: 'item.valuation.view',
        entityType: 'item_list',
        metadata: {
          role,
          itemCount: result.length,
          filters: {
            propertyId: filters.propertyId,
            category: filters.category,
            status: filters.status,
          },
        },
      });
      return result;
    }
    return items.map((item) =>
      this.withSignedUrls(
        this.accessControl.stripValuation(item.toObject()) as Item,
        userId,
        tenantId,
      ),
    );
  }

  async findById(
    tenantId: string,
    itemId: string,
    role: Role = Role.OWNER,
    userId = '',
  ): Promise<Item> {
    const item = await this.findOwnedItemOrThrow(tenantId, itemId);
    if (userId) {
      const allowedPropertyIds = await this.accessControl.getAllowedPropertyIds(
        userId,
        role,
      );
      if (
        allowedPropertyIds !== null &&
        !allowedPropertyIds.includes(String(item.propertyId))
      ) {
        throw new NotFoundException('Item not found');
      }
    }

    const property = await this.propertyModel
      .findOne({ _id: item.propertyId, tenantId })
      .select('_id name floors')
      .exec();

    const propertyName = property?.name ?? null;
    let roomName: string | null = null;
    let sectionPhoto: string | null = null;
    let sectionBoundingBox: {
      x: number;
      y: number;
      width: number;
      height: number;
    } | null = null;
    let sectionCode: string | null = null;
    let sectionFurnitureName: string | null = null;
    if (property && item.roomId) {
      for (const floor of property.floors ?? []) {
        const room = floor.rooms?.find((r) => r.roomId === String(item.roomId));
        if (room) {
          roomName = room.name;
          if (item.sectionId) {
            const section = room.sections?.find(
              (s) => s.sectionId === String(item.sectionId),
            );
            sectionPhoto = section?.photo ?? null;
            sectionCode = section?.code ?? null;
            sectionFurnitureName = section?.furnitureName ?? null;
            sectionBoundingBox = section?.boundingBox
              ? {
                  x: section.boundingBox.x,
                  y: section.boundingBox.y,
                  width: section.boundingBox.width,
                  height: section.boundingBox.height,
                }
              : null;
          }
          break;
        }
      }
    }

    if (role === Role.OWNER || role === Role.AUDITOR) {
      const plain = item.toObject();
      plain.valuation = this.decryptValuation(
        plain.valuation,
        String(item.tenantId),
      );
      await this.audit.log({
        tenantId,
        userId,
        action: 'item.valuation.view',
        entityType: 'item',
        entityId: itemId,
        metadata: {
          role,
          valueRange: toValueRange(
            (plain.valuation?.currentValue as number | undefined) ??
              (plain.valuation?.purchasePrice as number | undefined) ??
              0,
          ),
        },
      });
      return this.withSignedUrls(
        {
          ...plain,
          propertyName,
          roomName,
          sectionPhoto,
          sectionBoundingBox,
          sectionCode,
          sectionFurnitureName,
        } as Item & {
          propertyName: string | null;
          roomName: string | null;
          sectionPhoto: string | null;
          sectionBoundingBox: {
            x: number;
            y: number;
            width: number;
            height: number;
          } | null;
          sectionCode: string | null;
          sectionFurnitureName: string | null;
        },
        userId,
        tenantId,
      );
    }
    const stripped = this.accessControl.stripValuation(item.toObject()) as Item;
    return this.withSignedUrls(
      {
        ...stripped,
        propertyName,
        roomName,
        sectionPhoto,
        sectionBoundingBox,
        sectionCode,
        sectionFurnitureName,
      } as Item & {
        propertyName: string | null;
        roomName: string | null;
        sectionPhoto: string | null;
        sectionBoundingBox: {
          x: number;
          y: number;
          width: number;
          height: number;
        } | null;
        sectionCode: string | null;
        sectionFurnitureName: string | null;
      },
      userId,
      tenantId,
    );
  }

  async update(
    tenantId: string,
    itemId: string,
    dto: UpdateItemDto,
  ): Promise<Item> {
    await this.findOwnedItemOrThrow(tenantId, itemId);

    if (dto.attributes !== undefined) {
      assertSafeFlexibleObject(dto.attributes);
    }

    const encryptedValuation =
      dto.valuation !== undefined
        ? this.encryptValuation(dto.valuation, tenantId)
        : undefined;

    const item = await this.itemModel
      .findOneAndUpdate(
        { _id: itemId, tenantId },
        {
          $set: {
            ...(dto.propertyId !== undefined
              ? { propertyId: dto.propertyId }
              : {}),
            ...(dto.roomId !== undefined ? { roomId: dto.roomId } : {}),
            ...(dto.name !== undefined ? { name: dto.name } : {}),
            ...(dto.category !== undefined ? { category: dto.category } : {}),
            ...(dto.subcategory !== undefined
              ? { subcategory: dto.subcategory }
              : {}),
            ...(dto.attributes !== undefined
              ? { attributes: dto.attributes }
              : {}),
            ...(encryptedValuation !== undefined
              ? { valuation: encryptedValuation }
              : {}),
            ...(dto.status !== undefined ? { status: dto.status } : {}),
            ...(dto.photos !== undefined
              ? {
                  photos: dto.photos.map((u) =>
                    this.mediaService.normalizeTenantKey(u, tenantId),
                  ),
                }
              : {}),
            ...(dto.documents !== undefined
              ? {
                  documents: dto.documents.map((u) =>
                    this.mediaService.normalizeTenantKey(u, tenantId),
                  ),
                }
              : {}),
            ...(dto.tags !== undefined ? { tags: dto.tags } : {}),
            ...(dto.serialNumber !== undefined
              ? { serialNumber: dto.serialNumber }
              : {}),
            ...(dto.locationDetail !== undefined
              ? { locationDetail: dto.locationDetail }
              : {}),
            ...(dto.sectionId !== undefined
              ? { sectionId: dto.sectionId }
              : {}),
            ...(dto.quantity !== undefined ? { quantity: dto.quantity } : {}),
          },
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!item) {
      throw new NotFoundException('Item not found');
    }

    void this.indexItemEmbedding(item);

    if (dto.attributes !== undefined && item.category === 'wardrobe') {
      void this.redis?.del(`wardrobe:stats:${tenantId}`);
    }

    const plain = item.toObject();
    plain.valuation = this.decryptValuation(plain.valuation, tenantId);
    return plain as Item;
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
    const allowedPropertyIds = await this.accessControl.getAllowedPropertyIds(
      userId,
      role,
    );

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
        { category: searchRegex },
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

    query.status = filters.status ?? { $ne: 'disposed' };

    const itemQuery = this.itemModel.find(query);

    itemQuery.sort({ createdAt: -1 });

    const [items, total] = await Promise.all([
      itemQuery.skip(skip).limit(limit).exec(),
      this.itemModel.countDocuments(query).exec(),
    ]);

    const propertyIds = [
      ...new Set(items.map((item) => String(item.propertyId))),
    ];

    const properties = await this.propertyModel
      .find({ _id: { $in: propertyIds }, tenantId })
      .select('_id name floors')
      .exec();

    const propertyMap = new Map(
      properties.map((property) => [String(property._id), property]),
    );

    const enrichedItems = items.map((item) => {
      const property = propertyMap.get(String(item.propertyId));
      const propertyName = property?.name ?? null;

      let roomName: string | null = null;
      let sectionPhoto: string | null = null;
      let sectionBoundingBox: {
        x: number;
        y: number;
        width: number;
        height: number;
      } | null = null;
      let sectionCode: string | null = null;
      let sectionFurnitureName: string | null = null;
      if (property && item.roomId) {
        for (const floor of property.floors ?? []) {
          const room = floor.rooms?.find(
            (candidate) => candidate.roomId === String(item.roomId),
          );
          if (room) {
            roomName = room.name;
            if (item.sectionId) {
              const section = room.sections?.find(
                (s) => s.sectionId === String(item.sectionId),
              );
              sectionPhoto = section?.photo ?? null;
              sectionCode = section?.code ?? null;
              sectionFurnitureName = section?.furnitureName ?? null;
              sectionBoundingBox = section?.boundingBox
                ? {
                    x: section.boundingBox.x,
                    y: section.boundingBox.y,
                    width: section.boundingBox.width,
                    height: section.boundingBox.height,
                  }
                : null;
            }
            break;
          }
        }
      }

      const plain = item.toObject();
      plain.valuation = this.decryptValuation(plain.valuation, tenantId);

      return {
        ...plain,
        propertyName,
        roomName,
        sectionPhoto,
        sectionBoundingBox,
        sectionCode,
        sectionFurnitureName,
      } as ItemDocument & {
        propertyName: string | null;
        roomName: string | null;
        sectionPhoto: string | null;
        sectionBoundingBox: {
          x: number;
          y: number;
          width: number;
          height: number;
        } | null;
        sectionCode: string | null;
        sectionFurnitureName: string | null;
      };
    });

    const finalItems =
      role === Role.OWNER || role === Role.AUDITOR
        ? enrichedItems.map((item) =>
            this.withSignedUrls(item as unknown as Item, userId, tenantId),
          )
        : enrichedItems.map((item) =>
            this.withSignedUrls(
              this.accessControl.stripValuation(item) as unknown as Item,
              userId,
              tenantId,
            ),
          );

    if (role === Role.OWNER || role === Role.AUDITOR) {
      void this.audit.log({
        tenantId,
        userId,
        action: 'item.valuation.view',
        entityType: 'item_search',
        metadata: {
          role,
          resultCount: total,
          filters: {
            query: filters.query,
            category: filters.category,
            propertyId: filters.propertyId,
          },
        },
      });
    }

    return {
      items: finalItems as InventorySearchResponse['items'],
      total,
      page,
      limit,
    };
  }

  private withSignedUrls(item: Item, userId: string, tenantId: string): Item {
    const sign = (url: string) =>
      `${this.appUrl}/api/media/${this.mediaService.generateFileToken(url, tenantId, userId)}`;
    return {
      ...item,
      photos: (item.photos ?? []).map(sign),
      documents: (item.documents ?? []).map(sign),
      ...((item as unknown as Record<string, unknown>)['sectionPhoto']
        ? {
            sectionPhoto: sign(
              (item as unknown as Record<string, unknown>)[
                'sectionPhoto'
              ] as string,
            ),
          }
        : {}),
    };
  }

  // ── Field-Level Encryption helpers ───────────────────────────────────────

  private encryptFleField(
    raw: Record<string, unknown>,
    field: string,
    tenantId: string,
    serialize: (v: unknown) => string,
  ): string | undefined {
    const value = raw[field];
    if (value === undefined) return undefined;
    return this.crypto.encryptField(serialize(value), tenantId);
  }

  private decryptFleField<T>(
    raw: Record<string, unknown>,
    field: string,
    tenantId: string,
    transform: (plaintext: string) => T,
  ): T | undefined {
    const value = raw[field];
    if (!this.crypto.isEncryptedField(value)) {
      // Legacy data may be stored as a string (e.g. "0") before FLE was added.
      // Apply the transform so numeric fields are always returned as numbers.
      if (typeof value === 'string') return transform(value);
      return value as T | undefined;
    }
    return transform(this.crypto.decryptField(value as string, tenantId));
  }

  private encryptValuation(
    valuation: ItemValuation | undefined,
    tenantId: string,
  ): ItemValuation | undefined {
    if (!valuation) return undefined;
    const raw = valuation as unknown as Record<string, unknown>;
    return {
      ...valuation,
      purchasePrice: this.encryptFleField(
        raw,
        'purchasePrice',
        tenantId,
        String,
      ) as unknown as number,
      currentValue: this.encryptFleField(
        raw,
        'currentValue',
        tenantId,
        String,
      ) as unknown as number,
      lastAppraisalDate: this.encryptFleField(
        raw,
        'lastAppraisalDate',
        tenantId,
        (v) => (v instanceof Date ? v.toISOString() : String(v)),
      ) as unknown as Date,
    };
  }

  private decryptValuation(
    valuation: ItemValuation | undefined,
    tenantId: string,
  ): ItemValuation | undefined {
    if (!valuation) return undefined;
    const raw = valuation as unknown as Record<string, unknown>;
    try {
      return {
        ...valuation,
        purchasePrice: this.decryptFleField(
          raw,
          'purchasePrice',
          tenantId,
          parseFloat,
        ),
        currentValue: this.decryptFleField(
          raw,
          'currentValue',
          tenantId,
          parseFloat,
        ),
        lastAppraisalDate: this.decryptFleField(
          raw,
          'lastAppraisalDate',
          tenantId,
          (s) => new Date(s),
        ),
      };
    } catch (err) {
      this.logger.error(`FLE decryption failed for tenant ${tenantId}`, err);
      throw new InternalServerErrorException(
        'Failed to decrypt item valuation',
      );
    }
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
    svc
      .generateEmbedding(text)
      .then((embedding) => {
        const vector = `[${embedding.join(',')}]`;
        const upsertSql = [
          'INSERT INTO item_embeddings (item_id, tenant_id, embedding, updated_at)',
          'VALUES ($1, $2, $3::vector, NOW())',
          'ON CONFLICT (item_id) DO UPDATE SET embedding = EXCLUDED.embedding, updated_at = NOW()',
        ].join(' ');
        return ds.query(upsertSql, [itemId, tenantId, vector]);
      })
      .catch((err: unknown) => {
        logger.error(`Embedding index failed for item ${itemId}`, err);
      });
  }
}
