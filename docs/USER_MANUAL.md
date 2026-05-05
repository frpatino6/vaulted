# Vaulted — User Manual

**Everything you own. Protected. Organized. Yours.**

Version 1.0 · May 2026

---

## Table of Contents

1. [Welcome to Vaulted](#1-welcome-to-vaulted)
2. [Getting Started](#2-getting-started)
   - 2.1 [Creating Your Account](#21-creating-your-account)
   - 2.2 [Logging In](#22-logging-in)
   - 2.3 [Two-Factor Authentication (MFA)](#23-two-factor-authentication-mfa)
   - 2.4 [Navigating the App](#24-navigating-the-app)
3. [User Roles and Access](#3-user-roles-and-access)
4. [Dashboard](#4-dashboard)
5. [Properties](#5-properties)
   - 5.1 [Adding a Property](#51-adding-a-property)
   - 5.2 [Adding Floors](#52-adding-floors)
   - 5.3 [Adding Rooms](#53-adding-rooms)
   - 5.4 [AI Section Scan — Mapping Storage Furniture](#54-ai-section-scan--mapping-storage-furniture)
   - 5.5 [Viewing a Property](#55-viewing-a-property)
6. [Inventory](#6-inventory)
   - 6.1 [Adding an Item Manually](#61-adding-an-item-manually)
   - 6.2 [Item Details and Fields](#62-item-details-and-fields)
   - 6.3 [Item Statuses](#63-item-statuses)
   - 6.4 [Photos and Documents](#64-photos-and-documents)
   - 6.5 [QR Codes](#65-qr-codes)
   - 6.6 [Searching and Filtering](#66-searching-and-filtering)
   - 6.7 [Item History](#67-item-history)
   - 6.8 [Editing and Archiving Items](#68-editing-and-archiving-items)
7. [AI Scan — Auto-Catalog](#7-ai-scan--auto-catalog)
8. [AI Chat — Query Your Inventory](#8-ai-chat--query-your-inventory)
9. [Movements and Loans](#9-movements-and-loans)
   - 9.1 [Transferring an Item Between Rooms](#91-transferring-an-item-between-rooms)
   - 9.2 [Recording a Loan](#92-recording-a-loan)
   - 9.3 [Returning a Loaned Item](#93-returning-a-loaned-item)
10. [Wardrobe](#10-wardrobe)
    - 10.1 [Closet Grid](#101-closet-grid)
    - 10.2 [Managing Outfits](#102-managing-outfits)
    - 10.3 [Dry Cleaning Tracker](#103-dry-cleaning-tracker)
    - 10.4 [Wardrobe Stats](#104-wardrobe-stats)
11. [Insurance](#11-insurance)
    - 11.1 [Adding a Policy](#111-adding-a-policy)
    - 11.2 [Attaching Items to a Policy](#112-attaching-items-to-a-policy)
    - 11.3 [Coverage Gap Analysis](#113-coverage-gap-analysis)
    - 11.4 [AI Insurance Analysis](#114-ai-insurance-analysis)
12. [Maintenance](#12-maintenance)
    - 12.1 [Scheduling Maintenance](#121-scheduling-maintenance)
    - 12.2 [Logging Completed Work](#122-logging-completed-work)
    - 12.3 [Notifications](#123-notifications)
13. [Users and Access Management](#13-users-and-access-management)
    - 13.1 [Inviting a User](#131-inviting-a-user)
    - 13.2 [Assigning Roles Per Property](#132-assigning-roles-per-property)
    - 13.3 [Guest Access](#133-guest-access)
    - 13.4 [Removing a User](#134-removing-a-user)
14. [Security and Privacy](#14-security-and-privacy)
15. [Tips and Best Practices](#15-tips-and-best-practices)
16. [Glossary](#16-glossary)

---

## 1. Welcome to Vaulted

Vaulted is a private, secure home inventory platform designed for families who own and manage significant personal assets across one or more properties. Whether you maintain a primary residence, a vacation estate, or several homes across different states, Vaulted gives you a single, authoritative record of everything inside each property — from grand pianos and original artwork to wine collections and seasonal wardrobes.

**Vaulted is available as:**
- A mobile app for iPhone (iOS) and Android phones and tablets
- A web app accessible from any browser at [vaulted-prod-2026.web.app](https://vaulted-prod-2026.web.app)

All your data syncs in real time across every device.

**What you can do with Vaulted:**
- Catalog every item in every room of every property you own
- Track the value, condition, and location of each item over time
- Generate reports for insurance carriers and appraisers
- Manage who on your team can see or edit which information
- Automate maintenance scheduling and receive reminders
- Use AI to catalog new items instantly by pointing your phone camera at them
- Ask plain-language questions about your collection and get instant answers

---

## 2. Getting Started

### 2.1 Creating Your Account

Your Vaulted account is provisioned by Vaulted's onboarding team. Once your family's account has been set up, you will receive an invitation email from Vaulted containing a personal setup link.

1. Open the invitation email and tap **Activate My Account**.
2. You will be directed to the Vaulted app or web app.
3. Enter and confirm a strong password (minimum 12 characters, including uppercase, lowercase, a number, and a special character).
4. Complete the two-factor authentication setup (see Section 2.3).
5. Tap **Finish Setup**.

> **Note:** If you are joining an existing account as a Manager, Staff member, Auditor, or Guest, you will receive a separate invitation from the account Owner. Follow the same steps above.

---

### 2.2 Logging In

**On mobile:**
1. Open the Vaulted app.
2. Enter your email address and password.
3. Complete the MFA prompt if required for your role.
4. Tap **Sign In**.

**On the web:**
1. Navigate to [vaulted-prod-2026.web.app](https://vaulted-prod-2026.web.app).
2. Enter your email address and password.
3. Complete the MFA prompt if required for your role.
4. Click **Sign In**.

> **Tip:** Your session remains active for 15 minutes of inactivity on each device. You will be prompted to re-authenticate after that period for your security.

---

### 2.3 Two-Factor Authentication (MFA)

MFA is mandatory for all Owner and Manager accounts. It adds a second layer of protection beyond your password.

**Setting up MFA for the first time:**
1. Download an authenticator app on your phone if you do not already have one — for example, Google Authenticator or Authy.
2. During account setup, Vaulted will display a QR code on screen.
3. Open your authenticator app and select **Add Account** (or the "+" icon).
4. Scan the QR code displayed by Vaulted.
5. Enter the 6-digit code shown in your authenticator app to confirm the setup.
6. Save your backup codes in a secure location (such as a password manager or a printed document stored in a safe).

**Logging in with MFA:**
1. Enter your email and password as usual.
2. Open your authenticator app.
3. Enter the current 6-digit code when prompted.
4. Tap **Verify**.

> **Important:** If you lose access to your authenticator app, use one of the backup codes you saved during setup. Contact your account Owner or Vaulted support to reset MFA if all backup codes are lost.

---

### 2.4 Navigating the App

The app is organized around a bottom navigation bar (mobile) or a left sidebar (web) with the following main sections:

| Icon | Section | What it does |
|---|---|---|
| Dashboard | Home | Summary of your entire portfolio |
| Properties | Estates | All your properties and their contents |
| Inventory | Items | Search and browse all items |
| Wardrobe | Closet | Clothing, outfits, dry cleaning |
| Insurance | Coverage | Policies and coverage analysis |
| Maintenance | Schedule | Upkeep tasks and reminders |
| AI Chat | Assistant | Ask questions about your inventory |
| Users | Team | Manage access for your household team |

---

## 3. User Roles and Access

Vaulted uses a role-based access system. Each person invited to your account is assigned one of the following roles:

| Role | What they can do |
|---|---|
| **Owner** | Full access to all properties, all features, all financial data. Manages users, roles, and account settings. |
| **Manager** | Full inventory management (add, edit, move items, manage insurance and maintenance). Cannot view item valuations or financial figures. |
| **Staff** | Can view and update items specifically assigned to them. Cannot see financial data or other team members' assignments. |
| **Auditor** | Read-only access to specific categories. Exports are watermarked with the auditor's name and date. Financial figures are redacted. |
| **Guest** | Temporary read-only access to designated areas. Access expires automatically on a set date. |

**Access is always scoped per property.** A staff member assigned to your Miami estate cannot see, access, or be aware of your Aspen property unless explicitly granted access there.

> **Tip:** Use the Manager role for your chief of staff or household manager who needs to run operations but should not have visibility into asset valuations. Use Auditor for insurance agents or appraisers who need to review the inventory.

---

## 4. Dashboard

The Dashboard is the first screen you see after logging in. It gives you a real-time overview of your entire portfolio.

**What the Dashboard shows:**

- **Total Properties** — number of estates in your account
- **Total Items** — count of all cataloged items, broken down by status: Active, On Loan, In Repair, In Storage, and Disposed
- **Total Portfolio Valuation** — combined current value of all active items in USD
- **Items by Category** — a visual breakdown of your collection by category: Furniture, Art & Collectibles, Technology, Wardrobe, Vehicles, Wine & Spirits, Sports Equipment, and Other

**Reading the Dashboard:**

The valuation figures reflect the most recently recorded current value for each item. If an item has not been appraised recently, its valuation may not reflect current market conditions. Use the Insurance module's coverage gap analysis to identify items that may need updated appraisals.

> **Note:** Managers and Staff see the Dashboard without financial figures. Only Owners see valuations.

---

## 5. Properties

A property in Vaulted represents a physical estate, home, or residence. Each property is organized into floors, and each floor contains rooms. Items are assigned to specific rooms.

### 5.1 Adding a Property

1. Tap **Properties** in the navigation bar.
2. Tap the **+** button (or **Add Property** on web).
3. Enter the property name (e.g., "Palm Beach Estate" or "Aspen Chalet").
4. Enter the full address.
5. Add one or more exterior photos to identify the property visually.
6. Tap **Save**.

The new property will appear in your Properties list and on the Dashboard.

---

### 5.2 Adding Floors

1. Open the property by tapping its card.
2. Tap **Add Floor**.
3. Enter the floor name or number (e.g., "Ground Floor", "First Floor", "Basement", "Penthouse").
4. Tap **Save**.

Repeat for each floor in the property.

---

### 5.3 Adding Rooms

1. Open a property and tap on a floor.
2. Tap **Add Room**.
3. Enter the room name (e.g., "Master Bedroom", "Library", "Wine Cellar", "Garage").
4. Optionally add a room photo.
5. Tap **Save**.

Repeat for each room on that floor.

> **Tip:** Be as specific as you like. Separate the "Main Garage" from the "Carriage House" if they hold different collections. A well-organized room structure makes searching and reporting much faster.

---

### 5.4 AI Section Scan — Mapping Storage Furniture

One of Vaulted's most powerful features is the ability to photograph any piece of storage furniture — a cabinet, wardrobe, chest of drawers, pantry shelf, or safe — and have the AI automatically identify and label every individual section inside it. Each section becomes a precise location where items can be assigned.

**What is a section?**
A section is a subdivision within a room: a single drawer, a shelf, a cabinet compartment, a rack, or a safe. Sections let you track not just *which room* an item is in, but *exactly where* inside that room — down to the specific drawer or shelf.

**How to scan a piece of furniture:**

1. Open a room and tap **AI Section Scan** (the camera with sparkle icon).
2. Tap **Take Photo** or **Choose from Gallery**.
3. Point your camera at the storage furniture and take a clear, straight-on photo.
4. The AI analyzes the image and automatically detects every drawer, shelf, and compartment. This takes a few seconds.
5. The photo reappears with colored boxes drawn over each detected section, each labeled with an auto-assigned code (e.g., **1A**, **1B**, **2A**).
6. Review the detected sections:
   - **Tap a section chip** to select or deselect it.
   - **Tap the edit icon** on any chip to rename it, change its type, or add notes.
   - **Tap anywhere on the photo** (in normal mode) to manually add a section that the AI may have missed.
   - **Toggle Move Mode** (the arrows icon) to drag section boxes or resize them by pulling the corner handles.
   - Tap **Rescan** to discard the current result and photograph the same piece again.
7. If the room has more than one piece of furniture, tap **Scan another piece** to photograph a second cabinet without losing the first set of sections.
8. When satisfied, tap **Save X sections**. A confirmation sheet appears where you can give each piece of furniture a label (e.g., "Upper Cabinet", "Island", "Walk-in Pantry").
9. Tap **Confirm & Save**. The sections are created inside the room and are ready to receive items.

**Section types recognized by the AI:**
| Type | Examples |
|---|---|
| Drawer | Dresser drawers, filing drawers, kitchen drawers |
| Cabinet | Upper and lower kitchen cabinets, bathroom vanities |
| Shelf | Open shelving, bookcase shelves, pantry shelves |
| Rack | Wine racks, shoe racks, clothing racks |
| Safe | In-wall safes, floor safes, fireproof boxes |
| Compartment | Watch boxes, jewelry organizers, storage cubbies |

**Confidence indicator:**
After analysis, a percentage badge appears in the top bar. A score of 80% or above means the AI is highly confident. If the score is below 60%, a warning appears prompting you to retake the photo in better lighting or from a closer angle.

> **Tips for best results:**
> - Photograph furniture straight-on, not at an angle.
> - Open all drawers and doors slightly so the AI can distinguish compartments.
> - Use good lighting — natural light or overhead lighting works best.
> - For large pieces, take one photo per section of the furniture if needed.

**Assigning items to sections:**
Once sections are created, go to any item and edit its location. In addition to selecting the property, floor, and room, you will now see the list of sections for that room. Select the appropriate section to pinpoint the item's exact location.

---

### 5.5 Viewing a Property

Tap any property card to open it. From the property detail view you can:

- Browse all floors and rooms
- See a count of items per room
- Navigate into any room to see its contents
- Edit the property name, address, or photos
- Generate a PDF report of the entire property

---

## 6. Inventory

The Inventory module is the heart of Vaulted. Every object of value in your home is stored here as an item.

### 6.1 Adding an Item Manually

1. Navigate to a room inside a property, or tap **Inventory** in the navigation and then tap **+ Add Item**.
2. Fill in the item details (see Section 6.2 for all fields).
3. Tap **Save**.

Vaulted automatically generates a unique QR code for the item and records the creation in the audit log.

> **Tip:** Use the AI Scan feature (Section 7) to catalog new items in seconds by photographing them — the AI will pre-fill most fields for you.

---

### 6.2 Item Details and Fields

| Field | Description |
|---|---|
| **Name** | The common name of the item (e.g., "Louis XV Bergère Chair") |
| **Category** | Top-level category (see list below) |
| **Subcategory** | More specific classification within the category |
| **Brand / Maker** | Manufacturer, artist, designer, or house (e.g., "Cartier", "Hermès") |
| **Serial Number** | Manufacturer serial, hallmark, or registry number |
| **Purchase Price** | Original acquisition price in USD |
| **Current Value** | Most recent appraised or estimated value in USD |
| **Purchase Date** | Date the item was acquired |
| **Last Appraisal Date** | Date of the most recent professional appraisal |
| **Photos** | Up to 10 photos (see Section 6.4) |
| **Documents** | Certificates of authenticity, purchase receipts, appraisal reports |
| **Tags** | Free-form labels for flexible organization (e.g., "antique", "gift", "provenance") |
| **Notes** | Any additional information about the item |

**Available Categories:**
- Furniture
- Art & Collectibles
- Appliances & Technology
- Wardrobe (Clothing, Footwear, Accessories, Jewelry & Watches)
- Vehicles
- Wine & Spirits
- Books
- Sports Equipment
- Musical Instruments
- Household Supplies

---

### 6.3 Item Statuses

Every item in Vaulted has one of five statuses:

| Status | Meaning |
|---|---|
| **Active** | The item is in its assigned location and in normal use |
| **On Loan** | The item has been lent to someone and is not on-premises |
| **In Repair** | The item is with a restorer, jeweler, mechanic, or service provider |
| **In Storage** | The item is in a storage facility or designated storage room |
| **Disposed** | The item has been sold, donated, or otherwise removed from the collection |

Disposed items are retained in the record for historical and insurance purposes. They do not count toward active portfolio valuation.

---

### 6.4 Photos and Documents

Each item can have up to 10 photos and any number of attached documents (PDFs).

**Adding photos:**
1. Open an item and tap **Add Photo**.
2. Choose to take a new photo with your camera or select from your device's photo library.
3. The photo uploads immediately and is attached to the item.

**Best practice for photos:**
- Photograph the item from the front, back, and all relevant angles.
- Include a close-up of the serial number, hallmark, or maker's mark.
- Photograph any signatures, certificates, or labels.
- For jewelry, capture gemstone details and metalwork clearly.

**Adding documents:**
1. Open an item and tap **Add Document**.
2. Select a PDF from your device (purchase receipts, appraisal reports, certificates of authenticity).
3. The document uploads and is available for export at any time.

---

### 6.5 QR Codes

Vaulted automatically generates a unique QR code for every item when it is first created.

**To view an item's QR code:**
1. Open the item detail screen.
2. Tap **QR Code**.
3. Print it or display it on screen.

**To scan a QR code:**
1. Tap the scan icon in the Inventory or Movements screen.
2. Point your camera at the QR code on an item or its tag.
3. Vaulted opens the item detail instantly.

> **Tip:** Print QR code labels and affix them to the inside of furniture drawers, the base of sculptures, the back of frames, or inside vehicle door panels. This makes physical inventory checks much faster.

---

### 6.6 Searching and Filtering

**Full-text search:**
Tap the search icon in the Inventory screen and type any term — item name, brand, category, room, tag, or serial number. Results appear instantly as you type.

**Filtering:**
Use the Filter button to narrow results by:
- Category
- Status (Active, On Loan, In Repair, etc.)
- Property or Room
- Valuation range
- Date added or last updated

**Sorting:**
Sort results by name, value, date added, or category.

---

### 6.7 Item History

Every change to an item is recorded permanently. To view an item's full history:

1. Open the item.
2. Tap **History**.

The history log shows every event: who created the item, every edit made, every room transfer, every loan, and every status change — along with the name of the person who made the change and the exact date and time.

This record is immutable. It cannot be edited or deleted, even by the Owner.

---

### 6.8 Editing and Archiving Items

**To edit an item:**
1. Open the item.
2. Tap **Edit** (pencil icon).
3. Update any field.
4. Tap **Save**.

All changes are logged in the item history.

**To mark an item as Disposed:**
1. Open the item.
2. Tap **Edit**.
3. Change the Status to **Disposed**.
4. Add a note explaining the disposition (sold, donated, destroyed, etc.) and the date.
5. Tap **Save**.

Disposed items remain in your records permanently for insurance and tax purposes.

---

## 7. AI Scan — Auto-Catalog

The AI Scan feature lets you catalog a new item simply by pointing your phone's camera at it. Vaulted's AI identifies the object and pre-fills the item form for your review.

**How to use AI Scan:**

1. Tap the **AI Scan** button (camera with a sparkle icon) anywhere in the Inventory section, or from within a room view.
2. Point your camera at the item. Try to capture the whole object in frame with good lighting.
3. Tap the capture button to take the photo.
4. Vaulted's AI analyzes the image and returns:
   - Suggested name
   - Category and subcategory
   - Brand or maker (if identifiable)
   - Estimated current value in USD
   - Suggested room assignment
   - Tags
   - A confidence score
5. Review the AI's suggestions on the confirmation screen.
6. Edit any field if needed.
7. Tap **Save to Inventory** to create the item.

> **Note:** AI Scan works best in good lighting with the object fully visible. For artwork, try to capture the piece straight-on. For jewelry, use a clean white background if possible. You can always edit any field the AI fills in — the AI's suggestions are a starting point, not a final record.

> **Tip:** After AI Scan creates an item, add additional photos and attach any purchase documentation or appraisal certificates to complete the record.

---

## 8. AI Chat — Query Your Inventory

The AI Chat assistant lets you ask questions about your inventory in plain English and get instant, accurate answers drawn from your actual data.

**How to use AI Chat:**

1. Tap **AI Chat** in the navigation bar.
2. Type your question in the message box.
3. Tap **Send**.
4. The assistant responds with an answer based on your inventory.

**Example questions:**

- "What items are currently on loan?"
- "Show me all art pieces valued over $100,000."
- "What is in the wine cellar at the Palm Beach estate?"
- "Which items haven't been appraised in the last two years?"
- "List all Hermès pieces in the wardrobe."
- "What is the total value of the vehicles across all properties?"
- "Are there any maintenance tasks overdue this month?"

The AI Chat has access to your full inventory, room structure, item statuses, and history. It does not access external data.

> **Note:** For Managers, financial valuations are not shown in AI Chat responses. For Auditors, responses reflect their permitted category restrictions.

> **Tip:** You can use AI Chat as a quick alternative to searching manually. If you need to locate something specific before a formal event or audit, just ask.

---

## 9. Movements and Loans

The Movements module tracks the physical location of items over time, including temporary transfers between rooms or properties and items lent to others.

### 9.1 Transferring an Item Between Rooms

Use this when an item is permanently or semi-permanently moved to a new location.

1. Open the item.
2. Tap **Move Item**.
3. Select the destination property, floor, and room.
4. Add an optional note (e.g., "Moved for winter season").
5. Tap **Confirm Move**.

The item's location updates immediately, and the move is recorded in the item's history log.

---

### 9.2 Recording a Loan

Use this when an item leaves the property temporarily — lent to a family member, sent to an exhibition, or picked up by a specialist.

1. Open the item.
2. Tap **Record Loan**.
3. Enter:
   - The borrower's name
   - The expected return date
   - An optional note (reason for the loan)
4. Tap **Confirm**.

The item status changes to **On Loan**. It appears on the Dashboard in the On Loan count and is tracked in the Movements log.

---

### 9.3 Returning a Loaned Item

When a loaned item is returned:

1. Tap **Movements** in the navigation, or open the item directly.
2. Find the active loan record.
3. Tap **Complete Return**.
4. Optionally scan the item's QR code to confirm it is physically present.
5. Add a condition note if relevant (e.g., "Returned — minor surface scratch noted").
6. Tap **Confirm Return**.

The item status returns to **Active** and the loan is closed in the record.

> **Tip:** Use QR scan check-in during returns for high-value items. It adds an extra confirmation step that is recorded in the audit log with the exact time of return.

---

## 10. Wardrobe

The Wardrobe module provides a dedicated home for clothing, footwear, accessories, jewelry, and watches. It goes beyond simple cataloging to help you manage outfits and track dry cleaning.

### 10.1 Closet Grid

The Closet Grid displays all wardrobe items as a visual photo grid — similar to browsing a high-end boutique.

1. Tap **Wardrobe** in the navigation.
2. Browse all items in a visual grid.
3. Tap any item to open its full detail.
4. Use the filter bar to narrow by: type (clothing, footwear, accessories, jewelry, watches), season, color, or brand.

---

### 10.2 Managing Outfits

Outfits let you group wardrobe items into curated combinations.

**Creating an outfit:**
1. In the Wardrobe screen, tap **Outfits**.
2. Tap **+ New Outfit**.
3. Give the outfit a name (e.g., "Formal Gala — December" or "Casual Weekend").
4. Tap **Add Items** and select the pieces that make up the outfit from your wardrobe grid.
5. Optionally add a photo of the complete look.
6. Tap **Save**.

**Viewing outfits:**
Tap **Outfits** to see all saved outfits. Tap any outfit to see the items it includes and access each item's detail.

---

### 10.3 Dry Cleaning Tracker

The dry cleaning tracker helps you monitor which items are currently at the cleaner, when they are expected back, and flags items that are overdue.

**Logging an item sent to the cleaner:**
1. In the Wardrobe screen, tap **Dry Cleaning**.
2. Tap **+ New Drop-Off**.
3. Select the item(s) from your wardrobe.
4. Enter:
   - Cleaner name and address
   - Date sent
   - Expected return date
   - Cost
5. Tap **Save**.

The item status in the Wardrobe reflects that it is at the cleaner.

**Marking items as returned:**
1. In the Dry Cleaning tracker, find the item.
2. Tap **Mark as Returned**.
3. Confirm the return date.

**Overdue alerts:**
If an item has not been marked returned by its expected return date, Vaulted displays a visual alert in the Dry Cleaning tracker. You will also receive a push notification.

---

### 10.4 Wardrobe Stats

The Wardrobe Stats bar shows a summary of your wardrobe at a glance:

- Total items by type (clothing, footwear, accessories, jewelry, watches)
- Items by season
- Total outfit count
- Number of items currently at the cleaner

---

## 11. Insurance

The Insurance module provides a complete picture of your coverage across all properties. It connects your insurance policies directly to the items they cover, so you always know what is protected and what is not.

### 11.1 Adding a Policy

1. Tap **Insurance** in the navigation.
2. Tap **+ Add Policy**.
3. Enter the policy details:
   - Insurance provider name
   - Policy number
   - Coverage type (e.g., Fine Art, Jewelry, General Contents, Vehicle)
   - Coverage amount in USD
   - Policy start date
   - Policy expiry date
   - Annual premium (optional)
   - Contact name at the insurer (optional)
4. Attach the policy document (PDF) if available.
5. Tap **Save**.

---

### 11.2 Attaching Items to a Policy

Once a policy exists, you can attach specific inventory items to it.

1. Open a policy.
2. Tap **Add Items to Policy**.
3. Browse or search your inventory and select the items covered by this policy.
4. For each item, enter the covered value as stated in the policy (this may differ from the current appraised value).
5. Tap **Save**.

You can also attach an item to a policy from the item's own detail screen: open any item, tap **Insurance**, and select the policy that covers it.

---

### 11.3 Coverage Gap Analysis

The Coverage Gap Analysis automatically compares the current value of your items to your insurance coverage and identifies items that may be uninsured or underinsured.

1. Tap **Insurance** in the navigation.
2. Tap **Coverage Gaps**.

Vaulted displays:
- **Uninsured items** — items with a recorded value but no policy attached
- **Underinsured items** — items where the covered value is significantly below the current appraised value
- **Policies nearing expiry** — policies expiring within the next 60 days

> **Tip:** Run a coverage gap analysis at least once per quarter, and again after every significant acquisition, appraisal, or policy renewal.

---

### 11.4 AI Insurance Analysis

The AI Insurance Analysis feature reviews your entire coverage picture and generates a plain-language report with observations and recommendations.

1. Tap **Insurance** in the navigation.
2. Tap **AI Analysis**.
3. Vaulted's AI reviews your policies, items, covered values, and current valuations.
4. The analysis appears within a few seconds and may include:
   - Categories with the largest coverage gaps
   - Items that have appreciated significantly since last coverage update
   - Recommendations to consolidate or update policies
   - Alerts for policies expiring soon

> **Note:** The AI analysis is informational. It does not replace the advice of a licensed insurance professional. Share the analysis with your broker as a conversation starting point.

---

## 12. Maintenance

The Maintenance module helps you stay on top of upkeep for your properties and their contents — from HVAC servicing and pool maintenance to piano tuning and vehicle oil changes.

### 12.1 Scheduling Maintenance

1. Tap **Maintenance** in the navigation.
2. Tap **+ New Task**.
3. Fill in:
   - Title (e.g., "HVAC Filter Replacement — Master Wing")
   - Linked item or property area
   - Scheduled date
   - Recurrence (one-time, monthly, quarterly, annually)
   - Assigned to (a specific staff member, or unassigned)
   - Notes (e.g., service provider name, instructions)
4. Tap **Save**.

The task appears in the Maintenance calendar on its scheduled date. If it is recurring, Vaulted automatically creates the next occurrence when the current one is marked complete.

---

### 12.2 Logging Completed Work

1. Open the maintenance task.
2. Tap **Mark Complete**.
3. Enter:
   - Date completed
   - Who performed the work (staff member or external provider)
   - Cost (optional)
   - Notes about the work done
4. Tap **Save**.

The completion is recorded in the task history and in the item's history log if the task was linked to a specific item.

---

### 12.3 Notifications

Vaulted sends push notifications and in-app reminders for:
- Maintenance tasks due within 7 days
- Overdue maintenance tasks
- Dry cleaning items overdue for return (Wardrobe)
- Insurance policies expiring within 60 days
- Loaned items past their expected return date

Notification preferences can be adjusted in **Settings → Notifications**.

---

## 13. Users and Access Management

The Owner of an account has full control over who can access which properties and with what level of permission.

### 13.1 Inviting a User

1. Tap **Users** in the navigation.
2. Tap **+ Invite User**.
3. Enter the person's email address.
4. Select their role (Owner, Manager, Staff, Auditor, or Guest).
5. Select which properties they should have access to.
6. Tap **Send Invitation**.

The person receives an email invitation. Once they accept and set up their account, they appear as an active user.

---

### 13.2 Assigning Roles Per Property

A user can have different roles on different properties. For example, your chief of staff might be a Manager at your primary residence but a Staff member at the vacation home.

1. Tap **Users** and open a user's profile.
2. Tap **Manage Property Access**.
3. For each property, select the appropriate role or **No Access**.
4. Tap **Save**.

---

### 13.3 Guest Access

Guest access is ideal for temporary visitors such as appraisers, insurance adjusters, or family members visiting for a defined period.

When inviting a Guest:
1. Follow the standard invitation steps (Section 13.1).
2. Select **Guest** as the role.
3. Set an **Access Expiry Date**. After this date, the guest's access is automatically revoked — no manual action required.
4. Specify which properties and which areas (categories) the guest may view.

> **Tip:** Create a Guest account for an appraiser visiting to inspect your art collection. Scope access to the Art & Collectibles category only and set the expiry to their appointment date. Their exported reports will be automatically watermarked with their name and the date.

---

### 13.4 Removing a User

1. Tap **Users** and open the user's profile.
2. Tap **Remove User**.
3. Confirm the removal.

The user's access is revoked immediately across all devices. Their session is invalidated within seconds. Their historical actions in the audit log are permanently retained.

---

## 14. Security and Privacy

Vaulted is built from the ground up with the security requirements of high-value collections in mind.

**Two-factor authentication (MFA)**
All Owner and Manager accounts require MFA at every login. This prevents unauthorized access even if a password is compromised.

**Data encryption**
All data in Vaulted is encrypted at rest using AES-256 encryption. All communication between your device and Vaulted's servers uses TLS 1.3 — the most secure transport protocol available.

**Session security**
Your login session uses short-lived access tokens (15 minutes) paired with secure refresh tokens. This means that even if a session token were intercepted, it would expire within minutes. When you log out, your session is immediately invalidated across all devices.

**Immutable audit log**
Every action taken in Vaulted — every item created, edited, moved, or viewed — is permanently recorded in an immutable audit log. This log cannot be modified or deleted by anyone, including the account Owner. It is retained for two years and is available to Owners on request.

**Per-property access isolation**
Users can only see and access the properties they have been explicitly granted access to. There is no way for a staff member at one property to discover the existence of another property.

**Mobile security**
The Vaulted mobile app uses certificate pinning (it only communicates with Vaulted's verified servers), stores sensitive data in your device's secure enclave, and blocks screenshots in sensitive screens.

**Your responsibility**
- Keep your password strong and unique to Vaulted.
- Do not share your login credentials with others — invite them as users instead.
- Store your MFA backup codes securely.
- Log out of the web app when using shared computers.
- Report any suspicious activity to support@vaultedapp.com immediately.

---

## 15. Tips and Best Practices

**Getting started quickly**
Use AI Scan to photograph every item in one room before moving to the next. Even a rough catalog is better than none — you can refine fields later. Cover every room before trying to be perfect about any single room.

**Photograph everything**
For insurance and appraisal purposes, a photograph is worth more than any description. Always include at least a front-facing photo and a close-up of any serial number, hallmark, or maker's mark.

**Keep valuations current**
Schedule an annual review of item valuations — especially for art, jewelry, watches, wine, and vehicles, which can appreciate or depreciate significantly. Update the Current Value field after each appraisal.

**Use tags generously**
Tags are a powerful, flexible way to find items quickly. Tag items with their provenance ("acquired-Paris-2019"), their significance ("anniversary-gift"), their condition ("restoration-needed"), or any other attribute that matters to you.

**Assign QR codes physically**
Print QR code labels and attach them to items, their cases, or their storage locations. Physical QR codes turn Vaulted into a real-time inventory system you can interact with during physical inspections and move-ins/move-outs.

**Run a coverage gap analysis before every renewal**
Before renewing your insurance policies, run a coverage gap analysis and share the results with your broker. This ensures your coverage keeps pace with your portfolio's value.

**Use separate roles thoughtfully**
Give household staff the Staff role with access limited to their specific area. Give your insurance broker an Auditor guest account when they need to review the inventory. Do not share Owner credentials.

**Export for appraisers**
Before hosting an appraiser, generate a PDF export of the relevant property or category and send it in advance. This saves significant time on-site.

---

## 16. Glossary

| Term | Definition |
|---|---|
| **Active** | An item that is present in its assigned location and in normal use |
| **Audit Log** | A permanent, tamper-proof record of every action taken in Vaulted |
| **Coverage Gap** | A situation where an item has no insurance coverage or is covered for less than its current appraised value |
| **Current Value** | The estimated or appraised market value of an item at the present time |
| **Disposed** | An item that has been sold, donated, or removed from the collection |
| **Floor** | A level within a property, used to organize rooms |
| **Item History** | The complete log of all events related to a specific item |
| **Loan** | A temporary arrangement in which an item leaves the property and is expected to be returned |
| **MFA** | Multi-Factor Authentication — a second layer of identity verification beyond a password |
| **Movement** | Any transfer of an item from one location to another, or a loan event |
| **On Loan** | An item that has been lent to someone and is not currently on-premises |
| **Policy** | An insurance policy document recorded in the Insurance module |
| **Property** | A physical estate or residence managed within Vaulted |
| **Purchase Price** | The original price paid to acquire an item |
| **QR Code** | A scannable code auto-generated per item that opens the item record when scanned |
| **Room** | A specific area within a floor of a property where items are located |
| **Role** | The permission level assigned to a user (Owner, Manager, Staff, Auditor, or Guest) |
| **Serial Number** | A unique identifier assigned by the manufacturer or registrar of an item |
| **Status** | The current condition and location state of an item (Active, On Loan, In Repair, In Storage, Disposed) |
| **Tag** | A free-form label attached to an item for flexible categorization and search |
| **Tenant** | The family or household account that owns a Vaulted subscription |
| **Valuation** | The financial value of an item, including purchase price and current appraised value |

---

*Vaulted is a product of Vaulted Inc. For support, contact support@vaultedapp.com.*

*© 2026 Vaulted Inc. All rights reserved.*
