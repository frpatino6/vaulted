import { Module } from '@nestjs/common';
import { AiSharedModule } from './shared/ai-shared.module';
import { AiChatModule } from './chat/ai-chat.module';
import { AiMaintenanceModule } from './maintenance/ai-maintenance.module';
import { AiVisionModule } from './vision/ai-vision.module';

@Module({
  imports: [AiSharedModule, AiChatModule, AiMaintenanceModule, AiVisionModule],
})
export class AiModule {}
