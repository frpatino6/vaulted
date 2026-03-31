import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { MovementsController } from './movements.controller';
import { MovementsService } from './movements.service';
import { Movement, MovementSchema } from './schemas/movement.schema';
import { Item, ItemSchema } from '../inventory/schemas/item.schema';
import {
  ItemHistory,
  ItemHistorySchema,
} from '../inventory/schemas/item-history.schema';
import { Property, PropertySchema } from '../properties/schemas/property.schema';
import { AuditModule } from '../audit/audit.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: Movement.name, schema: MovementSchema },
      { name: Item.name, schema: ItemSchema },
      { name: ItemHistory.name, schema: ItemHistorySchema },
      { name: Property.name, schema: PropertySchema },
    ]),
    AuditModule,
  ],
  controllers: [MovementsController],
  providers: [MovementsService],
  exports: [MovementsService],
})
export class MovementsModule {}
