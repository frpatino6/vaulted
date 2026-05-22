import { HttpException, HttpStatus, Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
import Redis from 'ioredis';
import { v4 as uuidv4 } from 'uuid';
import { InjectRedis } from '../../../common/decorators/inject-redis.decorator';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { EmbeddingService } from '../shared/embedding.service';
import { GeminiChatMessage, GeminiClient } from '../shared/gemini.client';
import { HelpFeedbackDto } from './dto/help-feedback.dto';
import { HelpRequestDto, HelpScreen } from './dto/help-request.dto';

interface HelpSessionTurn {
  role: 'user' | 'model';
  content: string;
}

interface HelpKbChunk {
  chunk_id: string;
  title: string;
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

APP DOCUMENTATION (only the most relevant sections are shown):
{KNOWLEDGE_BASE}
`.trim();

// ─── Knowledge base chunks ─────────────────────────────────────────────────────
// Each chunk is a self-contained section that can answer questions independently.
// chunk_id matches the semantic topic; content uses exact UI text from the app.

const HELP_KB_CHUNKS: HelpKbChunk[] = [
  {
    chunk_id: 'dashboard',
    title: 'Dashboard',
    content: `
The Dashboard is the home screen of Vaulted. It shows:
- KPI stat cards: Total Items, Total Estimated Value (Owner and Auditor only — Managers cannot see valuations), Items on Loan, Upcoming Maintenance.
- Quick Actions grid — shortcuts to common tasks (Add Item, Scan Item, View Operations, etc.).
- Property cards — tap a property card to navigate to its detail.
- Active Operations alert — shows in-progress loans or transfers that need attention.
- Maintenance alert card — highlights overdue or soon-due maintenance records.

To navigate to a property: tap its card on the Dashboard.
To add a new property (Owner/Manager only): tap the **+** button in the properties section.

The Dashboard does not have a search bar. Use the Asset Directory for searching items.
    `.trim(),
  },
  {
    chunk_id: 'properties-rooms',
    title: 'Properties, Floors & Rooms',
    content: `
Properties represent physical locations (mansions, apartments, vacation homes). Each property has Floors, and each Floor has Rooms. Items are assigned to Rooms.

### Add a property (Owner/Manager only)
1. Tap the **+** button on the Dashboard properties section.
2. Enter: Property Name, Address, Property Type.
3. Tap **Save**.

### View a property's floors and rooms
1. Tap the property card on the Dashboard.
2. The Property Detail screen shows all floors and their rooms.
3. Tap a floor to expand it and see its rooms.
4. Tap a room to see all items assigned to that room.

### Add a floor to a property (Owner/Manager only)
1. Open the Property Detail screen.
2. Tap **Add Floor**.
3. Enter the floor name (e.g., "Ground Floor", "Second Floor", "Basement").
4. Tap **Save**.

### Add a room to a floor (Owner/Manager only)
1. Open the Property Detail → tap the floor to expand it.
2. Tap **Add Room**.
3. Enter: Room Name and Room Type (bedroom, living room, kitchen, office, garage, storage, etc.).
4. Tap **Save**.

💡 Rooms must exist before you can assign items to them. Create the property → floor → room structure first.

### AI Section Scan
From a Property Detail, tap the **AI Scan** option (camera icon) to scan a whole room section at once using the device camera.
    `.trim(),
  },
  {
    chunk_id: 'asset-directory',
    title: 'Asset Directory — Browse, Search & Filter',
    content: `
The main inventory screen is called **Asset Directory** (exact AppBar title). It shows all inventory items with filters.

Access: bottom navigation bar → Asset Directory icon.
Role access: Owner and Manager see all items; Staff sees only items assigned to them; Auditor and Guest have read-only access.

### Search
Use the **search bar** at the top (hint text: "Search by name, tag, serial…") to find items by name, tag, or serial number.

### Filter chips — Row 1 (Category & Status)
**Category chips**: All · Furniture · Art · Technology · Wardrobe · Vehicles · Wine · Sports
**Status chips**: Active · Loaned · Repair · Storage · Disposed
Tap a chip to filter; tap again to deselect. Tap **Clear** (top-right) to reset all filters.

### Filter chips — Row 2 (Property, Unlocated & Sort)
- **Property chips**: one chip per property — tap to limit results to that property.
- **Unlocated** chip: shows items with no room assigned.
- **Sort chips**: Recent · Value ↓ (Owner and Auditor only) · Name A–Z

### Results header
Shows count (e.g., "12 results") when filters are active, or sort label ("Recently Added", "All Items · A–Z") when browsing.

### Empty states
- "No items match your filters" — with active filters
- "No items yet" — no items in the inventory at all

### QR Codes
Tap the **View QR Codes** icon (top-right, QR code icon) to see all item QR codes at once.
    `.trim(),
  },
  {
    chunk_id: 'add-edit-items',
    title: 'Adding, Editing & Managing Items',
    content: `
### Add an item manually (Owner, Manager, Staff)
1. Open the **Asset Directory** screen.
2. Tap the **+** button (bottom-right corner).
3. Select a **Category** (Furniture, Art & Collectibles, Wardrobe, Vehicles, etc.).
4. Enter the **Item Name** and optionally a **Subcategory**.
5. Select the **Room** where the item is located.
6. Add up to **10 photos** using the camera or photo library.
7. Fill in **Valuation**: Purchase Price, Purchase Date, Current Value, Currency (USD default).
8. Optionally: Serial Number, Tags (comma-separated), Location Detail (e.g., "Left side of closet").
9. Tap **Save**.

### Use AI Scan to catalog an item from a photo (Owner/Manager only)
1. Tap the **AI Scan icon** (camera with sparkle) in the navigation bar.
2. Point the camera at the item and tap **Capture**.
3. Review AI suggestions: Category, Brand, Estimated Value, Attributes, Tags, Suggested Room.
4. Edit any fields — the AI may misidentify rare or uncommon items.
5. Tap **Save to Inventory**.

For **invoice scanning**: after capturing, select **Scan Invoice** to auto-fill Purchase Price, Purchase Date, and Vendor Name.

### Edit an item (Owner, Manager, Staff on assigned items)
1. Tap the item from the Asset Directory list to open its detail.
2. Tap the **pencil (edit) icon** (top-right corner of the item detail screen).
3. Modify the desired fields.
4. Tap **Save**.

Disposed items cannot be edited — their detail shows a "Disposed" banner.

### Item statuses
- **Active**: item is in its assigned room and available.
- **Loaned**: item has been lent to someone — managed via the Operations screen.
- **Repair**: item is at a repair provider — managed via the Operations screen.
- **Storage**: item was moved to a storage location.
- **Disposed**: item is archived and cannot be moved, loaned, or edited.

### Item QR code
Each item has a unique QR code on its detail page. Scanning the QR code from any screen opens that item's detail directly. Useful for audits and check-in/check-out.

### Item movement history
Open an item detail → scroll to the **Movement History** section to see all past operations: who moved it, when, where to.
    `.trim(),
  },
  {
    chunk_id: 'operations',
    title: 'Operations — Loans, Returns, Transfers & Repairs',
    content: `
The Operations screen (exact AppBar title: **"Operations"**) manages loans, transfers, and repairs.

Access: bottom navigation bar → Operations icon.
Tabs: **Active** (in-progress operations) · **History** (completed and cancelled).
Create operations: Owner and Manager only. Staff and Auditor can view but not create.

**Operation types**: Loan · Repair · Transfer (also Cataloged and Disposal appear in history).
**Operation statuses**: DRAFT · ACTIVE · DONE · PARTIAL · CANCELLED

### Loan an item to someone
1. Tap **Operations** in the navigation bar.
2. Tap the **New Operation** button (bottom-right corner, FAB labeled "New Operation").
3. Select **Loan** as the operation type.
4. Search and select the item(s) to loan.
5. Enter: Borrower Name, Borrower Contact (optional), Expected Return Date.
6. Tap **Confirm** — the operation moves to the **Active** tab.

The item's status automatically changes to **Loaned**.

### Mark a loaned item as returned
1. Open **Operations** → tap the **Active** tab → find the loan.
2. Tap the loan card to open its detail.
3. Tap **Mark as Returned** (or **Complete**).
4. Confirm the return.

The item status returns to **Active** automatically.

### Transfer an item to another room or property
1. In **Operations** → tap the **New Operation** button.
2. Select **Transfer** as the operation type.
3. Select the item(s).
4. Select the **Destination**: a different room or a different property.
5. Tap **Confirm**.

### Send an item for repair
1. In **Operations** → tap the **New Operation** button.
2. Select **Repair** as the operation type.
3. Select the item(s).
4. Enter: Repair Provider, Expected Return Date, Notes (optional).
5. Tap **Confirm** — item status changes to **Repair**.

### Operation workflow
All operations follow: **Draft → Active → Completed**.
- Draft banners appear at the top of the Operations screen if a draft was left unfinished.
- Tap **Resume →** on a draft banner to continue the operation.

### Empty states
- Active tab empty: "No active operations" / "Tap + to start a new operation"
- History tab empty: "No history yet" / "Completed operations will appear here"
    `.trim(),
  },
  {
    chunk_id: 'wardrobe',
    title: 'Wardrobe Module',
    content: `
Wardrobe is a specialized module for clothing, footwear, accessories, jewelry, and watches.
**Access: Owner and Manager only** — Staff, Auditor, and Guest cannot access Wardrobe.

### Open Wardrobe
Tap **Wardrobe** in the bottom navigation bar.
The screen (AppBar title: **"Wardrobe"**) shows all wardrobe-category items as a grid.

### Stats bar (interactive chips at top of screen)
- **Total** — total count of wardrobe items.
- **Needs cleaning** — tap to filter items by "Needs Cleaning" status.
- **At cleaner** — tap to open the **At Dry Cleaner** screen (items currently with a cleaner; red dot = overdue items).
- **Outfits** — tap to open the Outfits list screen.

### Type filter chips
**All** · **Clothing** · **Footwear** · **Accessories**
Tap a chip to filter the grid by item type.

### Advanced filters
Tap the **tune icon** (⚙️) to open advanced filters including: Cleaning Status, Season, and Household Member.

### Cleaning status values
Items can have: **Clean** · **Needs Cleaning** · **At Dry Cleaner**
To update: tap the item card's status area → select new status from the picker.

### Create an outfit
1. Tap the **Outfits** chip in the stats bar (or navigate to Wardrobe → Outfits).
2. Tap the **+** button.
3. Enter an outfit name and occasion tags.
4. Tap **Add Items** — select from your wardrobe items.
5. Tap **Save Outfit**.

### Log a dry cleaning record
1. Tap the **At cleaner** chip in the stats bar.
2. Tap the **+** button.
3. Select the item(s) sent to the cleaner.
4. Enter: Date Sent, Provider Name, Cost (optional), Expected Return Date (optional).
5. Tap **Save**.

Items sent to the cleaner automatically get "At Dry Cleaner" status.

### Empty state
"No wardrobe items yet" — add items with the Wardrobe category via Asset Directory or AI Scan.
    `.trim(),
  },
  {
    chunk_id: 'maintenance',
    title: 'Maintenance Calendar',
    content: `
The Maintenance screen (AppBar title: **"Maintenance"**) tracks scheduled maintenance for items.

Access: Owner, Manager, and Staff can view and update maintenance. Auditor and Guest cannot access the Maintenance list.
Create maintenance records: Owner and Manager only (FAB tooltip: "Schedule maintenance").
Complete maintenance records: Owner, Manager, and Staff.

### Maintenance tabs
**Overdue** · **This Week** · **Upcoming** · **Completed**
Each tab shows a count badge when records exist (e.g., "Overdue  3").

### Schedule a maintenance record (Owner/Manager only)
1. Tap **Maintenance** in the navigation.
2. Tap the **+** button (bottom-right corner).
3. Select the **Item** to maintain.
4. Enter: Scheduled Date, Maintenance Type, Notes (optional).
5. Maintenance types: Cleaning · Inspection · Repair · Service · Calibration · Other
6. Tap **Save**.

### Update maintenance status
1. Tap the maintenance record from the list.
2. Tap **Mark as Completed** or **Cancel**.
3. Confirm.

### AI risk scoring
The system automatically analyzes items based on age, category, and condition.
- Items with risk score ≥ 60% may auto-generate maintenance suggestions.
- These appear in the list with an "AI Suggested" tag.
    `.trim(),
  },
  {
    chunk_id: 'insurance',
    title: 'Insurance Policies & Claims',
    content: `
The Insurance screen (AppBar title: **"Insurance"**) manages insurance policies.

Access to view: Owner, Manager, Auditor.
Create or edit policies: Owner and Manager only.
Staff and Guest cannot access Insurance.

### Add an insurance policy (Owner/Manager only)
1. Tap **Insurance** in the navigation.
2. Tap the **+** icon (top-right corner).
3. Enter: Insurer Name, Policy Number, Coverage Type, Premium Amount, Start Date, End Date.
4. Tap **Save**.

### Link items to a policy
1. Open the policy detail (tap the policy card).
2. Tap **Link Items**.
3. Search and select items from your inventory.
4. Tap **Done**.

### Coverage gap analysis (AI)
1. Open a policy detail.
2. Tap **Analyze Coverage Gaps**.
3. The AI identifies items with no policy or with current value exceeding covered value.
4. Review the gaps report — items are listed with their coverage shortfall.

### Draft an insurance claim letter (AI)
1. Open the policy detail → tap **Draft Claim**.
2. Describe the incident or loss.
3. The AI generates a formal claim letter using your policy details and item data.
4. Review, edit if needed, and export or copy.

### Empty state
"No insurance policies yet" — tap **+** to add the first policy.
    `.trim(),
  },
  {
    chunk_id: 'ai-chat',
    title: 'AI Chat — Inventory Assistant',
    content: `
AI Chat (AppBar title: **"AI Assistant"**) answers natural-language questions about your own inventory items.

Access: Owner, Manager, Auditor only. Staff and Guest cannot use AI Chat.
Navigate: tap **AI Chat** in the bottom navigation bar (or the chat icon).

### What AI Chat can do
- Find items: "Where is my Hermès bag?", "Show all items on loan"
- Filter by value: "Items worth over $10,000"
- List by location: "What's in the master bedroom?"
- Show by status: "What items are currently at repair?"

Results include item photos, location (property + room), and valuation (if your role allows seeing values).

### Clear conversation
Tap the **Clear session** icon (trash/sweep icon, top-right) to start a fresh conversation.

### AI Chat vs Vaulted Guide
- **AI Chat** searches your actual inventory items — use it for "where is X" or "list items by Y".
- **Vaulted Guide** (this chat) explains how to use the app — use it for "how do I…" questions.

If you ask Vaulted Guide about a specific item, it will redirect you to AI Chat.
    `.trim(),
  },
  {
    chunk_id: 'users-roles',
    title: 'Users, Roles & Team Management',
    content: `
The Users screen (AppBar title: **"Team"**) manages who has access to Vaulted.

### Invite a new user (Owner only)
1. Go to **Settings** → **Team** (or tap the People icon in settings).
2. Tap the **+** (invite) icon (top-right corner).
3. Enter the user's email address.
4. Select their **Role**: Owner · Manager · Staff · Auditor · Guest
5. Select which **Properties** they can access.
6. For Guest role: set an **Expiry Date**.
7. Tap **Send Invite**.

The invited user receives an email with a registration link.

### Change a user's role or property access (Owner only)
1. Open **Settings** → **Team** → tap the user.
2. Tap **Edit**.
3. Update Role or Property access.
4. Tap **Save**.

### Role comparison

| Role    | Add/Edit Items | See Valuations | Manage Users | Wardrobe | AI Chat |
|---------|---------------|----------------|--------------|----------|---------|
| Owner   | ✅             | ✅              | ✅            | ✅        | ✅       |
| Manager | ✅             | ❌              | ❌            | ✅        | ✅       |
| Staff   | Limited        | ❌              | ❌            | ❌        | ❌       |
| Auditor | ❌ read-only   | ✅              | ❌            | ❌        | ✅       |
| Guest   | ❌ read-only   | ❌              | ❌            | ❌        | ❌       |

### Household Members
Household Members (separate from app users) can be linked to wardrobe items to indicate ownership within the family. Managed under **Settings** → **Household Members** (Owner/Manager only).
    `.trim(),
  },
  {
    chunk_id: 'navigation-access',
    title: 'Navigation Access by Role',
    content: `
Not all screens are accessible to every role. If a user reports not seeing a section, their role is the most likely cause.

| Screen | Owner | Manager | Staff | Auditor | Guest |
|--------|-------|---------|-------|---------|-------|
| Dashboard | ✅ | ✅ | ✅ | ✅ | ✅ |
| Asset Directory | ✅ all items | ✅ all items | ✅ assigned only | ✅ read-only | ✅ read-only |
| Operations | ✅ create | ✅ create | ✅ view only | ✅ view only | ❌ |
| Wardrobe | ✅ | ✅ | ❌ | ❌ | ❌ |
| Maintenance | ✅ create | ✅ create | ✅ complete only | ❌ | ❌ |
| Insurance (view) | ✅ | ✅ | ❌ | ✅ | ❌ |
| Insurance (create/edit) | ✅ | ✅ | ❌ | ❌ | ❌ |
| AI Chat | ✅ | ✅ | ❌ | ✅ | ❌ |
| AI Scan | ✅ | ✅ | ❌ | ❌ | ❌ |
| Vaulted Guide (this chat) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Team (Users) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Household Members | ✅ | ✅ | ❌ | ❌ | ❌ |
| Reports | ✅ | ✅ | ❌ | ✅ watermarked | ❌ |
| Settings | ✅ | ✅ | ✅ limited | ✅ limited | ❌ |

**Common "I can't find it" causes:**
- Wardrobe not visible → Staff, Auditor, or Guest role (Owner/Manager only)
- AI Chat not visible → Staff or Guest role
- Insurance not visible → Staff or Guest role
- Maintenance not visible → Auditor or Guest role
- Can't create operations → Staff, Auditor, or Guest role (creation is Owner/Manager only)
- Can't see valuations → Manager, Staff, or Guest role (Owner and Auditor only)
    `.trim(),
  },
  {
    chunk_id: 'reports-settings',
    title: 'Reports & Settings',
    content: `
### Reports
Access: Owner, Manager, Auditor (Staff and Guest cannot access Reports).

1. Tap **Reports** in the navigation.
2. Select the export format: **PDF** or **Excel**.
3. Apply filters: Category, Room, Property, Status.
4. Tap **Export**.

Auditor exports are automatically watermarked.

### Settings
Navigate: bottom navigation bar → **Settings** (gear icon).

Key settings options:
- **Team**: manage team members and invite users (Owner only).
- **Household Members**: manage household member profiles (Owner/Manager only).
- **Notifications**: toggle push and email notifications per event type.
- **Security / MFA Setup**: tap **Security** → **Enable MFA** → scan the QR code with an authenticator app (Google Authenticator, Authy, etc.).
- **Profile**: update display name and email.
- **Notification Preferences**: go to **Settings** → **Notifications** to set preferences for each event type.
    `.trim(),
  },
  {
    chunk_id: 'qr-scanning',
    title: 'QR Codes & Scanning',
    content: `
Every item in Vaulted has a unique QR code.

### View an item's QR code
Open the item detail page — the QR code is displayed below the item name.

### View all QR codes at once
Tap the **View QR Codes** icon (QR code icon, top-right) in the Asset Directory or Wardrobe screen.

### Scan a QR code
Tap the **scanner icon** in the app bar (any screen that shows it) to open the QR scanner.
Scanning an item QR code navigates directly to that item's detail page.

### QR codes during operations
When performing a loan, transfer, or repair operation, the app enters a **scan mode** where you scan each item's QR code to add it to the operation. This confirms which physical items are included.

### Useful scenarios
- Quick audits: scan items in a room to verify their presence.
- Staff check-in/check-out: scan items being moved.
- Insurance appraisals: share QR code with appraisers to verify item identity.
- Wardrobe: tap **View QR Codes** from Wardrobe to get QR codes of filtered items.
    `.trim(),
  },
];

// ─── Screen context, suggestions, chunk mapping ────────────────────────────────

const SCREEN_CONTEXT: Record<HelpScreen, string> = {
  dashboard: 'The user is on the Dashboard — viewing KPI cards and recent activity.',
  inventory: 'The user is on the Asset Directory screen — browsing or searching inventory items.',
  item_detail: "The user is viewing a single item's detail page.",
  add_item: 'The user is on the Add Item form.',
  movements:
    'The user is on the Operations screen (AppBar title: "Operations") — managing loans, transfers, and repairs. Tabs: Active and History.',
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

// chunk_ids to always include when user is on a specific screen
const SCREEN_CHUNK_BOOST: Partial<Record<HelpScreen, string[]>> = {
  dashboard: ['dashboard'],
  inventory: ['asset-directory', 'add-edit-items'],
  item_detail: ['add-edit-items'],
  add_item: ['add-edit-items'],
  movements: ['operations'],
  wardrobe: ['wardrobe'],
  maintenance: ['maintenance'],
  insurance: ['insurance'],
  properties: ['properties-rooms'],
  users: ['users-roles', 'navigation-access'],
  ai_scan: ['add-edit-items'],
  ai_chat: ['ai-chat'],
  reports: ['reports-settings'],
  settings: ['reports-settings'],
};

const SCREEN_SUGGESTIONS: Record<HelpScreen, string[]> = {
  dashboard: [
    'How do I navigate to a property?',
    'What does the Total Value card show?',
    'How do I see recent activity?',
  ],
  inventory: [
    'How do I add a new item?',
    'How do I filter items by status?',
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
    'How do I clear my AI Chat session?',
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
export class AiHelpService implements OnModuleInit {
  private readonly logger = new Logger(AiHelpService.name);
  private readonly rateLimit: number;
  private readonly sessionTtl = 3600;
  private readonly maxHistoryTurns = 15;
  private readonly maxFeedbackEntries = 1000;

  constructor(
    @InjectRedis() private readonly redis: Redis,
    private readonly dataSource: DataSource,
    private readonly embeddingService: EmbeddingService,
    private readonly geminiClient: GeminiClient,
    private readonly costLogger: AiCostLoggerService,
    private readonly config: ConfigService,
  ) {
    this.rateLimit = config.get<number>('AI_HELP_RATE_LIMIT_PER_MINUTE') ?? 30;
  }

  async onModuleInit(): Promise<void> {
    try {
      await this.ensureHelpEmbeddingsTable();
      await this.indexKbChunks();
      this.logger.log(`Help KB indexed: ${HELP_KB_CHUNKS.length} chunks`);
    } catch (err) {
      this.logger.error('Help KB indexing failed — falling back to full KB injection', err);
    }
  }

  async chat(tenantId: string, userId: string, dto: HelpRequestDto): Promise<AiHelpResponse> {
    await this.enforceRateLimit(tenantId);

    const sessionId = dto.sessionId ?? uuidv4();
    const history = await this.getSessionHistory(tenantId, userId, sessionId);
    const systemPrompt = await this.buildSystemPrompt(dto.query, dto.currentScreen);
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

  private async ensureHelpEmbeddingsTable(): Promise<void> {
    await this.dataSource.query(`
      CREATE TABLE IF NOT EXISTS help_embeddings (
        id         SERIAL PRIMARY KEY,
        chunk_id   VARCHAR(100) NOT NULL UNIQUE,
        title      VARCHAR(200) NOT NULL,
        content    TEXT         NOT NULL,
        embedding  vector(3072) NOT NULL,
        updated_at TIMESTAMPTZ  NOT NULL DEFAULT NOW()
      )
    `);
    await this.dataSource.query(`
      CREATE INDEX IF NOT EXISTS help_embeddings_chunk_idx
        ON help_embeddings (chunk_id)
    `);
  }

  private async indexKbChunks(): Promise<void> {
    for (const chunk of HELP_KB_CHUNKS) {
      const text = `${chunk.title}\n\n${chunk.content}`;
      const embedding = await this.embeddingService.generateEmbedding(text);
      const vector = `[${embedding.join(',')}]`;
      await this.dataSource.query(
        `INSERT INTO help_embeddings (chunk_id, title, content, embedding, updated_at)
         VALUES ($1, $2, $3, $4::vector, NOW())
         ON CONFLICT (chunk_id) DO UPDATE
           SET title      = EXCLUDED.title,
               content    = EXCLUDED.content,
               embedding  = EXCLUDED.embedding,
               updated_at = NOW()`,
        [chunk.chunk_id, chunk.title, chunk.content, vector],
      );
    }
  }

  private async retrieveRelevantChunks(query: string, currentScreen?: HelpScreen): Promise<string> {
    try {
      const queryEmbedding = await this.embeddingService.generateEmbedding(query);
      const vector = `[${queryEmbedding.join(',')}]`;

      const rows = await this.dataSource.query<
        Array<{ chunk_id: string; title: string; content: string }>
      >(
        `SELECT chunk_id, title, content
         FROM help_embeddings
         ORDER BY embedding <=> $1::vector
         LIMIT 4`,
        [vector],
      );

      const retrieved = new Map(rows.map((r) => [r.chunk_id, r]));

      // Always include screen-specific chunks regardless of similarity score
      const boostedIds = currentScreen ? (SCREEN_CHUNK_BOOST[currentScreen] ?? []) : [];
      for (const forcedId of boostedIds) {
        if (!retrieved.has(forcedId)) {
          const forced = await this.dataSource.query<
            Array<{ chunk_id: string; title: string; content: string }>
          >(`SELECT chunk_id, title, content FROM help_embeddings WHERE chunk_id = $1`, [forcedId]);
          if (forced[0]) retrieved.set(forcedId, forced[0]);
        }
      }

      const chunks = [...retrieved.values()];
      return chunks.map((c) => `## ${c.title}\n\n${c.content}`).join('\n\n---\n\n');
    } catch {
      // Table may not exist yet on first boot before onModuleInit completes — use full KB
      return HELP_KB_CHUNKS.map((c) => `## ${c.title}\n\n${c.content}`).join('\n\n---\n\n');
    }
  }

  private async buildSystemPrompt(query: string, currentScreen?: HelpScreen): Promise<string> {
    const screenContext = currentScreen
      ? SCREEN_CONTEXT[currentScreen]
      : 'No specific screen context provided.';
    const relevantKB = await this.retrieveRelevantChunks(query, currentScreen);
    return SYSTEM_PROMPT.replace('{SCREEN_CONTEXT}', screenContext).replace(
      '{KNOWLEDGE_BASE}',
      relevantKB,
    );
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
    const key = `ai:help:unresolved:${tenantId}`;
    await this.redis.lpush(key, entry);
    await this.redis.ltrim(key, 0, 499);
  }

  private getSuggestions(currentScreen?: HelpScreen): string[] {
    if (!currentScreen) return DEFAULT_SUGGESTIONS;
    return SCREEN_SUGGESTIONS[currentScreen];
  }

  private sessionKey(tenantId: string, userId: string, sessionId: string): string {
    return `ai:help:session:${tenantId}:${userId}:${sessionId}`;
  }
}
