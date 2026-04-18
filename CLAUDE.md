# Vaulted — Project Context for Claude Code

## What is Vaulted?

Premium home inventory management app for high-net-worth families in the USA.
Each client (tenant) can have one or multiple properties (mansions) and needs to track
everything inside: furniture, art, electronics, wardrobe, jewelry, watches, vehicles, wine, etc.
Each property has floors, rooms, and items assigned to specific locations.

---

## Product Decisions

- **App name**: Vaulted
- **Tagline**: "Everything you own. Protected. Organized. Yours."
- **Target market**: Ultra-high-net-worth families in the USA
- **Business model**: Premium SaaS subscription (per number of properties or items)
- **Language**: English (Spanish expansion planned post-MVP)

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

### GCP VM (production)
- Type: e2-micro (free tier) — VM name: `tennis-backend`, us-central1-c, IP 34.57.81.166
- Shared with unrelated `tennis-backend` app; both use the same Caddy container

### Architecture Flow
```
Cloudflare/Dynu DNS → Caddy (reverse proxy + SSL)
    → Docker Compose
        └── NestJS API (internal port 3000)
MongoDB Atlas M0 (free) · PostgreSQL Neon.tech (free) · Redis Upstash (free, TLS)
GCP Cloud Storage / local Docker volume → media files
```

### VM Security (before production launch)
- Firewall: ports 80, 443, one non-standard SSH only
- SSH: key-based, no passwords; Fail2ban + UFW
- Containers run as non-root; .env never in repo
- Daily automated GCP snapshots

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

- **JWT**: Access Token 15 min (memory) + Refresh Token 7 days (httpOnly cookie / secure storage)
- **Rotation**: each refresh generates a new token; blacklist in Redis
- **MFA**: mandatory for Owner and Manager (TOTP + YubiKey); Passkeys/FIDO2 supported
- **Data**: AES-256 at rest, TLS 1.3, MongoDB CSFLE for sensitive fields
- **Mobile**: certificate pinning (Dio), Secure Enclave/Keystore, jailbreak detection, screenshot guard
- **Audit logs**: immutable PostgreSQL table (no UPDATE/DELETE), 2-year retention
- **Compliance targets**: SOC 2 Type II, CCPA, ISO 27001 (post-launch)

---

## Item Categories

```
Furniture · Art & Collectibles · Appliances & Technology
Wardrobe (Clothing · Footwear · Accessories · Jewelry & Watches)
Vehicles · Wine & Spirits · Books · Sports Equipment · Musical Instruments
Household Supplies (linens, tableware, glassware)
```

---

## Key Features

**MVP (done):** Multi-property management · Property→Floor→Room→Item hierarchy · Photos (up to 10) · Serial number · Valuation · QR code per item · Item status (active/loaned/repair/storage/disposed) · Movement history · Loan tracking · RBAC per property · Push/email notifications · PDF export · Full-text search

**Phase 2 (partially done):** Wardrobe module ✅ · Insurance policies · Maintenance calendar · Incident reports · AI-powered cataloging ✅ · Dashboard KPIs ✅

**Phase 3 (pending):** Bulk import · REST API · Advanced reports · Offline mode

---

## Project Structure

### Backend modules (`apps/api/src/modules/`)
```
auth/          ✅  JWT, refresh tokens, MFA, sessions
users/         ✅  User management (PostgreSQL)
tenants/       ✅  Client/family management (PostgreSQL)
properties/    ✅  Properties and rooms (MongoDB)
inventory/     ✅  Items and item history (MongoDB)
movements/     ✅  Item transfers, loans, repairs (MongoDB)
maintenance/   ✅  Scheduled maintenance records (MongoDB)
dashboard/     ✅  Aggregated metrics, Redis cache
wardrobe/      ✅  Outfits + dry cleaning history (MongoDB) + Redis stats cache
media/         ✅  File upload (local Docker volume / GCP Storage)
audit/         ✅  Immutable audit logs (PostgreSQL)
ai/            ✅  vision/ · chat/ · maintenance/ · shared/
insurance/     ❌  Policies and warranties (PostgreSQL)
notifications/ ❌  Push (FCM) + email (Resend)
reports/       ❌  PDF and Excel generation
```

### Flutter features (`apps/mobile/lib/features/`)
```
auth/          ✅  login, register, MFA
dashboard/     ✅  stats summary, property cards
properties/    ✅  list, detail, floors, rooms
inventory/     ✅  list, detail, add/edit, QR scan, item history
movements/     ✅  draft→active→complete workflow, QR checkin
maintenance/   ✅  list, create, update status
ai_chat/       ✅  RAG chat UI, conversation history
ai_scan/       ✅  camera + AI overlay, review form, photo upload
users/         ✅  list, invite, edit role
media/         ✅  image picker, upload progress
wardrobe/      ✅  closet grid, outfit builder, dry cleaning history, stats bar
reports/       ❌  stub only
settings/      ✅  basic
```

### Flutter core packages
```yaml
dio · flutter_secure_storage · hive_flutter · flutter_riverpod
go_router · mobile_scanner · local_auth · cached_network_image
sentry_flutter · freezed · json_serializable
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
Access Token:  15 min — in memory (Flutter)
Refresh Token: 7 days — httpOnly cookie / secure storage
Blacklist:     Redis (immediate revocation)
```

---

## AI Features

### Implemented
| Feature | Endpoint | Model |
|---|---|---|
| Vision / Auto-catalog | `POST /ai/vision/analyze` | Gemini 2.5 Flash |
| RAG Chat | `POST /ai/chat` | Gemini embeddings + vector search |
| Maintenance risk scoring | nightly batch | Gemini |

**Vision notes:**
- Photos stored on Docker volume (`/app/uploads/`), NOT GCP Storage (not configured in test env)
- Service reads file → base64 → sends to Gemini (not public URL)
- Returns: `{ name, category, subcategory, brand, estimatedValue, attributes, confidence, tags[], suggestedRoom, invoiceData }`
- Tags: 3-5 required, parsed robustly (handles array or comma-string from model)

### Pending AI phases
| Phase | Feature |
|---|---|
| AI-3 | Dynamic Asset Valuation (web search + Claude reasoning) |
| AI-5 | Insurance Intelligence (PDF extraction, gap analysis) |

### AI Architecture
- **Primary LLM**: Gemini 2.5 Flash (`GOOGLE_GENAI_API_KEY`)
- **Embeddings**: Gemini embeddings (stored in MongoDB)
- **Web Search** (AI-3): Brave Search API
- **Queue**: BullMQ on Redis — `ai-vision` (5 workers) · `ai-valuation` (3) · `ai-maintenance` (3)
- **Cost control**: rate limits per tenant, token usage logged to AuditService

---

## Deployment (Testing)

### Live URLs
| Endpoint | URL |
|---|---|
| API | `https://api-vaulted.casacam.net` |
| Health | `https://api-vaulted.casacam.net/health` |
| Web app | `https://vaulted-prod-2026.web.app` |

### Deploy API Updates (SSH into VM)
```bash
gcloud compute ssh tennis-backend --zone us-central1-c --project tennis-management-fcd54
cd ~/vaulted/vaulted
git pull
./start-prod.sh down
docker compose -f docker-compose.prod.yml build --no-cache
./start-prod.sh up -d
docker logs vaulted_api --tail 50
```

### Deploy Web App (run locally)
```bash
./infra/build-web.sh   # Flutter web build + Firebase deploy
```

### Upload secrets to VM (run locally)
```bash
./infra/upload-env.sh
./start-prod.sh down && ./start-prod.sh up -d
```

### Test Credentials
| Env | Email | Password |
|---|---|---|
| Production | `owner@test.com` | `Test1234!Secure` |
| Local dev | `owner@test.com` | `Test1234!` |

### Key Files
| File | Purpose |
|---|---|
| `docker-compose.prod.yml` | Production compose (API only, joins `frpatino6_default` network) |
| `docker-compose.dev.yml` | Local dev (API + all databases) |
| `start-prod.sh` | Safe wrapper: parses `.env.prod`, runs docker compose |
| `.env.prod` | NOT in git — real secrets |
| `.env.prod.example` | Template with all required variable names |
| `apps/api/Dockerfile.prod` | Multi-stage build (builder + runner) |
| `infra/build-web.sh` | Flutter web build + Firebase deploy |
| `infra/Caddyfile` | Caddy config for both domains |
| `infra/upload-env.sh` | Uploads `.env.prod` to VM via gcloud scp |

---

## Environment Variables (`.env.prod.example`)

```
NODE_ENV · PORT · APP_URL
JWT_SECRET · JWT_EXPIRES_IN=15m · JWT_REFRESH_SECRET · JWT_REFRESH_EXPIRES_IN=7d
MONGODB_URI · POSTGRES_HOST/PORT/DB/USER/PASSWORD
REDIS_HOST/PORT/PASSWORD (use rediss:// for Upstash TLS)
GCP_PROJECT_ID · GCP_STORAGE_BUCKET · GCP_KEY_FILE
FIREBASE_PROJECT_ID · FIREBASE_PRIVATE_KEY · FIREBASE_CLIENT_EMAIL
RESEND_API_KEY · EMAIL_FROM
SENTRY_DSN
GOOGLE_GENAI_API_KEY · AI_VISION_MODEL=gemini-2.5-flash
BRAVE_SEARCH_API_KEY · VALUATION_SEARCH_ENGINE=brave
```

---

## Coding Conventions

### Backend (NestJS)
- Every feature = one folder in `modules/` — kebab-case files, PascalCase classes
- All input validated with `class-validator` DTOs
- All responses through `ResponseInterceptor`
- TypeScript strict mode always on — no `any`
- Test files `.spec.ts` co-located

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
- Implementation pattern for presentation screens:
  1. `bool _initialLoadCompleted = false;`
  2. `load(...).whenComplete(() { if (mounted) setState(() => _initialLoadCompleted = true); });`
  3. Compute `showInitialSkeleton` from first-load flag + state.
  4. Route UI through `renderState` (`AsyncLoading` while first load is unresolved).
- This avoids incorrect transient UI states when cache is empty and API response is still in-flight.

---

## MVP Cost (testing phase — all free tiers)

| Service | Cost |
|---|---|
| GCP e2-micro VM | Free tier |
| MongoDB Atlas M0 | Free |
| PostgreSQL Neon.tech | Free |
| Redis Upstash | Free |
| Firebase Hosting | Free |
| Cloudflare / Dynu DNS | Free |

Production target (paid): ~$125-130/month on e2-standard-4.
**Rule: infrastructure spend must follow revenue, not precede it.**

---

## Infrastructure Evolution Policy

- **Now**: Everything in Docker on single GCP VM, free tiers for testing
- **Post-MVP** (when paying clients exist): MongoDB Atlas managed · GCP Memorystore · Cloud SQL · GKE

---

## Multi-LLM Workflow

| Tool | Role |
|---|---|
| **Claude Code** | Architect + Reviewer (security, cross-module decisions) |
| **Cursor** | Writer (boilerplate, CRUD, repetitive code) |
| **Codex** | Writer (scaffolding, DTOs, schemas, tests) |

**Never delegate to Cursor/Codex:** auth/security logic, DB schema design, RBAC, cross-module decisions.

---

## Technical Debt

### App Icon — Android & iOS not updated
- **Date**: 2026-04-10
- **Context**: New icon (Option 2 — El Escudo shield) applied to web only.
- **Pending**: Android `mipmap-*/ic_launcher.png` (5 sizes) · iOS `AppIcon.appiconset/` (15 files)
- **Source SVG**: `apps/mobile/web/icon-option-2.svg` — use `cairosvg` or `flutter_launcher_icons`
- **Priority**: Low — only needed before App Store / Google Play publish
