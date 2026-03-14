import { Module } from '@nestjs/common';
import { AiSharedModule } from './shared/ai-shared.module';
import { AiChatModule } from './chat/ai-chat.module';

@Module({
  imports: [AiSharedModule, AiChatModule],
})
export class AiModule {}
