import { HttpException, HttpStatus, Injectable, Logger } from '@nestjs/common';
import { InjectRedis } from '../../../common/decorators/inject-redis.decorator';
import Redis from 'ioredis';
import { GeminiClient } from '../shared/gemini.client';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { InsuranceService } from '../../insurance/insurance.service';

const GEMINI_MODEL = 'gemini-2.0-flash';

export interface CoverageAnalysisResult {
  overallRisk: 'low' | 'medium' | 'high' | 'critical';
  summary: string;
  recommendations: string[];
  priorityItems: { itemId: string; itemName: string; issue: string }[];
  renewalUrgency: 'none' | 'soon' | 'urgent';
}

export interface ClaimDraftResult {
  subject: string;
  body: string;
  keyPoints: string[];
  nextSteps: string[];
}

@Injectable()
export class AiInsuranceService {
  private readonly logger = new Logger(AiInsuranceService.name);

  constructor(
    @InjectRedis() private readonly redis: Redis,
    private readonly geminiClient: GeminiClient,
    private readonly costLogger: AiCostLoggerService,
    private readonly insuranceService: InsuranceService,
  ) {}

  async analyzeCoverage(
    tenantId: string,
    userId: string,
    policyId: string,
  ): Promise<CoverageAnalysisResult> {
    const rateLimitKey = `ai:insurance:analyze:${tenantId}`;
    await this.enforceRateLimit(rateLimitKey, 10);

    const [policy, gapReport] = await Promise.all([
      this.insuranceService.findPolicyById(tenantId, policyId),
      this.insuranceService.getCoverageGaps(tenantId),
    ]);

    const now = new Date();
    const msUntilExpiry = policy.expiresAt.getTime() - now.getTime();
    const daysUntilExpiry = Math.ceil(msUntilExpiry / (1000 * 60 * 60 * 24));

    const insuredItemsContext = policy.insuredItems.length > 0
      ? policy.insuredItems
          .slice(0, 20)
          .map((i) => `- Item ID: ${i.itemId}, Covered: $${Number(i.coveredValue).toLocaleString()} ${i.currency}`)
          .join('\n')
      : 'No items currently attached to this policy.';

    const gapContext = [
      `Uncovered items (no insurance): ${gapReport.uncovered.length}`,
      `Underinsured items: ${gapReport.underinsured.length}`,
      `Total uncovered value: $${gapReport.totalUncoveredValue.toLocaleString()} USD`,
      `Total underinsured gap: $${gapReport.totalUnderinsuredGap.toLocaleString()} USD`,
    ].join('\n');

    const topGapItems = [
      ...gapReport.uncovered.slice(0, 3).map((i) => ({
        itemId: i.itemId,
        itemName: i.name,
        issue: `Completely uncovered — current value $${i.currentValue.toLocaleString()}`,
      })),
      ...gapReport.underinsured.slice(0, 2).map((i) => ({
        itemId: i.itemId,
        itemName: i.name,
        issue: `Underinsured by $${i.gap.toLocaleString()} — covered $${i.coveredValue.toLocaleString()} vs value $${i.currentValue.toLocaleString()}`,
      })),
    ];

    const prompt = `You are an insurance risk analyst for ultra-high-net-worth families.
Analyze the following insurance policy and coverage data, then return a risk assessment.

POLICY DETAILS:
Provider: ${policy.provider}
Policy Number: ${policy.policyNumber}
Coverage Type: ${policy.coverageType}
Total Coverage: $${Number(policy.totalCoverageAmount).toLocaleString()} ${policy.currency}
Status: ${policy.status}
Expires: ${policy.expiresAt.toISOString().split('T')[0]} (${daysUntilExpiry} days from today)

INSURED ITEMS (${policy.insuredItems.length} items):
${insuredItemsContext}

COVERAGE GAP SUMMARY (across all tenant policies):
${gapContext}

TOP GAP ITEMS (highest risk):
${topGapItems.map((i) => `- ${i.itemName} [${i.itemId}]: ${i.issue}`).join('\n') || 'None identified.'}

Return ONLY valid JSON with no markdown fences, no explanation:
{
  "overallRisk": "low" | "medium" | "high" | "critical",
  "summary": "<2-3 sentence plain English summary of coverage health>",
  "recommendations": ["<actionable recommendation>"],
  "priorityItems": [{ "itemId": "<string>", "itemName": "<string>", "issue": "<string>" }],
  "renewalUrgency": "none" | "soon" | "urgent"
}

Rules:
- recommendations: max 5 items
- priorityItems: max 5 items, only items needing immediate attention
- renewalUrgency: "urgent" if expires within 30 days, "soon" if within 90 days, "none" otherwise
- overallRisk: "critical" if status is expired or critical gaps exist; use your judgment`;

    const result = await this.geminiClient.chat('', [], prompt);

    await this.costLogger.log({
      tenantId,
      userId,
      feature: 'insurance_analysis',
      model: GEMINI_MODEL,
      inputTokens: result.inputTokens,
      outputTokens: result.outputTokens,
    });

    return this.parseCoverageAnalysis(result.text);
  }

  async draftClaim(
    tenantId: string,
    userId: string,
    policyId: string,
    itemId: string | undefined,
    incidentDescription: string,
  ): Promise<ClaimDraftResult> {
    const rateLimitKey = `ai:insurance:claim:${tenantId}`;
    await this.enforceRateLimit(rateLimitKey, 5);

    const policy = await this.insuranceService.findPolicyById(tenantId, policyId);

    const insuredItem = itemId
      ? policy.insuredItems.find((i) => i.itemId === itemId)
      : undefined;

    const itemContext = insuredItem
      ? `\nItem Details:\n- Item ID: ${insuredItem.itemId}\n- Covered Value: $${Number(insuredItem.coveredValue).toLocaleString()} ${insuredItem.currency}`
      : itemId
        ? `\nItem ID referenced: ${itemId} (not found in this policy)`
        : '';

    const prompt = `You are an insurance claims assistant for ultra-high-net-worth clients at a premium inventory management service.
Draft a formal insurance claim letter based on the following information.

POLICY DETAILS:
Provider: ${policy.provider}
Policy Number: ${policy.policyNumber}
Coverage Type: ${policy.coverageType}
Total Coverage: $${Number(policy.totalCoverageAmount).toLocaleString()} ${policy.currency}
Expires: ${policy.expiresAt.toISOString().split('T')[0]}
${itemContext}

INCIDENT DESCRIPTION:
${incidentDescription}

Return ONLY valid JSON with no markdown fences, no explanation:
{
  "subject": "<formal email subject line>",
  "body": "<complete formal claim letter in English, 3-5 paragraphs, professional tone>",
  "keyPoints": ["<key fact>"],
  "nextSteps": ["<action item>"]
}

Rules:
- subject: concise, formal, includes policy number
- body: professional language befitting ultra-premium clientele, include today's date placeholder [DATE], reference policy number and provider
- keyPoints: max 4 bullet points summarizing the most important facts
- nextSteps: max 3 action items for the policyholder to take immediately`;

    const result = await this.geminiClient.chat('', [], prompt);

    await this.costLogger.log({
      tenantId,
      userId,
      feature: 'insurance_claim_draft',
      model: GEMINI_MODEL,
      inputTokens: result.inputTokens,
      outputTokens: result.outputTokens,
    });

    return this.parseClaimDraft(result.text);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────────

  private async enforceRateLimit(key: string, maxPerHour: number): Promise<void> {
    const count = await this.redis.incr(key);
    if (count === 1) {
      await this.redis.expire(key, 3600);
    }
    if (count > maxPerHour) {
      this.logger.warn(`Rate limit exceeded for key ${key}`);
      throw new HttpException(
        'Rate limit exceeded. Please try again later.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private parseCoverageAnalysis(raw: string): CoverageAnalysisResult {
    try {
      const cleaned = raw
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      const parsed = JSON.parse(cleaned) as Record<string, unknown>;
      return {
        overallRisk: (['low', 'medium', 'high', 'critical'].includes(String(parsed.overallRisk))
          ? parsed.overallRisk
          : 'medium') as CoverageAnalysisResult['overallRisk'],
        summary: String(parsed.summary ?? 'Coverage analysis could not be completed.'),
        recommendations: Array.isArray(parsed.recommendations)
          ? (parsed.recommendations as unknown[]).map(String).slice(0, 5)
          : [],
        priorityItems: Array.isArray(parsed.priorityItems)
          ? (parsed.priorityItems as Record<string, unknown>[]).slice(0, 5).map((item) => ({
              itemId: String(item.itemId ?? ''),
              itemName: String(item.itemName ?? ''),
              issue: String(item.issue ?? ''),
            }))
          : [],
        renewalUrgency: (['none', 'soon', 'urgent'].includes(String(parsed.renewalUrgency))
          ? parsed.renewalUrgency
          : 'none') as CoverageAnalysisResult['renewalUrgency'],
      };
    } catch {
      this.logger.warn('Failed to parse Gemini coverage analysis response, using defaults');
      return {
        overallRisk: 'medium',
        summary: 'AI analysis could not be completed at this time. Please review your policy manually.',
        recommendations: ['Review your policy details with your insurance agent.'],
        priorityItems: [],
        renewalUrgency: 'none',
      };
    }
  }

  private parseClaimDraft(raw: string): ClaimDraftResult {
    try {
      const cleaned = raw
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      const parsed = JSON.parse(cleaned) as Record<string, unknown>;
      return {
        subject: String(parsed.subject ?? 'Insurance Claim Notification'),
        body: String(parsed.body ?? 'Claim draft could not be generated. Please contact your insurance provider directly.'),
        keyPoints: Array.isArray(parsed.keyPoints)
          ? (parsed.keyPoints as unknown[]).map(String).slice(0, 4)
          : [],
        nextSteps: Array.isArray(parsed.nextSteps)
          ? (parsed.nextSteps as unknown[]).map(String).slice(0, 3)
          : [],
      };
    } catch {
      this.logger.warn('Failed to parse Gemini claim draft response, using defaults');
      return {
        subject: 'Insurance Claim Notification',
        body: 'Claim draft could not be generated. Please contact your insurance provider directly.',
        keyPoints: [],
        nextSteps: ['Contact your insurance provider directly.'],
      };
    }
  }
}
