import { Injectable } from '@nestjs/common';
import { AuditService } from '../../audit/audit.service';

export interface AiUsage {
  tenantId: string;
  userId: string;
  feature: string;
  model: string;
  inputTokens: number;
  outputTokens: number;
}

@Injectable()
export class AiCostLoggerService {
  constructor(private readonly auditService: AuditService) {}

  async log(usage: AiUsage): Promise<void> {
    await this.auditService.log({
      tenantId: usage.tenantId,
      userId: usage.userId,
      action: 'ai_usage',
      entityType: 'ai',
      metadata: {
        feature: usage.feature,
        model: usage.model,
        inputTokens: usage.inputTokens,
        outputTokens: usage.outputTokens,
        totalTokens: usage.inputTokens + usage.outputTokens,
      },
    });
  }
}
