import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AiSharedModule } from '../shared/ai-shared.module';
import { MaintenanceModule } from '../../maintenance/maintenance.module';
import { Item, ItemSchema } from '../../inventory/schemas/item.schema';
import {
  MaintenanceRecord,
  MaintenanceRecordSchema,
} from '../../maintenance/schemas/maintenance-record.schema';
import { AiMaintenanceService } from './ai-maintenance.service';
import { AiMaintenanceController } from './ai-maintenance.controller';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Item.name, schema: ItemSchema },
      { name: MaintenanceRecord.name, schema: MaintenanceRecordSchema },
    ]),
    AiSharedModule,
    MaintenanceModule,
  ],
  controllers: [AiMaintenanceController],
  providers: [AiMaintenanceService],
})
export class AiMaintenanceModule {}
