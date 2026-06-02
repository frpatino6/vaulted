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
| `run-all.sh` | JWT alg=none, brute-force throttle, expired tokens, NoSQL/SQL/XSS injection, PHP shell upload, path traversal, CORS, rate limiting, security headers, TLS |
| `websocket-tests.js` | No-token, malformed token, alg=none, expired JWT, cross-tenant room isolation |
| `idor-rbac-tests.sh` | Cross-tenant property/inventory access, fake IDs, privilege escalation |

All tests pass against production (`https://api-vaulted.casacam.net`).

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

**Why PostgreSQL for this data:** Users and insurance policies have relational structure (users belong to tenants; policies cover specific items). The audit log requires strict immutability guarantees that SQL constraints enforce. `pgvector` enables semantic search for AI features without an external vector database.

**Security controls applied:**
- `rejectUnauthorized: true` — TLS certificate verified on every connection
- `TYPEORM_SYNC=false` in production — TypeORM cannot auto-drop or alter columns in prod
- `audit_logs` table has no `UPDATE` or `DELETE` permissions for the app user — immutable by design
- AES-256-GCM encryption on sensitive insurance fields (`policyNumber`, `premiumAmount`, `coverageAmount`, `deductible`, `notes`) and `users.mfa_secret`
- `pgvector` embeddings contain only AI-generated text vectors — no raw user content stored as plaintext in that table
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

**Why Redis for this data:** All data here is ephemeral by design — sessions expire, rate limit windows reset, caches are re-populated. Redis TTL enforcement is native and atomic. Storing JWT blacklists in a relational DB would create contention on every authenticated request.

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

**Por qué MongoDB para estos datos:** Los ítems de inventario tienen esquemas muy variables (un reloj tiene atributos diferentes a una pintura). El modelo de documentos de MongoDB maneja `attributes: {}` heterogéneo nativamente sin migraciones de esquema.

**Controles de seguridad aplicados:**
- Autenticación SCRAM-SHA-256 (enforced por Atlas)
- Usuario de la app con permisos `readWrite` solo en la DB `vaulted` — sin acceso admin
- Cifrado a nivel de campo (AES-256-GCM) en `valuation.purchasePrice`, `valuation.currentValue`, `valuation.lastAppraisalDate` — un dump de la DB no expone valores financieros
- `tenantId` en cada documento — todas las consultas filtran por tenant antes de retornar datos
- `escapeRegex()` en todos los términos de búsqueda del usuario — previene ReDoS
- Claves con `$`, `.`, `__proto__`, `constructor`, `prototype` rechazadas en `attributes` — previene inyección NoSQL

---

### PostgreSQL (Neon.tech) — Usuarios, Datos Financieros y Auditoría
**Proveedor:** Neon.tech (PostgreSQL serverless, free tier)
**Conexión:** variable de entorno `DATABASE_URL` (TLS, `rejectUnauthorized: true` en producción)
**ORM:** TypeORM (`TYPEORM_SYNC=false` en producción)
**Extensión:** `pgvector` (embeddings de IA, 3072 dimensiones)

| Propósito | Tablas |
|---|---|
| Cuentas de usuario y credenciales | `users` |
| Tenants / familias cliente | `tenants` |
| Pólizas de seguro y coberturas | `insurance_policies`, `insured_items` |
| Base de conocimiento de IA (embeddings) | `embeddings` (pgvector) |
| Registro de auditoría inmutable | `audit_logs` |

**Por qué PostgreSQL para estos datos:** Usuarios y pólizas de seguro tienen estructura relacional (usuarios pertenecen a tenants; pólizas cubren ítems específicos). El log de auditoría requiere garantías estrictas de inmutabilidad que las restricciones SQL imponen. `pgvector` habilita búsqueda semántica para funciones de IA sin una base de datos vectorial externa.

**Controles de seguridad aplicados:**
- `rejectUnauthorized: true` — certificado TLS verificado en cada conexión
- `TYPEORM_SYNC=false` en producción — TypeORM no puede auto-eliminar ni alterar columnas en prod
- La tabla `audit_logs` no tiene permisos de `UPDATE` o `DELETE` para el usuario de la app — inmutable por diseño
- Cifrado AES-256-GCM en campos sensibles de seguros (`policyNumber`, `premiumAmount`, `coverageAmount`, `deductible`, `notes`) y `users.mfa_secret`
- Los embeddings de `pgvector` contienen solo vectores generados por IA — no se almacena contenido de usuario en texto plano
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

**Por qué Redis para estos datos:** Todos los datos aquí son efímeros por diseño — las sesiones expiran, las ventanas de rate limit se resetean, los caches se repopulan. El TTL de Redis es nativo y atómico. Almacenar blacklists de JWT en una base de datos relacional generaría contención en cada request autenticado.

**Controles de seguridad aplicados:**
- `rediss://` (TLS) — datos cifrados en tránsito hacia Upstash
- Autenticación por contraseña obligatoria
- Comandos `FLUSHALL`, `FLUSHDB`, `DEBUG` deshabilitados — previene borrado accidental o malicioso del cache
- `maxmemory 512mb` con política de evicción — previene DoS por OOM
- Todas las claves de chat IA con scope `tenantId:userId` — session hijacking cross-tenant bloqueado
- Sin PII en texto plano en Redis — valores financieros y datos personales permanecen en MongoDB/PostgreSQL

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
