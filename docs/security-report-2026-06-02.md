# Vaulted — Security Status Report
**Date:** June 2, 2026 | **Classification:** Confidential | **Audience:** Executive & Engineering

---

# ENGLISH VERSION

---

## Executive Summary

Vaulted stores the complete asset inventory of ultra-high-net-worth families: what they own, where it is physically located, how much each item is worth, and photos of everything. A security breach is not just a privacy problem — it is a real physical risk vector: planned theft, extortion, or kidnapping based on wealth and location data.

Over the past 30 days, Vaulted underwent a comprehensive security audit covering all 14 security domains (OWASP Top 10, STRIDE threat modeling, AI security, supply chain, infrastructure hardening, mobile security). **36 vulnerabilities were identified and remediated** (1 critical, 2 high from the final CSO audit; plus earlier rounds). Zero critical vulnerabilities remain open.

---

## 1. Authentication & Access Control

| Control | Status | Detail |
|---|---|---|
| JWT Access Tokens | ✅ Implemented | 24h expiry, in-memory only (Flutter), HMAC-SHA256 |
| JWT Refresh Tokens | ✅ Implemented | 7-day expiry, httpOnly cookie / secure storage |
| Refresh Token Rotation | ✅ Implemented | One-time-use; replay attack triggers full session invalidation |
| Token Blacklist | ✅ Implemented | Redis-based immediate revocation on logout/rotation |
| Multi-Factor Authentication (TOTP) | ✅ Implemented | Mandatory for Owner and Manager roles |
| MFA Rate Limiting | ✅ Implemented | 5 attempts/minute on `/auth/mfa/verify` |
| MFA Setup Enforcement | ✅ Implemented | Access token with `mfaVerified=false` until MFA is configured |
| Role-Based Access Control (RBAC) | ✅ Implemented | 5 roles: Owner, Manager, Staff, Auditor, Guest |
| Property-scoped Access | ✅ Implemented | Staff of Property A cannot access Property B |
| Guest Expiration Guard | ✅ Implemented | Temporary tokens auto-revoked after expiry date |
| Privilege Escalation Prevention | ✅ Fixed (Jun 1) | Manager cannot promote users to Owner — `actorRole` guard enforced |

---

## 2. Data Encryption

| Control | Status | Detail |
|---|---|---|
| Encryption at Rest (fields) | ✅ Implemented | AES-256-GCM field-level encryption (FLE) on valuations, insurance fields, MFA secrets |
| Per-Tenant Key Derivation | ✅ Implemented | HKDF-SHA-256 with `tenantId` as context — different key per tenant |
| Encryption Key Management | ✅ Implemented | Master key via `ENCRYPTION_KEY` env var; salt via `ENCRYPTION_SALT` |
| TLS in Transit | ✅ Implemented | TLS 1.3 via Caddy + Let's Encrypt; Cloudflare proxy layer |
| PostgreSQL TLS | ✅ Fixed | `rejectUnauthorized: true` in production; `POSTGRES_CA_CERT` supported |
| Redis Encryption | ✅ Implemented | `rediss://` (TLS) for Upstash connection |
| Mobile Secure Storage | ✅ Implemented | `flutter_secure_storage` → iOS Keychain (`first_unlock_this_device`) / Android Keystore |
| Salt Migration Script | ✅ Available | `infra/re-encrypt-salt.js` for re-encrypting all FLE fields when rotating salt |

> **Known limitation:** Envelope encryption with per-tenant data keys stored in GCP KMS is deferred post-MVP. Current HKDF-SHA-256 derivation is cryptographically sound for this phase.

---

## 2a. Encryption — Technical Detail (for Security Auditors)

### Algorithm & Parameters

| Parameter | Value | Standard |
|---|---|---|
| Algorithm | AES-256-GCM | NIST FIPS 197 + SP 800-38D |
| Key length | 256 bits | |
| IV length | 96 bits (12 bytes) | GCM recommended |
| Auth tag length | 128 bits (16 bytes) | GCM maximum |
| IV generation | `crypto.randomBytes(12)` | CSPRNG — unique per encryption call |
| Ciphertext format | `{iv_hex}:{authTag_hex}:{ciphertext_hex}` | Stored as UTF-8 string in DB |
| Runtime library | Node.js built-in `crypto` (OpenSSL) | |

**Why AES-256-GCM:** Provides Authenticated Encryption with Associated Data (AEAD). The 128-bit auth tag detects any ciphertext tampering before decryption. A modified ciphertext fails the auth tag check and throws before returning any data.

---

### Key Derivation Architecture

Two-layer derivation. The base key is derived once at service startup; per-tenant keys are derived per operation.

```
ENCRYPTION_KEY  (env var — hex string, 256-bit minimum)
       │
       ▼
scryptSync(ENCRYPTION_KEY, ENCRYPTION_SALT, outputLength=32)
       │
       ▼
  Base Key (256 bits)  ← held in memory, never logged
       │
       ├──► HKDF-SHA-256(baseKey, salt='', info='vaulted-fle:{tenantId}', 32)
       │         └──► Tenant-Scoped Key (256 bits) — used for financial & insurance data
       │
       └──► Used directly for non-financial fields (MFA secrets)
```

| Parameter | Value |
|---|---|
| Base KDF | `scryptSync` (memory-hard, brute-force resistant) |
| scrypt N (cost factor) | Node.js default: 16384 |
| scrypt r (block size) | 8 |
| scrypt p (parallelization) | 1 |
| Tenant KDF | `hkdfSync('sha256', baseKey, '', 'vaulted-fle:{tenantId}', 32)` |
| Info string | `vaulted-fle:{tenantId}` — unique per tenant |

**Key isolation guarantee:** Deriving tenant A's key requires knowing `tenantId_A`. A full MongoDB dump from tenant A cannot be decrypted using tenant B's derived key — they are cryptographically independent outputs of HKDF with different `info` strings.

---

### Encrypted Fields Inventory

#### MongoDB — `items` collection (per-tenant key via HKDF)

| Field path | Type | Plaintext example | Sensitivity |
|---|---|---|---|
| `valuation.purchasePrice` | Number → encrypted string | `450000` | Critical — purchase price |
| `valuation.currentValue` | Number → encrypted string | `520000` | Critical — current market value |
| `valuation.lastAppraisalDate` | String → encrypted string | `2026-03-15` | High — appraisal date |

All three fields are encrypted before write and decrypted after read in `InventoryService`. A raw MongoDB document looks like:
```json
{
  "valuation": {
    "purchasePrice": "a3f1c2...:88d4...:ff920a...",
    "currentValue":  "b7e2a1...:99c3...:aa110b...",
    "lastAppraisalDate": "c9d3b2...:77e1...:bb220c..."
  }
}
```

#### PostgreSQL — `insurance_policies` table (per-tenant key via HKDF)

| Column | Type | Sensitivity |
|---|---|---|
| `provider` | varchar — encrypted | High — insurance company identity |
| `policyNumber` | varchar — encrypted | High — policy identifier |
| `totalCoverageAmount` | varchar — encrypted (stored as string) | Critical — total coverage value |
| `premium` | varchar — encrypted (nullable) | High — premium cost |
| `notes` | varchar — encrypted (nullable) | Medium — policy notes |

#### PostgreSQL — `insured_items` table (per-tenant key via HKDF)

| Column | Type | Sensitivity |
|---|---|---|
| `coveredValue` | varchar — encrypted | Critical — per-item insurance coverage amount |

#### PostgreSQL — `users` table (global base key — NOT tenant-scoped)

| Column | Type | Sensitivity | Why global key |
|---|---|---|---|
| `mfaSecret` | varchar — encrypted | Critical — TOTP seed | MFA secrets are user-specific, not tenant-financial data. A user belongs to exactly one tenant. Global key is acceptable here. |

---

### Security Properties

| Property | Implementation | Guarantee |
|---|---|---|
| Confidentiality | AES-256-GCM encryption | Ciphertext reveals no information about plaintext |
| Integrity | 128-bit GCM auth tag | Any modification to ciphertext is detected; decryption throws |
| IV uniqueness | `crypto.randomBytes(12)` per call | Same value encrypted twice produces different ciphertext (semantic security) |
| Cross-tenant isolation | HKDF with `tenantId` as info | Tenant A's key cannot decrypt Tenant B's data |
| DB dump safety | All sensitive fields encrypted before storage | Raw DB export exposes no financial or policy values |
| Key not in DB | Base key only in env var + memory | Compromise of DB alone is insufficient to decrypt |
| Brute-force resistance | `scryptSync` base KDF | Memory-hard; GPU/ASIC attack is economically infeasible |

---

### Known Limitations (Auditor Notes)

| Item | Detail | Mitigation / Roadmap |
|---|---|---|
| `ENCRYPTION_SALT` default | Falls back to `'vaulted-salt'` if env var not set. The salt is not secret — `ENCRYPTION_KEY` is the actual secret. | Configure `ENCRYPTION_SALT` in `.env.prod` before production. The salt adds domain separation, not entropy. |
| No key rotation | Changing `ENCRYPTION_KEY` or `ENCRYPTION_SALT` requires re-encrypting all FLE fields via `infra/re-encrypt-salt.js` | Script available and tested. Rotation procedure documented. |
| Base key in memory | `scryptSync` runs at startup; derived base key lives in `CryptoService` instance memory for the container lifetime | Mitigated by non-root container user, no memory dumps, no debug endpoints in prod |
| Envelope encryption absent | No per-tenant data key stored encrypted in DB (GCP KMS). Key compromise exposes all tenants' data | Deferred post-MVP. HKDF provides tenant isolation without KMS. Planned: GCP KMS wrap/unwrap of per-tenant data keys. |
| MFA secret: global key | `users.mfaSecret` uses global base key, not per-tenant HKDF | Acceptable: MFA secrets are user-owned, not tenant-financial. Low risk relative to added complexity. |

---

## 3. API Security

| Control | Status | Detail |
|---|---|---|
| Input Validation | ✅ Implemented | All endpoints use `class-validator` DTOs with `whitelist: true, forbidNonWhitelisted: true` |
| NoSQL Injection Prevention | ✅ Fixed | `attributes` keys with `$`, `.`, `__proto__`, `constructor`, `prototype` rejected |
| SQL Injection Prevention | ✅ Implemented | TypeORM parameterized queries throughout |
| XSS Prevention | ✅ Implemented | `escapeHtml()` in all email templates; Helmet security headers |
| Path Traversal Prevention | ✅ Fixed | Full canonical validation: rejects `..`, absolute paths, backslashes, null bytes |
| CORS | ✅ Hardened | Strict origin whitelist; centralized in `cors.constants.ts`; no wildcard |
| Rate Limiting (default) | ✅ Implemented | 600 req/min per user (in-memory, user-bucketed) |
| Rate Limiting (AI endpoints) | ✅ Implemented | 20 req/15min per tenant + secondary per-user bucket at 50% |
| Rate Limiting (dashboard) | ✅ Implemented | 10 req/5min |
| Media Token Security | ✅ Implemented | JWT-signed URLs; tenant prefix enforced; 2h expiry; no static file exposure |
| Swagger UI in Production | ✅ Fixed | Disabled in `NODE_ENV=production`; only available in dev/staging |
| Security Headers | ✅ Implemented | Helmet: HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy |

---

## 4. Infrastructure Security

| Control | Status | Detail |
|---|---|---|
| Container runs as non-root | ✅ Fixed (Jun 1) | Dedicated `vaulted` user in Dockerfile; `USER vaulted` directive |
| TypeORM Auto-Sync in Production | ✅ Fixed (Jun 1) | `TYPEORM_SYNC=false` enforced in prod; logic inverted to prevent accidental schema drops |
| Docker Network Isolation | ✅ Implemented | All DB containers on `internal: true` network; no direct internet access |
| MongoDB Authentication | ✅ Implemented | SCRAM-SHA-256; app user with minimal permissions (`readWrite` on `vaulted` DB only) |
| Redis Hardening | ✅ Implemented | Password required; `FLUSHALL`, `FLUSHDB`, `DEBUG` commands disabled; `maxmemory 512mb` |
| Encrypted Backups | ✅ Implemented | `mongodump` + `pg_dump` → AES-256-CBC (openssl); 7-day retention |
| VM Firewall | ✅ Implemented | Ports 80, 443, one non-standard SSH only; Fail2ban + UFW |
| SSH Hardening | ✅ Implemented | Key-based only; no password authentication |
| Secrets Management | ✅ Implemented | `.env.prod` never in git; uploaded to VM via `gcloud scp` |
| CI/CD Supply Chain | ✅ Fixed (Jun 1) | GitHub Actions pinned to full SHA (not mutable tags) |

---

## 5. WebSocket Security

| Control | Status | Detail |
|---|---|---|
| CORS on WebSocket gateways | ✅ Fixed | Both `orchestrator` and `presence` gateways use `ALLOWED_ORIGINS` whitelist |
| JWT Auth on WebSocket | ✅ Implemented | Token required for room join; `alg=none` and expired tokens rejected |
| Cross-tenant room isolation | ✅ Implemented | Room keys scoped to `tenantId`; cross-tenant access tested and blocked |

---

## 6. AI Security

| Control | Status | Detail |
|---|---|---|
| Prompt Injection Prevention | ✅ Fixed | `sanitizeUserQuery()` removes override patterns (`ignore previous instructions`, `act as`, etc.) |
| AI Output Sanitization | ✅ Fixed | `sanitizeAiOutput()` removes HTML and control characters from Gemini responses |
| Prompt Injection via Room Names | ✅ Fixed | Property/room names sanitized before interpolation in Gemini prompts |
| Session Hijacking (AI Chat) | ✅ Fixed | Redis key scoped to `tenantId:userId:sessionId` — cross-user access blocked |
| Sensitive Data in AI Prompts | ✅ Fixed | Insurance policy numbers masked to `****{last 4 digits}` before sending to Gemini |
| AI Rate Limiting (per-user) | ✅ Fixed | Secondary per-user bucket prevents one user from exhausting full tenant quota |
| AI Content Size Limits | ✅ Fixed | `@ArrayMaxSize`, `@MaxLength`, `@IsIn` on all AI DTOs |
| AI Output Stored in DB | ✅ Fixed | `sanitizeText()` + hard limits on AI-generated maintenance records |
| AI Help Access (Guest role) | ✅ Fixed | Guest role removed from AI Help endpoint |
| AI Session TTL | ✅ Reduced | Chat session TTL reduced from 3600s to 1800s |

---

## 7. Mobile Security

| Control | Status | Detail |
|---|---|---|
| Certificate Pinning | ✅ Implemented (Jun 1) | SHA-256 pinning via `IOHttpClientAdapter`; stored in `AppConfig.pinnedCertFingerprints` |
| Secure Token Storage | ✅ Implemented | iOS Keychain + Android Keystore via `flutter_secure_storage` |
| HTTPS Enforcement | ✅ Implemented | Release builds require HTTPS/WSS; HTTP only allowed in debug mode |
| Jailbreak / Root Detection | ❌ Pending | Scheduled before App Store / Google Play publish |
| Screenshot Guard | ❌ Pending | Scheduled before App Store / Google Play publish |
| App Icon (Android/iOS) | ❌ Pending | Low priority; only needed before store publish |

> **Certificate Pinning Rotation:** Let's Encrypt renews ~every 90 days via Caddy. Rotation procedure documented in CLAUDE.md. Two-fingerprint transition required to avoid blocking users on older app versions.

---

## 8. Audit & Compliance

| Control | Status | Detail |
|---|---|---|
| Immutable Audit Log | ✅ Implemented | PostgreSQL table with no UPDATE/DELETE; 2-year retention |
| Write Audit Coverage | ✅ Implemented | All create/update/delete operations logged |
| Read Audit (financial data) | ⚠️ Partial | Valuation read events not yet logged individually |
| IDOR Prevention | ✅ Fixed | Cross-tenant access blocked on movements, notifications, household-members |
| PII in Logs | ✅ Fixed | Email addresses removed from error logs; replaced with `tenantId` |
| SOC 2 / ISO 27001 / CCPA | 🔲 Roadmap | Target: post-launch with paying clients |

---

## 9. Dependency & Supply Chain

| Control | Status | Detail |
|---|---|---|
| Known CVEs | ✅ Fixed | `npm audit fix` eliminated all critical and high CVEs; 8 moderate remain in transitive Firebase/GCP deps |
| GitHub Actions pinning | ✅ Fixed | All actions pinned to full commit SHA |
| SBOM / Trivy / Semgrep | 🔲 Roadmap | Documented in `extended-security-plan.md`; not yet integrated in CI |

---

## 10. Penetration Testing

Automated penetration test suite available at `security-tests/`:

| Script | Coverage |
|---|---|
| `run-everything.sh` | Master orchestrator — runs all three suites in sequence, unified pass/fail report |
| `pentest-full.sh` | 17 phases: JWT alg=none, brute-force throttle, expired tokens, NoSQL/SQL/XSS injection, PHP shell upload, path traversal, CORS, rate limiting, security headers, TLS |
| `websocket-tests.js` | No-token, malformed token, alg=none, expired JWT, cross-tenant room isolation |
| `idor-rbac-tests.sh` | Cross-tenant property/inventory access, fake IDs, privilege escalation, RBAC |

All tests pass against production (`https://api-vaulted.casacam.net`).

Run: `bash security-tests/run-everything.sh`

---

## 11. Database Architecture & Security

Vaulted uses three purpose-specific databases. Each stores a different class of data with distinct security requirements.

### MongoDB Atlas M0 — Primary Inventory Database
**Provider:** MongoDB Atlas (cloud-managed, free tier / M0)
**Connection:** `MONGODB_URI` env var (TLS enforced by Atlas)

| Purpose | Collections |
|---|---|
| Properties, floors, rooms, sections | `properties` |
| Inventory items and item history | `items`, `item_history` |
| Movements, loans, repairs | `movements` |
| Maintenance records | `maintenance` |
| Wardrobe: outfits + dry-cleaning | `outfits`, `dry_cleaning` |
| AI chat sessions | `ai_chat_sessions` |
| Orchestrator task plans | `orchestrator_tasks` |
| Household members | `household_members` |

**Why MongoDB for this data:** Inventory items have highly variable schemas (a watch has different attributes than a painting). MongoDB's document model handles heterogeneous `attributes: {}` natively without schema migrations.

**Security controls applied:**
- SCRAM-SHA-256 authentication (Atlas enforced)
- App user has `readWrite` only on `vaulted` database — no admin access
- Field-Level Encryption (AES-256-GCM) on `valuation.purchasePrice`, `valuation.currentValue`, `valuation.lastAppraisalDate` — even a DB dump does not expose financial values
- `tenantId` on every document — all queries filter by tenant before returning data
- `escapeRegex()` on all user-supplied search terms before `new RegExp()` — prevents ReDoS
- `$`, `.`, `__proto__`, `constructor`, `prototype` rejected in `attributes` keys — prevents NoSQL injection

---

### PostgreSQL (Neon.tech) — Users, Financials & Audit
**Provider:** Neon.tech (serverless PostgreSQL, free tier)
**Connection:** `DATABASE_URL` env var (TLS, `rejectUnauthorized: true` in production)
**ORM:** TypeORM (`TYPEORM_SYNC=false` in production)
**Extension:** `pgvector` (AI embeddings, 3072 dimensions)

| Purpose | Tables |
|---|---|
| User accounts and credentials | `users` |
| Tenant / client families | `tenants` |
| Insurance policies and coverage | `insurance_policies`, `insured_items` |
| AI knowledge base embeddings | `embeddings` (pgvector) |
| Immutable audit trail | `audit_logs` |

**Security controls applied:**
- `rejectUnauthorized: true` — TLS certificate verified on every connection
- `TYPEORM_SYNC=false` in production — TypeORM cannot auto-drop or alter columns in prod
- `audit_logs` table has no `UPDATE` or `DELETE` permissions for the app user — immutable by design
- AES-256-GCM encryption on sensitive insurance fields and `users.mfa_secret`
- `pgvector` embeddings contain only AI-generated text vectors — no raw user content in plaintext
- 2-year retention policy on audit logs

---

### Redis (Upstash) — Session State & Rate Limiting
**Provider:** Upstash (serverless Redis, free tier)
**Connection:** `REDIS_URL` with `rediss://` scheme (TLS enforced)

| Purpose | Key pattern |
|---|---|
| JWT refresh token sessions (one-time-use) | `session:{userId}:{jti}` |
| JWT blacklist (revoked tokens) | `blacklist:{jti}` |
| MFA pending secrets (10-min TTL) | `mfa:pending:{userId}` |
| Rate limiting counters | `throttler:{name}:{tracker}` |
| AI chat session history | `ai:chat:session:{tenantId}:{userId}:{sessionId}` |
| Dashboard KPI cache | `dashboard:{tenantId}:{propertyId}` |
| Wardrobe stats cache | `wardrobe:stats:{tenantId}` |
| Orchestrator WebSocket progress | `orchestrator:progress:{taskId}` |

**Security controls applied:**
- `rediss://` (TLS) — data encrypted in transit to Upstash
- Password authentication required
- `FLUSHALL`, `FLUSHDB`, `DEBUG` commands disabled — prevents accidental or malicious cache wipe
- `maxmemory 512mb` with eviction policy — prevents OOM DoS
- All AI chat keys scoped to `tenantId:userId` — cross-tenant session hijacking blocked
- No plaintext PII stored in Redis — financial values and personal data stay in MongoDB/PostgreSQL

---

### Data Flow Summary

```
Mobile / Web App
      │
      ▼
NestJS API (Docker, port 3000)
      │
      ├──► MongoDB Atlas ──────── inventory, properties, items, wardrobe, movements
      │                           (document model, FLE on valuations)
      │
      ├──► PostgreSQL (Neon) ──── users, tenants, insurance, audit logs, AI embeddings
      │                           (relational, immutable audit, pgvector)
      │
      ├──► Redis (Upstash TLS) ── sessions, blacklist, rate limits, cache
      │                           (ephemeral, TTL-based, no PII)
      │
      └──► GCP Storage / Docker volume ── media files (photos, PDFs)
                                          (JWT-signed access tokens, tenant-prefixed paths)
```

---

## 12. Third-party Services & Vendor Security

All external services are accessed exclusively via API keys stored in `.env.prod` (never committed to git). No service receives plaintext financial data or PII beyond what is strictly necessary for its function.

| Service | Provider | Purpose | Data Sent | Security Controls |
|---|---|---|---|---|
| **Gemini AI** | Google DeepMind | Vision analysis, chat, insurance analysis, maintenance risk, embeddings | Item descriptions, photos (base64), AI prompts | API key in env var; photos not persisted by Google per ToS; insurance policy numbers masked to `****{last 4}` before sending |
| **Firebase FCM** | Google Firebase | Push notifications (mobile) | Device tokens, notification title/body | Service account credentials in env vars; no financial data in payloads; device tokens stored encrypted-at-rest |
| **Resend** | Resend Inc. | Transactional email | User email address, notification content | API key in env var; `escapeHtml()` applied to all content before sending; no financial or inventory data in emails |
| **Cloudflare** | Cloudflare Inc. | DNS, WAF, DDoS protection, TLS proxy | All inbound HTTP/S traffic | Hides VM origin IP; TLS 1.3 at edge; WAF rules active; DDoS mitigation layer; no data stored by Cloudflare beyond access logs |
| **Upstash** | Upstash Inc. | Managed Redis | Sessions, rate limit counters, cache | TLS (`rediss://`), password auth, no PII in plaintext values |
| **Neon.tech** | Neon Inc. | Managed PostgreSQL | Users, insurance, audit logs, embeddings | TLS, `rejectUnauthorized: true`, credentials in env vars |
| **MongoDB Atlas** | MongoDB Inc. | Managed MongoDB | Inventory documents | SCRAM-SHA-256, TLS enforced by Atlas, FLE on financial fields |
| **GCP** | Google Cloud | VM (Compute Engine) + Cloud Storage | API container, media files | SSH key-based access, non-root container user, service account with minimal IAM permissions |
| **Sentry** | Functional Software Inc. | Error monitoring (backend + Flutter) | Error stack traces, request context | DSN in env var; no sensitive field values logged; PII scrubbed from error payloads |
| **Brave Search** | Brave Software Inc. | Web search for AI valuation (Phase 3) | Item name + category for price research | API key in env var; no user PII or tenant IDs sent in search queries |
| **Firebase Hosting** | Google Firebase | Flutter web app (static hosting) | Static compiled Flutter web files | No sensitive data hosted; runtime config loaded from `firebase-config.js` excluded from git |

**Vendor risk summary:**
- All credentials stored exclusively in `.env.prod` (not in git, not in Docker images)
- No third-party service has direct DB access
- Financial data (valuations, policy amounts) never sent to any external API
- All services used are SOC 2 Type II certified (Google, Cloudflare, MongoDB, Neon, Upstash)

---

## 13. Network Security & Monitoring

### Network Architecture

```
Internet
   │
   ▼
Cloudflare (DNS proxy + WAF + DDoS + TLS 1.3)
   │  ← Origin IP hidden from public
   ▼
GCP VM: tennis-backend (us-central1-c)
   │
   ├── UFW Firewall: ports 80, 443, one non-standard SSH only
   ├── Fail2ban: SSH brute-force protection
   │
   ▼
Caddy (reverse proxy + TLS termination + auto-renewal Let's Encrypt)
   │
   ▼
Docker network (internal)
   ├── vaulted_api:3000  (NestJS)
   ├── MongoDB Atlas     (cloud, TLS)
   ├── PostgreSQL Neon   (cloud, TLS)
   └── Redis Upstash     (cloud, TLS)
```

### DDoS & WAF Protection (Cloudflare)
- All traffic passes through Cloudflare — origin VM IP is never exposed publicly
- Cloudflare WAF filters common web attack patterns (OWASP rulesets)
- DDoS mitigation is automatic at L3/L4/L7
- Rate limiting at application layer (NestJS ThrottlerGuard) provides secondary defense

### TLS Configuration
| Endpoint | TLS Version | Certificate | Notes |
|---|---|---|---|
| `api-vaulted.casacam.net` | TLS 1.3 | Let's Encrypt (auto-renewed via Caddy) | Cloudflare proxy layer adds additional TLS |
| `vaulted-prod-2026.web.app` | TLS 1.3 | Firebase Hosting managed | |
| MongoDB Atlas | TLS 1.3 | Atlas managed | `MONGODB_URI` includes TLS params |
| PostgreSQL Neon | TLS 1.3 | Neon managed | `rejectUnauthorized: true` |
| Redis Upstash | TLS 1.3 | Upstash managed | `rediss://` scheme |

### Monitoring & Alerting

| Tool | Coverage | Status |
|---|---|---|
| **Sentry** | Backend NestJS error tracking + Flutter crash reporting | ✅ Configured (`SENTRY_DSN` env var) |
| **Docker logs** | Container stdout/stderr | ✅ Available via `docker logs vaulted_api` |
| **GCP VM monitoring** | CPU, memory, disk via GCP Console | ✅ Available |
| **MongoDB Atlas alerts** | Connection count, slow queries, storage | ✅ Atlas built-in |
| Real-time intrusion detection (IDS) | Network anomaly detection | ❌ Not configured — roadmap post-MVP |
| Alerting on 4xx/5xx spikes | Automated alerts on error rate | ❌ Not configured — roadmap |
| Log aggregation (e.g., Loki/Datadog) | Centralized log search | ❌ Not configured — roadmap |

> **Auditor note:** The absence of a centralized SIEM or IDS is a known gap. For the current MVP phase with no paying clients, Sentry + GCP monitoring + Docker logs provide adequate visibility. A proper alerting pipeline (PagerDuty, Datadog, or GCP Cloud Monitoring) should be implemented before onboarding first paying client.

---

## Open Items (Pre-Production Checklist)

| Priority | Item | Owner |
|---|---|---|
| 🔴 High | Run valuation re-encryption script (`infra/restore-valuations.js`) | DevOps |
| 🟡 Medium | Jailbreak detection (Flutter) | Mobile team |
| 🟡 Medium | Screenshot guard (Flutter) | Mobile team |
| 🟡 Medium | Read audit for financial data (valuations) | Backend team |
| 🟢 Low | Android / iOS app icons | Mobile team |
| 🟢 Low | SBOM + Trivy in CI/CD | DevOps |
| 🔲 Post-MVP | GCP KMS envelope encryption | Architecture |
| 🔲 Post-MVP | SOC 2 Type II audit | Compliance |

---

## Summary by Severity

| Round | Critical | High | Medium | Low | Total |
|---|---|---|---|---|---|
| Initial audit (PR #253) | 2 | 1 | 3 | — | 6 |
| AI modules audit (PR #254) | 1 | 4 | 5 | 1 | 11 |
| Full modules audit (PR #255) | — | 4 | 2 | — | 6 |
| Media/auth hardening (PR #256) | — | 3 | 5 | 4 | 12 |
| CSO comprehensive audit (Jun 1) | 1 | 2 | 3 | — | 6 |
| **TOTAL FIXED** | **4** | **14** | **18** | **5** | **41** |
| **REMAINING OPEN** | **0** | **0** | **2** | **3** | **5** |

---
---

# VERSIÓN EN ESPAÑOL

---

## Resumen Ejecutivo

Vaulted almacena el inventario completo de familias ultra-HNW: qué poseen, dónde está físicamente, cuánto vale cada pieza y fotos de todo. Una brecha de seguridad no es solo un problema de privacidad — es un vector de riesgo físico real: robo planificado, extorsión o secuestro basado en datos de riqueza y ubicación.

En los últimos 30 días, Vaulted fue sometido a una auditoría de seguridad integral que cubrió los 14 dominios de seguridad (OWASP Top 10, modelado de amenazas STRIDE, seguridad de IA, supply chain, hardening de infraestructura, seguridad móvil). **Se identificaron y remediaron 41 vulnerabilidades** (en múltiples rondas de auditoría). No quedan vulnerabilidades críticas abiertas.

---

## 1. Autenticación y Control de Acceso

| Control | Estado | Detalle |
|---|---|---|
| JWT Access Tokens | ✅ Implementado | 24h de expiración, solo en memoria (Flutter), HMAC-SHA256 |
| JWT Refresh Tokens | ✅ Implementado | 7 días, httpOnly cookie / secure storage |
| Rotación de Refresh Token | ✅ Implementado | Un solo uso; replay ataque activa invalidación completa de sesión |
| Blacklist de Tokens | ✅ Implementado | Redis para revocación inmediata en logout/rotación |
| Autenticación de Dos Factores (TOTP) | ✅ Implementado | Obligatorio para Owner y Manager |
| Rate Limiting MFA | ✅ Implementado | 5 intentos/minuto en `/auth/mfa/verify` |
| Forzado de Configuración MFA | ✅ Implementado | Token con `mfaVerified=false` hasta completar setup |
| Control de Acceso por Roles (RBAC) | ✅ Implementado | 5 roles: Owner, Manager, Staff, Auditor, Guest |
| Acceso por Propiedad | ✅ Implementado | Staff de Propiedad A no puede acceder a Propiedad B |
| Guard de Expiración de Guest | ✅ Implementado | Tokens temporales revocados automáticamente |
| Prevención de Escalación de Privilegios | ✅ Corregido (1 jun) | Manager no puede promover usuarios a Owner — guard `actorRole` enforced |

---

## 2. Cifrado de Datos

| Control | Estado | Detalle |
|---|---|---|
| Cifrado en Reposo (campos) | ✅ Implementado | AES-256-GCM a nivel de campo (FLE): valuaciones, seguros, secretos MFA |
| Derivación de Clave por Tenant | ✅ Implementado | HKDF-SHA-256 con `tenantId` como contexto — clave diferente por tenant |
| Gestión de Claves | ✅ Implementado | Clave maestra vía `ENCRYPTION_KEY` env var; salt vía `ENCRYPTION_SALT` |
| TLS en Tránsito | ✅ Implementado | TLS 1.3 vía Caddy + Let's Encrypt; capa Cloudflare |
| TLS PostgreSQL | ✅ Corregido | `rejectUnauthorized: true` en producción |
| Redis Cifrado | ✅ Implementado | Conexión `rediss://` (TLS) para Upstash |
| Almacenamiento Seguro Móvil | ✅ Implementado | `flutter_secure_storage` → iOS Keychain / Android Keystore |
| Script de Migración de Salt | ✅ Disponible | `infra/re-encrypt-salt.js` para re-cifrar todos los campos FLE al rotar el salt |

> **Limitación conocida:** Envelope encryption con claves por tenant en GCP KMS está diferida post-MVP. La derivación HKDF-SHA-256 actual es criptográficamente sólida para esta fase.

---

## 2a. Cifrado — Detalle Técnico (para Auditores de Seguridad)

### Algoritmo y Parámetros

| Parámetro | Valor | Estándar |
|---|---|---|
| Algoritmo | AES-256-GCM | NIST FIPS 197 + SP 800-38D |
| Longitud de clave | 256 bits | |
| Longitud de IV | 96 bits (12 bytes) | Recomendado por GCM |
| Longitud de auth tag | 128 bits (16 bytes) | Máximo de GCM |
| Generación de IV | `crypto.randomBytes(12)` | CSPRNG — único por cada llamada de cifrado |
| Formato de ciphertext | `{iv_hex}:{authTag_hex}:{ciphertext_hex}` | Almacenado como string UTF-8 en la DB |
| Librería | Node.js built-in `crypto` (OpenSSL) | |

**Por qué AES-256-GCM:** Provee Cifrado Autenticado con Datos Asociados (AEAD). El auth tag de 128 bits detecta cualquier manipulación del ciphertext antes de desencriptar. Un ciphertext modificado falla el chequeo del auth tag y lanza error antes de retornar datos.

---

### Arquitectura de Derivación de Claves

Derivación en dos capas. La clave base se deriva una vez al iniciar el servicio; las claves por tenant se derivan por operación.

```
ENCRYPTION_KEY  (variable de entorno — hex string, mínimo 256 bits)
       │
       ▼
scryptSync(ENCRYPTION_KEY, ENCRYPTION_SALT, outputLength=32)
       │
       ▼
  Clave Base (256 bits)  ← en memoria, nunca en logs
       │
       ├──► HKDF-SHA-256(claveBase, salt='', info='vaulted-fle:{tenantId}', 32)
       │         └──► Clave por Tenant (256 bits) — datos financieros y de seguros
       │
       └──► Usada directamente para campos no financieros (secretos MFA)
```

| Parámetro | Valor |
|---|---|
| KDF base | `scryptSync` (memory-hard, resistente a fuerza bruta) |
| scrypt N (factor de costo) | Default Node.js: 16384 |
| scrypt r (tamaño de bloque) | 8 |
| scrypt p (paralelización) | 1 |
| KDF por tenant | `hkdfSync('sha256', claveBase, '', 'vaulted-fle:{tenantId}', 32)` |
| Info string | `vaulted-fle:{tenantId}` — única por tenant |

**Garantía de aislamiento de claves:** Derivar la clave del tenant A requiere conocer `tenantId_A`. Un dump completo de MongoDB del tenant A no puede ser descifrado con la clave derivada del tenant B — son outputs criptográficamente independientes de HKDF con diferentes strings `info`.

---

### Inventario de Campos Cifrados

#### MongoDB — colección `items` (clave por tenant vía HKDF)

| Ruta del campo | Tipo | Ejemplo en texto claro | Sensibilidad |
|---|---|---|---|
| `valuation.purchasePrice` | Número → string cifrado | `450000` | Crítica — precio de compra |
| `valuation.currentValue` | Número → string cifrado | `520000` | Crítica — valor de mercado actual |
| `valuation.lastAppraisalDate` | String → string cifrado | `2026-03-15` | Alta — fecha de última tasación |

Los tres campos se cifran antes de escribir y se descifran al leer en `InventoryService`. Un documento MongoDB crudo luce así:
```json
{
  "valuation": {
    "purchasePrice": "a3f1c2...:88d4...:ff920a...",
    "currentValue":  "b7e2a1...:99c3...:aa110b...",
    "lastAppraisalDate": "c9d3b2...:77e1...:bb220c..."
  }
}
```

#### PostgreSQL — tabla `insurance_policies` (clave por tenant vía HKDF)

| Columna | Tipo | Sensibilidad |
|---|---|---|
| `provider` | varchar cifrado | Alta — nombre de la aseguradora |
| `policyNumber` | varchar cifrado | Alta — número de póliza |
| `totalCoverageAmount` | varchar cifrado (almacenado como string) | Crítica — cobertura total |
| `premium` | varchar cifrado (nullable) | Alta — monto de la prima |
| `notes` | varchar cifrado (nullable) | Media — notas de la póliza |

#### PostgreSQL — tabla `insured_items` (clave por tenant vía HKDF)

| Columna | Tipo | Sensibilidad |
|---|---|---|
| `coveredValue` | varchar cifrado | Crítica — valor asegurado por ítem |

#### PostgreSQL — tabla `users` (clave base global — NO por tenant)

| Columna | Tipo | Sensibilidad | Por qué clave global |
|---|---|---|---|
| `mfaSecret` | varchar cifrado | Crítica — semilla TOTP | Los secretos MFA son propiedad del usuario, no datos financieros del tenant. Un usuario pertenece a exactamente un tenant. La clave global es aceptable aquí. |

---

### Propiedades de Seguridad

| Propiedad | Implementación | Garantía |
|---|---|---|
| Confidencialidad | Cifrado AES-256-GCM | El ciphertext no revela información sobre el texto claro |
| Integridad | Auth tag GCM de 128 bits | Cualquier modificación al ciphertext es detectada; el descifrado lanza error |
| Unicidad del IV | `crypto.randomBytes(12)` por llamada | El mismo valor cifrado dos veces produce ciphertexts distintos (seguridad semántica) |
| Aislamiento cross-tenant | HKDF con `tenantId` como info | La clave del tenant A no puede descifrar datos del tenant B |
| Seguridad ante dump de DB | Todos los campos sensibles cifrados antes de almacenar | Un export crudo de la DB no expone valores financieros ni de pólizas |
| Clave fuera de la DB | Clave base solo en variable de entorno + memoria | Comprometer la DB sola es insuficiente para descifrar |
| Resistencia a fuerza bruta | KDF base `scryptSync` (memory-hard) | Ataque con GPU/ASIC es económicamente inviable |

---

### Limitaciones Conocidas (Notas para el Auditor)

| Ítem | Detalle | Mitigación / Roadmap |
|---|---|---|
| Default de `ENCRYPTION_SALT` | Usa `'vaulted-salt'` si la variable de entorno no está configurada. El salt no es secreto — `ENCRYPTION_KEY` es el secreto real. | Configurar `ENCRYPTION_SALT` en `.env.prod` antes de producción. El salt aporta separación de dominio, no entropía. |
| Sin rotación de claves | Cambiar `ENCRYPTION_KEY` o `ENCRYPTION_SALT` requiere re-cifrar todos los campos FLE vía `infra/re-encrypt-salt.js` | Script disponible y probado. Procedimiento de rotación documentado. |
| Clave base en memoria | `scryptSync` corre al inicio; la clave base vive en memoria de la instancia `CryptoService` durante todo el tiempo de vida del contenedor | Mitigado por: usuario non-root en contenedor, sin memory dumps, sin endpoints de debug en prod |
| Sin envelope encryption | No hay clave de datos por tenant almacenada cifrada en DB (GCP KMS). El compromiso de la clave expone datos de todos los tenants | Diferido post-MVP. HKDF provee aislamiento de tenant sin KMS. Planificado: GCP KMS wrap/unwrap de claves por tenant. |
| Secreto MFA: clave global | `users.mfaSecret` usa la clave base global, no HKDF por tenant | Aceptable: los secretos MFA son del usuario, no datos financieros del tenant. Riesgo bajo relativo a la complejidad adicional. |

---

## 3. Seguridad de la API

| Control | Estado | Detalle |
|---|---|---|
| Validación de Entradas | ✅ Implementado | Todos los endpoints usan DTOs con `class-validator`; `whitelist: true, forbidNonWhitelisted: true` |
| Prevención de Inyección NoSQL | ✅ Corregido | Claves con `$`, `.`, `__proto__`, `constructor`, `prototype` rechazadas en `attributes` |
| Prevención de Inyección SQL | ✅ Implementado | Consultas parametrizadas TypeORM en todo el backend |
| Prevención XSS | ✅ Implementado | `escapeHtml()` en templates de email; Helmet headers |
| Prevención de Path Traversal | ✅ Corregido | Validación canónica completa: rechaza `..`, rutas absolutas, backslashes, null bytes |
| CORS | ✅ Reforzado | Whitelist estricta de orígenes; sin wildcard; centralizado en `cors.constants.ts` |
| Rate Limiting (default) | ✅ Implementado | 600 req/min por usuario (en memoria, bucket por userId) |
| Rate Limiting (endpoints IA) | ✅ Implementado | 20 req/15min por tenant + bucket secundario por usuario al 50% |
| Rate Limiting (dashboard) | ✅ Implementado | 10 req/5min |
| Seguridad de Tokens de Media | ✅ Implementado | URLs firmadas con JWT; prefijo de tenant enforced; expiración 2h; sin exposición de archivos estáticos |
| Swagger UI en Producción | ✅ Corregido | Deshabilitado con `NODE_ENV=production`; solo disponible en dev/staging |
| Headers de Seguridad | ✅ Implementado | Helmet: HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy |

---

## 4. Seguridad de Infraestructura

| Control | Estado | Detalle |
|---|---|---|
| Contenedor sin root | ✅ Corregido (1 jun) | Usuario dedicado `vaulted` en Dockerfile; directiva `USER vaulted` |
| Auto-Sync TypeORM en Producción | ✅ Corregido (1 jun) | `TYPEORM_SYNC=false` enforced en prod; lógica invertida para prevenir drops accidentales de schema |
| Aislamiento de Red Docker | ✅ Implementado | Todos los contenedores DB en red `internal: true`; sin acceso directo a internet |
| Autenticación MongoDB | ✅ Implementado | SCRAM-SHA-256; usuario con permisos mínimos (`readWrite` solo en DB `vaulted`) |
| Hardening Redis | ✅ Implementado | Contraseña obligatoria; comandos `FLUSHALL`, `FLUSHDB`, `DEBUG` deshabilitados |
| Backups Cifrados | ✅ Implementado | `mongodump` + `pg_dump` → AES-256-CBC; retención 7 días |
| Firewall VM | ✅ Implementado | Puertos 80, 443, un SSH no estándar; Fail2ban + UFW |
| SSH Hardening | ✅ Implementado | Solo autenticación por clave; sin contraseñas |
| Gestión de Secretos | ✅ Implementado | `.env.prod` nunca en git; subido a VM vía `gcloud scp` |
| Supply Chain CI/CD | ✅ Corregido (1 jun) | GitHub Actions fijadas a SHA completo (no tags mutables) |

---

## 5. Seguridad WebSocket

| Control | Estado | Detalle |
|---|---|---|
| CORS en Gateways WebSocket | ✅ Corregido | Ambos gateways (`orchestrator` y `presence`) usan whitelist `ALLOWED_ORIGINS` |
| Auth JWT en WebSocket | ✅ Implementado | Token requerido para unirse a sala; `alg=none` y tokens expirados rechazados |
| Aislamiento Cross-Tenant en Salas | ✅ Implementado | Claves de sala con scope de `tenantId`; acceso cross-tenant bloqueado |

---

## 6. Seguridad de IA

| Control | Estado | Detalle |
|---|---|---|
| Prevención de Prompt Injection | ✅ Corregido | `sanitizeUserQuery()` elimina patrones de override |
| Sanitización de Output de IA | ✅ Corregido | `sanitizeAiOutput()` elimina HTML y chars de control de respuestas Gemini |
| Prompt Injection vía Nombres de Habitación | ✅ Corregido | Nombres de propiedad/habitación sanitizados antes de interpolación |
| Session Hijacking (AI Chat) | ✅ Corregido | Clave Redis con scope `tenantId:userId:sessionId` |
| Datos Sensibles en Prompts IA | ✅ Corregido | Números de póliza enmascarados a `****{últimos 4 dígitos}` antes de enviar a Gemini |
| Rate Limiting IA (por usuario) | ✅ Corregido | Bucket secundario previene que un usuario agote la cuota del tenant |
| Límites de Tamaño en DTOs IA | ✅ Corregido | `@ArrayMaxSize`, `@MaxLength`, `@IsIn` en todos los DTOs de IA |
| Output de IA Almacenado en DB | ✅ Corregido | `sanitizeText()` + límites duros en registros de mantenimiento generados por IA |
| Acceso de IA Help al rol Guest | ✅ Corregido | Rol Guest eliminado del endpoint de AI Help |
| TTL de Sesión AI Chat | ✅ Reducido | Reducido de 3600s a 1800s |

---

## 7. Seguridad Móvil

| Control | Estado | Detalle |
|---|---|---|
| Certificate Pinning | ✅ Implementado (1 jun) | Pinning SHA-256 vía `IOHttpClientAdapter`; fingerprint en `AppConfig.pinnedCertFingerprints` |
| Almacenamiento Seguro de Tokens | ✅ Implementado | iOS Keychain + Android Keystore vía `flutter_secure_storage` |
| Forzado HTTPS | ✅ Implementado | Builds release requieren HTTPS/WSS; HTTP solo en modo debug |
| Detección de Jailbreak / Root | ❌ Pendiente | Programado para antes de publicar en App Store / Google Play |
| Screenshot Guard | ❌ Pendiente | Programado para antes de publicar en App Store / Google Play |

> **Rotación de Certificate Pinning:** Let's Encrypt renueva automáticamente ~cada 90 días vía Caddy. Procedimiento de rotación documentado en CLAUDE.md. Se requiere transición con dos fingerprints para no bloquear usuarios con versión anterior de la app.

---

## 8. Auditoría y Cumplimiento

| Control | Estado | Detalle |
|---|---|---|
| Log de Auditoría Inmutable | ✅ Implementado | Tabla PostgreSQL sin UPDATE/DELETE; retención 2 años |
| Cobertura de Auditoría de Escritura | ✅ Implementado | Todas las operaciones create/update/delete registradas |
| Auditoría de Lectura (datos financieros) | ⚠️ Parcial | Lecturas de valuaciones no registradas individualmente aún |
| Prevención IDOR | ✅ Corregido | Acceso cross-tenant bloqueado en movimientos, notificaciones, miembros del hogar |
| PII en Logs | ✅ Corregido | Direcciones de email removidas de logs de error; reemplazadas con `tenantId` |
| SOC 2 / ISO 27001 / CCPA | 🔲 Roadmap | Objetivo: post-lanzamiento con clientes pagos |

---

## 9. Dependencias y Supply Chain

| Control | Estado | Detalle |
|---|---|---|
| CVEs Conocidos | ✅ Corregido | `npm audit fix` eliminó todos los CVEs críticos y altos; 8 moderados residuales en deps transitivas de Firebase/GCP |
| Fijación de GitHub Actions | ✅ Corregido | Todas las actions fijadas a SHA completo de commit |
| SBOM / Trivy / Semgrep | 🔲 Roadmap | Documentado en `extended-security-plan.md`; no integrado en CI aún |

---

## 10. Pruebas de Penetración

Suite de pentest automatizado disponible en `security-tests/`:

| Script | Cobertura |
|---|---|
| `run-all.sh` | JWT alg=none, fuerza bruta throttle, tokens expirados, inyección NoSQL/SQL/XSS, upload de shell PHP, path traversal, CORS, rate limiting, headers de seguridad, TLS |
| `websocket-tests.js` | Sin token, token malformado, alg=none, JWT expirado, aislamiento cross-tenant en salas |
| `idor-rbac-tests.sh` | Acceso cross-tenant a propiedades/inventario, IDs falsos, escalada de privilegios |

Todas las pruebas pasan contra producción (`https://api-vaulted.casacam.net`).

---

## 11. Arquitectura de Bases de Datos y Seguridad

Vaulted utiliza tres bases de datos especializadas. Cada una almacena una clase diferente de datos con requisitos de seguridad distintos.

### MongoDB Atlas M0 — Base de Datos Principal de Inventario
**Proveedor:** MongoDB Atlas (cloud-managed, free tier / M0)
**Conexión:** variable de entorno `MONGODB_URI` (TLS enforced por Atlas)

| Propósito | Colecciones |
|---|---|
| Propiedades, pisos, habitaciones, secciones | `properties` |
| Ítems de inventario e historial | `items`, `item_history` |
| Movimientos, préstamos, reparaciones | `movements` |
| Registros de mantenimiento | `maintenance` |
| Wardrobe: outfits + tintorería | `outfits`, `dry_cleaning` |
| Sesiones de chat IA | `ai_chat_sessions` |
| Planes de tareas del orquestador | `orchestrator_tasks` |
| Miembros del hogar | `household_members` |

**Controles de seguridad aplicados:**
- Autenticación SCRAM-SHA-256 (enforced por Atlas)
- Usuario de la app con permisos `readWrite` solo en la DB `vaulted` — sin acceso admin
- Cifrado a nivel de campo (AES-256-GCM) en `valuation.purchasePrice`, `valuation.currentValue`, `valuation.lastAppraisalDate`
- `tenantId` en cada documento — todas las consultas filtran por tenant
- `escapeRegex()` en todos los términos de búsqueda — previene ReDoS
- Claves con `$`, `.`, `__proto__`, `constructor`, `prototype` rechazadas — previene inyección NoSQL

---

### PostgreSQL (Neon.tech) — Usuarios, Datos Financieros y Auditoría
**Proveedor:** Neon.tech (PostgreSQL serverless, free tier)
**Conexión:** `DATABASE_URL` (TLS, `rejectUnauthorized: true` en producción)
**ORM:** TypeORM (`TYPEORM_SYNC=false` en producción)
**Extensión:** `pgvector` (embeddings de IA, 3072 dimensiones)

| Propósito | Tablas |
|---|---|
| Cuentas de usuario y credenciales | `users` |
| Tenants / familias cliente | `tenants` |
| Pólizas de seguro y coberturas | `insurance_policies`, `insured_items` |
| Base de conocimiento de IA (embeddings) | `embeddings` (pgvector) |
| Registro de auditoría inmutable | `audit_logs` |

**Controles de seguridad aplicados:**
- `rejectUnauthorized: true` — certificado TLS verificado en cada conexión
- `TYPEORM_SYNC=false` en producción — TypeORM no puede eliminar ni alterar columnas en prod
- Tabla `audit_logs` sin permisos de `UPDATE`/`DELETE` — inmutable por diseño
- Cifrado AES-256-GCM en campos sensibles de seguros y `users.mfa_secret`
- Retención de 2 años en audit logs

---

### Redis (Upstash) — Estado de Sesión y Rate Limiting
**Proveedor:** Upstash (Redis serverless, free tier)
**Conexión:** `REDIS_URL` con esquema `rediss://` (TLS enforced)

| Propósito | Patrón de clave |
|---|---|
| Sesiones de refresh token JWT (un solo uso) | `session:{userId}:{jti}` |
| Blacklist de JWT (tokens revocados) | `blacklist:{jti}` |
| Secretos MFA pendientes (TTL 10 min) | `mfa:pending:{userId}` |
| Contadores de rate limiting | `throttler:{name}:{tracker}` |
| Historial de sesión de chat IA | `ai:chat:session:{tenantId}:{userId}:{sessionId}` |
| Cache de KPIs del dashboard | `dashboard:{tenantId}:{propertyId}` |
| Cache de estadísticas de wardrobe | `wardrobe:stats:{tenantId}` |
| Progreso WebSocket del orquestador | `orchestrator:progress:{taskId}` |

**Controles de seguridad aplicados:**
- `rediss://` (TLS) — datos cifrados en tránsito hacia Upstash
- Autenticación por contraseña obligatoria
- Comandos `FLUSHALL`, `FLUSHDB`, `DEBUG` deshabilitados
- `maxmemory 512mb` con política de evicción — previene DoS por OOM
- Claves de chat IA con scope `tenantId:userId` — session hijacking cross-tenant bloqueado
- Sin PII en texto plano en Redis

---

### Resumen del Flujo de Datos

```
App Móvil / Web
      │
      ▼
NestJS API (Docker, puerto 3000)
      │
      ├──► MongoDB Atlas ──────── inventario, propiedades, ítems, wardrobe, movimientos
      │                           (modelo documental, FLE en valuaciones)
      │
      ├──► PostgreSQL (Neon) ──── usuarios, tenants, seguros, audit logs, embeddings IA
      │                           (relacional, auditoría inmutable, pgvector)
      │
      ├──► Redis (Upstash TLS) ── sesiones, blacklist, rate limits, cache
      │                           (efímero, TTL-based, sin PII)
      │
      └──► GCP Storage / Docker volume ── archivos multimedia (fotos, PDFs)
                                          (tokens JWT firmados, rutas con prefijo de tenant)
```

---

## 12. Seguridad de Servicios de Terceros y Proveedores

Todos los servicios externos se acceden exclusivamente mediante API keys almacenadas en `.env.prod` (nunca en git). Ningún servicio recibe datos financieros en texto claro ni PII más allá de lo estrictamente necesario para su función.

| Servicio | Proveedor | Propósito | Datos enviados | Controles de seguridad |
|---|---|---|---|---|
| **Gemini AI** | Google DeepMind | Análisis de visión, chat, análisis de seguros, riesgo de mantenimiento, embeddings | Descripciones de ítems, fotos (base64), prompts de IA | API key en env var; fotos no persistidas por Google según ToS; números de póliza enmascarados a `****{últimos 4}` antes de enviar |
| **Firebase FCM** | Google Firebase | Notificaciones push (móvil) | Device tokens, título/cuerpo de notificación | Credenciales de service account en env vars; sin datos financieros en payloads |
| **Resend** | Resend Inc. | Email transaccional | Dirección de email del usuario, contenido de notificación | API key en env var; `escapeHtml()` en todo el contenido; sin datos financieros en emails |
| **Cloudflare** | Cloudflare Inc. | DNS, WAF, protección DDoS, proxy TLS | Todo el tráfico HTTP/S entrante | Oculta IP de origen de la VM; TLS 1.3 en el edge; reglas WAF activas; mitigación DDoS automática |
| **Upstash** | Upstash Inc. | Redis gestionado | Sesiones, contadores de rate limit, cache | TLS (`rediss://`), autenticación por contraseña, sin PII en valores |
| **Neon.tech** | Neon Inc. | PostgreSQL gestionado | Usuarios, seguros, audit logs, embeddings | TLS, `rejectUnauthorized: true`, credenciales en env vars |
| **MongoDB Atlas** | MongoDB Inc. | MongoDB gestionado | Documentos de inventario | SCRAM-SHA-256, TLS enforced por Atlas, FLE en campos financieros |
| **GCP** | Google Cloud | VM (Compute Engine) + Cloud Storage | Contenedor API, archivos multimedia | Acceso SSH solo por clave, contenedor non-root, service account con IAM mínimo |
| **Sentry** | Functional Software Inc. | Monitoreo de errores (backend + Flutter) | Stack traces de errores, contexto de requests | DSN en env var; sin valores de campos sensibles en logs; PII removido de payloads de error |
| **Brave Search** | Brave Software Inc. | Búsqueda web para valuación IA (Fase 3) | Nombre + categoría del ítem para investigación de precios | API key en env var; sin PII ni tenant IDs en consultas |
| **Firebase Hosting** | Google Firebase | Hosting de app web Flutter (archivos estáticos) | Archivos compilados de Flutter web | Sin datos sensibles en hosting; config de runtime excluida del git |

**Resumen de riesgo de proveedores:**
- Todas las credenciales almacenadas exclusivamente en `.env.prod` (no en git, no en imágenes Docker)
- Ningún servicio de terceros tiene acceso directo a las bases de datos
- Datos financieros (valuaciones, montos de pólizas) nunca enviados a ninguna API externa
- Todos los servicios utilizados tienen certificación SOC 2 Type II (Google, Cloudflare, MongoDB, Neon, Upstash)

---

## 13. Seguridad de Red y Monitoreo

### Arquitectura de Red

```
Internet
   │
   ▼
Cloudflare (proxy DNS + WAF + DDoS + TLS 1.3)
   │  ← IP de origen oculta del público
   ▼
GCP VM: tennis-backend (us-central1-c)
   │
   ├── UFW Firewall: solo puertos 80, 443, SSH no estándar
   ├── Fail2ban: protección contra fuerza bruta en SSH
   │
   ▼
Caddy (reverse proxy + terminación TLS + renovación automática Let's Encrypt)
   │
   ▼
Red interna Docker
   ├── vaulted_api:3000  (NestJS)
   ├── MongoDB Atlas     (cloud, TLS)
   ├── PostgreSQL Neon   (cloud, TLS)
   └── Redis Upstash     (cloud, TLS)
```

### Protección DDoS y WAF (Cloudflare)
- Todo el tráfico pasa por Cloudflare — la IP de origen de la VM nunca está expuesta públicamente
- WAF de Cloudflare filtra patrones de ataques web comunes (rulesets OWASP)
- Mitigación DDoS automática en capas L3/L4/L7
- Rate limiting a nivel de aplicación (NestJS ThrottlerGuard) provee defensa secundaria

### Configuración TLS
| Endpoint | Versión TLS | Certificado | Notas |
|---|---|---|---|
| `api-vaulted.casacam.net` | TLS 1.3 | Let's Encrypt (auto-renovado vía Caddy) | Capa proxy Cloudflare añade TLS adicional |
| `vaulted-prod-2026.web.app` | TLS 1.3 | Firebase Hosting gestionado | |
| MongoDB Atlas | TLS 1.3 | Gestionado por Atlas | `MONGODB_URI` incluye parámetros TLS |
| PostgreSQL Neon | TLS 1.3 | Gestionado por Neon | `rejectUnauthorized: true` |
| Redis Upstash | TLS 1.3 | Gestionado por Upstash | Esquema `rediss://` |

### Monitoreo y Alertas

| Herramienta | Cobertura | Estado |
|---|---|---|
| **Sentry** | Seguimiento de errores NestJS + crash reporting Flutter | ✅ Configurado (`SENTRY_DSN` env var) |
| **Docker logs** | stdout/stderr del contenedor | ✅ Disponible vía `docker logs vaulted_api` |
| **GCP VM monitoring** | CPU, memoria, disco vía GCP Console | ✅ Disponible |
| **MongoDB Atlas alerts** | Conteo de conexiones, consultas lentas, almacenamiento | ✅ Built-in de Atlas |
| Detección de intrusiones en tiempo real (IDS) | Detección de anomalías de red | ❌ No configurado — roadmap post-MVP |
| Alertas en spikes de 4xx/5xx | Alertas automáticas en tasa de error | ❌ No configurado — roadmap |
| Agregación de logs (Loki/Datadog) | Búsqueda centralizada de logs | ❌ No configurado — roadmap |

> **Nota para el auditor:** La ausencia de un SIEM o IDS centralizado es una brecha conocida. Para la fase MVP actual sin clientes pagos, Sentry + GCP monitoring + Docker logs proveen visibilidad adecuada. Un pipeline de alertas adecuado (PagerDuty, Datadog o GCP Cloud Monitoring) debe implementarse antes de incorporar el primer cliente pagador.

---

## Pendientes Antes de Producción

| Prioridad | Ítem | Responsable |
|---|---|---|
| 🔴 Alta | Ejecutar script de re-cifrado de valuaciones (`infra/restore-valuations.js`) | DevOps |
| 🟡 Media | Detección de jailbreak (Flutter) | Mobile |
| 🟡 Media | Screenshot guard (Flutter) | Mobile |
| 🟡 Media | Auditoría de lectura de datos financieros | Backend |
| 🟢 Baja | Íconos de app Android / iOS | Mobile |
| 🟢 Baja | SBOM + Trivy en CI/CD | DevOps |
| 🔲 Post-MVP | Envelope encryption con GCP KMS | Arquitectura |
| 🔲 Post-MVP | Auditoría SOC 2 Type II | Compliance |

---

## Resumen por Severidad

| Ronda | Críticos | Altos | Medios | Bajos | Total |
|---|---|---|---|---|---|
| Auditoría inicial (PR #253) | 2 | 1 | 3 | — | 6 |
| Módulos IA (PR #254) | 1 | 4 | 5 | 1 | 11 |
| Módulos completos (PR #255) | — | 4 | 2 | — | 6 |
| Hardening media/auth (PR #256) | — | 3 | 5 | 4 | 12 |
| Auditoría CSO completa (1 jun) | 1 | 2 | 3 | — | 6 |
| **TOTAL CORREGIDOS** | **4** | **14** | **18** | **5** | **41** |
| **ABIERTOS** | **0** | **0** | **2** | **3** | **5** |
