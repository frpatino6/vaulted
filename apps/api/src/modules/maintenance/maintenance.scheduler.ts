import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { MaintenanceService } from './maintenance.service';
import { NotificationsService } from '../notifications/notifications.service';
import { Role } from '../../common/enums/role.enum';

@Injectable()
export class MaintenanceScheduler {
  private readonly logger = new Logger(MaintenanceScheduler.name);

  constructor(
    private readonly maintenanceService: MaintenanceService,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Runs every night at 02:00 AM.
   * 1. Marks past-due pending records as overdue.
   * 2. Dispatches push/email notifications for records due in 7 days and 1 day.
   */
  @Cron(CronExpression.EVERY_DAY_AT_2AM)
  async runNightlyMaintenanceCheck(): Promise<void> {
    this.logger.log('Running nightly maintenance check...');

    const overdueCount = await this.maintenanceService.markOverdueRecords();
    this.logger.log(`Overdue records updated: ${overdueCount}`);

    const in7Days = await this.maintenanceService.findUpcomingInDays(7);
    if (in7Days.length > 0) {
      this.logger.log(
        `Upcoming maintenance in 7 days: ${in7Days.length} records — IDs: ${in7Days.map((r) => String((r as { _id?: unknown })._id)).join(', ')}`,
      );

      const byTenant = new Map<string, number>();
      for (const record of in7Days) {
        const tid = String(record.tenantId);
        byTenant.set(tid, (byTenant.get(tid) ?? 0) + 1);
      }

      for (const [tenantId, count] of byTenant) {
        void this.notificationsService.notifyTenantRoles({
          tenantId,
          roles: [Role.OWNER, Role.MANAGER],
          type: 'maintenance_due',
          title: 'Maintenance due in 7 days',
          body: `${count} item(s) require maintenance within 7 days.`,
          data: { count: String(count) },
        });
      }
    }

    const in1Day = await this.maintenanceService.findUpcomingInDays(1);
    if (in1Day.length > 0) {
      this.logger.log(
        `Urgent: maintenance due tomorrow: ${in1Day.length} records`,
      );

      const byTenant = new Map<string, number>();
      for (const record of in1Day) {
        const tid = String(record.tenantId);
        byTenant.set(tid, (byTenant.get(tid) ?? 0) + 1);
      }

      for (const [tenantId, count] of byTenant) {
        void this.notificationsService.notifyTenantRoles({
          tenantId,
          roles: [Role.OWNER, Role.MANAGER],
          type: 'maintenance_due',
          title: 'Urgent: Maintenance due tomorrow',
          body: `${count} item(s) require maintenance tomorrow.`,
          data: { count: String(count) },
        });
      }
    }

    this.logger.log('Nightly maintenance check complete.');
  }
}
