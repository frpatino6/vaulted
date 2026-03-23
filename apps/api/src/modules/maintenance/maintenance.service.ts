import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { AuditService } from '../audit/audit.service';
import { CreateMaintenanceDto } from './dto/create-maintenance.dto';
import { UpdateMaintenanceDto } from './dto/update-maintenance.dto';
import {
  MaintenanceRecord,
  MaintenanceRecordDocument,
} from './schemas/maintenance-record.schema';
import { Item, ItemDocument } from '../inventory/schemas/item.schema';

export interface MaintenanceFilters {
  itemId?: string;
  status?: string;
  upcoming?: boolean;
  daysAhead?: number;
}

@Injectable()
export class MaintenanceService {
  private readonly logger = new Logger(MaintenanceService.name);

  constructor(
    @InjectModel(MaintenanceRecord.name)
    private readonly recordModel: Model<MaintenanceRecordDocument>,
    @InjectModel(Item.name)
    private readonly itemModel: Model<ItemDocument>,
    private readonly auditService: AuditService,
  ) {}

  async create(
    tenantId: string,
    userId: string,
    itemId: string,
    dto: CreateMaintenanceDto,
  ): Promise<MaintenanceRecord> {
    await this.assertItemOwnership(tenantId, itemId);

    const record = await this.recordModel.create({
      itemId,
      tenantId,
      title: dto.title,
      description: dto.description,
      scheduledDate: new Date(dto.scheduledDate),
      isRecurring: dto.isRecurring ?? false,
      recurrenceIntervalDays: dto.recurrenceIntervalDays,
      providerName: dto.providerName,
      providerContact: dto.providerContact,
      cost: dto.cost,
      currency: dto.currency ?? 'USD',
      notes: dto.notes,
      documents: dto.documents ?? [],
      isAiSuggested: false,
      createdBy: userId,
    });

    await this.syncItemMaintenanceSummary(tenantId, itemId);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'maintenance_scheduled',
      entityType: 'maintenance_record',
      entityId: String(record._id),
      metadata: { itemId, title: dto.title, scheduledDate: dto.scheduledDate },
    });

    return record;
  }

  async findByItem(
    tenantId: string,
    itemId: string,
  ): Promise<MaintenanceRecord[]> {
    await this.assertItemOwnership(tenantId, itemId);
    return this.recordModel
      .find({ tenantId, itemId })
      .sort({ scheduledDate: 1 })
      .exec();
  }

  async findAll(tenantId: string, filters: MaintenanceFilters): Promise<MaintenanceRecord[]> {
    const query: Record<string, unknown> = { tenantId };

    if (filters.itemId) {
      query.itemId = filters.itemId;
    }

    if (filters.status) {
      query.status = filters.status;
    }

    if (filters.upcoming) {
      const now = new Date();
      const future = new Date();
      future.setDate(future.getDate() + (filters.daysAhead ?? 30));
      query.scheduledDate = { $gte: now, $lte: future };
      query.status = { $in: ['pending', 'overdue'] };
    }

    return this.recordModel
      .find(query)
      .sort({ scheduledDate: 1 })
      .exec();
  }

  async update(
    tenantId: string,
    userId: string,
    recordId: string,
    dto: UpdateMaintenanceDto,
  ): Promise<MaintenanceRecord> {
    const existing = await this.recordModel
      .findOne({ _id: recordId, tenantId })
      .exec();

    if (!existing) {
      throw new NotFoundException('Maintenance record not found');
    }

    const isBeingCompleted =
      dto.status === 'completed' && existing.status !== 'completed';

    const updateData: Record<string, unknown> = {};
    if (dto.title !== undefined) updateData.title = dto.title;
    if (dto.description !== undefined) updateData.description = dto.description;
    if (dto.scheduledDate !== undefined) updateData.scheduledDate = new Date(dto.scheduledDate);
    if (dto.completedDate !== undefined) updateData.completedDate = new Date(dto.completedDate);
    if (dto.status !== undefined) updateData.status = dto.status;
    if (dto.recurrenceIntervalDays !== undefined) updateData.recurrenceIntervalDays = dto.recurrenceIntervalDays;
    if (dto.providerName !== undefined) updateData.providerName = dto.providerName;
    if (dto.providerContact !== undefined) updateData.providerContact = dto.providerContact;
    if (dto.cost !== undefined) updateData.cost = dto.cost;
    if (dto.currency !== undefined) updateData.currency = dto.currency;
    if (dto.notes !== undefined) updateData.notes = dto.notes;
    if (dto.documents !== undefined) updateData.documents = dto.documents;

    const record = await this.recordModel
      .findOneAndUpdate(
        { _id: recordId, tenantId },
        { $set: updateData },
        { new: true },
      )
      .exec();

    if (!record) throw new NotFoundException('Maintenance record not found');

    if (isBeingCompleted && existing.isRecurring && existing.recurrenceIntervalDays) {
      await this.createNextRecurrence(tenantId, userId, record);
    }

    await this.syncItemMaintenanceSummary(tenantId, String(existing.itemId));

    await this.auditService.log({
      tenantId,
      userId,
      action: isBeingCompleted ? 'maintenance_completed' : 'maintenance_updated',
      entityType: 'maintenance_record',
      entityId: recordId,
      metadata: { itemId: existing.itemId, status: dto.status },
    });

    return record;
  }

  async delete(tenantId: string, userId: string, recordId: string): Promise<void> {
    const existing = await this.recordModel
      .findOne({ _id: recordId, tenantId })
      .exec();

    if (!existing) {
      throw new NotFoundException('Maintenance record not found');
    }

    await this.recordModel.deleteOne({ _id: recordId, tenantId }).exec();
    await this.syncItemMaintenanceSummary(tenantId, String(existing.itemId));

    await this.auditService.log({
      tenantId,
      userId,
      action: 'maintenance_deleted',
      entityType: 'maintenance_record',
      entityId: recordId,
      metadata: { itemId: existing.itemId },
    });
  }

  async markOverdueRecords(): Promise<number> {
    const now = new Date();
    const result = await this.recordModel
      .updateMany(
        { status: 'pending', scheduledDate: { $lt: now } },
        { $set: { status: 'overdue' } },
      )
      .exec();

    const count = result.modifiedCount;
    if (count > 0) {
      this.logger.log(`Marked ${count} maintenance records as overdue`);
    }
    return count;
  }

  async findUpcomingInDays(days: number): Promise<MaintenanceRecord[]> {
    const now = new Date();
    const threshold = new Date();
    threshold.setDate(threshold.getDate() + days);

    return this.recordModel
      .find({
        status: 'pending',
        scheduledDate: { $gte: now, $lte: threshold },
      })
      .exec();
  }

  private async createNextRecurrence(
    tenantId: string,
    userId: string,
    completed: MaintenanceRecordDocument,
  ): Promise<void> {
    const intervalDays = completed.recurrenceIntervalDays ?? 90;
    const nextDate = new Date(completed.scheduledDate);
    nextDate.setDate(nextDate.getDate() + intervalDays);

    await this.recordModel.create({
      itemId: completed.itemId,
      tenantId,
      title: completed.title,
      description: completed.description,
      scheduledDate: nextDate,
      isRecurring: true,
      recurrenceIntervalDays: intervalDays,
      providerName: completed.providerName,
      providerContact: completed.providerContact,
      currency: completed.currency,
      notes: completed.notes,
      documents: [],
      isAiSuggested: false,
      createdBy: userId,
    });

    this.logger.log(`Created next recurrence for item ${String(completed.itemId)} on ${nextDate.toISOString()}`);
  }

  async syncItemMaintenanceSummary(tenantId: string, itemId: string): Promise<void> {
    const pending = await this.recordModel
      .find({ tenantId, itemId, status: { $in: ['pending', 'overdue'] } })
      .sort({ scheduledDate: 1 })
      .exec();

    const nextMaintenanceDate = pending.length > 0 ? pending[0].scheduledDate : null;
    const maintenanceDueCount = pending.length;

    await this.itemModel
      .updateOne(
        { _id: itemId, tenantId },
        { $set: { nextMaintenanceDate, maintenanceDueCount } },
      )
      .exec();
  }

  private async assertItemOwnership(tenantId: string, itemId: string): Promise<void> {
    const item = await this.itemModel.findOne({ _id: itemId, tenantId }).exec();
    if (!item) throw new NotFoundException('Item not found');
  }
}
