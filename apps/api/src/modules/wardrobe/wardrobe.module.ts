import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditModule } from '../audit/audit.module';
import { InventoryModule } from '../inventory/inventory.module';
import { Item, ItemSchema } from '../inventory/schemas/item.schema';
import {
  DryCleaningRecord,
  DryCleaningRecordSchema,
} from './schemas/dry-cleaning-record.schema';
import { Outfit, OutfitSchema } from './schemas/outfit.schema';
import { WardrobeController } from './wardrobe.controller';
import { WardrobeService } from './wardrobe.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Outfit.name, schema: OutfitSchema },
      { name: DryCleaningRecord.name, schema: DryCleaningRecordSchema },
      { name: Item.name, schema: ItemSchema },
    ]),
    InventoryModule,
    AuditModule,
  ],
  controllers: [WardrobeController],
  providers: [WardrobeService],
  exports: [WardrobeService],
})
export class WardrobeModule {}
