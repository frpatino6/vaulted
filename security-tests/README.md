# Vaulted — Security Test Suite

Target: https://api-vaulted.casacam.net  
Última actualización: 2026-06-01

---

## Prerequisitos

```bash
# macOS
brew install curl python3 node

# Linux/Debian
apt-get install curl python3 nodejs npm
```

---

## Setup MFA (una sola vez, obligatorio)

El owner de prueba tiene MFA activo. Antes de correr cualquier script por **primera vez**, ejecutar:

```bash
cd security-tests
bash get-mfa-secret.sh
```

El script hace: login → setup MFA → muestra QR/secreto → pide código de tu app → guarda `MFA_SECRET` en `.env`.

> **No correr de nuevo.** Llamar a `/auth/mfa/setup` genera un secreto pendiente en Redis (TTL 10 min) que rompe el MFA de la cuenta hasta que expire.

---

## Scripts disponibles

### `pentest-full.sh` — Pentest completo (recomendado)

```bash
bash pentest-full.sh
```

Cubre **20 fases** de hacking ético en un solo comando (~5 min):

| Fase | Categoría |
|------|-----------|
| 1 | Security Headers (HSTS, CSP, X-Frame-Options, Referrer-Policy) |
| 2 | Auth & JWT (alg=none, firma falsa, expirado, brute-force, MFA, logout, pre-MFA token) |
| 3 | SQL Injection (6 payloads en login, time-based blind, SQLi en search) |
| 4 | NoSQL Injection ($gt, $ne, $where, ReDoS, prototype pollution) |
| 5 | Prompt Injection (6 payloads → /ai/chat, /ai/help, /ai/insurance/analyze) |
| 6 | IDOR/BOLA (GET/PATCH/DELETE cross-tenant en todos los endpoints, X-Tenant-Id injection, mass assignment) |
| 7 | RBAC (escalada de rol, pre-MFA en endpoints protegidos, audit log inmutable) |
| 8 | Business Logic (valuación negativa, overflow, cross-tenant transfer, fecha expirada) |
| 9 | File Upload (PHP shell, HTML, SVG/XSS, path traversal, sin auth, >11MB) |
| 10 | Input Validation (null bytes, Unicode RTL, 100k chars, JSON profundo, XSS, CRLF) |
| 11 | SSRF (GCP metadata, AWS metadata, Redis, MongoDB, PostgreSQL via imageUrl) |
| 12 | Race Conditions (5 loans simultáneos, 5 registros simultáneos) |
| 13 | CORS (origen malicioso, null origin, wildcard + credentials) |
| 14 | Rate Limiting (AI chat 20/min, API general) |
| 15 | Sensitive Data Exposure (stack traces, .env, passwords, hashes, Swagger) |
| 16 | TLS (HTTP→HTTPS redirect, TLS 1.0/1.1 rechazado, TLS 1.2 OK, cert válido) |
| 17 | Key Material (.env, .env.prod, .git/config, source maps, docker-compose) |
| 18 | Infrastructure (nmap, paths sensibles, Cloudflare WAF, X-Powered-By) |
| 19 | Session & Cookies (HttpOnly, Secure, SameSite, refresh token replay) |
| 20 | Guest & Expiration (token expirado, sin rol, guest en financials) |

---

### `run-all.sh` — Fases 1–11 (suite original)

```bash
bash run-all.sh
```

Guarda log en `pentest-YYYYMMDD-HHMMSS.log`. Cubre headers, auth, injections, file upload, CORS, rate limiting, TLS, sensitive data, key material, infraestructura.

---

### `idor-rbac-tests.sh` — IDOR y RBAC en detalle

```bash
bash idor-rbac-tests.sh
```

- **Fase 3A:** RBAC — lista de usuarios, acceso cross-tenant a property/inventory/insurance, X-Tenant-Id injection
- **Fase 3B:** Object-Level — ítem propio accesible, enumeración secuencial de IDs
- **Fase 3C:** Privilege Escalation — auto-modificación de rol, invitación con rol superior
- **Fase 3D:** Guest Expiration — JWT expirado, token sin rol, guest en financials

---

### `websocket-tests.js` — Seguridad WebSocket

```bash
# Instalar dependencia (solo la primera vez)
npm install

# Correr tests
node websocket-tests.js
```

Cubre `/presence` y `/orchestrator`:
- Sin token → rechazado
- Token malformado → rechazado
- JWT alg=none → rechazado
- JWT expirado → rechazado
- Token válido → conecta correctamente
- Room hopping → el servidor ignora joins a salas de otros tenants

---

### `get-mfa-secret.sh` — Setup MFA (una sola vez)

```bash
bash get-mfa-secret.sh
```

Script interactivo. Guarda `MFA_SECRET` en `.env`. Ver sección **Setup MFA** arriba.

---

## Resumen de cobertura

| Script | Duración | Tests aprox. |
|--------|----------|-------------|
| `pentest-full.sh` | ~5 min | ~110 checks |
| `run-all.sh` | ~3 min | ~60 checks |
| `idor-rbac-tests.sh` | ~1 min | ~15 checks |
| `websocket-tests.js` | ~30 seg | 8 checks |

---

## Interpretación de resultados

| Estado | Significado |
|--------|-------------|
| `✅ PASS` | Control funcionando correctamente |
| `❌ FAIL` | Vulnerabilidad confirmada — remediación requerida |
| `⚠ WARN` | Hallazgo informacional — revisar y decidir |
| `⏭ SKIP` | Test omitido por falta de prerequisito |

Código HTTP `000` = Cloudflare/WAF bloqueó la conexión. Es un rechazo válido (equivalente a PASS en tests de seguridad).

---

## Documentación completa

Ver `docs/security-fixes-summary.md` para:
- Lista completa de vulnerabilidades encontradas y corregidas (PRs #253–#256)
- Bugs encontrados durante ejecución de los scripts y sus fixes
- Tabla de riesgo residual
- Resumen ejecutivo de severidades
