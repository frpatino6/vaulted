import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { PropertiesController } from './properties.controller';
import { PropertiesService } from './properties.service';
import { Property, PropertySchema } from './schemas/property.schema';
import { Item, ItemSchema } from '../inventory/schemas/item.schema';
import { CommonModule } from '../../common/common.module';

@Module({
  imports: [
    CommonModule,
    MongooseModule.forFeature([
      { name: Property.name, schema: PropertySchema },
      { name: Item.name, schema: ItemSchema },
    ]),
  ],
  controllers: [PropertiesController],
  providers: [PropertiesService],
  exports: [PropertiesService],
})
export class PropertiesModule {}
