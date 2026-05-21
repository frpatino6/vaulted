# AI Help Chat ("Vaulted Guide") — Spec-Driven Design Document

## Overview

**Feature name**: AI Help Chat — Vaulted Guide  
**App**: Vaulted (premium home inventory management for ultra-high-net-worth families)  
**Status**: Spec approved, pending implementation  
**Priority phases**: Backend Core → System Prompt → Flutter UI → Navigation integration

### What it does

Any authenticated user — regardless of role — can open an in-app AI chat and ask questions about **how to use Vaulted**. The assistant answers with step-by-step instructions, explains features, and adapts its response to the screen the user is currently on.

This is distinct from the existing `ai_chat` feature, which performs RAG over the user's own inventory data. Vaulted Guide's knowledge base is the **app's documentation and feature set**, not the tenant's items.

### Example queries

- "How do I add a new item to my inventory?"
- "Where can I see all items currently on loan?"
- "How do I invite a new staff member?"
- "What does the AI scan feature do?"
- "How do I create an outfit in the wardrobe module?"
- "How do I file an insurance claim?"
- "What's the difference between Manager and Auditor roles?"

---

## Existing codebase context

### Tech stack
- Backend: NestJS + TypeScript, MongoDB (Mongoose), PostgreSQL (TypeORM), Redis
- Mobile: Flutter + Riverpod, Freezed models, go_router
- AI: Gemini 2.5 Flash via `GOOGLE_GENAI_API_KEY`
- Auth: JWT (access 15 min / refresh 7 days), `@nestjs/passport`

### Key existing modules to integrate with
| Module | Path | How Help Chat uses it |
|---|---|---|
| `ai/shared` | `apps/api/src/modules/ai/shared/` | Imports `AiSharedModule` for `GeminiClient` and `AiCostLoggerService` |
| `ai/chat` | `apps/api/src/modules/ai/chat/` | Reference implementation for Redis session pattern and Gemini call pattern |
| `ai` (root) | `apps/api/src/modules/ai/ai.module.ts` | Add `AiHelpModule` to its `imports` array |
| `audit` | `apps/api/src/modules/audit/` | Cost logging via `AiCostLoggerService` (already wraps audit) |

### Existing AI shared services (reuse as-is)
| Service | File | Usage |
|---|---|---|
| `GeminiClient` | `apps/api/src/modules/ai/shared/gemini.client.ts` | `chat(systemPrompt, history, userMessage)` → `{ text, inputTokens, outputTokens }` |
| `AiCostLoggerService` | `apps/api/src/modules/ai/shared/ai-cost-logger.service.ts` | `log({ tenantId, userId, feature, model, inputTokens, outputTokens, totalTokens })` |
| `AiSharedModule` | `apps/api/src/modules/ai/shared/ai-shared.module.ts` | Global module — import once, no extra providers needed |

### Redis session pattern (clone from `ai-chat.service.ts`)
```typescript
// Rate limit key
const rateLimitKey = `ai:help:ratelimit:${tenantId}`;
// Session key
const sessionKey = `ai:help:session:${sessionId}`;
// TTL: 3600s, max 15 turns per session
```

### Existing Flutter conventions
- Feature structure: `data/ domain/ presentation/` inside `apps/mobile/lib/features/`
- Models: Freezed + json_serializable, snake_case files, PascalCase classes
- State: Riverpod `Notifier<State>` with `copyWith`, providers in `_provider.dart` files
- Navigation: go_router in `apps/mobile/lib/core/router/app_router.dart`
- First-load skeleton rule: show skeleton until `_initialLoadCompleted = true`
- Reference UI: `apps/mobile/lib/features/ai_chat/presentation/chat_screen.dart`

---

## Differences vs existing `ai_chat`

| Aspect | `ai_chat` (inventory RAG) | `ai_help_chat` (Vaulted Guide) |
|---|---|---|
| Knowledge base | User's items (pgvector) | App documentation (static system prompt) |
| Vector search | Yes — pgvector KNN | No — pure LLM |
| Allowed roles | OWNER, MANAGER, AUDITOR | All roles (including STAFF, GUEST) |
| Response content | Text + item cards | Text only (markdown) |
| Context input | `propertyId` (optional) | `currentScreen` (optional) |
| Rate limit | 20 req/min | 30 req/min |
| Session max turns | 10 | 15 |

---

## Backend

### New files

```
apps/api/src/modules/ai/help/
├── ai-help.module.ts
├── ai-help.service.ts
├── ai-help.controller.ts
└── dto/
    └── help-request.dto.ts
```

### Module registration

**File to modify**: `apps/api/src/modules/ai/ai.module.ts`

Add `AiHelpModule` to the `imports` array (same pattern as `AiChatModule`, `AiVisionModule`, etc.).

---

### DTO

**File**: `apps/api/src/modules/ai/help/dto/help-request.dto.ts`

```typescript
import { IsString, IsOptional, MaxLength } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class HelpRequestDto {
  @ApiProperty({ description: 'User question about how to use the app', maxLength: 1000 })
  @IsString()
  @MaxLength(1000)
  query: string;

  @ApiPropertyOptional({ description: 'Session ID for multi-turn conversation' })
  @IsOptional()
  @IsString()
  sessionId?: string;

  @ApiPropertyOptional({
    description: 'Current screen name for contextual help',
    example: 'inventory',
    enum: [
      'dashboard', 'inventory', 'item_detail', 'add_item',
      'movements', 'wardrobe', 'maintenance', 'insurance',
      'properties', 'users', 'ai_scan', 'ai_chat', 'reports', 'settings',
    ],
  })
  @IsOptional()
  @IsString()
  currentScreen?: string;
}
```

---

### Controller

**File**: `apps/api/src/modules/ai/help/ai-help.controller.ts`

```typescript
@ApiTags('AI — Help Chat')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)           // All authenticated roles — no RolesGuard
@Controller('ai/help')
export class AiHelpController {
  constructor(private readonly aiHelpService: AiHelpService) {}

  @Post('chat')
  @ApiOperation({ summary: 'Ask the Vaulted Guide how to use the app' })
  @ApiResponse({ status: 201, description: 'Help answer returned' })
  @ApiResponse({ status: 429, description: 'Rate limit exceeded' })
  async chat(
    @Body() dto: HelpRequestDto,
    @CurrentUser() user: JwtPayload,
  ): Promise<{ answer: string; sessionId: string; suggestions: string[] }> {
    return this.aiHelpService.chat(user.tenantId, user.sub, dto);
  }
}
```

---

### Service

**File**: `apps/api/src/modules/ai/help/ai-help.service.ts`

#### Core flow
```
1. Rate limit check — Redis INCR/EXPIRE (30 req/min per tenant)
2. Load session history — Redis GET (max 15 turns)
3. Build system prompt — static app docs + currentScreen context injection
4. Call GeminiClient.chat(systemPrompt, history, query)
5. Generate follow-up suggestions (static map by screen or from model)
6. Save turn to Redis session (TTL 3600s)
7. Log tokens via AiCostLoggerService
8. Return { answer, sessionId, suggestions }
```

#### Session shape (Redis JSON array)
```typescript
interface HelpSessionTurn {
  role: 'user' | 'model';
  content: string;
}
// Key: ai:help:session:{sessionId}
// Max turns: 15 (trim oldest when exceeded)
// TTL: 3600s (reset on each turn)
```

#### Rate limit
```typescript
// Key: ai:help:ratelimit:{tenantId}
// Limit: 30 requests per 60 seconds
// On exceed: throw HttpException('Rate limit exceeded', 429)
```

#### System prompt structure
```
You are Vaulted Guide, the in-app AI assistant for Vaulted — a premium home inventory
management app for high-net-worth families. Your sole purpose is to help users
understand how to use the Vaulted app.

RULES:
- Answer ONLY questions about how to use Vaulted features.
- If asked about the user's actual inventory items, redirect: "For questions about
  your items, use the AI Chat feature in the navigation menu."
- Be concise, friendly, and use numbered steps for procedural instructions.
- Respond in the same language the user writes in.

CURRENT CONTEXT:
Screen: {currentScreen || 'not specified'}

APP FEATURES DOCUMENTATION:
[Full inline documentation — see "Knowledge Base" section below]
```

---

### Knowledge base content (system prompt body)

The system prompt inlines documentation for every Vaulted feature. Content is static — no DB query. The service builds this string at startup and caches it in memory.

#### Sections to include

```
## Dashboard
- Shows KPI cards: total items, total estimated value, items on loan, upcoming maintenance
- Property switcher at the top to filter by property
- Recent activity feed

## Properties & Rooms
- How to add a property (name, address, type)
- How to add floors and rooms within a property
- Room types: bedroom, living room, kitchen, basement, garage, storage, etc.

## Inventory (Items)
- How to add an item manually (category, name, room, valuation, photos up to 10, serial number)
- How to use AI Scan to catalog an item from a photo
- How to edit an item
- Item statuses: active, on loan, under repair, in storage, disposed
- How to search and filter items (by category, status, room, property)
- How to view item movement history
- QR codes: each item has a unique QR; tap to view item from any device

## Movements (Loans & Transfers)
- How to loan an item (select item → set borrower name, expected return date)
- How to mark a loaned item as returned
- How to transfer an item to another room or property
- Movement history: full log of every item move
- Draft → Active → Completed workflow

## Wardrobe
- Wardrobe is a specialized view for clothing, footwear, accessories, jewelry, watches
- How to view your closet grid
- How to create an outfit (select items, name the outfit, add occasion tags)
- How to log a dry cleaning record (item, date, provider, cost)
- Stats bar: total wardrobe items, outfits created, dry cleaning count

## Maintenance
- How to create a maintenance record (item, scheduled date, type, notes)
- Maintenance types: cleaning, inspection, repair, service, calibration, other
- How to update maintenance status (pending → completed / cancelled)
- AI risk scoring: the system automatically flags high-risk items for maintenance

## Insurance
- How to add an insurance policy (insurer, policy number, coverage type, premium, dates)
- How to link items to a policy
- Coverage gap analysis: AI identifies underinsured items
- How to draft an insurance claim letter with AI assistance

## AI Scan (Vision)
- Open AI Scan from the + button or navigation
- Point camera at any item → AI identifies category, brand, estimated value
- Review and confirm AI suggestions before saving
- Supports invoice scanning to extract purchase details

## AI Chat (Inventory Assistant)
- Natural language search over your inventory: "Where is my Hermès bag?"
- Context-aware: can filter by property
- Returns matching items with photos and location
- Access: Owner, Manager, Auditor roles

## Users & Roles
- How to invite a new user (email, assign role, assign property access)
- Roles:
  - Owner: full access, manages users
  - Manager: manages inventory, cannot see financial valuations
  - Staff: view/update assigned items only
  - Auditor: read-only, watermarked exports
  - Guest: temporary access with expiration date
- Property-scoped access: a staff member of Property A cannot see Property B

## Reports
- Export inventory as PDF or Excel
- Filtered exports by category, room, or property
- Watermarked exports for Auditor role

## Settings
- Notification preferences (push, email)
- MFA setup (TOTP authenticator app)
- Profile management

## QR Scanning
- Each item has a unique QR code
- Scan from the QR icon in any screen to jump directly to item detail
- Use for quick check-in/check-out during moves
```

---

### API contract

| Method | Path | Auth | Roles |
|---|---|---|---|
| `POST` | `/ai/help/chat` | JWT | All (Owner, Manager, Staff, Auditor, Guest) |

**Request body**:
```json
{
  "query": "How do I loan an item?",
  "sessionId": "optional-uuid-v4",
  "currentScreen": "movements"
}
```

**Success response** (`201`):
```json
{
  "success": true,
  "data": {
    "answer": "To loan an item in Vaulted:\n\n1. Go to **Movements** from the navigation menu.\n2. Tap the **+** button to create a new movement.\n3. Select the item you want to loan.\n4. Enter the borrower's name and expected return date.\n5. Tap **Confirm** to activate the loan.\n\nThe item status will change to **On Loan** automatically.",
    "sessionId": "abc123-uuid",
    "suggestions": [
      "How do I mark a loaned item as returned?",
      "Can I loan items to someone outside my family?",
      "How do I see all items currently on loan?"
    ]
  }
}
```

**Error responses**:
| Status | Scenario |
|---|---|
| `400` | `query` missing or exceeds 1000 chars |
| `401` | Missing or invalid JWT |
| `429` | Rate limit exceeded (30 req/min per tenant) |
| `500` | Gemini API error |

---

## Flutter

### New feature folder

```
apps/mobile/lib/features/ai_help_chat/
├── data/
│   ├── models/
│   │   ├── help_message_model.dart
│   │   ├── help_message_model.freezed.dart   (generated)
│   │   └── help_message_model.g.dart          (generated)
│   ├── ai_help_remote_data_source.dart
│   ├── ai_help_remote_data_source_provider.dart
│   ├── ai_help_repository.dart
│   └── ai_help_repository_provider.dart
├── domain/
│   ├── ai_help_notifier.dart
│   └── ai_help_state.dart
└── presentation/
    └── help_chat_screen.dart
```

---

### Data models (Freezed)

**File**: `apps/mobile/lib/features/ai_help_chat/data/models/help_message_model.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'help_message_model.freezed.dart';
part 'help_message_model.g.dart';

enum HelpMessageRole { user, assistant }

@freezed
class HelpMessageModel with _$HelpMessageModel {
  const factory HelpMessageModel({
    required String id,
    required HelpMessageRole role,
    required String content,
    @Default([]) List<String> suggestions,
    String? sessionId,
    DateTime? createdAt,
    @Default(false) bool isLoading,
  }) = _HelpMessageModel;

  factory HelpMessageModel.fromJson(Map<String, dynamic> json) =>
      _$HelpMessageModelFromJson(json);
}
```

---

### State

**File**: `apps/mobile/lib/features/ai_help_chat/domain/ai_help_state.dart`

```dart
class AiHelpState {
  const AiHelpState({
    this.messages = const [],
    this.sessionId,
    this.isLoading = false,
    this.error,
  });

  final List<HelpMessageModel> messages;
  final String? sessionId;
  final bool isLoading;
  final String? error;

  AiHelpState copyWith({
    List<HelpMessageModel>? messages,
    String? sessionId,
    bool? isLoading,
    String? error,
  }) => AiHelpState(
    messages: messages ?? this.messages,
    sessionId: sessionId ?? this.sessionId,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}
```

---

### Notifier

**File**: `apps/mobile/lib/features/ai_help_chat/domain/ai_help_notifier.dart`

```dart
class AiHelpNotifier extends Notifier<AiHelpState> {
  @override
  AiHelpState build() => const AiHelpState();

  Future<void> sendMessage(String query, {String? currentScreen}) async {
    // 1. Add user message immediately
    // 2. Add loading placeholder message
    // 3. Call repository.chat(query, sessionId, currentScreen)
    // 4. Replace placeholder with assistant message + suggestions
    // 5. On error: remove placeholder, set error in state
  }

  void clearSession() => state = const AiHelpState();
}

final aiHelpNotifierProvider =
    NotifierProvider<AiHelpNotifier, AiHelpState>(AiHelpNotifier.new);
```

---

### Remote data source

**File**: `apps/mobile/lib/features/ai_help_chat/data/ai_help_remote_data_source.dart`

```dart
class AiHelpRemoteDataSource {
  AiHelpRemoteDataSource(this._dio);
  final Dio _dio;

  Future<({String answer, String sessionId, List<String> suggestions})> chat({
    required String query,
    String? sessionId,
    String? currentScreen,
  }) async {
    final response = await _dio.post('ai/help/chat', data: {
      'query': query,
      if (sessionId != null) 'sessionId': sessionId,
      if (currentScreen != null) 'currentScreen': currentScreen,
    });
    final data = response.data['data'] as Map<String, dynamic>;
    return (
      answer: data['answer'] as String,
      sessionId: data['sessionId'] as String,
      suggestions: List<String>.from(data['suggestions'] ?? []),
    );
  }
}
```

---

### UI — HelpChatScreen

**File**: `apps/mobile/lib/features/ai_help_chat/presentation/help_chat_screen.dart`

**Widget**: `HelpChatScreen(String? currentScreen)` — ConsumerStatefulWidget

#### Layout

```
Scaffold
├── AppBar: "Vaulted Guide" title + clear button (if messages exist)
└── Body: Column
    ├── Expanded
    │   ├── _EmptyState (when no messages)
    │   └── ListView (message bubbles)
    └── _InputBar (fixed at bottom)
```

#### _EmptyState
- Icon: `Icons.auto_awesome` (or a shield icon)
- Title: "Vaulted Guide"
- Subtitle: "Ask me anything about how to use the app"
- Suggestion chips — context-aware grid:

| `currentScreen` | Suggestions shown |
|---|---|
| `inventory` | "How do I add an item?", "How do I scan with AI?", "How do I filter items?" |
| `movements` | "How do I loan an item?", "How do I mark a return?", "What is movement history?" |
| `wardrobe` | "How do I create an outfit?", "How do I log dry cleaning?", "What is the wardrobe module?" |
| `maintenance` | "How do I schedule maintenance?", "What is AI risk scoring?", "How do I mark maintenance done?" |
| `insurance` | "How do I add a policy?", "What is coverage gap analysis?", "How do I draft a claim?" |
| `users` | "How do I invite a user?", "What are the different roles?", "How do I change a user's role?" |
| *(default)* | "What can Vaulted do?", "How do I add a property?", "How do I invite someone?", "What roles exist?" |

#### _MessageBubble
- User messages: right-aligned, accent color background
- Assistant messages: left-aligned, surface variant background
- **Markdown rendering**: use `flutter_markdown` package to render assistant responses
  - Supports bold, numbered lists, bullet points (critical for step-by-step guides)
- Loading: `_LoadingDots` widget (same as `ai_chat`)
- After assistant message: suggestion chips row (tap to auto-send)

#### _SuggestionsRow
- Horizontal scroll of tappable suggestion chips
- Appears below each assistant message that includes suggestions
- Tap → calls `notifier.sendMessage(suggestion, currentScreen: widget.currentScreen)`

#### _InputBar
- Expandable TextField (1–4 lines)
- Hint: "Ask how to use Vaulted…"
- Send button disabled during `isLoading`

---

### Navigation integration

**File to modify**: `apps/mobile/lib/core/router/app_router.dart`

Add route:
```dart
GoRoute(
  path: '/help-chat',
  builder: (context, state) {
    final currentScreen = state.uri.queryParameters['screen'];
    return HelpChatScreen(currentScreen: currentScreen);
  },
),
```

**Access point — option A (recommended):** Floating "?" button on each main screen (Dashboard, Inventory, Movements, Wardrobe, Maintenance, Insurance):

```dart
floatingActionButton: FloatingActionButton.small(
  heroTag: 'help_fab',
  onPressed: () => context.push('/help-chat?screen=inventory'),
  child: const Icon(Icons.help_outline),
),
```

**Access point — option B:** Help icon in main AppBar (universal access).

Both options can coexist — FAB for screen-specific context, AppBar icon for general help.

---

## Implementation phases

| Phase | Deliverable | Files |
|---|---|---|
| 1 | Backend: DTO + service skeleton + controller | `ai/help/dto/help-request.dto.ts`, `ai-help.service.ts`, `ai-help.controller.ts`, `ai-help.module.ts` |
| 2 | Backend: Redis sessions + rate limiting | `ai-help.service.ts` (Redis logic) |
| 3 | Backend: System prompt + Gemini integration | `ai-help.service.ts` (knowledge base string + GeminiClient call) |
| 4 | Backend: Register module | `ai/ai.module.ts` |
| 5 | Flutter: Data layer | `help_message_model.dart`, data source, repository, providers |
| 6 | Flutter: Domain layer | `ai_help_state.dart`, `ai_help_notifier.dart` |
| 7 | Flutter: UI | `help_chat_screen.dart` |
| 8 | Flutter: Navigation | `app_router.dart` + FAB on main screens |

---

## Dependencies

### Backend
- No new npm packages — reuses `GeminiClient`, `ioredis`, `class-validator`

### Flutter
- `flutter_markdown`: add to `apps/mobile/pubspec.yaml` if not already present
  - Check: `grep -r "flutter_markdown" apps/mobile/pubspec.yaml`
  - Add if missing: `flutter_markdown: ^0.7.3` (or latest)

---

## Verification

### Backend
```bash
# 1. Basic query
curl -X POST https://api-vaulted.casacam.net/ai/help/chat \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query": "How do I add an item?", "currentScreen": "inventory"}'
# Expected: 201 with answer containing numbered steps

# 2. Multi-turn (use sessionId from previous response)
curl -X POST ... -d '{"query": "What about editing it?", "sessionId": "abc123"}'
# Expected: contextual follow-up answer

# 3. Rate limit
# Send 31 requests in 60s → expect 429

# 4. Staff role access
# Log in as staff@test.com → POST /ai/help/chat → expect 201 (not 403)

# 5. Empty query validation
curl -X POST ... -d '{"query": ""}'
# Expected: 400 validation error
```

### Flutter
1. Open any main screen → tap "?" FAB
2. Verify empty state shows context-specific suggestions
3. Tap a suggestion → message appears + loading dots → assistant responds with markdown
4. Numbered lists render as actual ordered lists (not raw markdown text)
5. Tap a suggestion chip in response → sends follow-up automatically
6. Tap clear button → session resets, empty state returns
7. Test on Staff account → help chat accessible (no permission error)
