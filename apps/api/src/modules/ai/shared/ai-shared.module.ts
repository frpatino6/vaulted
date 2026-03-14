import { Global, Module } from '@nestjs/common';
import { EmbeddingService } from './embedding.service';
import { GeminiClient } from './gemini.client';
import { AiCostLoggerService } from './ai-cost-logger.service';
import { AuditModule } from '../../audit/audit.module';

@Global()
@Module({
  imports: [AuditModule],
  providers: [EmbeddingService, GeminiClient, AiCostLoggerService],
  exports: [EmbeddingService, GeminiClient, AiCostLoggerService],
})
export class AiSharedModule {}
