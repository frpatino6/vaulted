import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditModule } from '../audit/audit.module';
import { InventoryModule } from '../inventory/inventory.module';
import { MediaModule } from '../media/media.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { Item, ItemSchema } from '../inventory/schemas/item.schema';
import {
  Property,
  PropertySchema,
} from '../properties/schemas/property.schema';
import {
  DryCleaningRecord,
  DryCleaningRecordSchema,
} from './schemas/dry-cleaning-record.schema';
import { Outfit, OutfitSchema } from './schemas/outfit.schema';
import { WardrobeOverdueJob } from './wardrobe-overdue.job';
import { WardrobeController } from './wardrobe.controller';
import { WardrobeService } from './wardrobe.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Outfit.name, schema: OutfitSchema },
      { name: DryCleaningRecord.name, schema: DryCleaningRecordSchema },
      { name: Item.name, schema: ItemSchema },
      { name: Property.name, schema: PropertySchema },
    ]),
    InventoryModule,
    MediaModule,
    AuditModule,
    NotificationsModule,
  ],
  controllers: [WardrobeController],
  providers: [WardrobeService, WardrobeOverdueJob],
  exports: [WardrobeService],
})
export class WardrobeModule {}
