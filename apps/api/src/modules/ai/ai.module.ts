import { Module } from '@nestjs/common';
import { AiSharedModule } from './shared/ai-shared.module';
import { AiChatModule } from './chat/ai-chat.module';
import { AiMaintenanceModule } from './maintenance/ai-maintenance.module';
import { AiVisionModule } from './vision/ai-vision.module';
import { AiInsuranceModule } from './insurance/ai-insurance.module';
import { AiHelpModule } from './help/ai-help.module';

@Module({
  imports: [
    AiSharedModule,
    AiChatModule,
    AiMaintenanceModule,
    AiVisionModule,
    AiInsuranceModule,
    AiHelpModule,
  ],
})
export class AiModule {}
