import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditModule } from '../audit/audit.module';
import { MaintenanceRecord, MaintenanceRecordSchema } from './schemas/maintenance-record.schema';
import { Item, ItemSchema } from '../inventory/schemas/item.schema';
import { MaintenanceController } from './maintenance.controller';
import { MaintenanceService } from './maintenance.service';
import { MaintenanceScheduler } from './maintenance.scheduler';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: MaintenanceRecord.name, schema: MaintenanceRecordSchema },
      { name: Item.name, schema: ItemSchema },
    ]),
    AuditModule,
  ],
  controllers: [MaintenanceController],
  providers: [MaintenanceService, MaintenanceScheduler],
  exports: [MaintenanceService],
})
export class MaintenanceModule {}
