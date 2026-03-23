import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { MaintenanceService } from './maintenance.service';

@Injectable()
export class MaintenanceScheduler {
  private readonly logger = new Logger(MaintenanceScheduler.name);

  constructor(private readonly maintenanceService: MaintenanceService) {}

  /**
   * Runs every night at 02:00 AM.
   * 1. Marks past-due pending records as overdue.
   * 2. Logs upcoming alerts for records due in 7 days and 1 day.
   *    (Push/email dispatch will be wired here when NotificationsModule is ready.)
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
      // TODO: dispatch push + email notifications when NotificationsModule is available
    }

    const in1Day = await this.maintenanceService.findUpcomingInDays(1);
    if (in1Day.length > 0) {
      this.logger.log(
        `Urgent: maintenance due tomorrow: ${in1Day.length} records`,
      );
      // TODO: dispatch urgent push + email notifications
    }

    this.logger.log('Nightly maintenance check complete.');
  }
}
