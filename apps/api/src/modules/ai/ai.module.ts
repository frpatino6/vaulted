import { Module } from '@nestjs/common';
import { AiSharedModule } from './shared/ai-shared.module';
import { AiChatModule } from './chat/ai-chat.module';
import { AiMaintenanceModule } from './maintenance/ai-maintenance.module';

@Module({
  imports: [AiSharedModule, AiChatModule, AiMaintenanceModule],
})
export class AiModule {}
