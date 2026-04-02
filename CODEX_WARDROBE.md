# Codex Task: Wardrobe Module — Missing Features

## Context

This is **Vaulted**, a premium home inventory management app for high-net-worth families.
Stack: NestJS (TypeScript) backend + Flutter frontend, MongoDB (inventory) + PostgreSQL (users/audit).

---

## What already exists — do NOT rewrite this

### Backend (NestJS)
The wardrobe feature has **no dedicated module**. It reuses the inventory module entirely:

- Items with `category: 'wardrobe'` are wardrobe items
- Wardrobe-specific data is stored in the flexible `attributes: Record<string, unknown>` field in MongoDB
- Relevant file: `apps/api/src/modules/inventory/schemas/item.schema.ts`
- All standard item endpoints already work for wardrobe:
  - `GET /items?category=wardrobe` — list wardrobe items
  - `GET /items/search?category=wardrobe` — search wardrobe items
  - `PUT /items/:id` — update item attributes (used for cleaning status)
  - `GET /items/:id` — get item detail

### Flutter frontend
Fully functional wardrobe screen at `apps/mobile/lib/features/wardrobe/`:

- **`wardrobe_screen.dart`** — Grid 2-column layout, two filter rows (type + cleaning status), pull-to-refresh, navigates to `/items/:id` on tap
- **`wardrobe_item_card.dart`** — Shows image, name, brand, cleaning status icon (green/amber/blue)
- **`wardrobe_notifier.dart`** — `AsyncNotifier<List<ItemModel>>`, calls `search(category: 'wardrobe')` with fallback to `getItems()`, `updateCleaningStatus()` with optimistic UI + rollback
- **`wardrobe_attributes.dart`** — Plain Dart class (not Freezed), parsed from `item.attributes` map. Fields: `size`, `color`, `brand`, `season`, `cleaningStatus`, `material`, `type`. Static constants for valid values.

### Attribute values already defined
```dart
// types
'clothing', 'footwear', 'accessories', 'jewelry_watches'

// seasons
'spring_summer', 'fall_winter', 'all_season'

// cleaningStatuses
'clean', 'needs_cleaning', 'at_dry_cleaner'
```

### Route already registered
```dart
GoRoute(path: '/wardrobe', builder: (context, state) => const WardrobeScreen())
```

---

## Coding conventions — follow these exactly

### Backend (NestJS)
- TypeScript strict mode — no `any` types
- All inputs validated with `class-validator` DTOs
- All responses through existing `ResponseInterceptor`
- All mutations logged to `AuditService` (already injected in inventory controller)
- Files: kebab-case | Classes: PascalCase
- Test files: `.spec.ts` co-located with the file they test

### Flutter
- Architecture: feature-first + Riverpod with code generation (`@riverpod`)
- Data models: `Freezed + json_serializable` for immutability (look at ItemModel for reference)
- Each feature: `data/` `domain/` `presentation/` separated
- Shared widgets only in `shared/widgets/`
- No business logic in UI widgets
- Files: snake_case | Classes: PascalCase

---

## What you need to build — the missing features

---

### FEATURE 1 — Outfit Builder (Backend + Flutter)

Users need to group multiple wardrobe items into named outfits (e.g., "Met Gala look", "Golf Sunday").

#### Backend
Create a new module `apps/api/src/modules/wardrobe/` with:

**MongoDB Schema** (`outfit.schema.ts`):
```typescript
Outfit {
  tenantId: string          // required, indexed
  name: string              // required
  description?: string
  itemIds: string[]         // array of Item._id references
  season?: string           // 'spring_summer' | 'fall_winter' | 'all_season'
  occasion?: string         // free text, e.g. "formal", "casual", "sport"
  photos?: string[]         // optional cover photos
  createdBy: string
  createdAt: Date
  updatedAt: Date
}
```

**Endpoints** (`wardrobe.controller.ts`):
```
POST   /wardrobe/outfits              → create outfit (OWNER, MANAGER)
GET    /wardrobe/outfits              → list all outfits for tenant
GET    /wardrobe/outfits/:id          → get outfit with populated items
PUT    /wardrobe/outfits/:id          → update outfit (OWNER, MANAGER)
DELETE /wardrobe/outfits/:id          → delete outfit (OWNER)
POST   /wardrobe/outfits/:id/items    → add item to outfit (OWNER, MANAGER)
DELETE /wardrobe/outfits/:id/items/:itemId → remove item from outfit (OWNER, MANAGER)
```

Rules:
- All queries scoped by `tenantId` from JWT (never return another tenant's data)
- On `GET /wardrobe/outfits/:id`, populate item details (name, photos[0], category, attributes.type, attributes.cleaningStatus)
- Log all mutations to `AuditService` with `entityType: 'outfit'`
- Validate that `itemIds` belong to the same `tenantId` before saving

#### Flutter
New files in `apps/mobile/lib/features/wardrobe/`:

- `data/outfit_model.dart` — Freezed model with `id`, `name`, `description`, `itemIds`, `season`, `occasion`, `photos`, `createdAt`
- `data/outfit_repository.dart` — CRUD calls to `/wardrobe/outfits` using existing Dio client
- `domain/outfit_notifier.dart` — `AsyncNotifier<List<OutfitModel>>` following the same pattern as `wardrobe_notifier.dart`
- `presentation/outfit_list_screen.dart` — List of outfits, each as a horizontal strip showing the first 3 item thumbnails
- `presentation/outfit_detail_screen.dart` — Shows all items in the outfit as a horizontal scroll, with a button to view each item detail
- `presentation/create_outfit_screen.dart` — Form: name + description + season + occasion, then a multi-select list of the user's wardrobe items to add

Register routes in `app_router.dart`:
```dart
GoRoute(path: '/wardrobe/outfits', builder: (_, __) => const OutfitListScreen()),
GoRoute(path: '/wardrobe/outfits/new', builder: (_, __) => const CreateOutfitScreen()),
GoRoute(path: '/wardrobe/outfits/:id', builder: (context, state) => OutfitDetailScreen(outfitId: state.pathParameters['id']!)),
```

Add an "Outfits" button or tab to the existing `WardrobeScreen` to navigate to `/wardrobe/outfits`.

---

### FEATURE 2 — Dry Cleaning History (Backend + Flutter)

Track every time an item was sent to dry cleaning and when it was returned.

#### Backend
Add to the existing wardrobe module:

**MongoDB Schema** (`dry-cleaning-record.schema.ts`):
```typescript
DryCleaningRecord {
  tenantId: string          // required, indexed
  itemId: string            // required, indexed
  sentDate: Date            // required
  returnedDate?: Date       // null = still at cleaner
  cleanerName?: string
  cost?: number
  currency?: string         // default 'USD'
  notes?: string
  createdBy: string
  createdAt: Date
}
```

**Endpoints**:
```
POST /wardrobe/dry-cleaning/:itemId          → create record (OWNER, MANAGER)
GET  /wardrobe/dry-cleaning/:itemId          → list history for item
PUT  /wardrobe/dry-cleaning/:recordId/return → mark as returned (set returnedDate = now, update item attributes.cleaningStatus = 'clean')
```

On `PUT .../return`:
1. Set `returnedDate = new Date()`
2. Call `InventoryService.update()` to set `attributes.cleaningStatus = 'clean'` on the item
3. Log to `AuditService` with `action: 'wardrobe.dry_cleaning.returned'`

#### Flutter
- `data/dry_cleaning_model.dart` — Freezed model
- `domain/dry_cleaning_notifier.dart` — loads records for a specific `itemId`
- `presentation/dry_cleaning_history_sheet.dart` — `DraggableScrollableSheet` showing the history timeline for one item, with a "Mark as returned" button on the most recent open record

Add a "Dry Cleaning History" button in the item detail screen when `item.category == 'wardrobe'`. Check `item.attributes['cleaningStatus'] == 'at_dry_cleaner'` to show/highlight the button.

---

### FEATURE 3 — Season filter in WardrobeScreen (Flutter only)

The `season` filter is already defined in `WardrobeAttributes.seasons` and stored in `attributes.season` but the `WardrobeScreen` does not expose it as a filter.

**Change** `apps/mobile/lib/features/wardrobe/presentation/wardrobe_screen.dart`:

1. Add a third `_FiltersRow` with these options:
```dart
static const Map<String, String> _seasonFilters = {
  'all': 'All Seasons',
  'spring_summer': 'Spring / Summer',
  'fall_winter': 'Fall / Winter',
  'all_season': 'All Season',
};
```

2. Add `String _selectedSeason = 'all'` state variable

3. Update `_applyFilters()` to also check:
```dart
final matchesSeason = _selectedSeason == 'all' || attrs.season == _selectedSeason;
return matchesType && matchesCleaning && matchesSeason;
```

No backend changes needed. This is purely frontend filtering on already-loaded data.

---

### FEATURE 4 — Wardrobe Stats endpoint (Backend + Flutter)

#### Backend
Add to wardrobe controller:

```
GET /wardrobe/stats
```

Response shape:
```typescript
{
  totalItems: number,
  byType: { clothing: number, footwear: number, accessories: number, jewelry_watches: number, unknown: number },
  byCleaning: { clean: number, needs_cleaning: number, at_dry_cleaner: number, unknown: number },
  bySeason: { spring_summer: number, fall_winter: number, all_season: number, unknown: number },
  outfitsCount: number,
  itemsWithOutfits: number
}
```

Implementation: use MongoDB aggregation pipeline on items with `category: 'wardrobe'` and `tenantId` filter. Cache in Redis with TTL of 5 minutes (inject existing `RedisService`).

Roles allowed: OWNER, MANAGER.

#### Flutter
Add a stats summary bar at the top of `WardrobeScreen` (above the filter rows), showing:
- Total items
- Items needing cleaning (amber badge)
- Items at dry cleaner (blue badge)
- Outfits count

Use a `Row` of small `_StatChip` widgets. Load via a separate `wardrobeStatsProvider` (simple `FutureProvider`). Show nothing (hide the row) while loading or on error — don't block the main grid.

---

## File structure summary for new files

```
apps/api/src/modules/wardrobe/
  wardrobe.module.ts
  wardrobe.controller.ts
  wardrobe.service.ts
  schemas/
    outfit.schema.ts
    dry-cleaning-record.schema.ts
  dto/
    create-outfit.dto.ts
    update-outfit.dto.ts
    create-dry-cleaning.dto.ts

apps/mobile/lib/features/wardrobe/
  data/
    outfit_model.dart           (Freezed)
    outfit_model.freezed.dart   (generated)
    outfit_model.g.dart         (generated)
    dry_cleaning_model.dart     (Freezed)
    dry_cleaning_model.freezed.dart
    dry_cleaning_model.g.dart
    outfit_repository.dart
    dry_cleaning_repository.dart
  domain/
    outfit_notifier.dart
    dry_cleaning_notifier.dart
  presentation/
    outfit_list_screen.dart
    outfit_detail_screen.dart
    create_outfit_screen.dart
    dry_cleaning_history_sheet.dart
```

---

## Reference files (read these before writing code)

These files show the exact patterns to follow:

| What to learn | File to read |
|---|---|
| Item schema pattern | `apps/api/src/modules/inventory/schemas/item.schema.ts` |
| Controller pattern with guards/audit | `apps/api/src/modules/inventory/inventory.controller.ts` |
| Service pattern | `apps/api/src/modules/inventory/inventory.service.ts` |
| NestJS module wiring | `apps/api/src/modules/inventory/inventory.module.ts` |
| Freezed model pattern | `apps/mobile/lib/features/inventory/data/models/item_model.dart` |
| Notifier pattern | `apps/mobile/lib/features/wardrobe/domain/wardrobe_notifier.dart` |
| Repository pattern | look at `item_repository_provider.dart` and `search_repository_provider.dart` in inventory |
| Existing WardrobeAttributes | `apps/mobile/lib/features/wardrobe/data/models/wardrobe_attributes.dart` |
| Router registration | `apps/mobile/lib/core/router/app_router.dart` |

---

## Do NOT do

- Do not create a separate `wardrobe` category in the item schema — it already exists
- Do not duplicate the item CRUD endpoints — reuse `/items` with `category=wardrobe`
- Do not use `any` types in TypeScript
- Do not put business logic in Flutter widgets
- Do not skip audit logging on mutations
- Do not forget `tenantId` scoping on every backend query
- Do not use `var` in Dart — use explicit types or `final`
