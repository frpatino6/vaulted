import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  Movement,
  MovementDocument,
  MovementStatus,
  MovementItemStatus,
  MovementType,
} from './schemas/movement.schema';
import { Item, ItemDocument } from '../inventory/schemas/item.schema';
import {
  ItemHistory,
  ItemHistoryDocument,
} from '../inventory/schemas/item-history.schema';
import {
  Property,
  PropertyDocument,
} from '../properties/schemas/property.schema';
import { CreateMovementDto } from './dto/create-movement.dto';
import { UpdateMovementDto } from './dto/update-movement.dto';
import { JwtPayload } from '../auth/strategies/jwt.strategy';

@Injectable()
export class MovementsService {
  constructor(
    @InjectModel(Movement.name)
    private readonly movementModel: Model<MovementDocument>,
    @InjectModel(Item.name)
    private readonly itemModel: Model<ItemDocument>,
    @InjectModel(ItemHistory.name)
    private readonly itemHistoryModel: Model<ItemHistoryDocument>,
    @InjectModel(Property.name)
    private readonly propertyModel: Model<PropertyDocument>,
  ) {}

  async create(
    dto: CreateMovementDto,
    user: JwtPayload,
  ): Promise<MovementDocument> {
    const movement = new this.movementModel({
      tenantId: user.tenantId,
      propertyId: dto.propertyId ?? '',
      operationType: dto.operationType,
      title: dto.title,
      description: dto.description ?? '',
      destination: dto.destination ?? '',
      destinationPropertyId: dto.destinationPropertyId ?? '',
      destinationRoomId: dto.destinationRoomId ?? '',
      destinationPropertyName: dto.destinationPropertyName ?? '',
      destinationRoomName: dto.destinationRoomName ?? '',
      dueDate: dto.dueDate ? new Date(dto.dueDate) : null,
      notes: dto.notes ?? '',
      createdBy: user.sub,
      status: MovementStatus.DRAFT,
      items: [],
    });

    return movement.save();
  }

  async findAll(
    tenantId: string,
    filters: { status?: string; operationType?: string } = {},
  ): Promise<MovementDocument[]> {
    const query: Record<string, unknown> = { tenantId };
    if (filters.status) query['status'] = filters.status;
    if (filters.operationType) query['operationType'] = filters.operationType;
    return this.movementModel.find(query).sort({ createdAt: -1 }).lean();
  }

  async findOne(id: string, tenantId: string): Promise<MovementDocument> {
    const movement = await this.movementModel.findOne({ _id: id, tenantId });
    if (!movement) throw new NotFoundException('Movement not found');
    return movement;
  }

  async findActiveDrafts(
    userId: string,
    tenantId: string,
  ): Promise<MovementDocument[]> {
    return this.movementModel
      .find({ tenantId, createdBy: userId, status: MovementStatus.DRAFT })
      .sort({ createdAt: -1 });
  }

  async update(
    id: string,
    dto: UpdateMovementDto,
    tenantId: string,
  ): Promise<MovementDocument> {
    const movement = await this.findOne(id, tenantId);
    if (movement.status !== MovementStatus.DRAFT) {
      throw new BadRequestException('Only draft movements can be edited');
    }

    if (dto.title !== undefined) movement.title = dto.title;
    if (dto.description !== undefined) movement.description = dto.description;
    if (dto.destination !== undefined) movement.destination = dto.destination;
    if (dto.notes !== undefined) movement.notes = dto.notes;
    if (dto.dueDate !== undefined) {
      movement.dueDate = dto.dueDate ? new Date(dto.dueDate) : null;
    }

    return movement.save();
  }

  async addItem(
    movementId: string,
    itemId: string,
    user: JwtPayload,
  ): Promise<MovementDocument> {
    const movement = await this.findOne(movementId, user.tenantId);
    if (movement.status !== MovementStatus.DRAFT) {
      throw new BadRequestException(
        'Items can only be added to draft movements',
      );
    }

    const alreadyAdded = movement.items.some(
      (i) => i.itemId.toString() === itemId,
    );
    if (alreadyAdded) {
      throw new ConflictException('Item is already in this movement');
    }

    const item = await this.itemModel.findOne({
      _id: itemId,
      tenantId: user.tenantId,
    });
    if (!item) throw new NotFoundException('Item not found');

    if (item.status === 'disposed') {
      throw new BadRequestException('Disposed items cannot be moved');
    }

    let fromPropertyName = '';
    let fromRoomName = '';
    try {
      const property = await this.propertyModel.findOne({
        _id: item.propertyId,
        tenantId: user.tenantId,
      });
      if (property) {
        fromPropertyName = property.name;
        for (const floor of property.floors ?? []) {
          const room = floor.rooms?.find(
            (r) => r.roomId?.toString() === item.roomId,
          );
          if (room) {
            fromRoomName = room.name;
            break;
          }
        }
      }
    } catch {
      // snapshot is best-effort
    }

    movement.items.push({
      itemId: item._id.toString(),
      itemName: item.name,
      itemCategory: item.category,
      itemPhoto: item.photos?.[0] ?? '',
      fromPropertyId: item.propertyId,
      fromRoomId: item.roomId,
      fromPropertyName,
      fromRoomName,
      scannedAt: new Date(),
      checkedInAt: null,
      checkedInBy: null,
      status: MovementItemStatus.OUT,
    } as any);

    return movement.save();
  }

  async removeItem(
    movementId: string,
    itemId: string,
    tenantId: string,
  ): Promise<MovementDocument> {
    const movement = await this.findOne(movementId, tenantId);
    if (movement.status !== MovementStatus.DRAFT) {
      throw new BadRequestException(
        'Items can only be removed from draft movements',
      );
    }

    const before = movement.items.length;
    movement.items = movement.items.filter(
      (i) => i.itemId.toString() !== itemId,
    );
    if (movement.items.length === before) {
      throw new NotFoundException('Item not found in this movement');
    }

    return movement.save();
  }

  async activate(
    movementId: string,
    user: JwtPayload,
  ): Promise<MovementDocument> {
    const movement = await this.findOne(movementId, user.tenantId);
    if (movement.status !== MovementStatus.DRAFT) {
      throw new BadRequestException('Only draft movements can be activated');
    }
    if (movement.items.length === 0) {
      throw new BadRequestException(
        'Cannot activate a movement with no items',
      );
    }

    const isTransfer = movement.operationType === MovementType.TRANSFER;
    const isDisposal = movement.operationType === MovementType.DISPOSAL;

    if (isTransfer) {
      // Transfer: move items to destination immediately and complete
      const destPropertyId = movement.destinationPropertyId;
      const destRoomId = movement.destinationRoomId;
      if (!destPropertyId || !destRoomId) {
        throw new BadRequestException(
          'Transfer requires a destination property and room',
        );
      }

      await Promise.all(
        movement.items.map((mi) =>
          this.itemModel.updateOne(
            { _id: mi.itemId, tenantId: user.tenantId },
            {
              $set: {
                status: 'active',
                propertyId: destPropertyId,
                roomId: destRoomId,
              },
            },
          ),
        ),
      );

      await Promise.all(
        movement.items.map((mi) =>
          this.itemHistoryModel.create({
            itemId: mi.itemId,
            tenantId: user.tenantId,
            action: 'moved',
            performedBy: user.sub,
            notes: `[Transfer] ${movement.title} → ${movement.destinationPropertyName}${movement.destinationRoomName ? ` / ${movement.destinationRoomName}` : ''}`,
            timestamp: new Date(),
          }),
        ),
      );

      movement.status = MovementStatus.COMPLETED;
      movement.activatedAt = new Date();
      movement.completedAt = new Date();
      return movement.save();
    }

    const itemStatus = this.operationTypeToItemStatus(
      movement.operationType as MovementType,
    );

    await Promise.all(
      movement.items.map((mi) =>
        this.itemModel.updateOne(
          { _id: mi.itemId, tenantId: user.tenantId },
          { $set: { status: itemStatus } },
        ),
      ),
    );

    const historyAction = this.operationTypeToHistoryAction(
      movement.operationType as MovementType,
    );
    await Promise.all(
      movement.items.map((mi) =>
        this.itemHistoryModel.create({
          itemId: mi.itemId,
          tenantId: user.tenantId,
          action: historyAction,
          performedBy: user.sub,
          notes: `[Movement] ${movement.title}${movement.destination ? ` → ${movement.destination}` : ''}`,
          timestamp: new Date(),
        }),
      ),
    );

    if (isDisposal) {
      movement.status = MovementStatus.COMPLETED;
      movement.completedAt = new Date();
    } else {
      movement.status = MovementStatus.ACTIVE;
      movement.activatedAt = new Date();
    }

    return movement.save();
  }

  async checkinItem(
    movementId: string,
    itemId: string,
    user: JwtPayload,
  ): Promise<MovementDocument> {
    const movement = await this.findOne(movementId, user.tenantId);
    if (movement.status !== MovementStatus.ACTIVE) {
      throw new BadRequestException(
        'Check-in is only available for active movements',
      );
    }

    const movementItem = movement.items.find(
      (i) => i.itemId.toString() === itemId,
    );
    if (!movementItem) {
      throw new NotFoundException('Item not found in this movement');
    }
    if (movementItem.status === MovementItemStatus.RETURNED) {
      throw new ConflictException('Item has already been checked in');
    }

    movementItem.status = MovementItemStatus.RETURNED;
    movementItem.checkedInAt = new Date();
    movementItem.checkedInBy = user.sub;

    await this.itemModel.updateOne(
      { _id: itemId, tenantId: user.tenantId },
      { $set: { status: 'active' } },
    );

    await this.itemHistoryModel.create({
      itemId,
      tenantId: user.tenantId,
      action: 'returned',
      performedBy: user.sub,
      notes: `[Movement] Check-in: ${movement.title}`,
      timestamp: new Date(),
    });

    const allReturned = movement.items.every(
      (i) => i.status === MovementItemStatus.RETURNED,
    );
    if (allReturned) {
      movement.status = MovementStatus.COMPLETED;
      movement.completedAt = new Date();
    }

    return movement.save();
  }

  async complete(
    movementId: string,
    user: JwtPayload,
  ): Promise<MovementDocument> {
    const movement = await this.findOne(movementId, user.tenantId);
    if (movement.status !== MovementStatus.ACTIVE) {
      throw new BadRequestException('Only active movements can be completed');
    }

    const pending = movement.items.filter(
      (i) => i.status === MovementItemStatus.OUT,
    );

    pending.forEach((i) => {
      i.status = MovementItemStatus.MISSING;
    });

    movement.status =
      pending.length > 0 ? MovementStatus.PARTIAL : MovementStatus.COMPLETED;
    movement.completedAt = new Date();

    return movement.save();
  }

  async cancel(
    movementId: string,
    user: JwtPayload,
  ): Promise<MovementDocument> {
    const movement = await this.findOne(movementId, user.tenantId);
    if (
      movement.status === MovementStatus.COMPLETED ||
      movement.status === MovementStatus.CANCELLED
    ) {
      throw new BadRequestException(
        'Cannot cancel a completed or already cancelled movement',
      );
    }

    if (movement.status === MovementStatus.ACTIVE) {
      await Promise.all(
        movement.items
          .filter((i) => i.status === MovementItemStatus.OUT)
          .map((mi) =>
            this.itemModel.updateOne(
              { _id: mi.itemId, tenantId: user.tenantId },
              { $set: { status: 'active' } },
            ),
          ),
      );
    }

    movement.status = MovementStatus.CANCELLED;
    return movement.save();
  }

  private operationTypeToItemStatus(type: MovementType): string {
    switch (type) {
      case MovementType.LOAN:
        return 'loaned';
      case MovementType.REPAIR:
        return 'repair';
      case MovementType.DISPOSAL:
        return 'disposed';
      default:
        return 'active';
    }
  }

  private operationTypeToHistoryAction(type: MovementType): string {
    switch (type) {
      case MovementType.LOAN:
        return 'loaned';
      case MovementType.REPAIR:
        return 'repaired';
      default:
        return 'moved';
    }
  }
}
