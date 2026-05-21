import { Module } from '@nestjs/common';
import { AiHelpController } from './ai-help.controller';
import { AiHelpService } from './ai-help.service';

@Module({
  controllers: [AiHelpController],
  providers: [AiHelpService],
  exports: [AiHelpService],
})
export class AiHelpModule {}
