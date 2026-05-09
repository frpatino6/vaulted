import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { TypeOrmModule } from '@nestjs/typeorm';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';
import { Item, ItemSchema } from './schemas/item.schema';
import { ItemHistory, ItemHistorySchema } from './schemas/item-history.schema';
import { Property, PropertySchema } from '../properties/schemas/property.schema';
import { Movement, MovementSchema } from '../movements/schemas/movement.schema';
import { CommonModule } from '../../common/common.module';
import { MediaModule } from '../media/media.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Item.name, schema: ItemSchema },
      { name: ItemHistory.name, schema: ItemHistorySchema },
      { name: Property.name, schema: PropertySchema },
      { name: Movement.name, schema: MovementSchema },
    ]),
    TypeOrmModule.forFeature([]),
    CommonModule,
    MediaModule,
    NotificationsModule,
  ],
  controllers: [InventoryController],
  providers: [InventoryService],
  exports: [InventoryService],
})
export class InventoryModule {}
