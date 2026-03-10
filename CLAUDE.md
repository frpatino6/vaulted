# Vaulted — Project Context for Claude Code

## What is Vaulted?

Premium home inventory management app for high-net-worth families in the USA.
These families own one or multiple properties (mansions) and need to track everything
inside: furniture, art, electronics, wardrobe, jewelry, watches, vehicles, wine cellars, etc.

Each client (tenant) can have one or multiple properties.
Each property has floors, rooms, and items assigned to specific locations.

---

## Product Decisions

- **App name**: Vaulted
- **Tagline concept**: "Everything you own. Protected. Organized. Yours."
- **Target market**: Ultra-high-net-worth families in the USA
- **Business model**: Premium SaaS subscription (per number of properties or items)
- **Language**: English (with potential future expansion to Spanish-speaking premium market)

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Mobile / Web | Flutter | Single codebase for iOS, Android, Web |
| Backend | NestJS + TypeScript | Modular architecture, mandatory TypeScript |
| Primary DB | MongoDB | Inventory, items, properties (flexible schema) |
| Secondary DB | PostgreSQL | Users, audit logs, insurance, financials |
| Cache / Sessions | Redis | JWT blacklist, rate limiting, session cache |
| Media Storage | GCP Cloud Storage | Photos, documents, certificates |
| CDN | GCP Cloud CDN | Media delivery |
| Infrastructure | GCP VM + Docker | Single VM with Docker Compose |
| Reverse Proxy | Nginx | SSL termination, security headers |
| DNS / WAF / DDoS | Cloudflare | Hides VM IP, WAF, DDoS protection |
| CI/CD | GitHub Actions | Lint, test, security scan, deploy |
| Error Monitoring | Sentry | Backend + Flutter |
| Push Notifications | Firebase FCM | Mobile push |
| Email | SendGrid or Resend | Transactional emails |

---

## Infrastructure

### GCP VM Specs (production)
- Type: e2-standard-4 (4 vCPU, 16GB RAM)
- Disk: 100GB SSD Persistent Disk (separate from VM)
- Region: US (data residency requirement)
- Backups: Daily automated GCP snapshots

### Architecture Flow
```
Cloudflare (DNS + WAF + DDoS)
    → Nginx (reverse proxy + SSL)
        → Docker Compose
            ├── NestJS API (port 3000, internal only)
            ├── MongoDB (internal only)
            ├── PostgreSQL (internal only)
            └── Redis (internal only)
GCP Cloud Storage + CDN → media files only
```

### VM Security Checklist (must implement before launch)
- Firewall: only ports 80, 443, and one non-standard SSH port open
- SSH: key-based only, password login disabled
- Fail2ban installed and configured
- UFW as secondary firewall layer
- Unattended security upgrades enabled
- Containers run as non-root user
- .env never in repository (use GCP Secret Manager for production secrets)
- Cloudflare proxying to hide real VM IP
- Daily automated snapshots of GCP Persistent Disk

---

## Roles and Access Control

```
Owner        → full access to everything, manages users
Manager      → manages inventory, cannot see financial valuations
Staff        → view and update status of assigned items only
Auditor      → read-only, specific categories only, watermarked exports
Guest        → temporary access with expiration date
```

- Access is scoped per property (staff of Miami house cannot see Aspen house)
- Temporary access tokens for third parties (appraisers, insurance agents)

---

## Security Requirements

### Authentication
- JWT: Access Token 15 min (in memory) + Refresh Token 7 days (httpOnly cookie)
- Refresh rotation: every use generates new refresh token
- Token blacklist in Redis for immediate revocation
- MFA mandatory for Owner and Manager roles (TOTP + YubiKey support)
- Passkeys / FIDO2 support as passwordless option
- Login from new geographic location triggers immediate notification

### Data Protection
- AES-256 encryption for data at rest
- TLS 1.3 mandatory for all communications
- MongoDB CSFLE (Client-Side Field Level Encryption) for sensitive fields
- Sensitive PostgreSQL columns encrypted with pgcrypto
- E2E encryption for documents (invoices, certificates, policies)

### Mobile Security
- Certificate pinning (Dio)
- Tokens stored in Secure Enclave (iOS) / Android Keystore
- Jailbreak/root detection
- Screenshots blocked on sensitive screens
- Session timeout with biometric re-auth

### Audit Logs
- Immutable audit log table in PostgreSQL (no UPDATE/DELETE allowed)
- Logs every action: who, what, when, from where
- Minimum 2-year retention
- Exportable for forensic investigation

### Compliance targets
- SOC 2 Type II (process starts after MVP)
- CCPA (California)
- ISO 27001 (strategic, 6-12 months post-launch)

---

## Domain-Specific Risks

| Risk | Mitigation |
|---|---|
| Inventory exposed to criminals | E2E encryption, IP allowlist option, no search engine indexing |
| Malicious insider (domestic staff) | Immutable logs, minimum access, behavior alerts |
| Divorce / legal disputes | Per-co-owner access controls, account freeze option |
| Owner death | Account transfer protocol with legal verification |
| Social engineering support | Zero-knowledge support model |

---

## Item Categories

```
Furniture (living room, dining, bedroom, outdoor)
Art & Collectibles
Appliances & Technology
Wardrobe
  ├── Clothing (formal, casual, sport)
  ├── Footwear
  ├── Accessories (bags, belts, hats)
  └── Jewelry & Watches
Vehicles (cars, boats, motorcycles)
Wine & Spirits (cellar)
Books & Library
Sports Equipment
Musical Instruments
Household Supplies (linens, tableware, glassware)
```

---

## Key Features (MVP)

- Multi-property management per client
- Hierarchical organization: Property → Floor → Room → Item
- Item registration with photos (up to 10), attributes, serial number, valuation
- QR code per item for quick mobile scan
- Item status tracking: active, loaned, repair, storage, disposed
- Item movement history between properties
- Loan tracking (to whom, expected return date)
- Purchase value, current value, depreciation tracking
- Document attachment (invoices, warranties, certificates)
- Role-based access control per property
- Push and email notifications (warranty expiration, maintenance due, overdue loans)
- PDF export for insurance valuation
- Full-text global search

## Key Features (Phase 2)

- Wardrobe module: virtual closet, outfits, dry cleaning tracking
- Insurance policies linked to items
- Maintenance calendar with service history
- Incident reports for claims
- AI-powered category suggestions from photos
- Dashboard KPIs

## Key Features (Phase 3)

- Bulk import via Excel/CSV
- REST API for external integrations
- Advanced financial reports
- Offline mode with sync
- Private cloud / on-premise option for ultra-premium clients

---

## Project Structure

### Monorepo layout
```
vaulted/
├── apps/
│   ├── api/          # NestJS backend
│   └── mobile/       # Flutter app
├── packages/
│   └── shared-types/ # Shared TypeScript types (for future web)
├── infra/
│   ├── docker/
│   └── nginx/
├── .github/
│   └── workflows/
├── docker-compose.yml
├── docker-compose.dev.yml
├── .env.example
└── CLAUDE.md
```

### Backend modules (apps/api/src/modules/)
```
auth/          # JWT, refresh tokens, MFA, sessions
users/         # User management (PostgreSQL)
tenants/       # Client/family management (PostgreSQL)
properties/    # Properties and rooms (MongoDB)
inventory/     # Items and item history (MongoDB)
wardrobe/      # Wardrobe extension of inventory (MongoDB)
media/         # File upload to GCP Storage
insurance/     # Policies and warranties (PostgreSQL)
audit/         # Immutable audit logs (PostgreSQL)
notifications/ # Push (FCM) and email (SendGrid/Resend)
reports/       # PDF and Excel report generation
```

### Flutter architecture (apps/mobile/lib/)
```
core/
  config/       # App config, flavors (dev/staging/prod)
  network/      # Dio + interceptors + certificate pinning
  storage/      # flutter_secure_storage (tokens), Hive (offline cache)
  security/     # Jailbreak detector, screenshot guard
  router/       # GoRouter + auth guard + role guard
  theme/        # Design system, colors, typography, spacing

features/       # Feature-first structure
  auth/
  dashboard/
  properties/
  inventory/
  wardrobe/
  reports/
  settings/

shared/
  widgets/      # Reusable premium UI components
  extensions/   # Dart extensions
```

### Flutter key packages
```yaml
dio: ^5.x                    # HTTP client + interceptors
flutter_secure_storage: ^9.x # Secure Enclave / Android Keystore
hive_flutter: ^1.x           # Local offline database
flutter_riverpod: ^2.x       # State management
go_router: ^13.x             # Navigation
mobile_scanner: ^5.x         # QR / Barcode scanning
local_auth: ^2.x             # Biometric authentication
cached_network_image: ^3.x   # Image caching
sentry_flutter: ^8.x         # Error monitoring
freezed: ^2.x                # Immutable data classes
json_serializable: ^6.x      # JSON serialization
```

---

## MongoDB Schemas (key structures)

### Property
```javascript
{
  _id: ObjectId,
  tenantId: ObjectId,
  name: String,
  type: "primary|vacation|rental",
  address: { street, city, state, zip, country },
  floors: [{ floorId, name, rooms: [{ roomId, name, type }] }],
  photos: [String],
  createdAt: Date,
  updatedAt: Date
}
```

### Item
```javascript
{
  _id: ObjectId,
  tenantId: ObjectId,
  propertyId: ObjectId,
  roomId: ObjectId,
  name: String,
  category: String,
  subcategory: String,
  attributes: {},           // flexible per category
  valuation: {
    purchasePrice: Number,
    purchaseDate: Date,
    currentValue: Number,
    currency: "USD",
    lastAppraisalDate: Date
  },
  status: "active|loaned|repair|storage|disposed",
  photos: [String],
  documents: [String],
  qrCode: String,
  tags: [String],
  insurance: { policyId, coveredValue },
  createdBy: ObjectId,
  createdAt: Date,
  updatedAt: Date
}
```

### ItemHistory
```javascript
{
  _id: ObjectId,
  itemId: ObjectId,
  tenantId: ObjectId,
  action: "moved|loaned|returned|repaired|valued|status_changed",
  fromPropertyId: ObjectId,
  toPropertyId: ObjectId,
  performedBy: ObjectId,
  notes: String,
  timestamp: Date
}
```

---

## PostgreSQL Tables (key structures)

```sql
tenants     (id, name, plan, status, created_at)
users       (id, tenant_id, email, password_hash, role, mfa_enabled, mfa_secret, last_login)
audit_logs  (id, tenant_id, user_id, action, entity_type, entity_id, metadata, ip_address, created_at)
            -- NO UPDATE or DELETE allowed on this table
insurance_policies (id, tenant_id, provider, policy_number, coverage_type, premium, expires_at)
```

---

## JWT Strategy

```
Access Token:   15 minutes  — stored in memory (Flutter)
Refresh Token:  7 days      — stored in httpOnly cookie / secure storage
Rotation:       each use generates new refresh token
Blacklist:      Redis (for immediate revocation on logout or suspicious activity)
```

---

## MVP Development Roadmap

Linux environment and GCP VM are already configured. Start directly with code.
Rule: backend module must be complete and tested before building its Flutter counterpart.

---

### PHASE 0 — Project Bootstrap
**Goal: monorepo running locally with all services up**

#### Step 1 — Monorepo structure
```
mkdir vaulted && cd vaulted
mkdir -p apps/api apps/mobile packages/shared-types infra/docker infra/nginx .github/workflows
```

#### Step 2 — Docker Compose (dev)
- `docker-compose.dev.yml` with: api + mongodb + postgres + redis
- Verify all containers start and connect to each other
- `GET /health` returns 200 before moving forward
- ✅ Done when: `docker-compose -f docker-compose.dev.yml up` runs cleanly

#### Step 3 — NestJS project init
```bash
cd apps/api
npx @nestjs/cli new . --package-manager npm --language typescript
```
- Configure: tsconfig strict mode, ESLint, Prettier
- Install core dependencies: mongoose, typeorm, pg, ioredis, passport, jwt, class-validator
- Connect MongoDB, PostgreSQL, Redis — verify connections on startup
- Create `ResponseInterceptor`, `HttpExceptionFilter`, `ValidationPipe`
- ✅ Done when: API starts, connects to all 3 databases, `/health` returns status of each

#### Step 4 — Flutter project init
```bash
cd apps/mobile
flutter create . --org com.vaulted --project-name vaulted
```
- Install core packages: dio, riverpod, go_router, flutter_secure_storage, hive, freezed
- Set up folder structure: core/, features/, shared/
- Set up AppTheme, AppColors, AppTypography, AppSpacing
- Configure GoRouter with placeholder routes
- ✅ Done when: app launches on simulator with theme applied

---

### PHASE 1 — Authentication
**Goal: users can register, login, use MFA, and logout securely**
**Dependency: Phase 0 complete**

#### Backend first
1. `tenants` module — PostgreSQL entity + CRUD (create tenant = create family account)
2. `users` module — PostgreSQL entity, password hashing (bcrypt), roles enum
3. `auth` module in this order:
   - POST `/auth/register` — create tenant + owner user
   - POST `/auth/login` — validate credentials, return JWT pair
   - POST `/auth/refresh` — refresh token rotation, Redis blacklist check
   - POST `/auth/logout` — add token to Redis blacklist
   - POST `/auth/mfa/setup` — generate TOTP secret (speakeasy)
   - POST `/auth/mfa/verify` — validate TOTP code
4. `JwtAuthGuard`, `RolesGuard`, `@CurrentUser()`, `@Roles()` decorators
5. `AuditService` — write-only service logging to PostgreSQL audit_logs
6. ✅ Done when: full auth flow tested with Postman/Insomnia, MFA working

#### Flutter second
1. `core/network/api_client.dart` — Dio instance + auth interceptor (attach token, handle 401)
2. `core/storage/secure_storage.dart` — store/retrieve/delete tokens
3. `features/auth/` — login screen, MFA screen, auth provider (Riverpod)
4. GoRouter auth guard — redirect to login if no valid token
5. ✅ Done when: user can log in, MFA works, token refreshes silently, logout clears storage

---

### PHASE 2 — Properties
**Goal: owner can create properties and organize them by floors and rooms**
**Dependency: Phase 1 complete**

#### Backend first
1. `properties` module — MongoDB schema
2. Endpoints:
   - GET/POST `/properties`
   - GET/PUT/DELETE `/properties/:id`
   - POST `/properties/:id/floors`
   - POST `/properties/:id/floors/:floorId/rooms`
3. All queries scoped by tenantId from JWT
4. All mutations logged to AuditService
5. ✅ Done when: CRUD tested, tenantId isolation verified

#### Flutter second
1. `features/properties/` — list screen, detail screen, add property form
2. `PropertyCard` widget in shared/widgets
3. Navigation: dashboard → properties → property detail → rooms
4. ✅ Done when: owner can create a property, add floors and rooms, see them listed

---

### PHASE 3 — Inventory Core
**Goal: items can be created, assigned to rooms, and tracked**
**Dependency: Phase 2 complete**

#### Backend first
1. `inventory` module — MongoDB schemas: Item + ItemHistory
2. Item status enum: active, loaned, repair, storage, disposed
3. Item category enum: furniture, art, technology, wardrobe, vehicles, wine, sports, other
4. Endpoints:
   - GET/POST `/items`
   - GET/PUT/DELETE `/items/:id`
   - POST `/items/:id/move` — move between properties/rooms, log to ItemHistory
   - POST `/items/:id/loan` — register loan with borrower and expected return
   - GET `/items/:id/history`
   - GET `/items/search?q=` — full-text search (MongoDB text index)
5. QR code generation on item creation (qrcode package)
6. All mutations logged to AuditService
7. ✅ Done when: full CRUD tested, move and loan tracked in history, search works

#### Flutter second
1. `features/inventory/` — list screen, item detail, add item form
2. `ItemCard`, `ItemStatusBadge`, `CategoryFilter` widgets
3. QR scanner screen using mobile_scanner package
4. ✅ Done when: user can add item with category, see it in the room, scan its QR code

---

### PHASE 4 — Media Upload
**Goal: items can have photos and documents attached**
**Dependency: Phase 3 complete**

#### Backend first
1. `media` module — GCP Cloud Storage provider
2. POST `/media/upload` — multipart upload, return public CDN URL
3. DELETE `/media/:id` — remove from GCP Storage
4. Attach photo URLs to Item documents on creation/update
5. ✅ Done when: image uploads to GCP, URL stored in item, accessible via CDN

#### Flutter second
1. `ImagePickerWidget` — camera + gallery, preview, upload progress
2. Integrate into add/edit item form
3. `CachedNetworkImage` for displaying item photos
4. ✅ Done when: user can take/select photo, it uploads and appears on item detail

---

### PHASE 5 — Dashboard & Search
**Goal: owner sees portfolio overview at a glance**
**Dependency: Phase 4 complete**

#### Backend first
1. GET `/dashboard` — returns: total properties, total items, items by status, total valuation
2. Cache dashboard response in Redis (TTL: 2 min)
3. GET `/items/search?q=&category=&propertyId=&status=` — filtered search
4. ✅ Done when: dashboard data accurate, search filters work, cache verified

#### Flutter second
1. `features/dashboard/` — stats summary, property cards, recent activity
2. Global search screen with filters
3. ✅ Done when: dashboard loads fast, search returns correct filtered results

---

### PHASE 6 — Users & Roles
**Goal: owner can invite managers and staff with scoped access**
**Dependency: Phase 1 complete (can be done in parallel with Phase 3-5)**

#### Backend first
1. POST `/users/invite` — send invitation email with temp token
2. GET/PUT `/users/:id` — manage user profile and role
3. DELETE `/users/:id` — deactivate user (soft delete)
4. Property-scoped access — user can only access assigned properties
5. ✅ Done when: owner invites manager, manager logs in with scoped access verified

#### Flutter second
1. `features/settings/users_screen.dart` — list users, invite, change role
2. ✅ Done when: owner can manage team from the app

---

### PHASE 7 — Notifications
**Goal: users receive alerts for warranties, loans, and maintenance**
**Dependency: Phase 3 complete**

#### Backend
1. `notifications` module — FCM provider + email provider
2. Scheduled jobs (node-cron):
   - Daily check: warranties expiring in 30 days → push + email
   - Daily check: loans overdue → push + email
3. POST `/notifications/test` — manual trigger for testing
4. ✅ Done when: notifications arrive on device for test triggers

---

### PHASE 8 — Reports
**Goal: owner can export inventory and insurance valuation reports**
**Dependency: Phase 3 complete**

#### Backend
1. `reports` module — PDF generation (puppeteer or pdfkit)
2. GET `/reports/inventory` — full inventory PDF/Excel per property
3. GET `/reports/insurance` — valuation report formatted for insurers
4. ✅ Done when: PDF generated with correct data, downloadable from app

#### Flutter
1. `features/reports/` — report selection screen, download + share
2. ✅ Done when: user taps generate, PDF downloads and can be shared

---

### PHASE 9 — Wardrobe Module
**Goal: wardrobe items have specific attributes and closet view**
**Dependency: Phase 4 complete**

#### Backend
1. `wardrobe` module extends inventory — adds garment-specific attributes
2. Outfit creation — link multiple wardrobe items
3. Dry cleaning / repair status tracking
4. ✅ Done when: garment CRUD works with wardrobe-specific fields

#### Flutter
1. `features/wardrobe/` — closet view, outfit builder
2. ✅ Done when: user sees wardrobe items in visual closet layout

---

### PHASE 10 — CI/CD & Production Deploy
**Goal: automated pipeline, app running on GCP VM**
**Dependency: Phases 1-8 complete**

1. GitHub Actions: lint + test + security scan on every PR
2. GitHub Actions: auto-deploy to GCP VM on merge to main
3. Nginx config: SSL, security headers, rate limiting at proxy level
4. Cloudflare: DNS pointing to VM, WAF rules active
5. GCP VM snapshot schedule: daily automated backup
6. Sentry configured for backend + Flutter
7. ✅ Done when: push to main auto-deploys, app accessible via domain, SSL active

---

### MVP Definition of Done
The MVP is complete when a real user (owner) can:
- [ ] Create an account and set up MFA
- [ ] Add a property with floors and rooms
- [ ] Add items to rooms with photos and valuation
- [ ] Scan item QR codes with the mobile app
- [ ] Invite a manager with scoped access
- [ ] Receive a notification for an overdue loan
- [ ] Export an inventory PDF
- [ ] All running on GCP VM within the $130/month budget

---

## MVP Cost Philosophy

For the MVP, everything that can run in Docker on the same VM runs there — no managed services.
The project only advances if the MVP validates the market, so infrastructure spend must be minimal.

### Services running in Docker (no additional cost)
- NestJS API
- MongoDB
- PostgreSQL
- Redis (consumes only ~10-30MB RAM — negligible on a 16GB VM)
- Nginx

### Redis cost clarification
Redis runs as a Docker container on the same GCP VM. Cost = $0.
Managed Redis services (GCP Memorystore ~$35/mo, Redis Cloud, Upstash) are NOT used in MVP.
This decision is intentional — migrate only if scale demands it.

### MVP monthly cost estimate
| Concept | Cost/month |
|---|---|
| GCP VM e2-standard-4 (4 vCPU, 16GB RAM) | ~$100 |
| GCP Persistent Disk 100GB SSD | ~$17 |
| GCP Cloud Storage (item photos/docs) | ~$5-10 |
| Cloudflare (DNS + WAF + DDoS) | $0 Free tier |
| Firebase FCM (push notifications) | $0 Free tier |
| Resend (transactional email) | $0 up to 3k emails/month |
| **Total** | **~$125-130/month** |

---

## Environment Variables Required (.env.example)

```
# App
NODE_ENV=production
PORT=3000
APP_URL=https://api.vaulted.app

# JWT
JWT_SECRET=
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=
JWT_REFRESH_EXPIRES_IN=7d

# MongoDB
MONGODB_URI=mongodb://mongodb:27017/vaulted

# PostgreSQL
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=vaulted
POSTGRES_USER=
POSTGRES_PASSWORD=

# Redis
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# GCP Storage
GCP_PROJECT_ID=
GCP_STORAGE_BUCKET=
GCP_KEY_FILE=

# Firebase (Push notifications)
FIREBASE_PROJECT_ID=
FIREBASE_PRIVATE_KEY=
FIREBASE_CLIENT_EMAIL=

# Email
SENDGRID_API_KEY=
EMAIL_FROM=noreply@vaulted.app

# Sentry
SENTRY_DSN=
```

---

## Coding Conventions

### Backend (NestJS)
- Every feature = one folder inside `modules/`
- Files: kebab-case | Classes: PascalCase
- All input validated with `class-validator` DTOs
- All responses through standard `ResponseInterceptor`
- Test files: `.spec.ts` co-located with the file they test
- TypeScript strict mode: always on
- No `any` types allowed

### Mobile (Flutter)
- Architecture: Feature-first + Riverpod
- Files: snake_case | Classes: PascalCase
- Data models: Freezed + json_serializable (immutability)
- Each feature: data / domain / presentation separated
- Shared widgets only in `shared/widgets/`
- No business logic in UI widgets

---

## Skills Configuration

### Built-in Skills (available immediately, no install needed)

| Skill | When to use in Vaulted |
|---|---|
| `/simplify` | After completing any module — review quality, reuse, efficiency |
| `/loop` | Monitor deployment status, poll GCP VM health during CI/CD |
| `/claude-api` | When building AI categorization feature (Phase 9+) |
| `/accessibility-a11y` | Flutter Web portal — WCAG compliance for premium clients |
| `/a11y-playwright-testing` | Automated accessibility tests on Flutter Web |

### Community Skills — Install on Linux BEFORE starting Phase 0

Skills are installed through a two-step process: add marketplace, then install plugin.
Run these commands in Claude Code on the Linux machine before writing any code.

```bash
# STEP 1 — Add marketplaces

# Official Anthropic (PDF, Excel, document generation)
/plugin marketplace add anthropics/claude-code

# Full-stack skills: NestJS, Flutter, DB, security (66+ skills)
/plugin marketplace add jeffallan/claude-skills

# Production workflows: audits, bootstrap, agile, documentation (114+ skills)
/plugin marketplace add levnikolaevich/claude-code-skills

# Security: JWT, OWASP, vulnerability detection
/plugin marketplace add trailofbits/skills


# STEP 2 — Install plugins from each marketplace

/plugin install fullstack-dev-skills@jeffallan
/plugin install production-workflows@levnikolaevich
/plugin install security-skills@trailofbits
/plugin install document-skills@anthropics
```

> Note: exact plugin names per marketplace must be confirmed on Linux with:
> `/plugin marketplace list jeffallan/claude-skills`

### Skills per Development Phase

| Phase | Skills to use |
|---|---|
| Phase 0 — Bootstrap | `docker-expert`, `cicd-engineer` |
| Phase 1 — Auth | `authentication-security-validator`, `jwt-expert`, `mfa-implementation` |
| Phase 2-3 — Properties/Inventory | `nestjs-expert`, `database-architect`, `orm-specialist` |
| Phase 4 — Media | `gcp-architect` |
| Phase 5 — Dashboard | `redis-expert`, `query-optimizer` |
| Phase 6 — Users/Roles | `secure-code-guardian`, `audit-logging-specialist` |
| Phase 7 — Notifications | `nestjs-expert` |
| Phase 8 — Reports | `pdf`, `xlsx` (anthropics/skills) |
| Phase 9 — Wardrobe | `flutter-expert` |
| Phase 10 — CI/CD | `github-actions-expert`, `docker-expert` |

### Security skills — mandatory gate before marking any phase done
```
/secure-code-guardian          → every module, every phase
/authentication-security-validator → Phase 1 only
/vulnerability-scanner         → Phase 10 before production deploy
/audit-logging-specialist      → every phase that writes data to DB
```

### Large-scale operations
```
/batch   → parallelize changes across multiple modules simultaneously
/loop 5m → monitor GCP VM health every 5 minutes during deploy
```

### First thing to do on Linux (before Phase 0)
```
1. Open Claude Code in the vaulted/ directory
2. Install all marketplaces and plugins above
3. Verify with: /plugin list
4. Then start Phase 0
```

---

## MCP Servers Configuration (Linux)

These MCPs allow Claude Code to monitor the GCP VM status and billing directly from the IDE.

### Install on Linux

```bash
# 1. gcloud MCP Server (official, Google-maintained)
npm install -g @googleapis/gcloud-mcp

# 2. GCP Billing MCP
pip install mcp-google_cloud_billing
```

### Configure Claude Code (~/.claude.json or MCP settings)

```json
{
  "mcpServers": {
    "gcloud": {
      "command": "npx",
      "args": ["@googleapis/gcloud-mcp"]
    },
    "gcp-billing": {
      "command": "python",
      "args": ["-m", "mcp_google_cloud_billing"]
    }
  }
}
```

### What each MCP provides

**gcloud MCP** (`googleapis/gcloud-mcp`)
- Check VM status and resource usage (CPU, RAM, disk)
- Verify Docker containers are running
- Query GCP logs
- Safe: blocks destructive gcloud commands

**GCP Billing MCP** (`mcp-google_cloud_billing`)
- `gcp-billing-analyse-costs` — cost breakdown by service and period
- `gcp-billing-detect-anomalies` — detect unexpected cost spikes
- `gcp-billing-cost-recommendations` — saving recommendations
- `gcp-billing-service-breakdown` — VM vs Storage vs Network breakdown

**Google Cloud Monitoring MCP** (built into GCP)
- Real-time metrics: CPU, memory, disk, network
- Natural language metric queries
- Alerts and logs

### MCP usage goal during MVP
Use these MCPs actively during development to ensure the VM stays within the ~$130/month
budget. Claude will help review VM status and costs on demand to catch anomalies early.
No managed services until a paying client contract justifies the upgrade.

### Useful prompts once configured

```
"How much have we spent on GCP this month vs our $130 budget?"
"Are all Docker containers for Vaulted running?"
"Any cost anomalies detected this week?"
"What is the current CPU and RAM usage on the VM?"
"Show me GCP Storage usage — are we within MVP estimates?"
```

---

## Infrastructure Evolution Policy

### MVP phase (no paying clients yet)
- Everything runs in Docker on a single GCP VM
- Target cost: ~$125-130/month
- Monitor with MCPs to prevent unexpected cost spikes
- No managed services — not justified without revenue

### Post-MVP (when client contracts exist)
Only then evaluate upgrading to managed services:
- MongoDB Atlas (managed, backups, scaling)
- GCP Memorystore (managed Redis)
- Cloud SQL (managed PostgreSQL)
- Scale VM or migrate to GKE (Kubernetes)
- Managed backups with guaranteed SLAs
- Stricter uptime SLAs for enterprise clients

**Rule: infrastructure spend must follow revenue, not precede it.**

---

## Multi-LLM Workflow Strategy

Three AI tools are used in parallel to build this project efficiently:

| Tool | Role | Strengths |
|---|---|---|
| **Claude Code** | Architect + Reviewer | Deep reasoning, security, cross-module decisions |
| **Cursor** | Writer | In-editor autocompletion, boilerplate, repetitive code |
| **Codex** | Writer | Module scaffolding, DTOs, schemas, tests |

### Rule: Think → Write → Review
```
1. PLAN   with Claude Code  → architecture, decisions, what to build next
2. WRITE  with Cursor/Codex → boilerplate, CRUD, DTOs, widgets
3. REVIEW with Claude Code  → /simplify, security check, coherence
```

### Never delegate to Cursor/Codex
- Architecture decisions
- Auth and security logic
- Database schema design
- RBAC / permissions logic
- Anything affecting multiple modules simultaneously

### Context files per tool
- `CLAUDE.md`   → Claude Code reads automatically
- `.cursorrules` → Cursor reads automatically
- `AGENTS.md`   → Codex / GitHub Copilot reads automatically

All three files are derived from the same decisions — single source of truth.

---

## Notes for Next Session

- Project code has NOT been written yet — we are in architecture/planning phase
- Next step decided: generate the base project code structure
- Docker Compose and NestJS bootstrap are the first things to implement
- The Linux machine is where actual development will happen
- GCP VM setup will come after local dev environment is working




 ##Orden de arranque en Linux:
  ##1. cd ~/vaulted
  ##2. claude
  ##3. Instalar los 4 marketplaces y 4 plugins
 ## 4. /plugin list  ← verificar que todo quedó
  ##5. Arrancar Phase 0