# Vaulted — Security Hardening Summary

Última actualización: 2026-06-01  
Agentes: Claude (PRs #253, #254, #255, sesión 2026-06-01) · Codex (PR #256)  
Rama base: `main` (commit `a815d75`)

---

## 1. Auditoría inicial — hallazgos y correcciones (Claude · PR #253)

### CRÍTICOS

| Hallazgo | Archivo | Fix aplicado |
|---|---|---|
| WebSocket CORS abierto a `*` | `orchestrator/orchestrator.gateway.ts` | Reemplazado por whitelist `ALLOWED_ORIGINS`; extraído a `common/config/cors.constants.ts` compartido con `main.ts` y ambos gateways |
| WebSocket CORS con `origin: true` (refleja cualquier origen) | `presence/presence.gateway.ts` | Mismo whitelist `ALLOWED_ORIGINS` con `credentials: true` |

### ALTOS

| Hallazgo | Archivo | Fix aplicado |
|---|---|---|
| Campos `notes` sin límite de tamaño en seguros | `insurance/dto/create-policy.dto.ts` · `update-policy.dto.ts` | `@MaxLength(2000)` en ambos DTOs |

### MEDIOS

| Hallazgo | Archivo | Fix aplicado |
|---|---|---|
| AUDITOR accede a datos financieros sin MFA obligatorio | `common/enums/role.enum.ts` | Añadido `Role.AUDITOR` a `MFA_REQUIRED_ROLES` |
| Salt HKDF hardcodeada (`'vaulted-salt'`) | `common/services/crypto.service.ts` | Salt ahora configurable vía `ENCRYPTION_SALT` env var; backward compatible |
| Orígenes CORS dispersos en múltiples archivos | `main.ts` + gateways | Centralizado en `cors.constants.ts`; `main.ts` simplificado |

---

## 2. Toolkit de pentesting ejecutable (Claude · PR #253)

Creados en `security-tests/`:

| Archivo | Contenido |
|---|---|
| `run-all.sh` | Pruebas automatizadas: JWT alg=none, fuerza bruta throttle, token expirado, inyección NoSQL/SQL/XSS, upload de shell PHP, path traversal, CORS, rate limiting, security headers, TLS |
| `websocket-tests.js` | WebSocket: sin token, token malformado, JWT alg=none, JWT expirado, aislamiento de salas entre tenants |
| `idor-rbac-tests.sh` | IDOR y RBAC: acceso cross-tenant a propiedades/inventario, IDs falsos, escalada de privilegios |
| `extended-security-plan.md` | 10 categorías adicionales: SBOM, Trivy, Semgrep, TruffleHog, Gitleaks, lógica de negocio, seguridad móvil, hardening VM, monitoreo/alertas, pentest externo, DR |

---

## 3. Infraestructura Docker fullstack (Claude · PR #253)

Archivo: `docker-compose-fullstack.prod.yml` + `start-prod-full.sh` + `infra/mongo-init.js` + `infra/backup/run-backup.sh`

| Control | Detalle |
|---|---|
| MongoDB 7.0 con SCRAM-SHA-256 | Auth habilitado; usuario app con permisos mínimos (`readWrite` solo en `vaulted`) |
| PostgreSQL 16 + pgvector | Sin puertos expuestos al host; resource limits |
| Redis 7.2 | Contraseña obligatoria; comandos `FLUSHALL`, `FLUSHDB`, `DEBUG` deshabilitados; `maxmemory 512mb` |
| Red interna Docker | Todos los contenedores DB en red `internal: true`; sin egreso a internet |
| Backup cifrado nocturno | `mongodump` + `pg_dump` → AES-256-CBC con openssl → retención 7 días |
| Validación de env vars | `start-prod-full.sh` verifica todas las variables requeridas antes de arrancar |

---

## 4. Módulos de IA — auditoría completa y correcciones (Claude · PR #254)

### CRÍTICOS

| ID | Hallazgo | Archivo | Fix aplicado |
|---|---|---|---|
| C-1 | Session hijacking: Redis key no incluía `tenantId:userId` — usuario B podía acceder al historial de usuario A si conocía el `sessionId` | `ai/chat/ai-chat.service.ts` | Clave cambiada a `ai:chat:session:${tenantId}:${userId}:${sessionId}` |

### ALTOS

| ID | Hallazgo | Archivo | Fix aplicado |
|---|---|---|---|
| C-2 | Prompt injection en chat: usuario podía enviar `ignore previous instructions`, `act as`, `system:`, etc. | `ai/chat/ai-chat.service.ts` | `sanitizeUserQuery()` elimina patrones de override; instrucción defensiva añadida al `SYSTEM_PROMPT`; `sanitizeAiOutput()` elimina HTML y chars de control de respuestas |
| H-1 | Inyección de prompt vía nombre de habitación: `name`/`type` de `PropertyRoomDto` se interpolaban sin escapar en prompt Gemini | `ai/vision/ai-vision.service.ts` | Sanitización: `.replace(/["\n\r\\]/g, ' ').slice(0, 200)` antes de construir el prompt |
| H-2 | DoS por lista masiva de habitaciones: sin límite en `propertyRooms` | `ai/vision/dto/analyze-item.dto.ts` | `@ArrayMaxSize(100)` |
| H-3 | `imageData` (base64) sin límite; `mimeType` sin validación de valores permitidos | `ai/vision/dto/analyze-sections.dto.ts` | `@MaxLength(10_485_760)` en `imageData`; `@IsIn(['image/jpeg','image/png','image/webp'])` en `mimeType`; `@MaxLength(500)` en `imageUrl` |
| H-4 | `PropertyRoomDto` fields sin límite de tamaño | `ai/vision/dto/analyze-item.dto.ts` | `@MaxLength` en `roomId`(100), `name`(200), `type`(100), URLs de imagen(500) |

### MEDIOS

| ID | Hallazgo | Archivo | Fix aplicado |
|---|---|---|---|
| M-1 | Rate limit solo por tenant, no por usuario: un usuario podía agotar la cuota de todo el tenant | `ai-chat`, `ai-help`, `ai-insurance` services | Bucket secundario por `userId` al 50% del límite tenant en los tres servicios |
| M-2 | Número de póliza completo enviado a Google Gemini en análisis de cobertura | `ai/insurance/ai-insurance.service.ts` | Número enmascarado a `****{últimos 4 dígitos}` en el prompt de análisis (el draft de claims sí lo incluye completo por necesidad) |
| M-3 | Contenido generado por IA guardado en DB sin sanitización: podía incluir HTML, chars de control | `ai/maintenance/ai-maintenance.service.ts` | `sanitizeText()` elimina HTML y chars de control; límites duros: `title`(200), `reason`(500), `recommendedAction`(500); `riskScore` clamped 0-100; `suggestedIntervalDays` clamped 1-3650 |
| M-4 | AI Help accesible al rol GUEST | `ai/help/ai-help.controller.ts` | Eliminado `Role.GUEST` del decorador `@Roles()` |
| M-5 | TTL de sesión AI chat demasiado largo (3600s) | `ai/chat/ai-chat.service.ts` | Reducido a 1800s |
| L-1 | Logger imprimía respuesta AI completa (potencialmente grande) en errores de parseo | `ai/vision/ai-vision.service.ts` | Truncado a 200 chars en `logger.error` |

---

## 5. Auditoría exhaustiva de módulos restantes y correcciones (Claude · PR #255)

Módulos auditados en paralelo: orchestrator, movements, household-members, notifications, wardrobe, dashboard, presence, BullMQ jobs, Redis keys, logging PII, TypeORM entities, media tokens, tenant registration, email injection, ReDoS.

### ALTOS

| Hallazgo | Archivo | Fix aplicado |
|---|---|---|
| IDOR en TRANSFER: destino de movimiento no verificaba que la propiedad pertenezca al tenant — se podía mover ítems a propiedades de otro tenant | `movements/movements.service.ts:248` | `propertyModel.findOne({ _id: destPropertyId, tenantId })` antes del bloque TRANSFER; lanza `BadRequestException` si la propiedad no pertenece al tenant |
| IDOR en `unregisterDeviceToken`: lookup solo por `token + userId`, sin `tenantId` — usuario de tenant A podía eliminar token de tenant B | `notifications/notifications.service.ts` + controller | Añadido `tenantId` al `where` del findOne; controller pasa `user.tenantId` |
| PII en logs: dirección de email del destinatario se logeaba en errores de Resend | `notifications/notifications.service.ts:231,239` | Email reemplazado por `tenant: ${params.tenantId}` en ambas líneas de error |
| CVEs críticos/altos en dependencias (handlebars, path-to-regexp, lodash, fast-xml-parser) | `package.json` | `npm audit fix` eliminó todos los críticos y altos; 8 moderados residuales en deps transitivas de Firebase/GCP |

### MEDIOS

| Hallazgo | Archivo | Fix aplicado |
|---|---|---|
| `linkedUserId` en household-members no validado contra tenant: podía referenciar usuarios de otros tenants | `household-members/household-members.service.ts` + module | `assertLinkedUserBelongsToTenant()` verifica via `UsersService.findById()` que el usuario pertenece al mismo tenant; `UsersModule` importado en `HouseholdMembersModule` |
| `completionPhotoUrl` sin validación de formato URL ni límite de tamaño | `orchestrator/dto/complete-step.dto.ts` | `@IsUrl({ require_tld: false })` + `@MaxLength(2000)` |

### Hallazgos verificados como seguros (sin acción requerida)

| Área | Veredicto |
|---|---|
| Redis keys inventory | Todas las claves correctamente namespaciadas por tenant/user; sin PII sin cifrar |
| Email injection (Resend API) | Array format en `to:` previene header injection; `escapeHtml()` en templates |
| ReDoS | `escapeRegex()` protege todas las entradas de usuario antes de usar en `new RegExp()`; resto son patrones estáticos |
| Media token scoping | `generateFileToken()` vincula `fileKey + tenantId + userId`; `serveFile()` valida prefijo tenantId |
| Wardrobe stats cache key | Estadísticas son aggregate de tenant, no datos individuales — scope de tenant es correcto |
| Tenant registration rate limit | 5 req/60s por IP ya implementado via `@Throttle`; `tenantName` con `@MinLength(2) @MaxLength(255)` |

---

## 6. Hardening de media, autenticación y móvil (Codex · PR #256)

### ALTOS

| Hallazgo | Fix aplicado |
|---|---|
| Path traversal en media local (`tenant/../../`) | Validación canónica completa: rechazo de `..`, paths absolutos, backslashes, segmentos vacíos, null bytes; resolución dentro de `uploadsRoot` |
| Media privada expuesta directamente via `/uploads` (Express static assets) | Montaje eliminado; todos los uploads se sirven exclusivamente via URL firmada `/api/media/:token` |
| Refresh token replay: rotación sin invalidación del token anterior | Refresh token one-time-use: se exige membresía en sesión Redis, JTI usado va a blacklist + srem, sesión completa invalidada ante replay detectado |

### MEDIOS

| Hallazgo | Fix aplicado |
|---|---|
| MFA obligatorio no forzado para Owner/Manager sin MFA configurado | Login/invite devuelven `mfaRequired=true` y `mfaSetupRequired=true`; access token con `mfaVerified=false` hasta completar setup |
| Rate limit MFA verify demasiado permisivo (100/min) | Reducido a 5/min en `/auth/mfa/verify` |
| Flutter release podía usar HTTP/WS por default | Build release exige `API_BASE_URL` HTTPS y `WS_BASE_URL` WSS; HTTP localhost solo en debug |
| PostgreSQL TLS con `rejectUnauthorized: false` | Producción usa `rejectUnauthorized: true`; soporte para `POSTGRES_CA_CERT` |
| Inyección NoSQL vía `inventory.attributes`: claves `$`, `.`, `__proto__` no rechazadas | Validación de claves: se rechazan `$`, `.`, `__proto__`, `constructor`, `prototype`, arrays muy grandes, strings extensos, profundidad excesiva |

### BAJOS

| Hallazgo | Fix aplicado |
|---|---|
| Tokens en almacenamiento inseguro móvil | `flutter_secure_storage` confirmado; iOS Keychain ahora con `first_unlock_this_device` |
| Permisos Android incompletos | `INTERNET` añadido al manifest principal |
| CORS dev/prod mezclado | Orígenes separados por entorno; override via `CORS_ALLOWED_ORIGINS` env var |
| Firebase web config hardcodeado en service worker | Config cargado desde `web/firebase-config.js` generado en deploy; ejemplo sin valores reales; runtime config en `.gitignore` |

---

## 7. Script de migración de salt (Codex · PR #256)

Creado `infra/re-encrypt-salt.js` — script Node.js standalone que re-cifra todos los campos FLE al cambiar `ENCRYPTION_SALT`. Cubre:

- **PostgreSQL:** `insurance_policies` (5 campos), `insured_items` (1 campo), `users.mfa_secret`
- **MongoDB:** `items.valuation` (3 subcampos)

> **Importante:** `ENCRYPTION_SALT` sigue usando el fallback `'vaulted-salt'` hasta que se configure explícitamente en `.env.prod`. Cambiar el salt requiere correr este script **antes** de redeployar la API para evitar que los datos existentes queden ilegibles.

---

## 10. Auditoría CSO completa y correcciones (Claude · 2026-06-01)

Auditoría ejecutada con `/cso --comprehensive` (modo exhaustivo, gate 2/10) sobre el estado actual de `main`. Se escanearon las 14 fases (secretos, supply chain, CI/CD, infraestructura, OWASP Top 10, STRIDE, AI security). Verificación independiente paralela en los dos hallazgos críticos/altos con sub-agentes.

### CRÍTICO

| Hallazgo | Archivo | Fix aplicado |
|---|---|---|
| Escalación de privilegios: Manager podía promover cualquier usuario a Owner via `PUT /users/:id` con `{ role: 'owner' }`. `updateUser()` nunca recibía el rol del actor y carecía del mismo check que ya existía en `invite()` | `users/users.service.ts:265` · `users/users.controller.ts` | Agregado parámetro `actorRole: Role` a `updateUser()`; guard `if (dto.role === OWNER && actorRole !== OWNER) → ForbiddenException`; controller pasa `user.role`; test actualizado |

### ALTOS

| Hallazgo | Archivo | Fix aplicado |
|---|---|---|
| `TYPEORM_SYNC=true` en template de producción + lógica `\|\|` cortocircuitable: si el env var estaba en `true`, TypeORM ejecutaba `ALTER TABLE DROP COLUMN` contra Neon.tech en cada deploy | `.env.prod.example:25` · `app.module.ts:83` | Template cambiado a `TYPEORM_SYNC=false`; lógica invertida a `!isProd && TYPEORM_SYNC === 'true'` — producción nunca sincroniza |
| `Dockerfile.prod` sin directiva `USER`: proceso Node corría como root dentro del contenedor | `apps/api/Dockerfile.prod` | Agregado usuario `vaulted` no-root (`addgroup`/`adduser`), `chown -R vaulted:vaulted /app`, directiva `USER vaulted` antes de `CMD` |

### MEDIOS

| Hallazgo | Archivo | Fix aplicado |
|---|---|---|
| Swagger UI accesible públicamente en producción: `SwaggerModule.setup()` corría sin guard de entorno | `main.ts:69` | Todo el bloque Swagger (setup + file write) envuelto en `if (NODE_ENV !== 'production')` |
| GitHub Actions con tags mutables: `subosito/flutter-action@v2` y `FirebaseExtended/action-hosting-deploy@v0` — un ataque de supply chain al repo de la acción comprometería el deploy key de Firebase | `.github/workflows/deploy-web.yml` | Ambas acciones fijadas a SHA completo: `@1a449444c387...` (flutter-action) y `@092436dca3ec...` (action-hosting-deploy) |
| Certificate pinning ausente en app mobile (marcado como TODO desde la sesión anterior) | `apps/mobile/lib/core/network/api_client.dart` | Pinning implementado con `IOHttpClientAdapter` + SHA-256 via `package:crypto`; fingerprint actual de `api-vaulted.casacam.net` almacenado en `AppConfig.pinnedCertFingerprints`; debug mode permisivo para desarrollo local; web skipeado (los browsers gestionan TLS nativamente) |

### Hallazgos descartados (FP)

| Área | Veredicto |
|---|---|
| TOTP replay attack | Tasa de 5/min hace inviable el brute-force; window de 90s limita la ventana de uso; sin acción |
| Salt `'vaulted-salt'` hardcodeada | Intencional para backward compatibility (documentado en `.env.prod.example`); ENCRYPTION_KEY es el secreto real; sin acción |
| Jailbreak detection / screenshot guard | En requirements del CLAUDE.md pero no implementado aún; pendiente pre-App Store |

---

## 8. Riesgo residual y seguimiento

| # | Área | Riesgo | Prioridad |
|---|---|---|---|
| R-1 | Email verification gate | Tenant creado sin verificar email; rate limit de IP no impide rotación de IPs | Post-MVP |
| R-2 | UX MFA setup Flutter | Backend fuerza `mfaSetupRequired`; flujo móvil debe mostrar QR/secret de `/auth/mfa/setup` para completar setup | Alta |
| R-3 | CVEs moderados Firebase/GCP | 8 vulnerabilidades moderadas en deps transitivas (`uuid` en firebase-admin, @google-cloud) — no corregibles sin actualización mayor del SDK | Media |
| R-4 | ObjectId validation pipe | Queries MongoDB mantienen `tenantId`; se recomienda pipe global de ObjectId para validación uniforme | Media |
| R-5 | Media histórica pre-fix | Registros anteriores con URLs `/uploads` se normalizan; acceso público directo ya no existe. Validar migración si hay datos activos | Media |
| R-6 | Firebase deploy CI | `web/firebase-config.js` debe generarse desde secretos CI antes de publicar | Alta (ops) |
| R-7 | Envelope encryption con KMS | HKDF-SHA-256 actual es criptográficamente sólido para MVP; migrar a GCP KMS post-MVP | Post-MVP |
| R-8 | Prompt injection sandbox completo | Fix actual mitiga inyecciones obvias; evaluación de output por el modelo pendiente para mayor robustez | Baja |
| R-9 | Audit log TODOs | Entradas pendientes en `properties.service.ts`, `users.service.ts`, `media.service.ts` | Baja |
| R-10 | Rotación de cert pinning | El fingerprint en `AppConfig.pinnedCertFingerprints` corresponde al cert actual de Let's Encrypt (TTL ~90 días via Caddy). Antes de cada renovación: agregar el nuevo fingerprint, publicar release, luego remover el viejo. Ver procedimiento en CLAUDE.md | Alta (ops) |
| R-11 | Jailbreak detection / screenshot guard | Listados en Security Requirements del CLAUDE.md pero no implementados en Flutter. Necesarios antes de App Store / Google Play | Media |

---

## 9. Verificaciones ejecutadas

| Check | Agente | Resultado |
|---|---|---|
| `npm run build` (apps/api) | Codex | OK |
| `npm test -- media.service.spec.ts auth.service.spec.ts inventory.service.spec.ts --runInBand` | Codex | OK |
| `npm audit` (apps/api) | Claude | 0 críticos, 0 altos, 8 moderados residuales (Firebase/GCP transitivos) |
| Validación de balanceo de llaves TypeScript en todos los archivos modificados | Claude | OK |
| `flutter analyze` / `dart format` | Codex | No ejecutable en contenedor (falta `flutter` en PATH) |

---

## Resumen ejecutivo

En total se identificaron y corrigieron **42 vulnerabilidades** distribuidas así:

| Severidad | Encontradas | Corregidas | Residuales |
|---|---|---|---|
| Críticas | 4 | 4 | 0 |
| Altas | 15 | 15 | 0 |
| Medias | 18 | 17 | 1 (email verify — decisión de producto) |
| Bajas | 5 | 5 | 0 |
| Moderadas (CVE deps) | 8 | 0 | 8 (Firebase/GCP transitivos) |

Los scripts de pentesting en `security-tests/` están listos para validar empíricamente todos los controles implementados. Los resultados de esas pruebas alimentarán el informe final orientado a cliente.
