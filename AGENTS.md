# Vaulted — Agent Context (Codex / GitHub Copilot / AI Agents)

## Project Summary
Vaulted is a premium home inventory management SaaS for high-net-worth families in the USA.
Clients can own one or multiple properties. Each property has floors, rooms, and items.
This is a security-critical application — clients store sensitive asset data (jewelry, art, valuations).

## Monorepo Structure
```
vaulted/
├── apps/
│   ├── api/        # NestJS + TypeScript backend
│   └── mobile/     # Flutter mobile + web app
├── infra/
│   ├── docker/
│   └── nginx/
├── docker-compose.yml
├── docker-compose.dev.yml
└── .env.example
```

---

## Backend (apps/api/)

### Stack
- NestJS with TypeScript (strict mode)
- Mongoose for MongoDB
- TypeORM for PostgreSQL
- Redis via ioredis
- class-validator + class-transformer for DTOs
- Passport + JWT for authentication

### Key modules
```
src/modules/
├── auth/        # JWT, refresh tokens, MFA (TOTP + YubiKey)
├── users/       # User management — PostgreSQL
├── tenants/     # Client/family accounts — PostgreSQL
├── properties/  # Properties and rooms — MongoDB
├── inventory/   # Items and item history — MongoDB
├── wardrobe/    # Wardrobe extension — MongoDB
├── media/       # GCP Storage uploads
├── insurance/   # Policies and warranties — PostgreSQL
├── audit/       # Immutable audit logs — PostgreSQL
├── notifications/ # FCM push + SendGrid email
└── reports/     # PDF and Excel generation
```

### Coding conventions
- TypeScript strict mode, no `any`
- kebab-case for filenames, PascalCase for classes
- All DTOs validated with class-validator
- All responses wrapped in standard format: `{ success, data, meta? }`
- Every controller endpoint protected with JwtAuthGuard unless explicitly public
- Every data-modifying operation logged to AuditService
- tenantId always extracted from JWT payload — never from request body

### Rules for Codex / AI code generation
These rules are mandatory and must never be violated:

1. **tenantId source**: ALWAYS extract tenantId from `@CurrentUser() user: JwtPayload` → `user.tenantId`.
   NEVER use headers (`x-tenant-id` or any other), request body, or query params for tenantId.

2. **Guards and decorators**: Do NOT add guards or auth decorators in generated controllers.
   Leave a comment `// TODO: Claude Code will add @Roles() and guards` where authorization logic belongs.
   JwtAuthGuard is already applied globally.

3. **Audit logs**: Do NOT implement AuditService calls. Leave a comment `// TODO: audit log` on every
   write operation (POST, PUT, PATCH, DELETE). Claude Code will wire AuditService.

4. **Cross-tenant isolation**: Every MongoDB query MUST include `{ tenantId }` in the filter.
   Every PostgreSQL query MUST include `WHERE tenant_id = $tenantId`. No exceptions.

5. **No business logic in controllers**: Controllers only call service methods and return results.
   All logic goes in the service.

### Authentication flow
- Access token: 15 minutes, stored in memory
- Refresh token: 7 days, stored in httpOnly cookie
- Refresh rotation: each use generates a new refresh token
- Revocation: Redis blacklist for immediate token invalidation
- MFA: mandatory for Owner and Manager roles

### Multi-tenancy
- Every MongoDB document has tenantId
- Every PostgreSQL query filters by tenant_id
- Zero cross-tenant data access

### Audit logs rule
- audit_logs PostgreSQL table is WRITE-ONLY
- No UPDATE or DELETE operations ever on this table
- Every user action must be logged with: userId, action, entityType, entityId, ip, timestamp

---

## Mobile (apps/mobile/)

### Stack
- Flutter (Dart) — iOS, Android, Web from single codebase
- Riverpod for state management
- GoRouter for navigation
- Dio for HTTP (with certificate pinning)
- flutter_secure_storage for tokens
- Hive for offline cache
- Freezed + json_serializable for data models
- mobile_scanner for QR code scanning
- local_auth for biometric authentication

### Architecture
Feature-first with clean separation:
```
features/feature-name/
├── data/           # Repository + API models (Freezed)
├── domain/         # Riverpod providers + notifiers
└── presentation/   # Screens + feature-specific widgets
```

### Coding conventions
- snake_case for files, PascalCase for classes, camelCase for variables
- No business logic in widgets
- No Navigator.push — use GoRouter context.go() / context.push()
- No Image.network — use CachedNetworkImage
- No hardcoded colors/spacing — use AppColors / AppSpacing / AppTypography
- Tokens stored only in flutter_secure_storage
- All data models use Freezed for immutability

### Flutter async loading rule (mandatory)
- For screens that use `AsyncNotifier` and trigger `load()` in `WidgetsBinding.instance.addPostFrameCallback`, do not render empty/not-found states before the first real fetch completes.
- During first load, always show skeleton UI.
- Empty states (`No items`, `No data`, `Not found`) are allowed only after first load completion.
- Required screen pattern:
  1. Add `bool _initialLoadCompleted = false;`
  2. In `postFrame`, call `load(...).whenComplete(() { if (mounted) setState(() => _initialLoadCompleted = true); });`
  3. Build `showInitialSkeleton` from `!_initialLoadCompleted`, `!state.hasError`, and initial empty/null or loading state.
  4. Use `renderState` (`AsyncLoading` while `showInitialSkeleton` is true) for `.when(...)` rendering.
- This prevents premature flashes such as `No items`/`Policy not found` before API response arrives.

---

## Database Decision Guide

| Data type | Database |
|---|---|
| Items, properties, rooms, item history | MongoDB |
| Users, tenants, roles | PostgreSQL |
| Audit logs | PostgreSQL (immutable) |
| Insurance policies, financials | PostgreSQL |
| JWT blacklist, refresh tokens | Redis |
| Rate limiting counters | Redis |
| Frequently read cache | Redis |

---

## Security Non-Negotiables
These must never be skipped or simplified:

1. tenantId from JWT only — never trust client-provided tenantId
2. Every endpoint requires authentication unless explicitly marked public
3. Audit log every write operation
4. Sensitive fields (serial numbers, valuations) must be encrypted at rest
5. Rate limit all auth endpoints (max 5 attempts/min on login)
6. No secrets, API keys, or credentials in source code

---

## Environment Variables
Never hardcode these — always use process.env:
```
NODE_ENV, PORT, APP_URL
JWT_SECRET, JWT_EXPIRES_IN, JWT_REFRESH_SECRET, JWT_REFRESH_EXPIRES_IN
MONGODB_URI
POSTGRES_HOST, POSTGRES_PORT, POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD
REDIS_HOST, REDIS_PORT, REDIS_PASSWORD
GCP_PROJECT_ID, GCP_STORAGE_BUCKET, GCP_KEY_FILE
FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL
SENDGRID_API_KEY, EMAIL_FROM
SENTRY_DSN
```

---

## MVP Build Order

Linux environment and GCP VM are already configured. Build in this exact phase order.
Rule: backend must be complete and tested before building its Flutter counterpart.

```
Phase 0  — Project Bootstrap
           Monorepo structure, Docker Compose, NestJS init, Flutter init

Phase 1  — Authentication
           tenants → users → auth (JWT + MFA) → Flutter login/MFA screens

Phase 2  — Properties
           Properties + floors + rooms CRUD → Flutter property screens

Phase 3  — Inventory Core
           Item CRUD + move + loan + history + QR + search → Flutter inventory screens

Phase 4  — Media Upload
           GCP Storage provider + photo upload → Flutter image picker

Phase 5  — Dashboard & Search
           Aggregated stats + Redis cache + filters → Flutter dashboard

Phase 6  — Users & Roles (parallel with Phase 3-5)
           Invite users + RBAC per property → Flutter team management

Phase 7  — Notifications
           FCM push + email + scheduled jobs (warranty/loan alerts)

Phase 8  — Reports
           PDF inventory + insurance valuation report → Flutter download/share

Phase 9  — Wardrobe Module
           Garment attributes + outfit builder → Flutter closet view

Phase 10 — CI/CD & Production Deploy
           GitHub Actions + Nginx + Cloudflare + GCP VM deploy
```

### MVP is done when a user can:
- Create account + MFA setup
- Add properties with floors and rooms
- Add items with photos and valuations
- Scan item QR codes with mobile
- Invite a manager with scoped access
- Receive overdue loan notifications
- Export an inventory PDF
- All running on GCP VM within $130/month budget

---

## Skills Available

### Built-in (no install required)
| Skill | Use case |
|---|---|
| `/simplify` | After every module — quality, reuse, efficiency review |
| `/loop` | Monitor GCP VM and deployments |
| `/claude-api` | AI categorization feature (future phase) |
| `/accessibility-a11y` | Flutter Web accessibility |
| `/a11y-playwright-testing` | Automated accessibility testing |
| `/batch` | Parallelize large cross-module changes |

### Community (install on Linux before Phase 0 — two steps each)
```bash
# Step 1: add marketplaces
/plugin marketplace add anthropics/claude-code
/plugin marketplace add jeffallan/claude-skills
/plugin marketplace add levnikolaevich/claude-code-skills
/plugin marketplace add trailofbits/skills

# Step 2: install plugins
/plugin install fullstack-dev-skills@jeffallan
/plugin install production-workflows@levnikolaevich
/plugin install security-skills@trailofbits
/plugin install document-skills@anthropics

# Verify all installed
/plugin list
```
> Confirm exact plugin names per marketplace with: `/plugin marketplace list <marketplace>`

### Key skills per phase
- **Phase 0**: docker-expert, cicd-engineer
- **Phase 1**: authentication-security-validator, jwt-expert
- **Phase 2-3**: nestjs-expert, database-architect, orm-specialist
- **Phase 4**: gcp-architect
- **Phase 5**: redis-expert, query-optimizer
- **Phase 6**: secure-code-guardian, audit-logging-specialist
- **Phase 8**: pdf, xlsx (anthropics/skills)
- **Phase 9**: flutter-expert
- **Phase 10**: github-actions-expert, docker-expert

### Security skills — mandatory before marking any phase done
```
/secure-code-guardian
/authentication-security-validator  (Phase 1 only)
/vulnerability-scanner              (Phase 10 — before production)
/audit-logging-specialist           (every phase that writes data)
```

---

## Multi-LLM Workflow

This project uses three AI tools with defined roles:

| Tool | Role |
|---|---|
| Claude Code | Architecture, security, cross-module decisions, code review |
| Cursor | Boilerplate, CRUD, DTOs, widgets, repetitive code |
| Codex | Module scaffolding, schemas, unit tests |

### Workflow per feature
1. Plan with Claude Code — what to build and in what order
2. Write with Cursor/Codex — boilerplate and repetitive code
3. Review with Claude Code — quality, security, coherence

### Never use Cursor/Codex for
- Auth and security logic
- Database schema design
- RBAC / permissions
- Anything touching multiple modules simultaneously

---

## What this project is NOT
- Not a logistics or warehouse management app
- Not a public marketplace
- Not a simple note-taking app
- This is a security-critical, premium SaaS — every decision should reflect that

## Code Quality Bar
- Code must be clean enough for a senior engineer to review without confusion
- No clever tricks — prefer readable over clever
- Every public method should be self-documenting by name
- If logic is non-obvious, add a brief inline comment


<claude-mem-context>
# Memory Context

# [vaulted] recent context, 2026-04-16 9:31pm GMT-5

No previous sessions found.
</claude-mem-context>
