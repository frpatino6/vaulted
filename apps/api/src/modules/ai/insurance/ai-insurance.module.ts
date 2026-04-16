import { Module } from '@nestjs/common';
import { AiSharedModule } from '../shared/ai-shared.module';
import { InsuranceModule } from '../../insurance/insurance.module';
import { AiInsuranceController } from './ai-insurance.controller';
import { AiInsuranceService } from './ai-insurance.service';

@Module({
  imports: [AiSharedModule, InsuranceModule],
  controllers: [AiInsuranceController],
  providers: [AiInsuranceService],
})
export class AiInsuranceModule {}
