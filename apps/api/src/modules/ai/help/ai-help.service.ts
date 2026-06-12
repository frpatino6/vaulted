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
The Dashboard is the home screen of Vaulted. It has a dynamic header showing "Welcome back, {name}" and a privacy toggle (eye icon) to show/hide monetary values.

### KPI stat cards
- **Total Items** — always visible.
- **Total Estimated Value** — Owner and Auditor only (Managers cannot see valuations). Hidden when privacy mode is on (shows ●●●●●).
- Items on Loan, Upcoming Maintenance appear as status chips below the KPIs with counts (e.g. "3 Active", "1 Loaned", "2 Repair", "5 Storage").

### Quick Actions grid (2-column layout, section header: "QUICK ACTIONS")
1. **Scan QR** — opens the QR scanner.
2. **AI Assistant** — opens AI Chat to query inventory.
3. **Vaulted Guide** — opens this help chat.
4. **Operations** — opens the Operations screen.
5. **Maintenance** — opens the Maintenance screen.
6. **Orchestrator** — opens the Orchestrator plans screen.

### Property cards
Tap a property card to navigate to its detail (floors and rooms).
To add a new property (Owner/Manager only): tap the **+** button in the properties section.
Empty state (can manage): "Add your first property" / "Create a property to organize floors, rooms and items."
Empty state (cannot manage): "No properties assigned to your account"
Error state: "Could not load properties" with a "Retry" button.

### Active Operations alert
Shows in-progress loans or transfers that need attention.

### Footer
"Vaulted — Private"

The Dashboard does not have a search bar. Use the Asset Directory for searching items.
    `.trim(),
  },
  {
    chunk_id: 'properties-rooms',
    title: 'Properties, Floors & Rooms',
    content: `
Properties represent physical locations (mansions, apartments, vacation homes). Each property has Floors, and each Floor has Rooms. Items are assigned to Rooms.

**Property types**: Primary · Vacation · Rental

### Add a property (Owner/Manager only)
1. Tap the **+** button on the Dashboard properties section.
2. Enter: Property name, Type (Primary / Vacation / Rental), Street, City, State, ZIP.
3. Optionally add a cover photo (choose Camera or Gallery).
4. Tap **Create property**.
5. Snackbar: "Property created"

### View a property's floors and rooms
1. Tap the property card on the Dashboard.
2. The Property Detail screen (section header: "FLOORS & ROOMS") shows all floors and their rooms.
3. Tap a floor to expand it.
4. The FAB opens a speed dial with: **Add floor**, **Add item**, **Add item with AI**.

### Add a floor (Owner/Manager only)
1. Open the Property Detail → tap **Add floor**.
2. Enter floor name (e.g., "Ground floor").
3. Tap **Add floor**.
4. Snackbar: "Floor added"

### Add a room to a floor (Owner/Manager only)
1. Open Property Detail → tap a floor to expand → tap **Add room**.
2. Enter: Room name (e.g. "Living room") and Type (e.g. "Living, Bedroom, Bathroom").
3. Tap **Add room**.
4. Snackbar: "Room added"

### Edit/delete floor or room
- Long-press a floor tile → Edit/Delete options.
- Delete room dialog: 'Delete "{room.name}"? Items in this room will become unlocated.'
- Delete floor dialog: 'Delete "{floor.name}"? All rooms and their items will become unlocated.'
- Snackbar: "Floor deleted" / "Room deleted"

### Sections within a room
Each room can have sections (drawers, cabinets, shelves, racks, safes, compartments).
Navigate to a room → tap **Sections** option to open the Room Sections screen.
**Room Sections screen** (AppBar: "{Room Name} – Sections").
Section types: Drawer · Cabinet · Shelf · Rack · Safe · Compartment · Other
Add section fields: Code (e.g. "1A"), Name (e.g. "Top Left Drawer"), Type dropdown, Notes (optional, e.g. "has glass door"), Photo (optional).
Empty state: "No sections yet" / "Define the storage sections of this room before adding inventory items."
Buttons: **Scan with AI** (FilledButton) or **Add manually** (OutlinedButton).

💡 Rooms must exist before you can assign items to them. Create the property → floor → room structure first.

### AI Section Scan
From a Room Sections screen, tap the **AI Section Scan** icon (tooltip: "AI Section Scan") to scan furniture with the device camera.
AppBar title: "AI Section Scan"
Captures a photo, AI detects drawers/cabinets/shelves and pins codes on the photo.
Users can: **Take photo**, **Choose from gallery**, review detected sections, drag boxes to reposition, **Scan another piece**, **Rescan**, then **Save {count} sections**.
Save summary asks for Cabinet label per group (e.g. "Upper Cabinet, Island, Pantry…").
Buttons: **Review** → **Confirm & Save**.
    `.trim(),
  },
  {
    chunk_id: 'asset-directory',
    title: 'Asset Directory — Browse, Search & Filter',
    content: `
The main inventory screen is **Asset Directory** (exact AppBar title). It shows all inventory items with filters.

Access: bottom navigation bar → **Home** tab → tap **Asset Directory** from the nav. Alternatively use the bottom nav's center tab for quick access.
Role access: Owner and Manager see all items; Staff sees only items assigned to them; Auditor and Guest have read-only access.

### Search
Use the search bar at the top (hint text: "Search by name, tag, serial…") to find items by name, tag, or serial number.
The search bar has a **Clear search** icon button tooltip.

### Filter chips — Row 1 (Category & Status)
**Category chips**: All · Furniture · Art · Technology · Wardrobe · Vehicles · Wine · Sports
**Status chips**: Active · Loaned · Repair · Storage · Disposed
Tap a chip to filter; tap again to deselect. Tap **Clear** (top-right TextButton) to reset all filters.

### Filter chips — Row 2 (Property, Unlocated & Sort)
- **Property chips**: one chip per property with home icon — tap to limit results.
- **Unlocated** chip (with location_off icon): shows items with no room assigned.
- **Sort chips**: **Recent** (schedule icon) · **Value ↓** (money icon, Owner and Auditor only) · **Name A–Z** (sort icon)

### Results header
- With active filters: "{count} results"
- Sort "recent": "Recently Added"
- Sort "valueDesc": "All Items · Value ↓"
- Sort "nameAsc": "All Items · A–Z"

### Empty states
- "No items match your filters" + "Try adjusting or clearing the active filters."
- "No items yet" — no items in inventory at all
- Error: "Try again" (TextButton retry)

### Item detail screen (tap an item)
AppBar shows the item name. Sections: VALUATION DETAILS · ADDED · DOCUMENTS · TAGS · QR CODE · WARDROBE DETAILS · MAINTENANCE · HISTORY
Edit button (pencil icon, top-right). Bottom buttons: **Transfer** (OutlinedButton), **Edit Item** (OutlinedButton).
QR code caption: "Scan to identify this item"

### Item spec fields
PROPERTY · ROOM (or "Unassigned") · CATEGORY · STATUS · SUBCATEGORY · SERIAL NUMBER (or "—") · SECTION · LOCATION

### Global Search screen
Accessible from the search icon. AppBar: **"Search results"** (when query active) or **"Global Search"** (empty).
Search hint: "Search items..."
Category chips: All · Furniture · Art · Technology · Wardrobe · Vehicles · Wine · Sports
Status chips: Active · Loaned · Repair · Storage
Empty (no query): "Search your inventory"
No results: "No items found for '{query}'"

### QR Codes
Tap the **View QR Codes** icon (top-right, tooltip: "View QR Codes") to see all item QR codes at once.
QR Codes screen (AppBar: "QR Codes", subtitle: "{count} items"). Has a **Print** action button (web: opens print dialog; non-web: "Open the web app in a browser to print QR codes.").
Empty: "No QR codes match the current filters" / "No QR codes yet"
    `.trim(),
  },
  {
    chunk_id: 'add-edit-items',
    title: 'Adding, Editing & Managing Items',
    content: `
### Add an item manually (Owner, Manager, Staff)
1. Open the **Asset Directory** screen.
2. Tap the **+** button (bottom-right corner).
3. Sheet title: **"Add item"**.
4. Select a **Category** (required): Furniture · Art · Technology · Wardrobe · Vehicles · Wine · Sports · Other
5. Enter **Name** (required, hint: "e.g. Chesterfield Sofa"), **Subcategory** (optional, hint: "e.g. living room").
6. Select the **Room** — tap "Select room" button if none assigned.
7. Section header **"LOCATION"** shows "No location assigned" if unassigned.
8. Optionally select a **Section** (from room sections) with grid_view icon.
9. Set **Quantity** with minus/plus buttons.
10. Add up to **10 photos** using Camera or Gallery.
11. Fill in **Purchase price** (optional, $ prefix), **Current value** (optional, $ prefix).
12. Enter **Serial number** (optional, hint: "e.g. SN123"), **Tags** (optional, hint: "comma separated"), **Within room** (optional, hint: "e.g. Left shelf, Cabinet 3").
13. For Wardrobe category: section header **"WARDROBE DETAILS"** with fields: Belongs to (dropdown, default "Unassigned"), Type, Brand, Size (hint: "S / M / L / 42 / 38..."), Color, Material, Season, Cleaning Status.
14. Tap **"Add item"** (FilledButton).
15. Saving overlay: "Saving item…"

Validation: "Please enter a name"

### Edit an item (Owner, Manager, Staff on assigned items)
1. Open item detail → tap the pencil (edit) icon (top-right).
2. Sheet title: **"Edit item"**. Same fields as Add.
3. Location section shows current room or "No location assigned".
4. Section picker: **"Select section (optional)"** with arrow down.
5. Tap **"Save changes"** (FilledButton).
6. Snackbar: "Item updated"

Disposed items cannot be edited — their detail shows a banner: "This item has been disposed and is no longer active."

### Item statuses
- **Active**: in its assigned room and available.
- **Loaned**: lent to someone — managed via Operations.
- **Repair**: at a repair provider — managed via Operations.
- **Storage**: moved to a storage location.
- **Disposed**: archived — cannot be moved, loaned, or edited.

### Item detail screen sections
- **VALUATION DETAILS**: Purchase price, Current value, Purchase date. Estimated Value label under price.
- **DOCUMENTS**: shows attached documents, tap to view. Snackbar: "Opening documents coming soon".
- **TAGS**: comma-separated tags.
- **QR CODE**: unique QR code. Caption: "Scan to identify this item".
- **WARDROBE DETAILS**: Belongs to, Type (Clothing/Footwear/Accessories/Jewelry & Watches), Brand, Size, Color, Material, Season (Spring/Summer, Fall/Winter, All Season), Cleaning (Clean ✓, Needs Cleaning, At Dry Cleaner).
- **MAINTENANCE**: AI Analysis button, Schedule button. Empty: "No maintenance scheduled." AI Analysis dialog with risk badges: "High risk · X/100", "Medium risk · X/100", "Low risk · X/100".
- **HISTORY**: past movement entries. Empty: "No movement recorded yet." Expand: "View all {n} entries →".

### Dry cleaning buttons (wardrobe items detail)
- **"Send to Dry Cleaner"** — confirmation dialog: 'Send "{item.name}" to the dry cleaner?'
- **"Mark as Returned"** — confirmation dialog: 'Mark "{item.name}" as returned from the dry cleaner?'
- **"Dry Cleaning History"** button.

### Repair context card on detail
Shows "Currently at {destination}", due date, "View Operation →" link.
If item has no active operation: recovery banner "No active operation found for this item." with "Mark as Returned" button.

### Movement history
Scroll to HISTORY section to see all past operations: who moved it, when, where to.
    `.trim(),
  },
  {
    chunk_id: 'operations',
    title: 'Operations — Loans, Returns, Transfers & Repairs',
    content: `
The Operations screen (exact AppBar title: **"Operations"**) manages loans, transfers, repairs, and disposals.

Access: bottom navigation bar → Operations icon (or Quick Action "Operations" from Dashboard).
Tabs: **Active** (in-progress operations) · **History** (completed and cancelled).
Create operations: Owner and Manager only. Staff and Auditor can view but not create.
Search hint: "Search by name or destination…"
Filter chips: **All** · **Repair** · **Loan** · **Transfer** · **Disposal**

**Operation types**: Transfer · Loan · Repair · Disposal (Cataloged also appears in history).
**Operation statuses**: DRAFT · ACTIVE · DONE · PARTIAL · CANCELLED
**Item-level statuses**: RETURNED · TRANSFERRED · MISSING · OUT

### New Operation flow
1. Tap the FAB labeled **"New Operation"** (bottom-right).
2. Sheet title: **"New Operation"**. Subtitle: "Items are saved to the server as you scan them."
3. Select type from cards:
   - **Transfer** — "Move to location"
   - **Loan** — "Lend to someone"
   - **Repair** — "Send for service"
   - **Disposal** — "Remove permanently"
4. Fill in fields per type:
   - **Title** hint: "e.g. Weekend loan to John" (Loan) / "e.g. Repair at ABC Service" (Repair) / "e.g. Donate to charity" (Disposal) / "e.g. Vacation to Aspen house" (Transfer)
   - **Destination/Recipient** hint: "e.g. John Doe" (Loan) / "e.g. ABC Repair Shop" (Repair) / "e.g. Sold on eBay" (Disposal) / "e.g. Storage Unit B" (Transfer)
   - **Property/Floow/Room** dropdowns for Transfer/Disposal
   - **Expected Return** date: default "Optional — tap to set"
   - **Notes**: hint "Optional internal notes…"
5. Tap **"Start Scanning Items"** (or "Creating…" while saving).

### Scanning items for an operation
1. Point camera at item QR codes.
2. Instruction: "Point camera at an item QR code".
3. Counter badge: "{count} item(s) scanned".
4. Feedback: "{itemName} added" / "Already scanned" (duplicate) / "Item scanned — refresh to see status".
5. Bottom panel: shows scanned items. Buttons: **Dispose** / **Transfer** / **Activate** (depending on type).
6. Tap button to confirm operation.
7. Activation dialog:
   - Disposal: 'Confirm Disposal' / "{count} item(s) will be marked as disposed. This cannot be undone." / **Dispose** button.
   - Transfer: 'Confirm Operation' / "{count} item(s) will be moved to {destination}." / **Transfer** button.
   - Other: 'Confirm Operation' / 'Activate "{title}" with {count} item(s)?' / **Activate** button.

### Mark items as returned (check-in)
1. From Movement Detail → tap **Scan Check-in**.
2. Scan item QR codes. Feedback: "{itemName} checked in" / "Item scanned — refresh to see status".
3. Bottom panel shows progress "{returned}/{total}".
4. All done: "All items checked in!" / "Operation is complete."
5. Buttons: **Save & Close**, **Complete**, **Complete ({pending} missing)".

### Operation detail screen
Shows header card with due date, start date, completed date.
Section: "ITEMS ({count})". PopupMenu: **Resume scanning**, **Mark as complete**, **Cancel operation**.
Progress card: "Check-in Progress" / "{returned} / {total} returned" / "{movement.missingCount} item(s) missing".

### Complete/cancel dialogs
- "Complete operation?": "{pending} item(s) haven't been checked in. They will be marked as MISSING." / **Cancel** · **Complete**
- "Cancel operation?": "Active items will be restored to their previous status." / **Keep** · **Cancel operation**
- Cancel flow during scan: "The draft will be saved. You can resume it later from the Operations screen." / **Keep scanning** · **Save & exit**

### Quick transfer from item detail
From item detail screen, tap the **Transfer** bottom button.
Sheet: **"Transfer Item"** / subtitle: "Move to another location immediately".
Auto-filled title: "Transfer: {itemName}".
Dropdowns: Select property → Select floor → Select room.
Button: **Transfer Now** (or "Transferring…").

### Operation workflow
**Draft → Active → Completed**.
Draft banners appear at top: "Draft in progress" with **Resume →** action.

### Empty states
- Active tab: "No active operations" / "Tap + to start a new operation"
- History tab: "No history yet" / "Completed operations will appear here"
    `.trim(),
  },
  {
    chunk_id: 'wardrobe',
    title: 'Wardrobe Module',
    content: `
Wardrobe is a specialized module for clothing, footwear, accessories, jewelry, and watches.
**Access: Owner and Manager only** — Staff, Auditor, and Guest cannot access Wardrobe.

### Open Wardrobe
Tap **Wardrobe** in the bottom navigation bar (or **Home** → Quick Actions or bottom nav).
The screen (AppBar title: **"Wardrobe"**) shows all wardrobe-category items as a grid.
Action button tooltip: "View QR Codes"
Error: "Unable to load wardrobe items"

### Stats bar (interactive chips at top)
- **Total** — total count of wardrobe items.
- **Needs cleaning** — tap to filter by "Needs Cleaning" status.
- **At cleaner** — tap to open the **At the Laundry** screen.
- **Outfits** — tap to open the Outfits list.

### Type filter chips
**All** · **Clothing** · **Footwear** · **Accessories**
Tap a chip to filter the grid by item type.

### Advanced filters
Tap the tune icon to open the **Filters** sheet.
Sections: **MEMBER** (Everyone / member names), **SEASON** (All Seasons / Spring / Summer / Fall / Winter / All Season), **CONDITION** (All / Clean / Needs Cleaning / At Dry Cleaner).
Buttons: **Clear All** · **Show Results**

### Cleaning status values
Values: **Clean ✓** (green dot) · **Needs Cleaning** (amber dot) · **At Dry Cleaner** (blue dot)
To update: tap the item card's status area → select from bottom sheet.

### At the Laundry screen (AppBar: "At the Laundry")
Shows items currently at dry cleaner, grouped by property.
Overdue banner: "{n} item(s) have been at the laundry for over {threshold} days"
Summary: "{total} items · {n} properties"
Each tile shows cleaner name (or "Unknown cleaner") and days count. "⚠" badge for overdue.
Button per tile: **"Mark returned"**.
Dialog: "Mark as returned?" / "{itemName} will be removed from the laundry list…" / **Cancel** · **Mark as returned**
Empty state: "Nothing at the laundry"
Error: "Unable to load laundry items"

### Outfits (AppBar title: "Outfits")
List of outfits with member filter chips (All members / member names).
FAB: **"Create Outfit"**.
Empty: "No outfits yet".
Error: "Unable to load outfits"

### Create Outfit screen (AppBar: "Create Outfit")
Fields: Outfit name (required), Description, Season dropdown (Spring / Summer / Fall / Winter / All Season), Occasion, Household member (default "No specific member").
Section: **"Select items"** — pick from wardrobe list.
Button: **"Create outfit"**.
Validation: "Name is required"

### Outfit detail (AppBar: outfit name)
Section header: **"Items"**. Each item shows name (fallback "Wardrobe Item") and **"View item"** button.
Error: "Unable to load outfit"

### Dry Cleaning History sheet
Sheet title: **"Dry Cleaning History"**
Each entry: "Sent {date}" with subtitle "At dry cleaner" or "Returned {date}".
Button per entry: **"Mark as returned"**.
Empty: "No dry cleaning history yet"
Error: "Unable to load history"

### Empty state (main wardrobe)
"No wardrobe items yet" — add wardrobe-category items via Asset Directory or AI Scan.
    `.trim(),
  },
  {
    chunk_id: 'maintenance',
    title: 'Maintenance Calendar',
    content: `
The Maintenance screen (AppBar title: **"Maintenance"**) tracks scheduled maintenance for items.

Access: Owner, Manager, and Staff can view and update. Auditor and Guest cannot access.
Create: Owner and Manager only (FAB tooltip: "Schedule maintenance").
Complete: Owner, Manager, and Staff.

### Maintenance tabs
**Overdue {count}** · **This Week {count}** · **Upcoming {count}** · **Completed**
Each tab shows a count badge when records exist.

### Empty states per tab
- Overdue: "All caught up" / "No overdue maintenance at this time."
- This Week: "Nothing due this week" / "Upcoming tasks will appear here automatically."
- Upcoming: "Schedule looks clear" / "Add tasks from item details to plan ahead."
- Completed: "No history yet" / "Completed maintenance will appear here."

### Schedule maintenance (Owner/Manager only)
1. Tap **Maintenance** → tap FAB (+).
2. Sheet title: **"Schedule Maintenance"**.
3. Fields:
   - **Item** — search field with hint "Type to search your inventory…". Must select an item.
   - **Title** — hint "e.g., HVAC Service, Oil Change"
   - **Description** — hint "What needs to be done?"
   - **Scheduled Date** — date picker.
   - **Repeat periodically** — switch toggle. Subtitle: "Creates the next maintenance automatically when marked complete".
   - **Repeat every (days)** — hint "e.g., 90 for every 3 months"
   - **Provider (optional)** — hint "Company or person name"
   - **Contact (optional)** — hint "Phone or email"
   - **Estimated cost (USD)** — hint "e.g., 250"
   - **Notes (optional)** — hint "Additional details or instructions"
4. Button: **"Schedule Maintenance"**.
5. Validation: "Please select an item first", "Enter a valid number of days"

### Update maintenance status
From the list: tap the check icon tooltip ("Mark as done" or "Completed").
Snackbar: "Marked as completed"
Slidable actions: **Reschedule**, **Snooze** (snackbar: "Snooze coming soon")

### Maintenance detail screen (AppBar: "Maintenance Detail")
Sections: **SCHEDULE** · **DESCRIPTION** · **NOTES**
Meta rows: Scheduled date, Recurring (Yes/No), Interval, Completed date, Provider, Contact, Cost.
For AI-suggested items: "AI suggested · Risk {score}%" badge.

### Status labels (displayed on cards)
**OVERDUE** (red) · **URGENT** (orange) · **DUE SOON** (gold) · **DONE** (green) · **CANCELLED** (grey) · **PENDING** (purple)
Urgency text: "due today" / "{n} days overdue" / "tomorrow" / "in {n} days"

### AI risk scoring
Automatically analyzes items based on age, category, and condition.
Risk score badge on items ≥ 60% may auto-generate suggestions.
AI badge shows "{score}%" on the card.
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
1. Tap **Insurance** in the bottom navigation (or Dashboard Quick Actions).
2. Tap the **+** icon (top-right corner).
3. Sheet (create mode): AppBar "New Policy". Edit mode: "Edit Policy".
4. Fields:
   - **Provider** (hint: "e.g. Chubb, AIG"), **Policy Number** (hint: "e.g. CHB-2024-001")
   - **Coverage Type** dropdown: All Risk · Named Peril · Liability · Scheduled
   - **Total Coverage** (hint: "1000000"), **Currency** dropdown: USD · EUR · GBP
   - **Annual Premium** (optional, hint: "5000")
   - **Start Date**, **Expiry Date** — date pickers (placeholder: "Select date")
   - **Status** dropdown: Active · Expired · Cancelled
   - **Notes** (optional, hint: "Any additional information…").
5. Validation: "Required", "Must be > 0", "Must be ≥ 0", "Select a start date.", "Select an expiry date."
6. Button: **"Create Policy"** / **"Save Changes"**.

### Policy list
Each card shows: provider name, policy number, coverage type label, status badge (Active/Expired capitalized), expiry date ("Expires {date}"), insured items count ("{n} items").
Empty: "No insurance policies" / "Tap + to add your first policy."

### Policy detail screen
AppBar shows provider name. Action button tooltip: "AI Analysis".
Section: "Total Coverage" / "Premium: $X / year".
Detail rows: Policy Number · Coverage Type · Currency · Start Date · Expires · Notes
**"Insured Items"** section with **"Gap Analysis"** button.
Empty: "No items attached to this policy."

### Link items to a policy
1. Open policy detail → tap **Attach Item**.
2. Sheet: **"Attach Item"** — subtitle "Search your inventory and select an item to insure."
3. Search field hint: "Search by name, category, brand…"
4. Select item → phase 2: **"Set Covered Value"** with Covered Value field and Currency dropdown.
5. Button: **"Attach Item"**.
6. Detach dialog: "Remove Item" / "Remove this item from the policy?" / **Cancel** · **Remove**

### Coverage Gap Analysis (AppBar: "Coverage Gap Analysis")
Summary card: Uninsured Gap, Underinsured Gap, Total Coverage Gap.
If all covered: "All items are fully covered."
Sections: **Uninsured Items** (chip: "Uninsured"), **Underinsured Items**.
Value columns: Item Value · Covered · Gap

### AI Coverage Analysis sheet
Sheet: **"AI Coverage Analysis"**
Renewal urgency: "Policy renewal is {urgency}"
Sections: **Recommendations**, **Priority Items** (with risk badges: Low/High/Critical).
Item tooltip: "Add to policy". Dialog: "Add to Policy" with Covered Value field.
**"Draft a Claim"** link.

### Draft a claim letter (AI)
1. Policy detail → tap "Draft a Claim".
2. Screen: **"Claim Draft"**.
3. Phase 1: "Describe what happened" / "Provide details about the incident so AI can draft a formal claim letter."
   - Field: "Incident description" (max 2000 chars, hint: "e.g. Water damage caused by a burst pipe…")
   - Optional: Item ID (24-char MongoDB ID).
4. Button: **"Generate Draft"**.
5. Phase 2 result: Subject, Letter, Key Points, Next Steps.
6. Buttons: **"Copy Letter"** (snackbar: "Letter copied to clipboard."), **"Start Over"**.

### Delete policy
Dialog: "Delete Policy" / 'Delete "{provider} – {number}"? This cannot be undone.' / **Cancel** · **Delete**
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
The Team screen (AppBar title: **"Team"**) manages who has access to Vaulted.

### View team
Navigate: **Settings** → **Team** (or tap the People icon in settings).
Each member shows: avatar initial (or "?" fallback), display name (fallback "Member"), email, role badge (OWNER/MANAGER/STAFF/AUDITOR/GUEST uppercase), status, last seen ("Never" or date).

The Team header shows a **Presence badge**: "{N} online" with a pulsing green dot — tap it to see all team members. Each user also has a small green dot indicator next to their name when online (grey when offline).
Empty: "No team members yet. Invite someone." / "Only authorized members can access vault data."

### Invite a new user (Owner only)
1. Open **Team** → tap the **+** (invite) icon (top-right).
2. Sheet title: **"Invite team member"**.
3. Fields:
   - **Email** (hint: "colleague@example.com", validation: "Email is required" / "Enter a valid email")
   - **Role** dropdown: Owner · Manager · Staff · Auditor · Guest
   - **Property Access** — ExpansionTile with checkboxes per property.
   - **Access expires (optional)** — date picker for Guest role.
4. Button: **"Send Invite"**.
5. Snackbar: "Invitation sent to {email}"

### User detail sheet
Tap a user → sheet shows role, status, last seen, property access.
Section header: **"Role"**. Editable roles: Manager · Staff · Auditor · Guest.
Buttons: **"Edit Role"**, **"Deactivate user"**, **"Revoke Access"**.
Deactivate dialog: "Deactivate user" / 'Deactivate {email}? They will no longer be able to sign in.' / **Cancel** · **Deactivate**
Snackbar: "User deactivated"

### Change role or property access (Owner only)
Tap user → tap **Edit Role** → update Role and Property Access → save.

### Role comparison

| Role    | Add/Edit Items | See Valuations | Manage Users | Wardrobe | AI Chat | Operations | Maintenance |
|---------|---------------|----------------|--------------|----------|---------|------------|-------------|
| Owner   | ✅             | ✅              | ✅            | ✅        | ✅       | ✅ create   | ✅ create   |
| Manager | ✅             | ❌              | ❌            | ✅        | ✅       | ✅ create   | ✅ create   |
| Staff   | assigned only  | ❌              | ❌            | ❌        | ❌       | view only   | ✅ complete |
| Auditor | ❌ read-only   | ✅              | ❌            | ❌        | ✅       | view only   | ❌          |
| Guest   | ❌ read-only   | ❌              | ❌            | ❌        | ❌       | ❌          | ❌          |
    `.trim(),
  },
  {
    chunk_id: 'navigation-access',
    title: 'Navigation Access by Role',
    content: `
Not all screens are accessible to every role. If a user reports not seeing a section, their role is the most likely cause.

**Bottom navigation tabs**: Home · Insurance · Wardrobe

| Screen | Owner | Manager | Staff | Auditor | Guest |
|--------|-------|---------|-------|---------|-------|
| Dashboard | ✅ | ✅ | ✅ | ✅ | ✅ |
| Asset Directory | ✅ all items | ✅ all items | ✅ assigned only | ✅ read-only | ✅ read-only |
| Operations | ✅ create | ✅ create | ✅ view only | ✅ view only | ❌ |
| Wardrobe | ✅ | ✅ | ❌ | ❌ | ❌ |
| Maintenance | ✅ create | ✅ create | ✅ complete | ❌ | ❌ |
| Insurance (view) | ✅ | ✅ | ❌ | ✅ | ❌ |
| Insurance (create/edit) | ✅ | ✅ | ❌ | ❌ | ❌ |
| AI Chat | ✅ | ✅ | ❌ | ✅ | ❌ |
| AI Scan | ✅ | ✅ | ❌ | ❌ | ❌ |
| AI Section Scan | ✅ | ✅ | ❌ | ❌ | ❌ |
| Vaulted Guide (this chat) | ✅ | ✅ | ✅ | ✅ | ✅ |
| Team (Users) | ✅ | ❌ | ❌ | ❌ | ❌ |
| Household Members | ✅ | ✅ | ❌ | ❌ | ❌ |
| Reports | ✅ | ✅ | ❌ | ✅ watermarked | ❌ |
| Orchestrator | ✅ | ✅ | ✅ assigned | ❌ | ❌ |
| Settings | ✅ | ✅ | ✅ limited | ✅ limited | ❌ |

**Common "I can't find it" causes:**
- Wardrobe not visible → Staff, Auditor, or Guest role (Owner/Manager only)
- AI Chat not visible → Staff or Guest role
- Insurance not visible → Staff or Guest role
- Maintenance not visible → Auditor or Guest role
- Can't create operations → Staff, Auditor, or Guest role (creation is Owner/Manager only)
- Can't see valuations → Manager, Staff, or Guest role (Owner and Auditor only)
- Orchestrator not visible → Guest role
- AI Scan / AI Section Scan not visible → Staff, Auditor, or Guest
    `.trim(),
  },
  {
    chunk_id: 'reports-settings',
    title: 'Reports & Settings',
    content: `
### Reports (AppBar: "Inventory Reports")
Access: Owner, Manager, Auditor (Staff and Guest cannot access).

Action button: **"Export PDF"** (snackbar: "PDF export coming soon" — not yet implemented).

Dashboard-style sections:
- **TOTAL ASSET VALUE**: shows total value, "{total} items across {n} properties"
- **BY CATEGORY**: breakdown per category. Empty: "No category data"
- **BY STATUS**: breakdown per status. Empty: "No status data"
- **ASSET VALUE**: value trends.

Error: "Unable to load reports"

### Settings (AppBar: "Settings")
Navigate: bottom navigation bar → Settings (gear icon). Only visible roles can access.

Sections:
- **Team** — navigates to Team management (Owner only).
- **Household Members** — manage household member profiles (Owner/Manager only).
- **Appearance** — theme toggle: **Light** · **Dark** · **System**
- **Account**:
  - **Notifications** — opens Notification Preferences.
  - **Support** — snackbar: "Coming soon".
  - **Sign out** — dialog: "Are you sure you want to sign out?" / **Cancel** · **Sign out**
- Footer: "Vaulted · v1.0.0"

### Notification Preferences (AppBar: "Notification Preferences")
Sections: **Channels** · **Alert types**.
Toggles:
- **Push Notifications** — "Receive alerts on this device"
- **Email Notifications** — "Receive alerts by email"
- **Dry Cleaning Overdue** — "Items past their expected return date"
- **Maintenance Due** — "Scheduled maintenance reminders"
- **Item Added** — "When a new item is cataloged"
Error: "Could not load preferences." / "Failed to save preference. Try again."

### Notification Center (AppBar: "Notifications")
Lists all notifications with timestamps ("Xm ago", "Xh ago", "Yesterday", "dd/MM").
Action: **"Mark all read"**. PopupMenu: **"Clear read notifications"**.
Dialog: "Clear read notifications" / "All read notifications will be permanently deleted. This cannot be undone." / **Cancel** · **Clear**
Empty: "No notifications yet" / "You're all caught up. Alerts for maintenance, item updates, and wardrobe reminders will appear here."
    `.trim(),
  },
  {
    chunk_id: 'qr-scanning',
    title: 'QR Codes & Scanning',
    content: `
Every item in Vaulted has a unique QR code.

### View an item's QR code
Open the item detail page — the QR code is displayed below the item name with caption "Scan to identify this item".

### View all QR codes at once
Tap the **View QR Codes** icon (top-right, tooltip: "View QR Codes") in the Asset Directory or Wardrobe screen.
QR Codes screen (AppBar: "QR Codes", subtitle: "{count} items"). Has a **Print** action.
Print dialog: full-screen QR view with item name, location "{property} › {room}", caption "Scan to identify this item".
Non-web snackbar: "Open the web app in a browser to print QR codes."

### Section QR codes
From Room Sections screen → tap Section QR icon.
Sheet: **"Section QR Codes"** with room name subtitle.
Each section: code badge, name, room line "{room} · {count} items".
Instruction: "Print and place this QR in the physical section. Staff can scan it to see all items here."
Buttons: **"Copy QR link"**, **"View items in this section"**.
Section photo: "Location map" header if photo exists.

### Scan a QR code (AppBar: "Scan Item")
Tap the scanner icon in the app bar. Overlay text: "Point camera at an item or section QR code".
Scanning navigates directly to the item detail or section view.

### QR codes during operations
Scan mode: scan each item's QR code to add it to the operation.
Feedback: "{itemName} added" or "Already scanned".

### Useful scenarios
- Quick audits: scan items in a room to verify presence.
- Staff check-in/check-out: scan items being moved.
- Insurance appraisals: share QR code with appraisers.
- Wardrobe: tap **View QR Codes** from Wardrobe.
    `.trim(),
  },
  {
    chunk_id: 'ai-scan',
    title: 'AI Scan — Catalog Items from Photos',
    content: `
AI Scan lets you catalog items by taking photos. **Access: Owner and Manager only.**

### AI Scan screen
Navigate: tap the **AI Scan icon** (camera with sparkle) in the navigation bar.
Two-step process:
1. **Product photo** — "AI will identify the item automatically". Viewfinder hint: "Tap here or the button to take a photo".
2. **Receipt photo** (optional) — "Extracts price, date and serial number". Button: **"Skip this step →"**.
Progress: "STEP {n} OF 2".

### Analyzing
Title: "Analyzing images..." / Subtitle: "AI is identifying the item and extracting receipt data".

### Review item screen (AppBar: "Review item")
Confidence badge: "✦ IA · {n}%"
Banner (with receipt): "AI analyzed the product and receipt. Review the fields before saving."
Banner (without receipt): "AI analyzed the product. You can fill in additional fields manually."
Footer: "Fields marked ✦ were suggested by AI — review before saving"

Fields:
- **NAME** (hint: "Item name")
- **CATEGORY** (dropdown: Furniture · Art · Technology · Wardrobe · Vehicles · Wine · Sports · Other)
- **SUBCATEGORY** (hint: "Opcional")
- **BRAND** (hint: "Opcional")
- **ROOM** (dropdown with "No room — assign later" option, empty: "No rooms available")
- **PURCHASE PRICE** (hint: "$0")
- **ESTIMATED VALUE** (hint: "$0")
- **SERIAL NUMBER**
- **TAGS** (hint: "tag1, tag2, ...")

### Wardrobe fields (when category = Wardrobe)
Section: **"WARDROBE DETAILS"**
Fields: TYPE (Clothing/Footwear/Accessories/Jewelry & Watches), COLOR (hint: "e.g. navy blue"), SIZE (hint: "S / M / L / 42 / 38…"), MATERIAL (hint: "e.g. cotton, leather"), SEASON (Spring/Summer/Fall/Winter/All Season), CLEANING STATUS (Clean ✓/Needs Cleaning/At Dry Cleaner).

### Save
Button: **"Save item"**. Validation: "Name is required". Error: "Error saving item: {error}"

### Error state
"Analysis failed" / **"Try again"** · **"Cancel"**
    `.trim(),
  },
  {
    chunk_id: 'orchestrator',
    title: 'Orchestrator — AI Task Plans',
    content: `
The Orchestrator creates AI-generated task plans. **Access: Owner, Manager, and assigned Staff.**

### Orchestrator list screen (AppBar: "Orchestrator")
Tabs: **My Tasks** · **All Plans**
FAB: **"New Plan"**.
Status labels: Published · In Progress · Completed · Cancelled · Draft
Progress: "{n}% complete · {done}/{total} steps"
Assignee count: "{n} staff"
Empty (My Tasks): "No active tasks" / "Plans assigned to you will appear here."
Empty (All Plans): "No plans yet" / 'Tap "New Plan" to generate your first AI plan.'

### Create a new plan (AppBar: "New Plan")
1. Instruction: "Describe what you need done"
2. Input hint: 'e.g. "Prepare the dining room for a formal dinner for 8 this Saturday"'
3. Options: **Property scope** dropdown (default "All properties"), **Target date** (default "Not set").
4. Example commands: "Prepare the dining room for a formal dinner for 8" / "Pack for the Aspen trip next week" / "Move the wine collection from the basement" / "Inspect the living room before the visit"
5. Button: **"Generate Plan"** (or "Generating…" while processing).
6. Validation: "Please describe what you need done."

### Review plan (AppBar: "Review Plan")
Section: **"PLAN TITLE"** / **"AI Summary"** / **"TASK GROUPS"**.
Group count: "{n} groups · drag to reorder". Empty: "All groups removed".
Each group: title, step count "{n} step(s)", **"Assign to…"** button, **"Add Item"** button.
Bottom: **"Save & Publish"** · **"Save as Draft"**.
Validation: "Plan title is required."

### Plan detail (AppBar: plan title)
Sections: **"OVERALL PROGRESS"** ("{done} of {total} steps completed") · **"TASK GROUPS"**.
Menu: **"Live Progress"** · **"Cancel Plan"**.
Publish button: **"Publish Plan"** (snackbar: "Plan published — staff notified!").
Cancel dialog: "Delete Draft" / "Cancel Plan" with confirmation.
Group statuses: In Progress · Done · Pending.
Add Group button: **"Add Group"**.

### Task group screen (AppBar: group title)
Assignee: "Assigned to: {name}" or "Unassigned".
Progress: "{done} / {total} done".
Step statuses: Done · Skipped · Orphaned · Pending.
Empty: "No steps in this group"

### Step guide screen (AppBar: item name)
Tabs: **Room** · **Section** · **Item**.
Panel 1 header: **"GO TO ROOM"** (or "Unknown room").
Panel 2 header: **"FIND THE SECTION"** (or "Unknown section", code: "Code: {code}").
Panel 3: item photo (or "No photo available"), note field (hint: "Add a note (optional)…").
Buttons: **"Mark Complete"** · **"Already Done"**, then **"Next"**.
Snackbar: "Step completed!"

### Live Progress (AppBar: "Live Progress")
Sections: **"BY STAFF"** · **"COMPLETED STEPS"**.
Progress ring with "complete" label. Text: "{done} of {total} steps".
Timeline with timestamps. Empty: "No steps completed yet".

### Assign to Staff sheet
Sheet: **"Assign to Staff"**.
Lists staff/manager accounts. Empty: "No staff or manager accounts found." Error: "Could not load users."
    `.trim(),
  },
  {
    chunk_id: 'household-members',
    title: 'Household Members',
    content: `
Household Members are profiles of family members linked to wardrobe items, separate from app user accounts.

### Manage household members
Navigate: **Settings** → **Household Members**.
**Access**: Owner and Manager only.

### Household Members screen (AppBar: "Household Members")
Lists all members with name, relationship, and adult/minor status.
FAB: **"Add member"**.
Empty: "No household members yet"

### Add / Edit member
Sheet title: **"Add household member"** / **"Edit household member"**.
Fields: **Name** (required), **Relationship** (optional), **Minor** (toggle).
Button: **"Save"** / **"Save changes"**.

### Remove member
Popup menu: **Edit** · **Remove**.
Dialog: "Remove member" / 'Remove {name} from your household members?' / **Cancel** · **Remove**
Default avatar initial: "?"
    `.trim(),
  },
  {
    chunk_id: 'auth',
    title: 'Login, MFA & Account Setup',
    content: `
### Login screen
Logo: "VAULTED". Tagline: "Everything you own. Protected."
Fields: **Email** (required), **Password** (required).
Button: **"Log in"**
Validation: "Email is required", "Password is required"

### Two-Factor Authentication (MFA)
Page: "Two-Factor Authentication"
Description: "Enter the 6-digit code from your authenticator app"
Field: **"Verification code"** (hint: "000000").
Button: **"Verify"**.
Validation: "Please enter a 6-digit code"

### Accept invitation
Accessed via invite link from email.
Page: logo "VAULTED" / subtitle: "Accept your invitation"
Invalid link: "This invite link is missing a token. Open the link from your email…"
Fields: **Password** (required, min 12 chars, must contain uppercase, lowercase, number, special char), **Confirm password**.
Button: **"Create account"**.
API errors: "Too many attempts. Wait a moment and try again." / "Invalid invite link. Request a new invitation."

### Device Security
Vaulted requires devices to meet security standards. Jailbroken or rooted devices will see a security requirements screen and cannot access the app.
    `.trim(),
  },
];

// ─── Screen context, suggestions, chunk mapping ────────────────────────────────

const SCREEN_CONTEXT: Record<HelpScreen, string> = {
  dashboard: 'The user is on the Dashboard — viewing KPI stat cards, Quick Actions grid, and property cards.',
  inventory: 'The user is on the Asset Directory screen (AppBar: "Asset Directory") — browsing, searching, or filtering inventory items.',
  item_detail: "The user is viewing a single item's detail page with spec fields, valuation, wardrobe details, maintenance, and movement history.",
  add_item: 'The user is on the Add Item or Edit Item form sheet.',
  movements:
    'The user is on the Operations screen (AppBar: "Operations") — managing loans, transfers, repairs, and disposals. Tabs: Active and History.',
  wardrobe: 'The user is in the Wardrobe module (AppBar: "Wardrobe") — grid view, outfits, dry cleaning, or filters.',
  maintenance: 'The user is on the Maintenance screen. Tabs: Overdue, This Week, Upcoming, Completed.',
  insurance: 'The user is managing insurance policies, coverage gap analysis, or claim drafts.',
  properties: 'The user is managing properties, floors, rooms, or room sections.',
  users: 'The user is on the Team screen — managing invited users, roles, and property access.',
  ai_scan: 'The user is using AI Scan to catalog items from photos. May be on the capture, analyzing, or review step.',
  ai_section_scan: 'The user is using AI Section Scan to map drawers, cabinets, and shelves from a furniture photo.',
  ai_chat: 'The user is on the AI Chat (AppBar: "AI Assistant") — asking questions about their inventory items.',
  reports: 'The user is on the Reports screen (AppBar: "Inventory Reports") — viewing asset value, category, and status breakdowns.',
  settings: 'The user is in Settings (AppBar: "Settings") — managing team, household members, appearance, notifications, and account.',
  orchestrator: 'The user is on the Orchestrator screen — managing AI-generated task plans, groups, and step guides.',
  notifications: 'The user is on the Notification Center (AppBar: "Notifications") — viewing alerts for maintenance, wardrobe, and item updates.',
  household_members: 'The user is on the Household Members screen — managing family member profiles linked to wardrobe items.',
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
  ai_scan: ['ai-scan', 'add-edit-items'],
  ai_section_scan: ['ai-section-scan', 'properties-rooms'],
  ai_chat: ['ai-chat'],
  reports: ['reports-settings'],
  settings: ['reports-settings'],
  orchestrator: ['orchestrator'],
  notifications: ['reports-settings'],
  household_members: ['household-members', 'users-roles'],
};

const SCREEN_SUGGESTIONS: Record<HelpScreen, string[]> = {
  dashboard: [
    'How do I add a new property?',
    'What do the Quick Actions do?',
    'How do I hide my valuables from view?',
  ],
  inventory: [
    'How do I add a new item?',
    'How do I filter items by status?',
    'How do I find items currently on loan?',
  ],
  item_detail: [
    'How do I edit this item?',
    "How do I see this item's movement history?",
    'How do I send an item to dry cleaner?',
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
    'What are room sections for?',
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
  ai_section_scan: [
    'How does AI Section Scan work?',
    'What section types can AI detect?',
    'How do I edit detected sections?',
  ],
  ai_chat: [
    'What kind of questions can AI Chat answer?',
    'How is AI Chat different from Vaulted Guide?',
    'How do I clear my AI Chat session?',
  ],
  reports: [
    'How do I export a report?',
    'Can I see breakdowns by category?',
    'Why are Auditor exports watermarked?',
  ],
  settings: [
    'How do I set up MFA?',
    'How do I change notification preferences?',
    'How do I invite a team member?',
  ],
  orchestrator: [
    'How do I create a new plan?',
    'How do I assign tasks to staff?',
    'What does Live Progress show?',
  ],
  notifications: [
    'How do I enable push notifications?',
    'How do I clear read notifications?',
    'What alerts can I receive?',
  ],
  household_members: [
    'How do I add a household member?',
    'What is the difference between a user and a household member?',
    'How do I link a member to wardrobe items?',
  ],
};

const DEFAULT_SUGGESTIONS = [
  'How do I add a new item?',
  'How do I invite a staff member?',
  'What is the difference between roles?',
];

const UNRESOLVED_MARKER = '[UNRESOLVED:';

function sanitizeAiOutput(text: string): string {
  return text.replace(/<[^>]*>/g, '').replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
}

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
    await this.enforceRateLimit(tenantId, userId);

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
      answer: sanitizeAiOutput(result.text),
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
      if (chunks.length === 0) {
        return HELP_KB_CHUNKS.map((c) => `## ${c.title}\n\n${c.content}`).join('\n\n---\n\n');
      }
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

  private async enforceRateLimit(tenantId: string, userId: string): Promise<void> {
    const tenantKey = `ai:help:ratelimit:${tenantId}`;
    const tenantCount = await this.redis.incr(tenantKey);
    if (tenantCount === 1) await this.redis.expire(tenantKey, 60);
    if (tenantCount > this.rateLimit) {
      throw new HttpException('Rate limit exceeded', HttpStatus.TOO_MANY_REQUESTS);
    }
    const userKey = `ai:help:ratelimit:user:${userId}`;
    const userCount = await this.redis.incr(userKey);
    if (userCount === 1) await this.redis.expire(userKey, 60);
    const userLimit = Math.max(1, Math.floor(this.rateLimit / 2));
    if (userCount > userLimit) {
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
