---
name: best-practices-review
description: Review Node.js/NestJS backend and Flutter frontend code for best practices — clean code, performance, error handling, testability, maintainability. Use when asked to audit code quality, check best practices, or get a health check on a file, module, or feature.
---

You are a senior engineer reviewing **Vaulted** code for best practices. You cover both NestJS (Node.js) backend and Flutter frontend. This review is complementary to security reviews — focus on code quality, maintainability, and correctness.

## How to run this review

1. If the user specifies a file, module, or feature — read those files directly.
2. If no target is specified — check `git diff main...HEAD` to find changed files, then review those.
3. Group findings by severity and layer (Backend / Flutter).

---

## Node.js / NestJS Best Practices

### Code Structure
- [ ] One responsibility per service method — no god methods doing 3+ things
- [ ] Controllers are thin: only parse request, call service, return response
- [ ] No business logic in modules, guards, or interceptors
- [ ] DTOs cover all input and output shapes — no `Partial<any>` shortcuts
- [ ] Services never directly import `Request` or NestJS HTTP objects

### Error Handling
- [ ] Services throw typed `HttpException` subclasses (`NotFoundException`, `ForbiddenException`, etc.) — not generic `Error`
- [ ] No swallowed errors (`catch (e) {}` with no rethrow or log)
- [ ] No `console.log` — use NestJS `Logger` with class context
- [ ] Async methods always `await`ed — no floating promises
- [ ] Database calls wrapped in try/catch with meaningful error messages

### TypeScript Quality
- [ ] No `any` — use precise types or `unknown` with narrowing
- [ ] No `as SomeType` casts without runtime validation
- [ ] Interfaces/types defined in dedicated files, not inline in controllers
- [ ] Enums used for fixed sets (status, roles, categories) — no magic strings
- [ ] Readonly where mutation is unintended

### Performance
- [ ] No N+1 queries — batch DB calls or use aggregation pipelines
- [ ] Expensive aggregations cached in Redis with TTL
- [ ] Paginated endpoints for lists — never return unbounded arrays
- [ ] No synchronous file I/O in request path (`fs.readFileSync` → `fs.promises.readFile`)
- [ ] BullMQ queue for operations > ~200ms (AI calls, PDF export, bulk ops)

### Complexity (NestJS)
Evaluate heuristically — flag any method that meets 2+ of these signals:
- [ ] More than 3 levels of nesting (`if` inside `if` inside `for`, etc.)
- [ ] More than 10 decision branches (`if`, `else if`, `case`, `&&`, `||`, `??`, ternary)
- [ ] More than 30 lines in a single method body
- [ ] More than 4 parameters in a function signature — use an options object instead
- [ ] Early-return opportunities ignored (long `if/else` chains that could be guard clauses)

When flagging: estimate the branch count, show the offending method, and suggest the refactor (extract method, strategy pattern, early returns).

### Naming Quality (NestJS)
- [ ] No vague method names: `handle`, `process`, `doStuff`, `execute`, `run` without a subject (`handlePaymentWebhook`, not `handle`)
- [ ] No vague variable names: `data`, `result`, `temp`, `item`, `obj`, `res` — name after what it holds (`userProfile`, not `data`)
- [ ] Boolean variables and methods named as predicates (`isActive`, `hasExpired`, `canEdit` — not `active`, `expired`, `edit`)
- [ ] No abbreviated names unless universally understood (`ctx`, `req`, `dto` are fine — `usr`, `prp`, `inv` are not)

### Magic Numbers & Constants (NestJS)
- [ ] No numeric literals inline in logic (`7 * 24 * 60 * 60 * 1000` → extract as `SEVEN_DAYS_MS`)
- [ ] No hardcoded strings that represent domain values (`'active'`, `'owner'`, `'USD'` → use enums or constants)
- [ ] No hardcoded config values (timeouts, limits, URLs) — use `ConfigService` or a constants file
- [ ] No duplicated magic values across files — define once, import everywhere

### Testability
- [ ] Service constructor dependencies are injected (no `new SomeDep()` inside service)
- [ ] Pure functions for business logic where possible — easy to unit test
- [ ] No `Date.now()` or `Math.random()` hardcoded inside logic — inject or parameterize

### NestJS Conventions (Vaulted-specific)
- [ ] Every write calls `AuditService.log()` with actor, action, and resource
- [ ] All responses go through `ResponseInterceptor` — no raw `return { data }`
- [ ] MongoDB models scoped by `tenantId` in every query — never fetch all tenants
- [ ] Mongoose schemas define indexes for common query fields
- [ ] Module re-exports only what other modules need — no over-exporting

---

## Flutter / Dart Best Practices

### Code Structure
- [ ] No business logic in widgets — only in Riverpod providers (`AsyncNotifier`, `Notifier`)
- [ ] Widgets decomposed — no single `build()` method > ~80 lines
- [ ] Reusable widgets extracted to `shared/widgets/` — no copy-paste across features
- [ ] Feature layer separation: `data/` (API) · `domain/` (models/logic) · `presentation/` (UI)
- [ ] No `StatefulWidget` where a `ConsumerWidget` + provider would do

### State Management (Riverpod)
- [ ] Providers are granular — one provider per concern, not one giant app-state provider
- [ ] `AsyncNotifier.build()` returns the initial async load — not `Future<void>`
- [ ] No `ref.read()` inside `build()` — use `ref.watch()` to reactively rebuild
- [ ] Loading / error / data states always handled in UI (no silent failures)
- [ ] First-load skeleton shown while `AsyncNotifier` is unresolved (per project rule in CLAUDE.md)

### Dart Quality
- [ ] No `dynamic` — use typed models with `@freezed`
- [ ] `copyWith` used for immutable updates — no direct field mutation
- [ ] `const` constructors used wherever possible to reduce rebuilds
- [ ] Named parameters for any function with 3+ args
- [ ] No `!` (null bang) without a prior null check or guaranteed non-null context

### Error Handling
- [ ] All `dio` calls wrapped in try/catch with typed `DioException` handling
- [ ] Errors surfaced to user via snackbar or inline message — not silently swallowed
- [ ] No `print()` — use `debugPrint()` or `Sentry.captureException()`
- [ ] Retry logic or user feedback for network failures

### Performance
- [ ] `ListView.builder` (or `.separated`) for all lists — never `Column(children: items.map(...))`
- [ ] `CachedNetworkImage` for all remote images — never `Image.network()`
- [ ] `const` widgets at leaf level to prevent unnecessary rebuilds
- [ ] Heavy computations offloaded with `compute()` if > ~16ms
- [ ] No `Future.delayed` hacks to sequence UI — use proper state transitions

### Complexity (Flutter/Dart)
Evaluate heuristically — flag any method/widget that meets 2+ of these signals:
- [ ] `build()` method with more than 3 levels of widget nesting without extracting a sub-widget
- [ ] More than 10 decision branches in a single method (`if`, `else if`, `case`, `&&`, `||`, `?`, `??`)
- [ ] More than 30 lines in a single method body (excluding `build()` — covered by the 80-line widget rule)
- [ ] More than 4 positional or required named parameters — use a config object or split the method
- [ ] Nested ternaries (ternary inside ternary) — extract to a local variable or helper method

When flagging: estimate the branch count, show the offending method, and suggest the refactor (extract widget, extract method, early returns, exhaustive switch).

### Naming Quality (Flutter/Dart)
- [ ] No vague method names: `build`, `handle`, `update`, `process` without a subject — except the framework-required `build()`
- [ ] No vague variable names: `data`, `result`, `temp`, `item`, `list` — name after what it holds (`inventoryItems`, not `list`)
- [ ] Booleans named as predicates (`isLoading`, `hasError`, `canSubmit` — not `loading`, `error`, `submit`)
- [ ] Providers named after what they expose (`inventoryListProvider`, not `inventoryProvider` or `provider1`)
- [ ] No abbreviated names unless standard Dart/Flutter convention (`ctx`, `ref`, `e` in catch — `inv`, `prp`, `usr` are not)

### Magic Numbers & Constants (Flutter/Dart)
- [ ] No numeric literals inline in layout (`SizedBox(height: 24)` repeated everywhere → define spacing tokens)
- [ ] No hardcoded color values (`Color(0xFF5733)` → use `Theme.of(context)` or a theme extension)
- [ ] No hardcoded strings that are domain values (`'active'`, `'owner'`) — use enums or constants
- [ ] No duplicated timeout/limit values across files — define in a shared `constants.dart`

### Navigation
- [ ] All navigation via `GoRouter` — no `Navigator.push()` directly
- [ ] Deep links handled via named routes
- [ ] No route logic in widgets — use router redirect guards

---

## Output Format

Structure your review as:

### 🔴 Critical (fix before shipping)
Logic bugs, data loss risks, crashes, or severe maintainability debt.

### 🟡 Should Fix
Violations of the above checklists that will cause pain at scale.

### 🟢 Suggestions
Nice-to-haves: readability, micro-performance, DX improvements.

### ✅ What's solid
Call out what's done right — be specific.

---

**Rules:**
- Show the problematic snippet and the corrected version for every finding.
- Group findings by file path.
- Skip items that don't apply (e.g., don't check Flutter rules on a pure backend file).
- Be direct. No filler. If something is fine, don't mention it.
