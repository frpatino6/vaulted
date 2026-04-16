import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MongooseModule } from '@nestjs/mongoose';
import { InsurancePolicy } from './entities/insurance-policy.entity';
import { InsuredItem } from './entities/insured-item.entity';
import { InsuranceController } from './insurance.controller';
import { InsuranceService } from './insurance.service';
import { Item, ItemSchema } from '../inventory/schemas/item.schema';

@Module({
  imports: [
    TypeOrmModule.forFeature([InsurancePolicy, InsuredItem]),
    // Read-only access to MongoDB items for coverage gap analysis
    MongooseModule.forFeature([{ name: Item.name, schema: ItemSchema }]),
  ],
  controllers: [InsuranceController],
  providers: [InsuranceService],
  exports: [InsuranceService],
})
export class InsuranceModule {}
