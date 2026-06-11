# Vaulted — Project Context for Claude Code

## What is Vaulted?

Premium home inventory SaaS for high-net-worth families in the USA. Clients manage multiple properties with full hierarchy: floors → rooms → items (furniture, art, wardrobe, vehicles, wine, etc.).

- **Tagline**: "Everything you own. Protected. Organized. Yours."
- **Model**: Premium SaaS subscription · Target: ultra-high-net-worth USA families · Language: English

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Mobile / Web | Flutter | Single codebase for iOS, Android, Web |
| Backend | NestJS + TypeScript | Modular, strict TypeScript |
| Primary DB | MongoDB | Inventory, items, properties |
| Secondary DB | PostgreSQL | Users, audit logs, insurance, financials |
| Cache / Sessions | Redis | JWT blacklist, rate limiting, session cache |
| Media Storage | GCP Cloud Storage / local Docker volume | Photos, documents |
| Infrastructure | GCP VM + Docker | Single VM with Docker Compose |
| Reverse Proxy | Caddy | SSL via Let's Encrypt |
| DNS / WAF / DDoS | Cloudflare / Dynu | Hides VM IP |
| CI/CD | GitHub Actions | Lint, test, deploy |
| Error Monitoring | Sentry | Backend + Flutter |
| Push Notifications | Firebase FCM | Mobile push |
| Email | Resend | Transactional emails |

---

## Infrastructure

- **GCP VM**: e2-micro (free) — `tennis-backend`, us-central1-c, IP 34.57.81.166. Shared with unrelated `tennis-backend` app; same Caddy container.
- **Flow**: Cloudflare/Dynu DNS → Caddy → Docker Compose → NestJS API (port 3000) · MongoDB Atlas M0 · PostgreSQL Neon.tech · Redis Upstash (TLS)
- **Security**: ports 80/443/non-standard SSH · key-based SSH, Fail2ban + UFW · non-root containers · daily GCP snapshots
- **Evolution (post-MVP)**: MongoDB Atlas managed · GCP Memorystore · Cloud SQL · GKE

---

## Roles and Access Control

```
Owner    → full access, manages users
Manager  → manages inventory, cannot see financial valuations
Staff    → view/update assigned items only
Auditor  → read-only, specific categories, watermarked exports
Guest    → temporary access with expiration date
```

- Access scoped per property (staff of Miami house cannot see Aspen house)
- Temporary tokens for third parties (appraisers, insurance agents)

---

## Security Requirements

- **JWT**: Access Token 24h (memory) + Refresh Token 7 days (httpOnly cookie / secure storage)
- **Rotation**: each refresh generates a new token; blacklist in Redis
- **MFA**: mandatory for Owner and Manager (TOTP + YubiKey); Passkeys/FIDO2 supported
- **Data**: AES-256 at rest, TLS 1.3, MongoDB CSFLE for sensitive fields
- **Mobile**: certificate pinning (Dio) ✅ 2026-06-01, Secure Enclave/Keystore, jailbreak detection ❌ pendiente, screenshot guard ❌ pendiente
- **Audit logs**: immutable PostgreSQL table (no UPDATE/DELETE), 2-year retention
- **Compliance targets**: SOC 2 Type II, CCPA, ISO 27001 (post-launch)
- **Security audit**: `/cso --comprehensive` 2026-06-01 — 6 hallazgos corregidos. Ver `docs/security-fixes-summary.md` §10.

---

## Key Features

**MVP (done):** Multi-property · Property→Floor→Room→Item · Photos (10) · Serial # · Valuation · QR · Status (active/loaned/repair/storage/disposed) · Movement history · Loans · RBAC · Push/email · PDF export · Full-text search

**Phase 2 (partial):** Wardrobe ✅ · Insurance ✅ · Maintenance calendar ✅ · AI cataloging ✅ · Dashboard KPIs ✅ · AI Insurance Analysis ✅ · Incident reports ❌

**Phase 3 (pending):** Bulk import · REST API · Advanced reports · Offline mode

---

## Project Structure

### Backend modules (`apps/api/src/modules/`)
```
auth/              ✅  JWT, refresh tokens, MFA, sessions
users/             ✅  User management (PostgreSQL)
tenants/           ✅  Client/family management (PostgreSQL)
properties/        ✅  Properties and rooms (MongoDB)
inventory/         ✅  Items and item history (MongoDB)
movements/         ✅  Item transfers, loans, repairs (MongoDB)
maintenance/       ✅  Scheduled maintenance records (MongoDB)
dashboard/         ✅  Aggregated metrics, Redis cache
wardrobe/          ✅  Outfits + dry cleaning history (MongoDB) + Redis stats cache
media/             ✅  File upload (local Docker volume / GCP Storage)
audit/             ✅  Immutable audit logs (PostgreSQL)
ai/                ✅  vision/ · chat/ · help/ · insurance/ · maintenance/ · shared/
insurance/         ✅  Policies, coverage gaps, claims, encryption (PostgreSQL)
notifications/     ✅  FCM push + Resend email, device tokens, preferences
household-members/ ✅  Household people management (MongoDB)
orchestrator/      ✅  Multi-step task plans + WebSocket progress (MongoDB)
presence/          ⚠️  WebSocket presence tracking (partial)
reports/           ❌  PDF and Excel generation
```

### Flutter features (`apps/mobile/lib/features/`)
```
auth/              ✅  login, register, MFA
dashboard/         ✅  stats summary, property cards
properties/        ✅  list, detail, floors, rooms
inventory/         ✅  list, detail, add/edit, QR scan, item history
movements/         ✅  draft→active→complete workflow, QR checkin
maintenance/       ✅  list, create, update status
ai_chat/           ✅  RAG chat UI, conversation history
ai_help_chat/      ✅  contextual help chat (Vaulted Guide)
ai_scan/           ✅  camera + AI overlay, review form, photo upload
users/             ✅  list, invite, edit role
media/             ✅  image picker, upload progress
wardrobe/          ✅  closet grid, outfit builder, dry cleaning history, stats bar
insurance/         ✅  policies, coverage gaps, claims
household_members/ ✅  household people management
notifications/     ✅  notification inbox + preferences
orchestrator/      ✅  task plans, step guide, progress dashboard
presence/          ✅  online presence indicators
reports/           ❌  stub only
settings/          ❌  stub only
```

### Flutter core packages
```yaml
dio · flutter_secure_storage · flutter_riverpod · go_router
mobile_scanner · cached_network_image · freezed · json_serializable
firebase_messaging · fl_chart · speech_to_text · socket_io_client · google_fonts
```

---

## Key Schemas

### Item (MongoDB)
```javascript
{ _id, tenantId, propertyId, roomId, name, category, subcategory,
  attributes: {},
  valuation: { purchasePrice, purchaseDate, currentValue, currency: "USD", lastAppraisalDate },
  status: "active|loaned|repair|storage|disposed",
  photos: [String], documents: [String], qrCode, tags: [String],
  insurance: { policyId, coveredValue }, createdBy, createdAt, updatedAt }
```

### PostgreSQL tables
```
tenants · users · audit_logs (NO UPDATE/DELETE) · insurance_policies
```

### JWT Strategy
```
Access Token:  24h — in memory (Flutter)
Refresh Token: 7 days — httpOnly cookie / secure storage
Blacklist:     Redis (immediate revocation)
```

---

## AI Features

| Feature | Endpoint | Model |
|---|---|---|
| Vision / Auto-catalog | `POST /ai/vision/analyze` | Gemini 2.5 Flash |
| RAG Chat | `POST /ai/chat` | Gemini embeddings + pgvector search |
| Insurance Analysis | `POST /ai/insurance/analyze` | Gemini 2.5 Flash |
| Maintenance risk scoring | nightly batch | Gemini |
| Dynamic Asset Valuation (AI-3) | pending | Claude reasoning + Brave Search |

**Vision**: photos on Docker volume `/app/uploads/` → base64 → Gemini. Returns `{ name, category, subcategory, brand, estimatedValue, attributes, confidence, tags[], suggestedRoom, invoiceData }`. Tags: 3-5, handles array or comma-string.

**Architecture**: Primary LLM: Gemini 2.5 Flash (`GOOGLE_GENAI_API_KEY`) · Secondary: Anthropic Claude (`@anthropic-ai/sdk`, AI-3 only) · Embeddings: `gemini-embedding-001` (3072 dims, pgvector) · Queue: BullMQ on Redis (`ai-vision` 5w · `ai-valuation` 3w · `ai-maintenance` 3w) · Rate limit: `AI_CHAT_RATE_LIMIT_PER_MINUTE=20` per tenant.

---

## Deployment

### Live URLs
| Endpoint | URL |
|---|---|
| API | `https://api-vaulted.casacam.net` |
| Health | `https://api-vaulted.casacam.net/health` |
| Web app | `https://vaulted-prod-2026.web.app` |

### Deploy
- **API**: SSH into VM → `git pull && ./start-prod.sh down && docker compose -f docker-compose.prod.yml build --no-cache && ./start-prod.sh up -d`
- **Web**: `./infra/build-web.sh` (Flutter web + Firebase)
- **Secrets**: `./infra/upload-env.sh` then restart

### Key Files
| File | Purpose |
|---|---|
| `docker-compose.prod.yml` | Production compose (joins `frpatino6_default` network) |
| `docker-compose.dev.yml` | Local dev (API + all DBs) |
| `start-prod.sh` | Safe docker compose wrapper |
| `.env.prod.example` | Env var template (real secrets not in git) |
| `infra/build-web.sh` | Flutter web build + Firebase deploy |
| `infra/Caddyfile` | Caddy config for both domains |

### Test Credentials
| Env | Email | Password |
|---|---|---|
| Production | `owner@test.com` | `Test1234!Secure` |
| Local dev | `owner@test.com` | `Test1234!` |

> Env vars: see `.env.prod.example`. Note: `FIREBASE_*`, `RESEND_*`, `SENTRY_DSN`, `BRAVE_*` not yet in template — add before production deploy.

---

## Style and Response Rules

- **Minimalist edits:** Only modify the exact lines required. Never rewrite large code blocks or entire files if it can be avoided.
- **No explanations:** Do not explain what you changed, why, or how the code works unless explicitly asked.
- **Concise responses:** Absolute minimum text. If a tool call or modification succeeds, confirm in one line.
- **No diffs or full code:** Never show visual diff outputs (additions/deletions) or complete existing code. Write only the filename and a short plain-text description, e.g.: "Modificado auth.ts — se agregó validación de expiración al guard de refresh token."
- **No per-fix summaries:** During multi-fix execution, skip detailed summaries after each fix. One short completion note, then wait for the next instruction.
- **CodeGraph first:** Use CodeGraph for all code exploration, symbol lookup, callers/callees, and impact analysis before any shell search. Shell commands only for silent verification or file operations CodeGraph cannot perform — never to print search results or code snippets into the conversation.

---

## Coding Conventions

### Backend (NestJS)
- Every feature = one folder in `modules/` — kebab-case files, PascalCase classes
- All input validated with `class-validator` DTOs
- All responses through `ResponseInterceptor`
- TypeScript strict mode always on — no `any`
- Test files `.spec.ts` co-located
- **Swagger/OpenAPI**: every new or modified route and request DTO must be documented. Use `PartialType` from `@nestjs/swagger`, not `@nestjs/mapped-types`.
- **Only add what was explicitly asked.** Never add extra decorators, validations, comments, or methods beyond the minimum — except Swagger decorators, which are mandatory.

### Mobile (Flutter)
- Feature-first + Riverpod — snake_case files, PascalCase classes
- Models: Freezed + json_serializable
- Each feature: `data/` `domain/` `presentation/`
- Shared widgets only in `shared/widgets/`
- No business logic in UI widgets

#### First-load skeleton rule (mandatory)
- If a screen uses `AsyncNotifier` and runs `load()` in `postFrame`, never show empty/not-found states on initial frame.
- Show skeleton while first fetch is pending, even if notifier starts as `[]` or `null`.
- Show `No items` / `No data` / `Not found` only after first load has completed.
- Implementation pattern:
  1. `bool _initialLoadCompleted = false;`
  2. `load(...).whenComplete(() { if (mounted) setState(() => _initialLoadCompleted = true); });`
  3. Compute `showInitialSkeleton` from first-load flag + state.
  4. Route UI through `renderState` (`AsyncLoading` while first load is unresolved).

#### Vaulted Guide KB maintenance rule (mandatory)
Whenever a Flutter screen is **added or modified**, update the corresponding section of `HELP_KNOWLEDGE_BASE` in `apps/api/src/modules/ai/help/ai-help.service.ts`.

Always sync: AppBar title · Tab names · Button labels/tooltips · Filter/sort chip labels · Form field hints · Role restrictions · Empty state messages.

If a screen is renamed, also update `SCREEN_CONTEXT` (~line 400 in same file).

This rule applies to Cursor and Codex tasks too — include a KB update in the PR whenever UI-facing text changes.

---

## Multi-LLM Workflow

| Tool | Role |
|---|---|
| **Claude Code** | Architect + Reviewer (security, cross-module decisions) |
| **Cursor** | Writer (boilerplate, CRUD, repetitive code) |
| **Codex** | Writer (scaffolding, DTOs, schemas, tests) |

**Never delegate to Cursor/Codex:** auth/security logic, DB schema design, RBAC, cross-module decisions.

G Stack skills available via `/skill-name` — see `~/.claude/skills/gstack/` for the full list.

---

## Technical Debt

### Envelope Encryption — post-MVP
- Current `CryptoService` uses HKDF-SHA-256 (solid for MVP). Defer envelope encryption + GCP KMS to post-MVP.
- Files: `common/services/crypto.service.ts` · `tenants/entities/tenant.entity.ts`

### Certificate Pinning — rotate every ~90 days
- Fingerprint in `AppConfig.pinnedCertFingerprints` (`core/config/app_config.dart`). During rotation keep both old + new fingerprints until all users update, then remove old.
- Rotation command: `echo | openssl s_client -connect api-vaulted.casacam.net:443 2>/dev/null | openssl x509 -noout -fingerprint -sha256 | sed 's/sha256 Fingerprint=//' | tr -d ':' | tr '[:upper:]' '[:lower:]'`
- Files: `core/network/api_client.dart` · `core/config/app_config.dart` — **Alta prioridad operativa**

### App Icon — Android & iOS not updated
- New icon (shield) applied to web only. Pending: `mipmap-*/ic_launcher.png` (5 sizes) + `AppIcon.appiconset/` (15 files).
- Source: `apps/mobile/web/icon-option-2.svg` — **Low priority** (needed before store publish)
