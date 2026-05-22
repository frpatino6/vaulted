import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { v4 as uuidv4 } from 'uuid';
import { InjectRedis } from '../../../common/decorators/inject-redis.decorator';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { GeminiChatMessage, GeminiClient } from '../shared/gemini.client';
import { HelpRequestDto, HelpScreen } from './dto/help-request.dto';

interface HelpSessionTurn {
  role: 'user' | 'model';
  content: string;
}

export interface AiHelpResponse {
  answer: string;
  sessionId: string;
  suggestions: string[];
}

const HELP_KNOWLEDGE_BASE = `
## Dashboard
- Shows KPI cards: total items, total estimated value, items on loan, upcoming maintenance.
- Property switcher at the top filters dashboard data by property.
- Recent activity feed shows the latest inventory actions.

## Properties & Rooms
- Add a property with name, address, and property type.
- Add floors and rooms inside each property.
- Common room types include bedroom, living room, kitchen, basement, garage, and storage.

## Inventory (Items)
- Add an item manually with category, name, room, valuation, photos, and serial number.
- Use AI Scan to catalog an item from a photo.
- Edit item details from the item detail screen.
- Item statuses include active, on loan, under repair, in storage, and disposed.
- Search and filter items by category, status, room, and property.
- Item detail shows movement history.
- Each item has a QR code that opens the item detail from any device.

## Movements (Loans & Transfers)
- Loan an item by selecting the item, entering borrower details, and setting expected return date.
- Mark loaned items as returned from Movements.
- Transfer an item to another room or property.
- Movement history records every move.
- Movement workflow is draft, active, then completed.

## Wardrobe
- Wardrobe is a specialized view for clothing, footwear, accessories, jewelry, and watches.
- Closet grid shows wardrobe items.
- Create outfits by selecting items, naming the outfit, and adding occasion tags.
- Log dry cleaning records with item, date, provider, and cost.
- Stats show wardrobe items, outfits created, and dry cleaning count.

## Maintenance
- Create a maintenance record with item, scheduled date, type, and notes.
- Maintenance types include cleaning, inspection, repair, service, calibration, and other.
- Update maintenance status to completed or cancelled.
- AI risk scoring flags high-risk items for maintenance.

## Insurance
- Add an insurance policy with insurer, policy number, coverage type, premium, and dates.
- Link inventory items to policies.
- Coverage gap analysis identifies underinsured items.
- AI can draft an insurance claim letter.

## AI Scan (Vision)
- Open AI Scan from the add button or navigation.
- Point the camera at an item to identify category, brand, and estimated value.
- Review and confirm AI suggestions before saving.
- Invoice scanning can extract purchase details.

## AI Chat (Inventory Assistant)
- AI Chat answers natural language questions over the user's inventory.
- It can filter by property and return matching items with photos and location.
- For questions about actual inventory data, users should use AI Chat.

## Users & Roles
- Invite users with email, role, and property access.
- Owner has full access and manages users.
- Manager manages inventory but cannot see financial valuations.
- Staff can view and update assigned items only.
- Auditor has read-only access with watermarked exports.
- Guest has temporary access with expiration.
- Property-scoped access keeps users limited to assigned properties.

## Reports
- Export inventory as PDF or Excel.
- Filter exports by category, room, or property.
- Auditor exports are watermarked.

## Settings
- Manage notification preferences for push and email.
- Set up MFA with a TOTP authenticator app.
- Update profile details.

## QR Scanning
- Each item has a unique QR code.
- Scan from the QR icon to jump directly to item detail.
- QR scanning helps quick check-in and check-out during moves.
`.trim();

const SCREEN_CONTEXT: Record<HelpScreen, string> = {
  dashboard: 'The user is viewing Dashboard metrics and recent activity.',
  inventory: 'The user is browsing or searching inventory items.',
  item_detail: 'The user is viewing a single item detail page.',
  add_item: 'The user is creating a new inventory item.',
  movements: 'The user is managing item loans, returns, and transfers.',
  wardrobe: 'The user is using the wardrobe module.',
  maintenance: 'The user is managing item maintenance records.',
  insurance: 'The user is managing policies, claims, or coverage analysis.',
  properties: 'The user is managing properties, floors, and rooms.',
  users: 'The user is managing invited users, roles, and property access.',
  ai_scan: 'The user is using AI Scan to catalog an item or invoice from an image.',
  ai_chat: 'The user is using the inventory AI Chat feature.',
  reports: 'The user is exporting or reviewing reports.',
  settings: 'The user is managing profile, MFA, or notification settings.',
};

const SCREEN_SUGGESTIONS: Record<HelpScreen, string[]> = {
  dashboard: [
    'How do I filter the dashboard by property?',
    'What do the dashboard KPI cards mean?',
    'Where can I see recent activity?',
  ],
  inventory: [
    'How do I add a new item?',
    'How do I filter items by room?',
    'How do I find items on loan?',
  ],
  item_detail: [
    'How do I edit this item?',
    'How do I see movement history?',
    'How do I use the item QR code?',
  ],
  add_item: [
    'Which fields are required for a new item?',
    'How many photos can I add?',
    'When should I use AI Scan instead?',
  ],
  movements: [
    'How do I mark a loaned item as returned?',
    'How do I transfer an item to another room?',
    'How do I see all active loans?',
  ],
  wardrobe: [
    'How do I create an outfit?',
    'How do I add dry cleaning history?',
    'Which items appear in wardrobe?',
  ],
  maintenance: [
    'How do I schedule maintenance?',
    'What maintenance types are available?',
    'How do I complete a maintenance record?',
  ],
  insurance: [
    'How do I add a policy?',
    'How do I link items to insurance?',
    'How does coverage gap analysis work?',
  ],
  properties: [
    'How do I add a room?',
    'How do I organize floors?',
    'How do I move an item between properties?',
  ],
  users: [
    'How do I invite a staff member?',
    'What is property-scoped access?',
    'What is the difference between roles?',
  ],
  ai_scan: [
    'How do I scan an item?',
    'Can AI Scan read invoices?',
    'Do I need to confirm AI suggestions?',
  ],
  ai_chat: [
    'What can AI Chat answer?',
    'How do I ask about a specific property?',
    'Why should I use Vaulted Guide instead?',
  ],
  reports: [
    'How do I export a PDF?',
    'Can I filter a report before export?',
    'Why are auditor exports watermarked?',
  ],
  settings: [
    'How do I set up MFA?',
    'How do I change notification preferences?',
    'How do I update my profile?',
  ],
};

const DEFAULT_SUGGESTIONS = [
  'How do I add a new item?',
  'How do I invite a staff member?',
  'How do I export an inventory report?',
];

@Injectable()
export class AiHelpService {
  private readonly rateLimit: number;
  private readonly sessionTtl = 3600;
  private readonly maxHistoryTurns = 15;

  constructor(
    @InjectRedis() private readonly redis: Redis,
    private readonly geminiClient: GeminiClient,
    private readonly costLogger: AiCostLoggerService,
    private readonly config: ConfigService,
  ) {
    this.rateLimit = config.get<number>('AI_HELP_RATE_LIMIT_PER_MINUTE') ?? 30;
  }

  async chat(tenantId: string, userId: string, dto: HelpRequestDto): Promise<AiHelpResponse> {
    await this.enforceRateLimit(tenantId);

    const sessionId = dto.sessionId ?? uuidv4();
    const history = await this.getSessionHistory(tenantId, userId, sessionId);
    const systemPrompt = this.buildSystemPrompt(dto.currentScreen);
    const geminiHistory: GeminiChatMessage[] = history.map((turn) => ({
      role: turn.role,
      content: turn.content,
    }));

    const result = await this.geminiClient.chat(systemPrompt, geminiHistory, dto.query);

    await this.updateSessionHistory(tenantId, userId, sessionId, dto.query, result.text);

    void this.costLogger.log({
      tenantId,
      userId,
      feature: 'help_chat',
      model: this.config.get<string>('AI_CHAT_MODEL') ?? 'gemini-2.5-flash',
      inputTokens: result.inputTokens,
      outputTokens: result.outputTokens,
    });

    return {
      answer: result.text,
      sessionId,
      suggestions: this.getSuggestions(dto.currentScreen),
    };
  }

  private async enforceRateLimit(tenantId: string): Promise<void> {
    const key = `ai:help:ratelimit:${tenantId}`;
    const count = await this.redis.incr(key);
    if (count === 1) await this.redis.expire(key, 60);
    if (count > this.rateLimit) {
      throw new HttpException('Rate limit exceeded', HttpStatus.TOO_MANY_REQUESTS);
    }
  }

  private async getSessionHistory(
    tenantId: string,
    userId: string,
    sessionId: string,
  ): Promise<HelpSessionTurn[]> {
    const raw = await this.redis.get(this.sessionKey(tenantId, userId, sessionId));
    if (!raw) return [];

    try {
      const parsed: unknown = JSON.parse(raw);
      if (!Array.isArray(parsed)) return [];

      return parsed.filter((turn): turn is HelpSessionTurn => {
        if (typeof turn !== 'object' || turn === null) return false;
        const candidate = turn as { role?: unknown; content?: unknown };
        return (
          (candidate.role === 'user' || candidate.role === 'model') &&
          typeof candidate.content === 'string'
        );
      });
    } catch {
      return [];
    }
  }

  private async updateSessionHistory(
    tenantId: string,
    userId: string,
    sessionId: string,
    userMessage: string,
    modelResponse: string,
  ): Promise<void> {
    const history = await this.getSessionHistory(tenantId, userId, sessionId);
    history.push({ role: 'user', content: userMessage });
    history.push({ role: 'model', content: modelResponse });

    const trimmed = history.slice(-this.maxHistoryTurns * 2);
    await this.redis.set(
      this.sessionKey(tenantId, userId, sessionId),
      JSON.stringify(trimmed),
      'EX',
      this.sessionTtl,
    );
  }

  private buildSystemPrompt(currentScreen?: HelpScreen): string {
    const screen = currentScreen ?? 'not specified';
    const screenContext = currentScreen ? SCREEN_CONTEXT[currentScreen] : 'No screen context was provided.';

    return `
You are Vaulted Guide, the in-app AI assistant for Vaulted, a premium home inventory management app for high-net-worth families. Your sole purpose is to help users understand how to use the Vaulted app.

RULES:
- Answer only questions about how to use Vaulted features.
- If asked about the user's actual inventory items, redirect them to use the AI Chat feature in the navigation menu.
- Be concise and use numbered steps for procedural instructions.
- Respond in the same language the user writes in.
- Do not invent unavailable screens, permissions, or data.

CURRENT CONTEXT:
Screen: ${screen}
Context: ${screenContext}

APP FEATURES DOCUMENTATION:
${HELP_KNOWLEDGE_BASE}
`.trim();
  }

  private getSuggestions(currentScreen?: HelpScreen): string[] {
    if (!currentScreen) return DEFAULT_SUGGESTIONS;
    return SCREEN_SUGGESTIONS[currentScreen];
  }

  private sessionKey(tenantId: string, userId: string, sessionId: string): string {
    return `ai:help:session:${tenantId}:${userId}:${sessionId}`;
  }
}
