# Estate Orchestrator — Spec-Driven Design Document

## Overview

**Feature name**: Estate Orchestrator  
**App**: Vaulted (premium home inventory management for ultra-high-net-worth families)  
**Status**: Spec approved, pending implementation  
**Priority phases**: Backend CRUD → AI Pipeline → Notifications → Flutter

### What it does

The Owner or Manager types (or speaks) a natural-language command. The AI parses intent, retrieves relevant items from inventory, and generates a structured operational work plan. Each plan contains task groups assigned to specific staff members. Staff receive a push notification and follow a visual step-by-step guide — room photo → section photo with bounding box highlight → item photo — to execute each task. Owners see real-time progress.

### Example commands

- "Prepare the dining room for a formal dinner for 8 this Saturday"
- "Pack for the Aspen trip next week"
- "Move the wine collection from the basement to the Miami property"
- "What needs maintenance in the living room before the visit?"

---

## Existing codebase context

### Tech stack
- Backend: NestJS + TypeScript, MongoDB (Mongoose), PostgreSQL (TypeORM), Redis
- Mobile: Flutter + Riverpod, Freezed models, go_router
- AI: Gemini 2.5 Flash via `GOOGLE_GENAI_API_KEY`, embeddings via `text-embedding-004`
- Notifications: Firebase FCM + Resend email

### Key existing modules to integrate with
| Module | Path | How Orchestrator uses it |
|---|---|---|
| `inventory` | `apps/api/src/modules/inventory/` | Direct Mongoose query to `itemModel` + pgvector `item_embeddings` |
| `properties` | `apps/api/src/modules/properties/` | Traversal of `property.floors[].rooms[].sections[]` to resolve section photos and bounding boxes |
| `ai/shared` | `apps/api/src/modules/ai/shared/` | Imports `AiSharedModule` (GeminiClient, EmbeddingService, AiCostLoggerService) |
| `ai/chat` | `apps/api/src/modules/ai/chat/` | Reference implementation for RAG pipeline and Gemini JSON output pattern |
| `notifications` | `apps/api/src/modules/notifications/` | Injects `NotificationsService`, uses `sendPush()` and `notifyTenantRoles()` |
| `audit` | `apps/api/src/modules/audit/` | Logs every state change via `AuditService.log()` |
| `users` | `apps/api/src/modules/users/` | Validates assignee roles; Flutter staff picker reuses `GET /users` |
| `presence` | `apps/api/src/modules/presence/` | Reference pattern for new `OrchestratorGateway` (WebSocket) |

### Existing item location fields (already in ItemModel)
```
roomId, roomName, sectionId, sectionCode, sectionFurnitureName,
sectionPhoto, sectionBoundingBox { x, y, width, height }, locationDetail
```

### Existing Flutter conventions
- Feature structure: `data/ domain/ presentation/` inside `apps/mobile/lib/features/`
- Models: Freezed + json_serializable, snake_case files, PascalCase classes
- State: Riverpod `AsyncNotifier`, providers in `_provider.dart` files
- Navigation: go_router in `apps/mobile/lib/core/router/app_router.dart`
- First-load skeleton rule: show skeleton until `_initialLoadCompleted = true`
- No `@nestjs/swagger` decorators — not installed, breaks build

---

## Data Models

### MongoDB — new collection `orchestrator_plans`

File: `apps/api/src/modules/orchestrator/schemas/orchestrator-plan.schema.ts`

```typescript
OrchestratorPlan
  _id                   ObjectId
  tenantId              string          // required, indexed
  title                 string          // required, max 200, AI-generated or user-edited
  originalCommand       string          // required, max 2000, raw NL input
  commandType           enum: 'prepare' | 'pack' | 'move' | 'inspect' | 'general'
  targetDate            Date?           // extracted from command
  targetPropertyId      string?         // scoping hint
  targetRoomId          string?         // scoping hint
  destinationPropertyId string?         // for move commands
  status                enum: 'draft' | 'published' | 'in_progress' | 'completed' | 'cancelled'
  aiSummary             string          // 1-2 sentence plain-English description
  taskGroups            OrchestratorTaskGroup[]
  createdBy             string          // userId
  publishedAt           Date?
  completedAt           Date?
  cancelledAt           Date?
  createdAt / updatedAt                 // timestamps: true

OrchestratorTaskGroup  (_id: false)
  groupId               string          // uuid v4
  title                 string          // e.g. "Set dining table"
  assignedUserId        string?
  assignedUserName      string?         // denormalized
  status                enum: 'pending' | 'in_progress' | 'completed'
  steps                 OrchestratorStep[]
  startedAt             Date?
  completedAt           Date?

OrchestratorStep  (_id: false)
  stepId                string          // uuid v4
  itemId                string          // MongoDB ObjectId as string
  itemName              string          // denormalized
  itemCategory          string          // denormalized
  itemPhoto             string?         // first photo URL, denormalized
  roomId                string?
  roomName              string?         // denormalized
  roomPhoto             string?         // room overview photo if available
  sectionId             string?
  sectionPhoto          string?         // section.photo URL from RoomSection
  sectionCode           string?
  sectionFurnitureName  string?
  boundingBox           BoundingBox?    // { x, y, width, height } — reuses existing sub-schema
  instruction           string          // AI-written imperative sentence for this item
  status                enum: 'pending' | 'done' | 'skipped' | 'orphaned'
  completedByUserId     string?
  completedAt           Date?
  note                  string?         // staff note on completion
  completionPhotoUrl    string?         // optional photo taken by staff on completion
```

Indexes:
```
{ tenantId: 1, status: 1 }
{ tenantId: 1, createdAt: -1 }
{ tenantId: 1, 'taskGroups.assignedUserId': 1 }
```

### PostgreSQL — minimal additions

Extend `NotificationType` union in `notification-log.entity.ts`:
```typescript
'orchestrator_assigned' | 'orchestrator_completed'
```

Add two boolean columns to `notification-preference.entity.ts`:
```typescript
orchestratorAssigned: boolean  // default true
orchestratorCompleted: boolean // default true
```

No new PostgreSQL table needed. The plan lives entirely in MongoDB.

---

## API Contract

All endpoints under `apps/api/src/modules/orchestrator/`. Follow existing conventions: global JWT auth guard, `@Roles()` decorator per endpoint, responses through `ResponseInterceptor`.

### POST /orchestrator/parse
**Purpose**: Submit NL command → AI parses + RAG retrieves → returns draft plan. Does NOT persist.  
**Roles**: OWNER, MANAGER

Request body `ParseCommandDto`:
```typescript
command       string   // required, max 2000
propertyId?   string
targetDate?   string   // ISO-8601 hint
```

Response `ParsedPlanDto`:
```typescript
commandType             string
title                   string
aiSummary               string
targetDate?             string
targetPropertyId?       string
destinationPropertyId?  string
taskGroups: Array<{
  groupId     string
  title       string
  steps: Array<{
    stepId                string
    itemId                string
    itemName              string
    itemCategory          string
    itemPhoto?            string
    roomId?               string
    roomName?             string
    roomPhoto?            string
    sectionId?            string
    sectionPhoto?         string
    sectionFurnitureName? string
    boundingBox?          { x: number, y: number, width: number, height: number }
    instruction           string
  }>
}>
```

### POST /orchestrator/plans
**Purpose**: Persist a plan in `draft` status after owner review.  
**Roles**: OWNER, MANAGER  
**Request**: `CreatePlanDto` — mirrors `ParsedPlanDto` fields + `originalCommand`  
**Response**: Full `OrchestratorPlan` document

### GET /orchestrator/plans
**Purpose**: List plans for the tenant.  
**Roles**: OWNER, MANAGER (full list), STAFF (only plans where they have an assigned group)  
**Query params**: `status?`, `propertyId?`, `page?` (default 1), `limit?` (default 20)  
**Response**: `{ items: OrchestratorPlan[], total: number }`

### GET /orchestrator/plans/:id
**Purpose**: Single plan detail.  
**Roles**: OWNER, MANAGER (full), STAFF (plan filtered to their groups only)

### PATCH /orchestrator/plans/:id
**Purpose**: Edit plan metadata, reassign groups, or cancel.  
**Roles**: OWNER, MANAGER  
**Request** `UpdatePlanDto` (all optional):
```typescript
title?
targetDate?
status?      // only 'cancelled' settable here
taskGroups?  // Array<{ groupId, assignedUserId?, assignedUserName?, title? }>
```

### POST /orchestrator/plans/:id/publish
**Purpose**: Transition `draft` → `published`. Validates all groups have `assignedUserId`. Sends FCM push to all assignees.  
**Roles**: OWNER, MANAGER  
**Side effects**: `NotificationsService.sendPush()` for each unique assignee

### PATCH /orchestrator/plans/:planId/groups/:groupId/steps/:stepId/complete
**Purpose**: Staff marks a step done. Validates caller is the group's assignee. Cascades: step done → check group done → check plan done → send completion push to Owner/Manager.  
**Roles**: OWNER, MANAGER, STAFF  
**Request**:
```typescript
note?               string
completionPhotoUrl? string
```
**Response**: Updated plan (caller-scoped for staff)

### GET /orchestrator/plans/:id/progress
**Purpose**: Real-time progress summary for owner/manager dashboard.  
**Roles**: OWNER, MANAGER  
**Response**:
```typescript
{
  planId:          string
  status:          string
  totalSteps:      number
  completedSteps:  number
  percentComplete: number
  byGroup: Array<{
    groupId:          string
    title:            string
    assignedUserId:   string
    assignedUserName: string
    status:           string
    totalSteps:       number
    completedSteps:   number
  }>
}
```

### GET /orchestrator/plans/my-tasks
**Purpose**: All active plans where the calling user has assigned groups, filtered to their steps only.  
**Roles**: STAFF, MANAGER, OWNER

### WebSocket — namespace `/orchestrator`

New `OrchestratorGateway` following the identical pattern of `PresenceGateway`. Emits into `tenant:{tenantId}` rooms:

- `orchestrator:step_completed` — `{ planId, groupId, stepId, completedByUserId, percentComplete }`
- `orchestrator:plan_completed` — `{ planId, title }`

`OrchestratorService` emits these events by holding a reference to the Socket.io server instance via the gateway.

---

## AI Pipeline

### Two-stage architecture

**Stage 1 — Intent parsing & item retrieval**

1. Generate embedding from the command text using `EmbeddingService.generateEmbedding()` (existing `text-embedding-004`)
2. Run `vectorSearch()` against `item_embeddings` scoped to `tenantId` (and optionally `propertyId`) — retrieve top 30 candidates
3. Fetch full item documents. Traverse `property.floors[].rooms[].sections[]` to denormalize: `sectionPhoto`, `sectionBoundingBox`, `sectionCode`, `sectionFurnitureName`, `roomPhoto`
4. Build context block:
   ```
   - [itemId] ${name} (${category}) | location: ${propertyName} → ${roomName} → ${sectionCode}:${sectionFurnitureName}
   ```

**Stage 2 — Plan generation (Gemini 2.5 Flash)**

System prompt:
```
You are an estate operations planner for an ultra-high-net-worth household.
Your job is to convert a natural-language command into a structured operational
work plan that staff can execute item by item.
Always respond ONLY with valid JSON matching the schema provided.
Never fabricate items — only reference items from the provided inventory context.
Be concise and action-oriented. Each instruction should be a single imperative sentence.
```

User message:
```
Command: "${command}"
Target date hint: ${targetDate ?? 'not specified'}
Property scope: ${propertyName ?? 'all properties'}

Relevant inventory items:
${contextBlock}

Produce a JSON work plan:
{
  "commandType": "prepare|pack|move|inspect|general",
  "title": "short plan title (max 80 chars)",
  "aiSummary": "1-2 sentence description",
  "targetDate": "ISO-8601 date or null",
  "destinationPropertyId": "propertyId or null",
  "taskGroups": [
    {
      "groupId": "uuid-v4",
      "title": "group action label",
      "steps": [
        {
          "stepId": "uuid-v4",
          "itemId": "exact itemId from context",
          "instruction": "one imperative sentence"
        }
      ]
    }
  ]
}
Do not create more than 6 groups. Do not include items not present in the context.
```

Prompt tail varies by `commandType`:
- `prepare` → "Group by preparation phase: layout, setting, decoration."
- `pack` → "Group items by container or category for packing."
- `move` → "Create one group per destination room or container."
- `inspect` → "Group by urgency based on maintenance status. Include risk score in instruction if available."
- `general` → "Group by logical operational sequence."

**Post-processing** (in `OrchestratorAiService`):
- Parse JSON, strip markdown fences (same pattern as `AiMaintenanceService.parseGeminiResponse()`)
- For each step's `itemId`, look up and attach all denormalized location fields
- Validate UUIDs, generate any missing `groupId`/`stepId` with `uuid v4`
- Log AI cost via `AiCostLoggerService` with `feature: 'orchestrator'`

**Error handling**: If JSON parsing fails, return HTTP 422 with `{ error: 'AI plan generation failed — please rephrase your command.' }`. No silent fallback.

**Rate limiting**: Redis key `ai:orchestrator:ratelimit:${tenantId}`, default 10 commands/minute. Config: `AI_ORCHESTRATOR_RATE_LIMIT_PER_MINUTE`.

---

## Flutter Screens

All files under `apps/mobile/lib/features/orchestrator/`. Structure:

```
orchestrator/
  data/
    models/
      orchestrator_plan_model.dart
      orchestrator_plan_model.freezed.dart   (generated)
      orchestrator_plan_model.g.dart         (generated)
      parsed_plan_model.dart
    orchestrator_remote_data_source.dart
    orchestrator_remote_data_source_provider.dart
    orchestrator_repository.dart
    orchestrator_repository_provider.dart
  domain/
    orchestrator_list_notifier.dart          (AsyncNotifier<List<OrchestratorPlanModel>>)
    orchestrator_detail_notifier.dart        (AsyncNotifier<OrchestratorPlanModel?>)
    orchestrator_progress_notifier.dart      (AsyncNotifier<PlanProgressModel>)
    orchestrator_parse_notifier.dart         (AsyncNotifier<ParsedPlanModel?>)
  presentation/
    orchestrator_list_screen.dart
    orchestrator_new_command_screen.dart
    orchestrator_plan_review_screen.dart
    orchestrator_plan_detail_screen.dart
    orchestrator_task_group_screen.dart
    orchestrator_step_guide_screen.dart
    orchestrator_progress_dashboard_screen.dart
    orchestrator_assign_sheet.dart
```

### Screen descriptions

**`orchestrator_list_screen.dart`** — `/orchestrator`
- Tabbed: "My Tasks" (staff) and "All Plans" (owner/manager)
- Plan card: title, command type chip, status badge, progress bar, target date, staff count
- FAB "New Plan" visible for OWNER/MANAGER only

**`orchestrator_new_command_screen.dart`** — `/orchestrator/new`
- Large text input + mic button (`speech_to_text` package — placeholder in Phase 5, live in Phase 6)
- Property scope picker (dropdown of tenant properties)
- Target date picker
- "Generate Plan" CTA → `POST /orchestrator/parse` → navigate to review screen passing `ParsedPlanModel` as `extra`

**`orchestrator_plan_review_screen.dart`** — `/orchestrator/review`
- Receives `ParsedPlanModel` via `state.extra`
- Editable plan title
- Task groups list: drag-to-reorder, delete group, assign staff via `OrchestratorAssignSheet`
- Tap any step to preview visual guide
- "Save as Draft" → `POST /orchestrator/plans`
- "Save & Publish" → `POST /orchestrator/plans` + `POST /orchestrator/plans/:id/publish`

**`orchestrator_plan_detail_screen.dart`** — `/orchestrator/plans/:id`
- OWNER/MANAGER: full plan, progress bar, per-group progress rings, all task groups
- STAFF: only their assigned groups
- "Publish" button if status is `draft`
- "Cancel Plan" in overflow menu

**`orchestrator_task_group_screen.dart`** — `/orchestrator/plans/:planId/groups/:groupId`
- Ordered list of steps with status chips
- Tap step → navigate to `OrchestratorStepGuideScreen`
- Assignee name at top, progress indicator "3 / 7 steps done"

**`orchestrator_step_guide_screen.dart`** ⭐ — `/orchestrator/plans/:planId/groups/:groupId/steps/:stepId`

The core staff-facing screen. Three-panel `PageView`:

1. **Panel 1 — "Find the Room"**: Full-width room photo (`CachedNetworkImage`). Room name shown below.
2. **Panel 2 — "Find the Section"**: Section photo with `CustomPainter` bounding box overlay using `SectionBoundingBox` coordinates (same system already in codebase). Furniture name and section code shown.
3. **Panel 3 — "The Item"**: Item photo full-width. Item name, category, and AI instruction in a card below.

Bottom bar:
- "Mark Complete" button → `PATCH /orchestrator/plans/:planId/groups/:groupId/steps/:stepId/complete`
- Optional note text field
- Optional camera button for completion photo

On completion: auto-advances to next pending step, or pops back to `OrchestratorTaskGroupScreen` if group is done.

**`orchestrator_progress_dashboard_screen.dart`** — `/orchestrator/plans/:id/progress`
- OWNER/MANAGER only
- Overall percentage ring + per-staff progress bars with avatars
- Polls `GET /orchestrator/plans/:id/progress` every 5 seconds (fallback) or listens to `orchestrator:step_completed` WebSocket event
- Timeline list: completed steps with timestamp and staff name

**`orchestrator_assign_sheet.dart`** — bottom sheet
- Lists all active users with roles STAFF or MANAGER
- Single-select; returns selected user to caller

### Routes to add in `app_router.dart`

```dart
GoRoute(path: '/orchestrator', builder: (_, __) => const OrchestratorListScreen()),
GoRoute(path: '/orchestrator/new', builder: (_, __) => const OrchestratorNewCommandScreen()),
GoRoute(
  path: '/orchestrator/review',
  builder: (context, state) {
    final parsed = state.extra as ParsedPlanModel;
    return OrchestratorPlanReviewScreen(parsed: parsed);
  },
),
GoRoute(
  path: '/orchestrator/plans/:id',
  builder: (context, state) => OrchestratorPlanDetailScreen(
    planId: state.pathParameters['id']!,
  ),
),
GoRoute(
  path: '/orchestrator/plans/:planId/groups/:groupId',
  builder: (context, state) => OrchestratorTaskGroupScreen(
    planId: state.pathParameters['planId']!,
    groupId: state.pathParameters['groupId']!,
  ),
),
GoRoute(
  path: '/orchestrator/plans/:planId/groups/:groupId/steps/:stepId',
  builder: (context, state) => OrchestratorStepGuideScreen(
    planId: state.pathParameters['planId']!,
    groupId: state.pathParameters['groupId']!,
    stepId: state.pathParameters['stepId']!,
  ),
),
GoRoute(
  path: '/orchestrator/plans/:id/progress',
  builder: (context, state) => OrchestratorProgressDashboardScreen(
    planId: state.pathParameters['id']!,
  ),
),
```

---

## Implementation Phases

### Phase 1 — Backend CRUD (no AI, no notifications)

Files to create:
- `apps/api/src/modules/orchestrator/schemas/orchestrator-plan.schema.ts`
- `apps/api/src/modules/orchestrator/orchestrator.module.ts`
- `apps/api/src/modules/orchestrator/orchestrator.service.ts` — CRUD + `completeStep()` + `getProgress()`
- `apps/api/src/modules/orchestrator/orchestrator.controller.ts` — all endpoints except `POST /parse`
- `apps/api/src/modules/orchestrator/dto/create-plan.dto.ts`
- `apps/api/src/modules/orchestrator/dto/update-plan.dto.ts`
- `apps/api/src/modules/orchestrator/dto/complete-step.dto.ts`

Register `OrchestratorModule` in `apps/api/src/app.module.ts`.

Key business logic in `OrchestratorService.completeStep()`:
- Validate caller is the group's assignee (or OWNER/MANAGER)
- Mark step `done`
- If all steps in group done → mark group `completed`, set `completedAt`
- If all groups done → mark plan `completed`, set `completedAt`

**Dependencies**: None — standalone module.

---

### Phase 2 — AI Pipeline

Files to create:
- `apps/api/src/modules/orchestrator/orchestrator-ai.service.ts` — `parseCommand()` method
- `apps/api/src/modules/orchestrator/dto/parse-command.dto.ts`

Add `POST /orchestrator/parse` to controller calling `OrchestratorAiService.parseCommand()`.

`parseCommand()` must:
1. Call `EmbeddingService.generateEmbedding(command)`
2. Query pgvector `item_embeddings` scoped to `tenantId`
3. Fetch full items + traverse property hierarchy to get `sectionPhoto`, `sectionBoundingBox`, `roomPhoto`
4. Build context block
5. Call Gemini with system + user prompt
6. Parse + validate JSON response
7. Denormalize all location fields into each step
8. Log cost via `AiCostLoggerService`

**Dependencies**: Phase 1 complete.

---

### Phase 3 — Notifications + WebSocket

Files to create:
- `apps/api/src/modules/orchestrator/orchestrator.gateway.ts` — WebSocket gateway, namespace `/orchestrator`

Files to modify:
- `apps/api/src/modules/notifications/notification-log.entity.ts` — add two types to union
- `apps/api/src/modules/notifications/notification-preference.entity.ts` — add two columns
- `apps/api/src/modules/notifications/dto/update-notification-preference.dto.ts` — add two fields
- `apps/api/src/modules/orchestrator/orchestrator.service.ts` — inject `NotificationsService`, emit WebSocket events

`publishPlan()` side effects:
- For each unique `assignedUserId` → `notificationsService.sendPush({ type: 'orchestrator_assigned', data: { planId, planTitle } })`

`completeStep()` side effects when plan completes:
- `notificationsService.notifyTenantRoles([Role.OWNER, Role.MANAGER], { type: 'orchestrator_completed' })`
- Emit `orchestrator:plan_completed` via gateway

**Dependencies**: Phase 1 complete.

---

### Phase 4 — Flutter Data + Domain Layer

Files to create:
- `orchestrator_plan_model.dart` — Freezed model with all plan fields
- `parsed_plan_model.dart` — Lighter model for review screen transit
- `orchestrator_remote_data_source.dart` — all API calls
- `orchestrator_repository.dart` — wraps data source
- Four Riverpod notifiers: list, detail, progress, parse
- Provider files following existing `_provider.dart` convention

**Dependencies**: Phase 1 + Phase 2 backend endpoints working.

---

### Phase 5 — Flutter Presentation (staff-first order)

Implementation order:
1. `orchestrator_step_guide_screen.dart` — highest-value screen
2. `orchestrator_task_group_screen.dart`
3. `orchestrator_list_screen.dart` with My Tasks tab
4. `orchestrator_plan_detail_screen.dart`
5. `orchestrator_new_command_screen.dart` (mic as placeholder snackbar)
6. `orchestrator_plan_review_screen.dart`
7. `orchestrator_progress_dashboard_screen.dart`
8. `orchestrator_assign_sheet.dart`
9. Add all routes to `app_router.dart`
10. Add "Orchestrator" entry to dashboard navigation

**Dependencies**: Phase 4 complete.

---

### Phase 6 — Voice Input

- Integrate `speech_to_text` Flutter package
- Replace mic button placeholder in `orchestrator_new_command_screen.dart` with live transcription
- No backend changes

**Dependencies**: Phase 5 complete.

---

## Integration Points Summary

| Existing module | Integration type | Notes |
|---|---|---|
| `inventory/` | Direct Mongoose + pgvector read | No new endpoints on inventory module |
| `properties/` | Direct Mongoose read | Traverse floors → rooms → sections for photo/bbox resolution |
| `ai/shared/` | Import `AiSharedModule` | No changes to AI shared module |
| `ai/chat/` | Reference only | Pattern for RAG pipeline and Gemini JSON output |
| `notifications/` | Inject `NotificationsService` | FCM deep-link data: `{ type, planId, planTitle }` |
| `audit/` | Inject `AuditService` | Events: plan.created, plan.published, step.completed, plan.completed, plan.cancelled |
| `users/` | Inject `UsersService` | Validate assignee roles on publish |
| `presence/` | Pattern reference for gateway | New `/orchestrator` WebSocket namespace |
| `movements/` | Future integration | After plan `move` completes, prompt to create Movement record |

---

## Edge Cases

| Case | Handling |
|---|---|
| Command yields zero items | AI returns plan with `itemCount: 0`; UI shows "No items found for this command" |
| Assignee deactivated mid-plan | Tasks remain; Owner receives push notification |
| Item deleted after plan created | Step status set to `orphaned`; plan continues |
| Multiple active plans with overlapping items | Plans are independent; no lock needed (operational, not transactional) |
| Cross-property move command | `destinationPropertyId` set on plan; future Movement record integration |
| All groups unassigned on publish attempt | Validation error — must assign at least one group |
| Gemini returns invalid JSON | HTTP 422 returned; no silent fallback |
| Voice transcription fails | Text input fallback shown immediately |
