import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditModule } from '../audit/audit.module';
import {
  OrchestratorPlan,
  OrchestratorPlanSchema,
} from './schemas/orchestrator-plan.schema';
import { OrchestratorController } from './orchestrator.controller';
import { OrchestratorService } from './orchestrator.service';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: OrchestratorPlan.name, schema: OrchestratorPlanSchema },
    ]),
    AuditModule,
  ],
  controllers: [OrchestratorController],
  providers: [OrchestratorService],
  exports: [OrchestratorService],
})
export class OrchestratorModule {}
