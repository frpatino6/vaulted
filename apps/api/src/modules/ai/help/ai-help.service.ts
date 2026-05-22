import { HttpException, HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { v4 as uuidv4 } from 'uuid';
import { InjectRedis } from '../../../common/decorators/inject-redis.decorator';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { GeminiChatMessage, GeminiClient } from '../shared/gemini.client';
import { HelpFeedbackDto } from './dto/help-feedback.dto';
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

// ─── System prompt ────────────────────────────────────────────────────────────

const SYSTEM_PROMPT = `
You are Vaulted Guide, the official in-app AI assistant for Vaulted — a premium home inventory
management app for ultra-high-net-worth families. Your purpose is to guide users through every
feature of the app with precision and clarity.

## Step 1 — Classify the question (internally), then respond accordingly

**PROCEDURAL** ("how do I…", "how to…", "steps to…", "can I…"):
→ One-sentence overview, then numbered steps with exact UI element names.
→ End with a "💡 Pro tip:" line with a relevant shortcut or best practice.

**CONCEPTUAL** ("what is…", "what does X do", "explain…"):
→ 1–2 sentence definition, then 2–3 key use cases as bullet points.

**TROUBLESHOOTING** ("why can't I…", "I don't see…", "it's not working", "not showing"):
→ Diagnose the most likely cause first (role restriction, wrong status, wrong screen).
→ Then give fix steps.

**COMPARISON** ("difference between…", "which should I use…"):
→ Use a table or parallel bullet list.

## Step 2 — Precision rules

- Name exact UI elements: "Tap the **+** button (bottom-right corner)" not "tap add".
- Include navigation path on first mention: "Bottom navigation bar → Inventory".
- Mention exact field labels as they appear in the app form.
- Mention role restrictions inline when relevant: "(Owner and Manager only)".
- Mention limits: items support up to 10 photos; sessions expire for Guest role.

## Step 3 — Role awareness

If a user can't see a feature or value, their role is likely the cause. Roles and their limits:
- **Owner**: full access — manages users, sees all valuations, all properties.
- **Manager**: manages inventory; **cannot see financial valuations**; cannot manage users.
- **Staff**: view and update only items assigned to them; limited to their property.
- **Auditor**: read-only; exports are watermarked; cannot create or edit anything.
- **Guest**: temporary access with expiry date; read-only.

## Other rules

- **Redirect inventory queries**: If asked about actual items ("where is my watch", "value of my sofa"), say: "For questions about your items, use the **AI Chat** feature in the navigation menu — it searches your inventory directly."
- **Unresolved**: If the question is completely outside Vaulted functionality, end your response with exactly: [UNRESOLVED: brief description]
- **Never invent** features, buttons, or screens that don't exist.
- **Language**: Respond in the same language the user writes in (English or Spanish supported).

CURRENT SCREEN CONTEXT:
{SCREEN_CONTEXT}

APP DOCUMENTATION:
{KNOWLEDGE_BASE}
`.trim();

// ─── Knowledge base ────────────────────────────────────────────────────────────
// Detailed step-by-step workflows with exact UI element names.

const HELP_KNOWLEDGE_BASE = `
## Dashboard

The Dashboard is the home screen. It shows:
- KPI cards: Total Items, Total Estimated Value (Owner/Manager only), Items on Loan, Upcoming Maintenance.
- Property switcher (top of screen) — tap to filter all cards by a specific property.
- Recent Activity feed — shows the last inventory actions across the account.

To switch property context: tap the property name in the header dropdown and select a property or "All Properties".

---

## Properties, Floors & Rooms

### Add a property
1. Tap **Properties** in the bottom navigation bar.
2. Tap the **+** button (top-right corner).
3. Enter: Property Name, Address, and Property Type (mansion, apartment, vacation home, etc.).
4. Tap **Save**.

### Add a floor to a property
1. Open the property detail (tap the property card).
2. Tap **Add Floor**.
3. Enter the floor name (e.g., "Ground Floor", "Second Floor").
4. Tap **Save**.

### Add a room to a floor
1. Open the property detail → tap the floor.
2. Tap **Add Room**.
3. Enter: Room Name and Room Type (bedroom, living room, kitchen, office, garage, storage, etc.).
4. Tap **Save**.

💡 Rooms must exist before you can assign items to them.

---

## Inventory (Items)

### Add an item manually
1. Tap **Inventory** in the bottom navigation bar.
2. Tap the blue **+** button (bottom-right corner).
3. Select a **Category** (e.g., Furniture, Art & Collectibles, Wardrobe, Vehicles).
4. Enter the **Item Name** and optionally a **Subcategory**.
5. Select the **Room** where the item is located.
6. Add up to **10 photos** using the camera or photo library.
7. Fill in **Valuation**: Purchase Price, Purchase Date, Current Value, Currency.
8. Optionally: Serial Number, Tags (comma-separated), Location Detail (e.g., "Left side of closet").
9. Tap **Save**.

### Use AI Scan to catalog an item from a photo
1. Tap the **camera icon** (AI Scan) in the navigation bar, or tap **Scan with AI** from the + menu.
2. Point the camera at the item and tap **Capture**.
3. Review AI suggestions: Category, Brand, Estimated Value, Attributes.
4. Edit any fields as needed — the AI may misidentify rare or uncommon items.
5. Tap **Confirm & Save**.

For **invoice scanning**: after capturing, tap **Scan Invoice** to auto-fill Purchase Price and Purchase Date from a receipt or invoice image.

💡 Pro tip: AI Scan works best with good lighting and the full item in frame.

### Edit an item
1. Open the item detail (tap the item from the list).
2. Tap the **pencil (edit) icon** (top-right corner).
3. Modify the desired fields.
4. Tap **Save**.

### Item statuses
- **Active**: item is in its assigned room and available.
- **On Loan**: item has been lent to someone — see Movements to manage return.
- **Under Repair**: item is being repaired (a Repair movement was created).
- **In Storage**: item was moved to a storage location.
- **Disposed**: item is no longer in inventory — it cannot be moved, loaned, or edited.

To change status: edit the item → update the Status field. Some transitions (e.g., Repair) create a Movement automatically.

### Search and filter items
- Use the **Search bar** at the top of the Inventory screen — searches name, tags, serial number.
- Use the **Filter chips** below the search bar to filter by: Category, Status, Room.
- Use the **Property switcher** (top of screen) to limit results to one property.

### Item QR code
- Each item has a unique QR code — visible on the item detail page under the item name.
- Scanning the QR code from any screen opens that item's detail directly.
- Useful for quick audits, check-in/check-out during moves, or sharing item info.

---

## Movements (Loans, Returns, Transfers, Repairs)

Movements track every time an item changes hands or location.

### Loan an item to someone
1. Tap **Movements** (or Operations) in the navigation.
2. Tap the **+** button (bottom-right corner).
3. Select **Loan** as the movement type.
4. Search and select the item(s) to loan.
5. Enter: Borrower Name, Borrower Contact (optional), Expected Return Date.
6. Tap **Confirm** — status changes to **Active**.

The item's status automatically changes to **On Loan**.

### Mark a loaned item as returned
1. Open **Movements** → find the active loan.
2. Tap the loan card to open its detail.
3. Tap **Mark as Returned** (or **Complete**).
4. Confirm the return.

The item status returns to **Active** automatically.

### Transfer an item to another room or property
1. Tap **Movements** → **+** button.
2. Select **Transfer** as the movement type.
3. Select the item(s).
4. Select the **Destination**: choose a different room (same property) or a different property.
5. Tap **Confirm**.

### View movement history for an item
- Open the item detail page → scroll to **Movement History** section.
- Shows all past and active movements: who moved it, when, where to.

### Movement workflow
All movements follow: **Draft → Active → Completed**.
- Draft: created but not yet confirmed.
- Active: confirmed, in progress (item has changed status).
- Completed: movement finished (item returned, transfer done).

---

## Wardrobe

Wardrobe is a specialized module for clothing, footwear, accessories, jewelry, and watches.

### Access Wardrobe
- Tap **Wardrobe** in the bottom navigation bar.
- The closet grid shows all wardrobe-category items.

### Create an outfit
1. In the Wardrobe screen, tap the **Outfits** tab (or the outfits icon).
2. Tap **+ New Outfit**.
3. Enter an outfit name (e.g., "Business Meeting") and occasion tags.
4. Tap **Add Items** — select from your wardrobe items.
5. Tap **Save Outfit**.

### Log a dry cleaning record
1. In the Wardrobe screen, tap the **Dry Cleaning** tab.
2. Tap **+ Log Dry Cleaning**.
3. Select the item(s) sent to the cleaner.
4. Enter: Date Sent, Provider Name, Cost (optional), Return Date (optional).
5. Tap **Save**.

### Wardrobe stats bar
The top bar shows: Total Wardrobe Items, Outfits Created, Dry Cleaning count.

---

## Maintenance

### Schedule a maintenance record
1. Tap **Maintenance** in the navigation.
2. Tap the **+** button.
3. Select the **Item** to maintain.
4. Enter: Scheduled Date, Maintenance Type, Notes (optional).
5. Maintenance types: Cleaning, Inspection, Repair, Service, Calibration, Other.
6. Tap **Save**.

### Update maintenance status
1. Open the maintenance record (tap it from the list).
2. Tap **Mark as Completed** or **Cancel**.
3. Confirm.

### AI risk scoring
The system automatically analyzes items based on age, category, and condition and flags high-risk ones.
- Items with risk score ≥ 60% may auto-generate maintenance suggestions.
- These appear in the maintenance list with an "AI Suggested" tag.

---

## Insurance

### Add an insurance policy
1. Tap **Insurance** in the navigation.
2. Tap **+ New Policy**.
3. Enter: Insurer Name, Policy Number, Coverage Type, Premium Amount, Start Date, End Date.
4. Tap **Save**.

### Link items to a policy
1. Open the policy detail.
2. Tap **Link Items**.
3. Search and select items from your inventory.
4. Tap **Done**.

### Coverage gap analysis
1. Open a policy detail.
2. Tap **Analyze Coverage Gaps**.
3. The AI identifies items with no policy or with current value exceeding covered value.
4. Review the gaps report — items are listed with their coverage shortfall.

### Draft an insurance claim letter (AI)
1. Open the policy detail → tap **Draft Claim**.
2. Describe the incident or loss.
3. The AI generates a formal claim letter using your policy details and item data.
4. Review, edit if needed, and export or copy.

---

## AI Scan (Vision)

AI Scan uses the device camera to catalog items automatically.

1. Tap the **AI Scan icon** (camera with sparkle) in the navigation.
2. Choose: **Scan Item** or **Scan Invoice**.
3. Frame the item or invoice in the camera view.
4. Tap **Capture**.
5. Review AI output: Name, Category, Brand, Estimated Value, Tags, Suggested Room.
6. Edit any fields.
7. Tap **Save to Inventory**.

For invoices: AI extracts Purchase Price, Purchase Date, and Vendor Name.

---

## AI Chat (Inventory Assistant)

AI Chat answers natural-language questions about your own inventory.

- Access: tap **AI Chat** in the navigation (available to Owner, Manager, Auditor).
- Ask: "Where is my Hermès bag?", "Show all items on loan", "Items worth over $10,000".
- Results include item photos, location, and valuation (if your role allows).
- Use the Property filter to narrow results to one property.
- Distinct from Vaulted Guide: AI Chat searches your items; Vaulted Guide explains the app.

---

## Users & Roles

### Invite a new user
1. Tap **Users** (or the People icon) in the navigation. (Owner only)
2. Tap **+ Invite User**.
3. Enter their email address.
4. Select their **Role**: Owner, Manager, Staff, Auditor, Guest.
5. Select which **Properties** they can access.
6. For Guest: set an **Expiry Date**.
7. Tap **Send Invite**.

The invited user receives an email with a registration link.

### Change a user's role or property access
1. Open **Users** → tap the user.
2. Tap **Edit**.
3. Update Role or Property access.
4. Tap **Save**.

### Role comparison

| Role    | Add/Edit Items | See Valuations | Manage Users | Property Scope  |
|---------|---------------|----------------|--------------|-----------------|
| Owner   | ✅             | ✅              | ✅            | All properties  |
| Manager | ✅             | ❌              | ❌            | Assigned        |
| Staff   | Limited        | ❌              | ❌            | Assigned items  |
| Auditor | ❌ (read-only) | ✅              | ❌            | Assigned        |
| Guest   | ❌ (read-only) | ❌              | ❌            | Assigned, timed |

---

## Reports

1. Tap **Reports** in the navigation.
2. Select the export format: **PDF** or **Excel**.
3. Apply filters: Category, Room, Property, Status.
4. Tap **Export**.

Auditor exports are automatically watermarked.

---

## Settings

- **Notifications**: toggle push and email notifications per event type.
- **MFA Setup**: tap **Security** → **Enable MFA** → scan the QR code with an authenticator app (Google Authenticator, Authy).
- **Profile**: update display name and email.

---

## QR Scanning

- Each item has a unique QR code on its detail page.
- Tap the **QR icon** in the app bar (any screen) to open the scanner.
- Scanning an item QR code navigates directly to that item's detail.
- Useful for: quick audits, staff check-in/check-out, insurance appraisals.
`.trim();

// ─── Screen context & suggestions ─────────────────────────────────────────────

const SCREEN_CONTEXT: Record<HelpScreen, string> = {
  dashboard: 'The user is on the Dashboard — viewing KPI cards and recent activity.',
  inventory: 'The user is browsing or searching the inventory item list.',
  item_detail: "The user is viewing a single item's detail page.",
  add_item: 'The user is on the Add Item form.',
  movements:
    'The user is on the Movements/Operations screen — managing loans, transfers, and repairs.',
  wardrobe: 'The user is in the Wardrobe module — closet grid, outfits, or dry cleaning.',
  maintenance: 'The user is on the Maintenance screen.',
  insurance: 'The user is managing insurance policies, coverage gaps, or claims.',
  properties: 'The user is managing properties, floors, or rooms.',
  users: 'The user is managing invited users, roles, and property access.',
  ai_scan: 'The user is using AI Scan to catalog an item or invoice.',
  ai_chat: 'The user is on the AI Chat (inventory assistant) screen.',
  reports: 'The user is on the Reports/export screen.',
  settings: 'The user is in Settings.',
};

const SCREEN_SUGGESTIONS: Record<HelpScreen, string[]> = {
  dashboard: [
    'How do I filter the dashboard by property?',
    'What does the Total Value card show?',
    'How do I see recent activity?',
  ],
  inventory: [
    'How do I add a new item?',
    'How do I filter items by room?',
    'How do I find items currently on loan?',
  ],
  item_detail: [
    'How do I edit this item?',
    "How do I see this item's movement history?",
    'How do I use the item QR code?',
  ],
  add_item: [
    'Which fields are required?',
    'How many photos can I add?',
    'When should I use AI Scan instead?',
  ],
  movements: [
    'How do I loan an item?',
    'How do I mark a loaned item as returned?',
    'How do I transfer an item to another property?',
  ],
  wardrobe: [
    'How do I create an outfit?',
    'How do I log a dry cleaning record?',
    'Which item categories appear in Wardrobe?',
  ],
  maintenance: [
    'How do I schedule maintenance?',
    'What is AI risk scoring?',
    'How do I complete a maintenance record?',
  ],
  insurance: [
    'How do I add a policy?',
    'How do I link items to a policy?',
    'How does coverage gap analysis work?',
  ],
  properties: [
    'How do I add a room to a floor?',
    'How do I add a new property?',
    'How do I transfer an item between properties?',
  ],
  users: [
    'How do I invite a new user?',
    'What can a Manager do vs a Staff member?',
    'How do I restrict a user to one property?',
  ],
  ai_scan: [
    'How do I scan an item?',
    'Can AI Scan read invoices?',
    'What happens after I capture a photo?',
  ],
  ai_chat: [
    'What kind of questions can AI Chat answer?',
    'How is AI Chat different from Vaulted Guide?',
    'How do I filter AI Chat results to one property?',
  ],
  reports: [
    'How do I export a PDF report?',
    'Can I filter before exporting?',
    'Why are Auditor exports watermarked?',
  ],
  settings: [
    'How do I set up MFA?',
    'How do I change my notification preferences?',
    'How do I update my profile?',
  ],
};

const DEFAULT_SUGGESTIONS = [
  'How do I add a new item?',
  'How do I invite a staff member?',
  'What is the difference between roles?',
];

const UNRESOLVED_MARKER = '[UNRESOLVED:';

// ─── Service ───────────────────────────────────────────────────────────────────

@Injectable()
export class AiHelpService {
  private readonly rateLimit: number;
  private readonly sessionTtl = 3600;
  private readonly maxHistoryTurns = 15;
  private readonly maxFeedbackEntries = 1000;

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
    await this.detectAndLogUnresolved(tenantId, dto.query, result.text);

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

  async submitFeedback(tenantId: string, userId: string, dto: HelpFeedbackDto): Promise<void> {
    const entry = JSON.stringify({
      tenantId,
      userId,
      sessionId: dto.sessionId,
      messageIndex: dto.messageIndex,
      helpful: dto.helpful,
      comment: dto.comment ?? null,
      ts: Date.now(),
    });
    const key = `ai:help:feedback:${tenantId}`;
    await this.redis.lpush(key, entry);
    await this.redis.ltrim(key, 0, this.maxFeedbackEntries - 1);
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
        const t = turn as { role?: unknown; content?: unknown };
        return (t.role === 'user' || t.role === 'model') && typeof t.content === 'string';
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

  private async detectAndLogUnresolved(
    tenantId: string,
    query: string,
    answer: string,
  ): Promise<void> {
    if (!answer.includes(UNRESOLVED_MARKER)) return;
    const entry = JSON.stringify({ tenantId, query, answer, ts: Date.now() });
    await this.redis.lpush('ai:help:unresolved', entry);
    await this.redis.ltrim('ai:help:unresolved', 0, 499);
  }

  private buildSystemPrompt(currentScreen?: HelpScreen): string {
    const screenContext = currentScreen
      ? SCREEN_CONTEXT[currentScreen]
      : 'No specific screen context provided.';

    return SYSTEM_PROMPT.replace('{SCREEN_CONTEXT}', screenContext).replace(
      '{KNOWLEDGE_BASE}',
      HELP_KNOWLEDGE_BASE,
    );
  }

  private getSuggestions(currentScreen?: HelpScreen): string[] {
    if (!currentScreen) return DEFAULT_SUGGESTIONS;
    return SCREEN_SUGGESTIONS[currentScreen];
  }

  private sessionKey(tenantId: string, userId: string, sessionId: string): string {
    return `ai:help:session:${tenantId}:${userId}:${sessionId}`;
  }
}
