---
name: kb-maintenance-rule
description: Mandatory project rule — keep HELP_KNOWLEDGE_BASE and SCREEN_CONTEXT in sync with screen UI text
metadata:
  type: feedback
---

# Vaulted Guide KB Maintenance Rule (Mandatory)

**Rule:** Whenever a Flutter screen is **added or modified**, update the corresponding section of `HELP_KNOWLEDGE_BASE` in `apps/api/src/modules/ai/help/ai-help.service.ts`.

**Why:** The AI Help system uses the KB to provide contextual guidance. If UI text doesn't match KB, help answers will be inaccurate or miss key terms.

## What to Sync
- AppBar title
- Tab names / section labels
- Button labels and tooltips
- Chip/filter labels
- Form field hints
- Empty state messages
- Error state messages
- Role-specific restrictions (e.g., "Owner/Manager only")

## File Locations

**KB Content:** `apps/api/src/modules/ai/help/ai-help.service.ts`
- **HELP_KNOWLEDGE_BASE** (~line 130-800): Chunks organized by feature (chunk_id)
- **SCREEN_CONTEXT** (~line 936-956): Human-readable context for each screen
- **SCREEN_CHUNK_BOOST** (~line 959-978): Which chunks to prioritize for each screen

## Example: Properties Screen

**Current KB entry (line 946):**
```typescript
properties: 'The user is managing properties, floors, rooms, or room sections.',
```

**Boost chunks (line 968):**
```typescript
properties: ['properties-rooms'],
```

**If you modify property_detail_screen and change:**
- "FLOORS & ROOMS" label → update KB term
- "Add floor" button → ensure KB explains this action
- "No floors added yet" message → update in KB

## Property Detail Screen Check

**Current state:** 
- Line 451: `"FLOORS & ROOMS"` label ✓ matches KB (`floor(s)`, `room(s)`)
- Line 475: `"Add floor"` button ✓ matches KB
- Line 498: `"No floors added yet"` ✓ covered by KB empty-state guidance
- Line 1705: `"Add room"` ✓ covered
- Line 713: `"X item(s) pending location"` ✓ covered by "unlocated items" KB section

**Action after UI changes:** Always check lines 120-800 and 946 in ai-help.service.ts and update if any labels changed.

