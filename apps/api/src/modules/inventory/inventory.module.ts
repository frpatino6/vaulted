import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';
import { Item, ItemSchema } from './schemas/item.schema';
import { ItemHistory, ItemHistorySchema } from './schemas/item-history.schema';
import { Property, PropertySchema } from '../properties/schemas/property.schema';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Item.name, schema: ItemSchema },
      { name: ItemHistory.name, schema: ItemHistorySchema },
      { name: Property.name, schema: PropertySchema },
    ]),
  ],
  controllers: [InventoryController],
  providers: [InventoryService],
  exports: [InventoryService],
})
export class InventoryModule {}
