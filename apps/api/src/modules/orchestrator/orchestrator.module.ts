import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditModule } from '../audit/audit.module';
import { AiSharedModule } from '../ai/shared/ai-shared.module';
import { Item, ItemSchema } from '../inventory/schemas/item.schema';
import { Property, PropertySchema } from '../properties/schemas/property.schema';
import {
  OrchestratorPlan,
  OrchestratorPlanSchema,
} from './schemas/orchestrator-plan.schema';
import { OrchestratorController } from './orchestrator.controller';
import { OrchestratorService } from './orchestrator.service';
import { OrchestratorAiService } from './orchestrator-ai.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: OrchestratorPlan.name, schema: OrchestratorPlanSchema },
      { name: Item.name, schema: ItemSchema },
      { name: Property.name, schema: PropertySchema },
    ]),
    AuditModule,
    AiSharedModule,
  ],
  controllers: [OrchestratorController],
  providers: [OrchestratorService, OrchestratorAiService],
  exports: [OrchestratorService],
})
export class OrchestratorModule {}
