# Prompts para Codex — Resolución de hallazgos críticos (análisis 2026-06-10)

Origen: revisión completa de best practices del 2026-06-10 (backend NestJS + Flutter).
Un prompt por hallazgo crítico. Cada prompt es autocontenido: copiar y pegar tal cual en Codex.

> ⚠️ **Política Multi-LLM (CLAUDE.md)**: los prompts **C1, C4, C8 y C11** tocan código de auth/RBAC.
> Son fixes acotados y mecánicos, pero el diff resultante debe ser revisado por Claude Code antes de mergear.
> El prompt **C14** es arquitectónico (colas BullMQ) — preferiblemente ejecutarlo con Claude Code, no con Codex.

Reglas globales para todos los prompts (incluirlas siempre):

```
General rules:
- Minimal edits only: touch the exact lines required, never rewrite whole files.
- TypeScript strict mode: no `any`, no `as` casts without runtime validation.
- Do NOT add extra decorators, validations, comments, or methods beyond what is asked.
- If a route in *.controller.ts changes its surface, update Swagger decorators (match auth.controller.ts style).
- Run existing tests for the touched module before finishing.
```

---

## C1 — Logger no declarado en AuthService (crash en error path de HIBP) [HECHO]

```
In apps/api/src/modules/auth/auth.service.ts, the method that calls the HIBP
(haveibeenpwned) API references `this.logger.warn('HIBP API call failed', err)`
around line 520, but the AuthService class never declares a `logger` member.
If the HIBP request errors, this throws `TypeError: Cannot read properties of
undefined` instead of failing open.

Fix: add `private readonly logger = new Logger(AuthService.name);` as a class
field, importing `Logger` from '@nestjs/common' if not already imported.
Do not change any other behavior. Verify the file compiles with `npx tsc --noEmit`
scoped to the api app.
```

## C2 — Borrado de propiedad deja items huérfanos [HECHO]

```
In apps/api/src/modules/properties/properties.service.ts, the `delete()` method
(~line 125) removes a property without handling its items, leaving every item
pointing at a dead propertyId. By contrast, `deleteFloor`/`deleteRoom` in the
same file already null out `roomId`/`sectionId` on affected items.

Fix: in `delete()`, after `findOwnedPropertyOrThrow`, count items for that
property in the inventory items collection scoped by `{ tenantId, propertyId }`.
If count > 0, throw `ConflictException('Cannot delete a property that still
contains items. Move or dispose them first.')`. Only then run the deleteOne.

You will need the Item model: check how PropertiesService already receives
injected models/services and follow the same pattern (if InventoryService or
the Item model is not available in PropertiesModule, inject the Item model via
`@InjectModel` and add the schema import to PropertiesModule following the
existing module style).

Update the Swagger `@ApiResponse` decorators of the DELETE property route in
properties.controller.ts to document the 409 response.
Add/adjust the corresponding .spec.ts test: deleting a property with items → 409;
without items → succeeds.
```

## C3 — activate() de movements no valida el room destino [HECHO]

```
In apps/api/src/modules/movements/movements.service.ts, the `activate()` method
(~lines 248-280) verifies the destination property belongs to the tenant but
never validates that `destRoomId` exists inside that property, then writes
`roomId: destRoomId` to every item. The `quickTransfer()` method (~line 487)
in the same file already validates room existence correctly.

Fix: inside `activate()`, when the movement has a `destRoomId`, reuse the exact
room-existence check used by `quickTransfer` (room id present in the destination
property's floors/rooms structure). If the room does not exist, throw
`BadRequestException('Destination room not found in destination property')`.
If the validation logic is duplicated, extract it into a small private helper
`assertRoomInProperty(property, roomId)` used by both methods.

Add a .spec.ts test: activating a movement with a non-existent destRoomId → 400.
```

## C4 — Defaults privilegiados en InventoryService.findById ⚠️ revisar con Claude Code [HECHO]

```
In apps/api/src/modules/inventory/inventory.service.ts, `findById` (~line 384)
is declared as:

  async findById(tenantId: string, itemId: string, role: Role = Role.OWNER, userId = '')

Any internal caller that omits arguments silently gets the most privileged path:
decrypted valuations, the property-scope check skipped (it's guarded by `if (userId)`),
and audit entries with an empty userId.

Fix: remove the default values — make `role: Role` and `userId: string` required
parameters. Then fix every compile error this produces: find all internal callers
of `findById` (grep the api codebase) and pass the real role and userId they have
in scope. Do NOT pass Role.OWNER hardcoded from any caller that has access to the
actual requester's role. If a caller is a system/internal job with no user context,
pass the role and a userId it already tracks, or thread the actor through from the
controller.

Verify with `npx tsc --noEmit`. Do not change the method's logic, only the
signature and call sites.
```

## C5 — presence.service.ts no compila bajo strict TS [HECHO]

```
In apps/api/src/modules/presence/presence.service.ts there are two strict-mode
TypeScript errors:

1. ~line 166 references the type `SanitizedUser` which is never imported. It is
   exported from apps/api/src/modules/users/users.service.ts (~line 27). Add the
   import.

2. `registerConnection` (~lines 34-75) declares return type
   `Promise<{ isNewSession: boolean }>` but returns an object literal with an
   extra `broadcastPayload` property (TS2353). The gateway
   (presence.gateway.ts ~line 95) destructures only `isNewSession` and never
   uses broadcastPayload.

Fix for (2): delete the dead `broadcastPayload` property from the return value
so the implementation matches the declared type. Do not widen the type.

Verify the whole api compiles: `npx tsc --noEmit` from apps/api.
```

## C6 — Job de dry-cleaning vencido ignora preferencias de notificación [HECHO]

```
In apps/api/src/modules/wardrobe/wardrobe-overdue.job.ts (~lines 80-87), the call
to `this.notificationsService.notifyTenantRoles({...})` omits the `type` field,
so it defaults to 'general' (always-on) and the user's `dryCleaningOverdue`
notification preference toggle is never consulted. The persisted NotificationLog
type is also wrong.

Fix: add `type: 'dry_cleaning_overdue'` to the notifyTenantRoles payload.
Mirror how apps/api/src/modules/maintenance/maintenance.scheduler.ts (~line 44)
correctly passes `type: 'maintenance_due'`. Confirm that
`isTypeEnabledForUser` in notifications.service.ts (~line 599) already handles
the 'dry_cleaning_overdue' key — if the key name differs, use the exact key that
the preferences schema defines (search for dryCleaningOverdue in the
notifications module).

Add/adjust a .spec.ts test asserting the job passes the correct type.
```

## C7 — Mantenimientos creados por AI saltan el audit trail [HECHO]

```
In apps/api/src/modules/ai/maintenance/ai-maintenance.service.ts (~lines 73-87),
AI-generated maintenance records are written directly via
`this.recordModel.create({...})` with no AuditService.log() call anywhere in the
service or its controller. Every other maintenance write audits (see
apps/api/src/modules/maintenance/maintenance.service.ts ~line 60, action
'maintenance_scheduled').

Fix: after the create succeeds, call `this.auditService.log(...)` with
action 'maintenance_scheduled', the tenantId, the record id as the entity,
and metadata `{ isAiSuggested: true, riskScore }` (use the risk score variable
in scope). Inject AuditService following the same constructor-injection pattern
used in maintenance.service.ts; add AuditModule to the AI maintenance module's
imports if it is not already there (check how other ai/ submodules import it).

For the actor: if the code path is a nightly batch with no user, use the same
system-actor convention other schedulers in the codebase use (grep for how
maintenance.scheduler.ts or other jobs log audits). Do not invent a new convention.
```

## C8 — Credenciales de producción hardcodeadas en el login ⚠️ revisar con Claude Code [HECHO]

```
In apps/mobile/lib/features/auth/presentation/login_screen.dart, the production
test credentials are hardcoded twice:

  ~lines 18-19:
    final _emailController = TextEditingController(text: 'owner@test.com');
    final _passwordController = TextEditingController(text: 'Test1234!Secure');

  ~lines 31-34: a postFrameCallback sets the same values again.

This ships real credentials inside the app binary and pre-fills them for every
user.

Fix:
1. Replace both controllers with empty `TextEditingController()`.
2. Delete the postFrameCallback block that re-assigns them.
3. For local dev convenience, allow optional prefill ONLY via compile-time env:
   read `const String.fromEnvironment('DEV_LOGIN_EMAIL')` and
   `const String.fromEnvironment('DEV_LOGIN_PASSWORD')` and apply them only when
   non-empty AND `kDebugMode` is true (import 'package:flutter/foundation.dart').
4. Do not change any other login logic.

Run `flutter analyze` on the file. Since this changes a user-facing screen's
default state, no HELP_KNOWLEDGE_BASE update is needed (no labels changed), but
verify no test depends on the prefilled values (grep test/ for Test1234).
```

## C9 — Parsing de precio corrompe valuaciones en AI Scan (error 100x) [HECHO]

```
In apps/mobile/lib/features/ai_scan/presentation/ai_item_review_screen.dart
(~lines 409-416), the purchase price is parsed by stripping every non-digit:

  purchasePrice: int.tryParse(
    _purchasePriceCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
  ) ?? 0,

Input "1,499.99" becomes 149999 → saved as $149,999 instead of $1,499.99.

Fix:
1. Parse as a decimal: strip only currency symbols, spaces and thousands
   separators (`$`, `,`, spaces), keep the decimal point, then `double.tryParse`.
   Example: a helper `double parsePrice(String raw)` → `double.tryParse(
   raw.replaceAll(RegExp(r'[$,\s]'), '')) ?? 0`.
2. Check the type the backend DTO expects for purchasePrice (see the item
   create DTO in apps/api/src/modules/inventory/dto/create-item.dto.ts and the
   Flutter ItemModel/freezed model used by this screen). If the model field is
   typed num/double, pass the double directly; if it is int dollars, round
   half-up and note it.
3. Apply the same fix to ANY other field in this screen parsed with the same
   digit-stripping pattern (search the file for `[^\d]`).
4. Add a unit test for the parsing helper covering: "1,499.99", "$1499.99",
   "1499", "" → 0.

Run `flutter analyze` and the feature's existing tests.
```

## C10 — Crash en web por cast no-null de state.extra en el router [HECHO]

```
In apps/mobile/lib/core/router/app_router.dart there are unguarded non-null
casts of GoRouter's `state.extra`, which is ALWAYS null on browser refresh or
direct URL entry (deployed web app):

  ~lines 339-340:
    final extra = state.extra as Map<String, dynamic>?;
    final result = extra?['result'] as AiScanResult;   // null → _CastError

  ~line 398:
    final parsed = state.extra as ParsedPlanModel;     // same crash

Fix: for each route builder that requires `extra`, make the cast nullable and,
when the value is null, return a redirect to the nearest safe parent route
instead of building the screen. Follow GoRouter idiom: in the route's `redirect`
callback return the parent path when `state.extra` is null (preferred), or in
the builder return the parent screen. Pick the parent route that already exists
in this router for each case (e.g. the AI scan entry screen for the scan result
route, the orchestrator list for the parsed-plan route — read the surrounding
route tree to choose correctly).

Also fix ~line 368 `state.extra as dynamic` by typing it as the nullable model
the target screen expects.

Run `flutter analyze`. Do not restructure any routes.
```

## C11 — currentUserRole() puede lanzar dentro del redirect del router ⚠️ revisar con Claude Code [HECHO]

```
In apps/mobile/lib/features/users/domain/current_user_jwt.dart (~lines 11-12),
the JWT payload is decoded with no error handling:

  final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
  return jsonDecode(payload)['role'] as String?;

This function runs inside GoRouter.redirect (app_router.dart ~line 90) and in
many build() methods. A corrupt or truncated token makes EVERY navigation throw.

Fix: wrap the whole decode in try/catch and return null on any exception:

  try {
    ... existing decode ...
  } catch (_) {
    return null;
  }

Also guard the prior `parts` access: if the token doesn't split into 3 parts,
return null (check if the function already does this — only add it if missing).
Apply the same guard to any sibling function in the same file that decodes the
JWT (e.g. a currentUserId() helper, if present).

Add a unit test: corrupt token string → returns null, no throw.
Run `flutter analyze`.
```

## C12 — Notifiers que tragan errores → snackbars de éxito en fallo [HECHO]

```
Two Riverpod notifiers catch action errors without rethrowing, so their calling
screens always show success snackbars even when the action failed, AND the whole
screen state is replaced by AsyncError (wiping the loaded data):

1. apps/mobile/lib/features/orchestrator/domain/orchestrator_detail_notifier.dart
   (~lines 26-36): `publish()`, `removeGroup()`, `updateAssignments()`, `addGroup()`
   all do `catch (e) { state = AsyncError(e, StackTrace.current); }`.
   Caller orchestrator_plan_detail_screen.dart (~lines 50-72) try/catches around
   publish() and shows 'Plan published — staff notified!' — dead code today.

2. apps/mobile/lib/features/maintenance/domain/maintenance_notifier.dart
   (~lines 35-44): `complete()`, `cancel()`, `delete()` same pattern.
   Caller maintenance_list_screen.dart (~lines 417-431) shows 'Marked as
   completed' unconditionally.

Fix pattern (apply to every action method in both notifiers, NOT to load()):
- Keep the current AsyncData state on failure instead of setting AsyncError:
  snapshot `final previous = state;` before the optimistic/loading change,
  restore it in catch, then `rethrow`.
- load()/refresh() keep their current behavior (screen-level AsyncError is
  correct for initial load).

Reference implementation in this codebase:
apps/mobile/lib/features/wardrobe/domain/wardrobe_notifier.dart →
`updateCleaningStatus` (snapshot, rollback, rethrow). Copy that pattern.

Then verify the calling screens: their existing try/catch + success snackbar
logic now works; add an error snackbar in the catch where missing (use the
feature's existing errorMessage(e) helper).

Run `flutter analyze` and the tests for both features.
```

## C13 — Item equivocado / StateError tras check-in por QR [HECHO]

```
Two scan screens use firstWhere with a wrong-item fallback that can show
incorrect feedback or throw StateError on an empty list:

1. apps/mobile/lib/features/movements/presentation/movement_checkin_screen.dart
   (~lines 308-312):
     final checkedItem = updated?.items.firstWhere(
       (i) => i.itemId == itemId,
       orElse: () => updated.items.first,
     );
2. apps/mobile/lib/features/movements/presentation/movement_scan_screen.dart
   (~lines 264-267): same pattern with `items.last`.

Fix in both files:
- Replace with a null-safe lookup:
    final checkedItem =
        updated?.items.where((i) => i.itemId == itemId).firstOrNull;
  (import 'package:collection/collection.dart' if firstWhereOrNull/firstOrNull
  is not already available; check pubspec — collection is a Flutter SDK dep.)
- When checkedItem is null, show a neutral feedback message like
  'Item scanned — refresh to see status' instead of another item's name. Match
  the exact feedback widget already used in each screen.

While in these two files, also guard the `setState` calls that run after
`await` (~lines 314-330 in checkin, ~269-288 in scan): add `if (!mounted) return;`
after each await before touching state — including in the `finally` blocks.

Run `flutter analyze`. If any user-visible string changed, update the
movements section of HELP_KNOWLEDGE_BASE in
apps/api/src/modules/ai/help/ai-help.service.ts accordingly.
```

## C14 — reindex() de embeddings corre inline en el request HTTP ⚠️ preferir Claude Code [HECHO]

```
CLAUDE.md documents BullMQ queues (ai-vision, ai-valuation, ai-maintenance) but
no bullmq/@nestjs/bullmq dependency exists in apps/api. The worst consequence:
apps/api/src/modules/ai/chat/ai-chat.service.ts `reindex()` (~lines 204-225)
loads ALL tenant items and synchronously generates embeddings batch-by-batch
inside an HTTP request — minutes of blocking work on a single-vCPU VM.

Scope for this task (minimal, no full queue architecture):
1. Make the reindex endpoint return immediately: the controller responds
   202 Accepted with `{ status: 'started' }` and the service runs the existing
   batch loop in the background (fire-and-forget with proper error logging via
   the service's Logger — no unhandled rejections).
2. Add a Redis-based guard so only one reindex per tenant runs at a time:
   SET key `ai:reindex:lock:${tenantId}` NX with a TTL (e.g. 15 min), released
   in a finally block. If locked, respond 409 Conflict. Use the Redis client
   already injected in this service.
3. Expose progress minimally: write `ai:reindex:status:${tenantId}` =
   processed/total after each batch with the same TTL, and add a small GET
   status endpoint in the same controller returning it.
4. Update Swagger decorators for both routes.
5. Do NOT add bullmq. Do NOT touch the other AI services. Leave a `// TODO:
   migrate to BullMQ queue (see CLAUDE.md AI Architecture)` on the background
   runner.

Add .spec.ts coverage: second reindex while locked → 409.
```

---

## Orden de ejecución sugerido

| Prioridad | Prompts | Razón |
|---|---|---|
| 1 | C8, C9 | Credenciales en binario · corrupción de datos de valuación |
| 2 | C2, C3, C12, C13 | Integridad de inventario y feedback falso al usuario |
| 3 | C1, C5, C10, C11 | Crashes (error paths, compilación, web refresh) |
| 4 | C4, C6, C7 | Privilegios por defecto, preferencias, audit trail |
| 5 | C14 | Mitigación de carga (preferir Claude Code) |
