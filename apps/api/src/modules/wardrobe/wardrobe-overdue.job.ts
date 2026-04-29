import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import {
  DryCleaningRecord,
  DryCleaningRecordDocument,
} from './schemas/dry-cleaning-record.schema';
import { NotificationsService } from '../notifications/notifications.service';
import { Role } from '../../common/enums/role.enum';

const OVERDUE_THRESHOLD_DAYS = 7;

interface TenantOverdueSummary {
  tenantId: string;
  overdueCount: number;
  recordIds: string[];
}

@Injectable()
export class WardrobeOverdueJob {
  private readonly logger = new Logger(WardrobeOverdueJob.name);

  constructor(
    @InjectModel(DryCleaningRecord.name)
    private readonly dryCleaningRecordModel: Model<DryCleaningRecordDocument>,
    private readonly notificationsService: NotificationsService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_9AM)
  async checkOverdueItems(): Promise<void> {
    this.logger.log(
      `[WardrobeOverdueJob] Running overdue dry-cleaning check (threshold: ${OVERDUE_THRESHOLD_DAYS} days)`,
    );

    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - OVERDUE_THRESHOLD_DAYS);

    const overdueRecords = await this.dryCleaningRecordModel
      .find({
        returnedDate: null,
        sentDate: { $lt: cutoffDate },
      })
      .select('_id tenantId itemId sentDate cleanerName')
      .lean()
      .exec();

    if (overdueRecords.length === 0) {
      this.logger.log('[WardrobeOverdueJob] No overdue items found.');
      return;
    }

    const byTenant = new Map<string, TenantOverdueSummary>();

    for (const record of overdueRecords) {
      const tenantId = record.tenantId;
      const recordId = String(record._id);

      if (!byTenant.has(tenantId)) {
        byTenant.set(tenantId, { tenantId, overdueCount: 0, recordIds: [] });
      }

      const summary = byTenant.get(tenantId)!;
      summary.overdueCount += 1;
      summary.recordIds.push(recordId);
    }

    for (const summary of byTenant.values()) {
      this.logger.warn(
        `[WardrobeOverdueJob] Tenant ${summary.tenantId} has ${summary.overdueCount} overdue dry-cleaning item(s). ` +
          `Record IDs: ${summary.recordIds.join(', ')}`,
      );
    }

    this.logger.log(
      `[WardrobeOverdueJob] Summary: ${overdueRecords.length} total overdue record(s) across ${byTenant.size} tenant(s).`,
    );

    await Promise.allSettled(
      Array.from(byTenant.values()).map((summary) =>
        this.notificationsService.notifyTenantRoles({
          tenantId: summary.tenantId,
          roles: [Role.OWNER, Role.MANAGER],
          title: 'Dry cleaning overdue',
          body: `${summary.overdueCount} item(s) have been at the cleaner for over ${OVERDUE_THRESHOLD_DAYS} days.`,
          data: { recordIds: summary.recordIds.join(',') },
        }),
      ),
    );
  }
}
