import { Module } from '@nestjs/common';
import { AiSharedModule } from './shared/ai-shared.module';
import { AiChatModule } from './chat/ai-chat.module';
import { AiMaintenanceModule } from './maintenance/ai-maintenance.module';
import { AiInsuranceModule } from './insurance/ai-insurance.module';

@Module({
  imports: [AiSharedModule, AiChatModule, AiMaintenanceModule, AiInsuranceModule],
})
export class AiModule {}
