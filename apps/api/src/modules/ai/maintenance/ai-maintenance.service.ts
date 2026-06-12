import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { GeminiClient } from '../shared/gemini.client';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { AccessControlService } from '../../../common/services/access-control.service';
import { Role } from '../../../common/enums/role.enum';
import { AuditService } from '../../audit/audit.service';
import { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { MaintenanceService } from '../../maintenance/maintenance.service';
import { Item, ItemDocument } from '../../inventory/schemas/item.schema';
import {
  MaintenanceRecord,
  MaintenanceRecordDocument,
} from '../../maintenance/schemas/maintenance-record.schema';

export interface AiMaintenanceSuggestion {
  riskScore: number;
  title: string;
  reason: string;
  recommendedAction: string;
  suggestedIntervalDays: number | null;
}

@Injectable()
export class AiMaintenanceService {
  private readonly logger = new Logger(AiMaintenanceService.name);

  private static readonly RISK_THRESHOLD = 60;
  private static readonly ANALYSIS_COOLDOWN_DAYS = 7;

  constructor(
    @InjectModel(Item.name)
    private readonly itemModel: Model<ItemDocument>,
    @InjectModel(MaintenanceRecord.name)
    private readonly recordModel: Model<MaintenanceRecordDocument>,
    private readonly geminiClient: GeminiClient,
    private readonly costLogger: AiCostLoggerService,
    private readonly accessControlService: AccessControlService,
    private readonly maintenanceService: MaintenanceService,
    private readonly auditService: AuditService,
  ) {}

  async analyzeItem(
    user: JwtPayload,
    itemId: string,
  ): Promise<{ suggestion: AiMaintenanceSuggestion | null; recordCreated: boolean }> {
    const tenantId = user.tenantId;
    const userId = user.sub;
    const item = await this.itemModel.findOne({ _id: itemId, tenantId }).exec();
    if (!item) throw new NotFoundException('Item not found');
    await this.assertPropertyAccess(item.propertyId, user);

    // Cooldown: skip if analyzed within the last ANALYSIS_COOLDOWN_DAYS
    const recentAiRecord = await this.recordModel
      .findOne({
        itemId,
        tenantId,
        isAiSuggested: true,
        createdAt: {
          $gte: new Date(
            Date.now() - AiMaintenanceService.ANALYSIS_COOLDOWN_DAYS * 24 * 60 * 60 * 1000,
          ),
        },
      })
      .exec();

    if (recentAiRecord) {
      this.logger.debug(`Skipping AI analysis for item ${itemId} — cooldown active`);
      return { suggestion: null, recordCreated: false };
    }

    const suggestion = await this.callGeminiForSuggestion(item);

    let recordCreated = false;

    if (suggestion.riskScore >= AiMaintenanceService.RISK_THRESHOLD) {
      const scheduledDate = new Date();
      scheduledDate.setDate(scheduledDate.getDate() + 14); // suggest 2 weeks out by default

      const record = await this.recordModel.create({
        itemId,
        tenantId,
        title: suggestion.title,
        description: suggestion.recommendedAction,
        scheduledDate,
        isRecurring: suggestion.suggestedIntervalDays !== null,
        recurrenceIntervalDays: suggestion.suggestedIntervalDays ?? undefined,
        isAiSuggested: true,
        aiRiskScore: suggestion.riskScore,
        aiReason: suggestion.reason,
        currency: 'USD',
        documents: [],
        createdBy: userId,
      });

      await this.auditService.log({
        tenantId,
        userId,
        action: 'maintenance_scheduled',
        entityType: 'maintenance_record',
        entityId: String(record._id),
        metadata: { isAiSuggested: true, riskScore: suggestion.riskScore },
      });

      await this.maintenanceService.syncItemMaintenanceSummary(tenantId, itemId);
      recordCreated = true;

      this.logger.log(
        `AI maintenance suggestion created for item ${itemId} — risk: ${suggestion.riskScore}`,
      );
    }

    return { suggestion, recordCreated };
  }

  private async callGeminiForSuggestion(item: ItemDocument): Promise<AiMaintenanceSuggestion> {
    const ageYears = item.valuation?.purchaseDate
      ? Math.floor(
          (Date.now() - new Date(item.valuation.purchaseDate).getTime()) /
            (365.25 * 24 * 60 * 60 * 1000),
        )
      : null;

    const itemContext = [
      `Name: ${item.name}`,
      `Category: ${item.category}`,
      item.subcategory ? `Subcategory: ${item.subcategory}` : null,
      ageYears !== null ? `Age: ${ageYears} year(s)` : null,
    ]
      .filter(Boolean)
      .join('\n');

    const prompt = `You are a home asset maintenance expert for ultra-high-net-worth families.
Analyze this household item and determine if it needs maintenance soon.

Item details:
${itemContext}

Respond ONLY with valid JSON (no markdown, no explanation):
{
  "riskScore": <number 0-100, where 100 = critical maintenance needed>,
  "title": <short maintenance task title, max 100 chars>,
  "reason": <1-2 sentences explaining why maintenance is needed>,
  "recommendedAction": <specific action the owner should take>,
  "suggestedIntervalDays": <number of days for recurring maintenance, or null if one-time>
}`;

    const result = await this.geminiClient.chat('', [], prompt);

    await this.costLogger.log({
      tenantId: String(item.tenantId),
      userId: 'system',
      feature: 'ai_maintenance',
      model: 'gemini-2.5-flash',
      inputTokens: result.inputTokens,
      outputTokens: result.outputTokens,
    });

    return this.parseGeminiResponse(result.text);
  }

  private sanitizeText(value: unknown, maxLength: number): string {
    return String(value ?? '')
      .replace(/<[^>]*>/g, '')
      .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
      .slice(0, maxLength);
  }

  private parseGeminiResponse(raw: string): AiMaintenanceSuggestion {
    try {
      const cleaned = raw
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      const parsed = JSON.parse(cleaned) as Record<string, unknown>;
      return {
        riskScore: Math.min(100, Math.max(0, Number(parsed.riskScore ?? 0))),
        title: this.sanitizeText(parsed.title ?? 'Maintenance recommended', 200),
        reason: this.sanitizeText(parsed.reason ?? '', 500),
        recommendedAction: this.sanitizeText(parsed.recommendedAction ?? '', 500),
        suggestedIntervalDays:
          parsed.suggestedIntervalDays !== null && parsed.suggestedIntervalDays !== undefined
            ? Math.min(3650, Math.max(1, Number(parsed.suggestedIntervalDays)))
            : null,
      };
    } catch {
      this.logger.warn('Failed to parse Gemini maintenance response, using defaults');
      return {
        riskScore: 0,
        title: 'Maintenance check recommended',
        reason: 'AI analysis could not be completed.',
        recommendedAction: 'Please inspect the item manually.',
        suggestedIntervalDays: null,
      };
    }
  }

  private async assertPropertyAccess(
    propertyId: string,
    user: JwtPayload,
  ): Promise<void> {
    const allowedPropertyIds = await this.accessControlService.getAllowedPropertyIds(
      user.sub,
      user.role as Role,
    );
    if (allowedPropertyIds !== null && !allowedPropertyIds.includes(propertyId)) {
      throw new NotFoundException('Item not found');
    }
  }
}
