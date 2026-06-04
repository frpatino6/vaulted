# Informe de Auditoría de Seguridad — Vaulted Backend

**Fecha**: 2026-06-03
**Herramienta**: opencode + backend-security-auditor skill
**Objetivo**: `apps/api` — NestJS + TypeScript (19 controladores, 23 módulos, ~30K LOC)
**Estándares**: OWASP Top 10:2025, OWASP API Security Top 10:2023, NIST SP 800-53, OWASP LLM Top 10:2025

---

## Resumen Ejecutivo

1. **Sin bloqueo de cuenta por brute force** — atacantes con red de proxies pueden probar contraseñas indefinidamente a 5 intentos/min/IP.
2. **Los cambios de rol no invalidan sesiones** — usuarios degradados retienen privilegios viejos hasta 7 días vía refresh token.
3. **NotificationsController sin `@Roles()`** — cualquier usuario autenticado (incluso GUEST) puede registrar dispositivos, enviar push de prueba, y borrar notificaciones. Cero control de acceso por rol.
4. **Orchestrator + Insurance + Maintenance sin audit logs** — 3 módulos completos sin `AuditService`. Ninguna operación de escritura queda registrada.
5. **AI Help no sanitiza output del LLM** — `AiChatService` sí lo hace, `AiHelpService` no. Inconsistencia que permite XSS si hay prompt injection.
6. **Postura general sólida** — aislamiento multi-tenant correcto, protección anti-replay en MFA, encriptación de campo correcta, pipeline de guards bien ordenado, rotación de refresh tokens atómica.

---

## Resumen de Hallazgos por Severidad

| Severidad | Cantidad |
|-----------|----------|
| **CRÍTICO** | 0 |
| **ALTO** | 5 |
| **MEDIO** | 10 |
| **BAJO** | 13 |
| **Total** | **28** |

---

## ALTO (5)

---

### SEC-001 — Sin bloqueo de cuenta por brute force

| Campo | Detalle |
|-------|---------|
| **OWASP** | A07: Fallas de Autenticación, API2: Broken Authentication |
| **Archivo** | `apps/api/src/modules/auth/auth.service.ts:88-100` |
| **Problema** | No se trackingean intentos fallidos por cuenta. El rate limit es solo por IP (5/min). Un atacante con red de proxies (miles de IPs) puede brute force passwords indefinidamente. |
| **Escenario de explotación** | Atacante con botnet de 1000 IPs envía 5 requests/min/IP = 5000 intentos/min. Sin bloqueo de cuenta, la contraseña se descubre en horas/días. |
| **Impacto** | Toma de cuenta por adivinación de contraseña |
| **Solución** | Agregar contador `failed_login_attempts` y timestamp `locked_until` en entidad `User`. Incrementar en fallo, resetear en éxito. Bloquear 15 min tras 10 fallos consecutivos. |
| **Verificación** | Test unitario: 11º intento con contraseña incorrecta retorna `423 Locked` |

---

### SEC-002 — Enumeración de emails por timing

| Campo | Detalle |
|-------|---------|
| **OWASP** | A01: Broken Access Control (fuga de info), API6: Acceso sin restricciones |
| **Archivo** | `apps/api/src/modules/auth/auth.service.ts:88-100` |
| **Problema** | El tiempo de respuesta del login difiere: email no existe (~5ms) vs contraseña incorrecta (~60-100ms por bcrypt). Esto permite determinar qué emails están registrados. |
| **Escenario de explotación** | Script automatizado mide tiempos de respuesta. Emails existentes devuelven ~60ms+; inexistentes ~5ms. Se construye lista de emails para phishing dirigido o credential stuffing. |
| **Impacto** | Enumeración de cuentas — prerrequisito para phishing y credential stuffing |
| **Solución** | Siempre ejecutar bcrypt compare aunque el usuario no exista: `const passwordHash = user?.passwordHash ?? dummyHash;` usando un hash dummy del mismo costo. |
| **Verificación** | Test de timing: 100 iteraciones no deben mostrar diferencia estadística significativa |

---

### SEC-003 — Cambio de rol no invalida sesiones

| Campo | Detalle |
|-------|---------|
| **OWASP** | A01: Broken Access Control |
| **Archivo** | `apps/api/src/modules/users/users.service.ts` (updateUser), auth.service.ts (sin invalidación) |
| **Problema** | Cuando OWNER degrada MANAGER a GUEST, los JWTs existentes aún contienen el rol viejo. `RolesGuard` lee el rol del JWT, no de la DB. El refresh token (7 días TTL) sigue siendo válido. |
| **Escenario de explotación** | Usuario degradado usa su refresh token para obtener nuevos access tokens con el rol antiguo. Sigue teniendo acceso completo por hasta 7 días. |
| **Impacto** | Escalación de privilegios persiste hasta 7 días post-degradación |
| **Solución** | Llamar `invalidateAllSessions(userId)` después de cualquier cambio de rol en `UsersService.updateUser()`. |
| **Verificación** | Test de integración: degradar usuario → token viejo retorna 403 en endpoint protegido |

---

### SEC-004 — NotificationsController sin `@Roles()` en ningún endpoint

| Campo | Detalle |
|-------|---------|
| **OWASP** | A01: Broken Access Control |
| **Archivo** | `apps/api/src/modules/notifications/notifications.controller.ts` — todos los 10 endpoints |
| **Problema** | Ningún endpoint tiene decorador `@Roles()`. Cualquier usuario autenticado (OWNER, MANAGER, STAFF, AUDITOR, GUEST) tiene acceso idéntico a: test-push, device-token register/delete, preferences R/W, notification list/R/W, clear-read. |
| **Endpoints expuestos** | `POST /notifications/test-push`, `POST /notifications/device-token`, `DELETE /notifications/device-token/:token`, `PATCH /notifications/preferences`, `PATCH /notifications/:id/read`, `POST /notifications/mark-all-read`, `DELETE /notifications/clear-read`, `DELETE /notifications/:id` |
| **Impacto** | Guest puede enviar push, registrar dispositivos, borrar notificaciones. Violación del principio de mínimo privilegio. |
| **Solución** | Agregar `@Roles(OWNER, MANAGER)` a endpoints de escritura. `@Roles(OWNER, MANAGER, STAFF, AUDITOR)` a los de lectura. |
| **Verificación** | Test de integración: GUEST token retorna 403 en test-push |

---

### SEC-005 — Orchestrator + Insurance + Maintenance sin audit logs

| Campo | Detalle |
|-------|---------|
| **OWASP** | A09: Fallas de Logging y Monitoreo |
| **Archivo** | `orchestrator.controller.ts` (11 endpoints), `insurance.controller.ts` (5 endpoints), `maintenance.controller.ts` (3 endpoints) |
| **Problema** | Estos 3 módulos no inyectan `AuditService`. Ninguna operación de escritura tiene logging de auditoría. En total: 19 endpoints de escritura sin registro forense. |
| **Endpoints sin audit** | **Orchestrator**: POST plans, PATCH plans, POST publish, PATCH complete-step, POST groups, POST steps, DELETE groups, DELETE steps. **Insurance**: POST policies, PUT policies, DELETE policies, POST attach-item, DELETE detach-item. **Maintenance**: POST create, PUT update, DELETE delete. |
| **Impacto** | Imposibilidad de investigación forense post-incidente. Violación de cumplimiento. |
| **Solución** | Inyectar `AuditService` en cada controlador y llamar `auditService.log()` en cada endpoint de escritura. |
| **Verificación** | Test de integración: cada endpoint de escritura crea una fila en `audit_logs` |

---

## MEDIO (10)

---

### SEC-006 — Login DTO sin límite de longitud de contraseña

| Campo | Detalle |
|-------|---------|
| **OWASP** | A05: Security Misconfiguration |
| **Archivo** | `apps/api/src/modules/auth/dto/login.dto.ts:9-11` |
| **Problema** | Solo `@IsString()` — sin `@MinLength`/`@MaxLength`. Un atacante puede enviar una contraseña de 10MB, consumiendo CPU/memoria en class-validator y parsing de Express. |
| **Solución** | Agregar `@MinLength(1)` y `@MaxLength(128)` a `LoginDto` |
| **Verificación** | Test unitario: contraseña de 129 caracteres retorna 400 |

---

### SEC-007 — JWT algorithm no restringido explícitamente

| Campo | Detalle |
|-------|---------|
| **OWASP** | A07: Fallas de Autenticación, A02: Security Misconfiguration |
| **Archivo** | `apps/api/src/modules/auth/strategies/jwt.strategy.ts:25-29`, `jwt-refresh.strategy.ts` |
| **Problema** | No se especifica `algorithms` en Passport strategy. Aunque `jsonwebtoken` rechaza `alg: none` por defecto, un whitelist explícito es defensa en profundidad contra algorithm confusion. |
| **Solución** | Agregar `algorithms: ['HS256']` a ambas estrategias JWT |
| **Verificación** | Test unitario: token con `alg: HS512` es rechazado |

---

### SEC-008 — MFA setup no invalida sesiones existentes

| Campo | Detalle |
|-------|---------|
| **OWASP** | A07: Fallas de Autenticación |
| **Archivo** | `apps/api/src/modules/auth/auth.service.ts:256-301` |
| **Problema** | Cuando un usuario configura MFA, las sesiones existentes con `mfaVerified: false` siguen siendo válidas por 15 min. El token viejo puede acceder a `/auth/mfa/verify`. |
| **Solución** | Llamar `invalidateAllSessions(userId)` después de `setupMfa()` |
| **Verificación** | Test de integración: configurar MFA → token viejo retorna 401 en endpoint protegido |

---

### SEC-009 — TOTP window=2 reduce entropía efectiva

| Campo | Detalle |
|-------|---------|
| **OWASP** | A07: Fallas de Autenticación |
| **Archivo** | `apps/api/src/modules/auth/auth.service.ts:334` |
| **Problema** | `window: 2` valida 5 intervalos de tiempo por intento (current ± 2). El espacio de búsqueda efectivo baja de 1,000,000 a ~200,000 combinaciones. Con 5 intentos/min permitidos, el brute force se reduce de ~14 días a ~3 días. |
| **Solución** | Reducir a `window: 1` (3 intervalos). Agregar bloqueo de MFA a nivel de cuenta tras 10 fallos. |
| **Verificación** | Manual: verificar que solo ±1 intervalo sea aceptado |

---

### SEC-010 — Blacklist de access token usa JWT crudo como key de Redis

| Campo | Detalle |
|-------|---------|
| **OWASP** | A04: Cryptographic Failures |
| **Archivo** | `apps/api/src/modules/auth/auth.service.ts:193`, `jwt.strategy.ts:47` |
| **Problema** | El JWT completo (~500+ chars) se usa como key de Redis. Esto expone claims del token en el key namespace de Redis (visible via `INFO keyspace` o `MONITOR`). Ineficiente en memoria. |
| **Solución** | Usar SHA-256 hash del token como key: `createHash('sha256').update(token).digest('hex')` |
| **Verificación** | Test unitario: la blacklist usa string hexadecimal, no el JWT |

---

### SEC-011 — Logout sin rate limiting

| Campo | Detalle |
|-------|---------|
| **OWASP** | API4: Unrestricted Resource Consumption |
| **Archivo** | `apps/api/src/modules/auth/auth.controller.ts:150-197` |
| **Problema** | Sin `@Throttle()` en logout/logout-all. Un token válido puede spamear writes a Redis (10,000 requests/s), causando amplificación de escritura y costos de infraestructura. |
| **Solución** | Agregar `@Throttle({ default: { limit: 10, ttl: 60000 } })` a ambos endpoints |
| **Verificación** | Test de integración: 11º intento de logout retorna 429 |

---

### SEC-012 — LLM output sin sanitizar en AI Help

| Campo | Detalle |
|-------|---------|
| **OWASP** | LLM05: Improper Output Handling, A05: Injection |
| **Archivo** | `apps/api/src/modules/ai/help/ai-help.service.ts:1134` vs `ai-chat.service.ts:185` |
| **Problema** | `AiChatService` sanitiza el output de Gemini con `sanitizeAiOutput()` (elimina etiquetas HTML + caracteres de control). `AiHelpService` retorna `result.text` directamente sin sanitización. Una inyección de prompt en el chat de ayuda puede causar que Gemini devuelva HTML/scripts que se rendericen en el cliente. |
| **Solución** | Aplicar `sanitizeAiOutput(result.text)` en `AiHelpService.chat()` línea 1134. La función ya existe en `ai-chat.service.ts:29-31`. |
| **Verificación** | Test unitario: payload de prompt injection retorna output sanitizado |

---

### SEC-013 — Abuso de FCM quota via test-push sin rate limit

| Campo | Detalle |
|-------|---------|
| **OWASP** | API4: Unrestricted Resource Consumption |
| **Archivo** | `apps/api/src/modules/notifications/notifications.controller.ts:26-38` |
| **Problema** | `POST /notifications/test-push` no tiene rate limit. Un atacante puede disparar llamadas FCM ilimitadas, agotando la cuota diaria gratuita o generando costos excesivos. |
| **Solución** | Agregar `@Throttle({ default: { limit: 5, ttl: 60000 } })` a test-push |
| **Verificación** | Test de integración: 6º intento retorna 429 |

---

### SEC-014 — Device token sin verificación de posesión

| Campo | Detalle |
|-------|---------|
| **OWASP** | API2: Broken Authentication |
| **Archivo** | `apps/api/src/modules/notifications/notifications.service.ts:104-106` |
| **Problema** | El registro de device tokens busca por token value sin verificar pertenencia. Cualquier usuario autenticado puede registrar cualquier token FCM. Si un atacante conoce el token de otro usuario (ej. por leak en logs), puede secuestrar sus notificaciones. El diseño find-then-update no es atómico — dos registros concurrentes con el mismo token pueden producir estado inconsistente. |
| **Solución** | Requerir prueba de posesión: que el token sea generado desde el mismo dispositivo en el mismo request. Alternativamente, usar UPSERT atómico en PostgreSQL en vez de find-then-update. |
| **Verificación** | Test de integración: registrar token de otro usuario debe fallar |

---

### SEC-015 — `MfaVerifiedGuard` pasa silenciosamente con usuario undefined

| Campo | Detalle |
|-------|---------|
| **OWASP** | A01: Broken Access Control |
| **Archivo** | `apps/api/src/common/guards/mfa-verified.guard.ts:38` |
| **Problema** | `if (!user) return true;` — retorna `true` (pasa) en vez de lanzar una excepción. Si el orden de los guards cambia o una ruta pasa sin JwtAuthGuard, requests sin autenticar atraviesan el MFA guard. |
| **Solución** | `if (!user) throw new UnauthorizedException('Authentication required');` |
| **Verificación** | Test unitario: request sin user lanza 401 |

---

## BAJO (13)

---

### SEC-016 — Logout decodifica refresh token sin verificar firma

| Campo | Detalle |
|-------|---------|
| **OWASP** | A07: Fallas de Autenticación |
| **Archivo** | `apps/api/src/modules/auth/auth.service.ts:202,482-488` (decodeRefreshToken) |
| **Problema** | Usa `jwtService.decode()` que retorna el payload sin verificar la firma. Una cookie manipulada puede inyectar un `refreshTokenId` arbitrario en las operaciones de Redis. |
| **Solución** | Usar `jwtService.verifyAsync(token, { secret: refreshSecret })` en vez de `decode()` |
| **Verificación** | Test unitario: cookie manipulada retorna 401, no fallo silencioso |

---

### SEC-017 — AcceptInvite regex sin constraint de longitud

| Campo | Detalle |
|-------|---------|
| **OWASP** | A05: Security Misconfiguration |
| **Archivo** | `apps/api/src/modules/auth/dto/accept-invite.dto.ts:14-15` |
| **Problema** | La regex `@Matches()` no incluye el cuantificador `{12,128}` que `RegisterDto` sí tiene. Contraseñas de más de 128 caracteres son aceptadas por el flujo de invitación mientras son rechazadas en registro. |
| **Solución** | Sincronizar regex con `RegisterDto`: agregar `[A-Za-z\d@$!%*?&_\\-#^]{12,128}$` |
| **Verificación** | Test unitario: contraseña de 129 caracteres retorna 400 |

---

### SEC-018 — propertyIds en interface nunca poblado

| Campo | Detalle |
|-------|---------|
| **Archivo** | `apps/api/src/modules/auth/strategies/jwt.strategy.ts:16`, `auth.service.ts:376-383` |
| **Problema** | `JwtPayload.propertyIds` está declarado en la interfaz pero nunca se setea en `generateTokenPair()`. Cualquier código que lea `user.propertyIds` recibe `undefined`. Sin impacto en runtime porque `AccessControlService` lee de DB. |
| **Solución** | Poblar `propertyIds` en `generateTokenPair()` o removerlo de la interfaz |

---

### SEC-019 — Crypto deriveKey con nombre de parámetro engañoso

| Campo | Detalle |
|-------|---------|
| **Archivo** | `apps/api/src/common/services/crypto.service.ts:31`, `users.service.ts:359` |
| **Problema** | `deriveKey(tenantId: string)` es llamado con `userId` desde `users.service.ts`. El string HKDF info es `vaulted-fle:${userId}` pero el parámetro se llama `tenantId`. La derivación por usuario es más segura que por tenant, pero el nombre es engañoso. |
| **Solución** | Renombrar parámetro a `entityId` o agregar comentario aclaratorio |

---

### SEC-020 — WebSocket gateways usan JWT crudo para blacklist check

| Campo | Detalle |
|-------|---------|
| **OWASP** | A04: Cryptographic Failures |
| **Archivo** | `apps/api/src/modules/presence/presence.gateway.ts:61`, `orchestrator.gateway.ts:70` |
| **Problema** | Mismo problema que SEC-010: se usa el JWT completo como key de Redis para verificar blacklist. |
| **Solución** | Aplicar hash SHA-256 al JWT antes del lookup en ambos gateways |

---

### SEC-021 — Media JWT deshabilita claim `iat`

| Campo | Detalle |
|-------|---------|
| **OWASP** | A04: Cryptographic Failures |
| **Archivo** | `apps/api/src/modules/media/media.service.ts:103-105` |
| **Problema** | `sign()` es llamado con `{ noTimestamp: true }`. El claim `iat` no se incluye. Si `MEDIA_JWT_SECRET` se rota, los tokens antiguos no pueden distinguirse por ventana de emisión. |
| **Solución** | Remover `noTimestamp: true` y agregar `iat` explícito: `iat: Math.floor(Date.now() / 1000)` |
| **Verificación** | Test unitario: token decodificado tiene `iat` válido |

---

### SEC-022 — Notifications: `clear-read` sin audit log

| Campo | Detalle |
|-------|---------|
| **OWASP** | A09: Fallas de Logging y Monitoreo |
| **Archivo** | `apps/api/src/modules/notifications/notifications.service.ts:489-504` |
| **Problema** | DELETE en `notification_logs` sin llamada a `AuditService.log()`. |
| **Solución** | Agregar `auditService.log()` en el método `clearReadNotifications()` |

---

### SEC-023 — Notifications: `mark-read` y `mark-all-read` sin audit log

| Campo | Detalle |
|-------|---------|
| **OWASP** | A09: Fallas de Logging y Monitoreo |
| **Archivo** | `apps/api/src/modules/notifications/notifications.service.ts:436-463` |
| **Problema** | UPDATEs de estado de lectura sin audit logging. |
| **Solución** | Agregar `auditService.log()` en ambos métodos |

---

### SEC-024 — `filterUsersByPushPreference` sin filtro tenantId

| Campo | Detalle |
|-------|---------|
| **OWASP** | A01: Broken Access Control (defensa en profundidad) |
| **Archivo** | `apps/api/src/modules/notifications/notifications.service.ts:533-545` |
| **Problema** | Consulta preferences por userId solo (sin `tenantId`). Si los userIds no son únicos globalmente (secuencias separadas por tenant en PostgreSQL), podría traer preferencias del tenant equivocado. |
| **Solución** | Agregar `AND tenantId = :tenantId` a la query |

---

### SEC-025 — `loadPreferencesMap` sin filtro tenantId

| Campo | Detalle |
|-------|---------|
| **Archivo** | `apps/api/src/modules/notifications/notifications.service.ts:547-559` |
| **Problema** | Mismo riesgo que SEC-024. |
| **Solución** | Agregar filtro `tenantId` |

---

### SEC-026 — `updatePreferences` re-fetch sin tenantId

| Campo | Detalle |
|-------|---------|
| **Archivo** | `apps/api/src/modules/notifications/notifications.service.ts:406` |
| **Problema** | Re-lectura de preference actualizada por id solo (sin `tenantId`). Baja explotabilidad por UUIDs no adivinables, pero viola defensa en profundidad. |
| **Solución** | Agregar `AND tenantId = :tenantId` |

---

### SEC-027 — `sendPush` es método público sin verificación de permisos

| Campo | Detalle |
|-------|---------|
| **Archivo** | `apps/api/src/modules/notifications/notifications.service.ts:154` |
| **Problema** | Cualquier servicio interno con referencia a `NotificationsService` puede enviar push a cualquier userId en cualquier tenantId sin verificación de permisos. |
| **Solución** | Agregar verificación de que `tenantId` del caller coincida con los tokens destino |

---

## Quick Wins (implementar en 24-48 horas)

| Prioridad | Hallazgo | Cambio | Esfuerzo |
|-----------|----------|--------|----------|
| 1 | SEC-004 | Agregar `@Roles()` a NotificationsController (10 endpoints) | 30 min |
| 2 | SEC-012 | Sanitizar output de AI Help: 1 línea en `ai-help.service.ts:1134` | 5 min |
| 3 | SEC-005 | Audit logs en Orchestrator (11 endpoints) | 1 hora |
| 4 | SEC-005 | Audit logs en Insurance (5 endpoints) | 30 min |
| 5 | SEC-005 | Audit logs en Maintenance (3 endpoints) | 30 min |
| 6 | SEC-011 | Rate limiting en logout (2 decoradores) | 10 min |
| 7 | SEC-007 | JWT algorithm whitelist (2 archivos) | 15 min |
| 8 | SEC-015 | MfaVerifiedGuard fix: throw en vez de return true | 5 min |
| 9 | SEC-006 | LoginDTO: agregar @MinLength/@MaxLength | 5 min |
| 10 | SEC-017 | AcceptInvite regex: sincronizar con RegisterDto | 5 min |

---

## Hardening Backlog (1-3 sprints)

| # | Área | Cambio | Esfuerzo |
|---|------|--------|----------|
| 1 | Auth | Bloqueo de cuenta con backoff exponencial (SEC-001) | 2 días |
| 2 | Auth | Login en tiempo constante (SEC-002) | 1 día |
| 3 | Auth | Invalidar sesiones al cambiar rol (SEC-003) | 1 día |
| 4 | Auth | Hash de tokens como keys Redis (SEC-010) | 1 día |
| 5 | Auth | Invalidad sesiones en MFA setup (SEC-008) | 0.5 día |
| 6 | Auth | Reducir TOTP window a 1 (SEC-009) | 0.5 día |
| 7 | Auth | Refresh decode con verify (SEC-016) | 0.5 día |
| 8 | Auth/Redis | Hash JWT en WebSocket gateways (SEC-020) | 0.5 día |
| 9 | Auth | Media JWT con iat habilitado (SEC-021) | 0.5 día |
| 10 | Notifications | Rate limiting + proof-of-possession en device tokens (SEC-013, SEC-014) | 2 días |
| 11 | Notifications | Audit logs en mark-read/mark-all-read/clear-read (SEC-022, SEC-023) | 0.5 día |
| 12 | Notifications | tenantId filters en query helpers (SEC-024, SEC-025, SEC-026) | 0.5 día |
| 13 | Notifications | Control de acceso en sendPush (SEC-027) | 0.5 día |
| 14 | Auth | propertyIds en JWT: poblar o remover (SEC-018) | 0.5 día |

---

## Observaciones Positivas

1. **Protección anti-replay en MFA**: Redis `SET NX` con TTL de 180s en códigos TOTP — más fuerte que la mayoría de implementaciones.

2. **Rotación de refresh tokens**: Script Lua atómico previene race conditions. La detección de replay escala a invalidación completa de sesión. Mejor práctica de la industria.

3. **Aislamiento multi-tenant**: `TenantInterceptor` estampa `request.tenantId` desde JWT. Queries MongoDB usan `withTenant()`. Queries PostgreSQL filtran por `tenantId`. Nunca se confía en tenantId provisto por el cliente.

4. **Validación de entrada**: `ValidationPipe` global con `whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`. Rechaza campos desconocidos en todos los endpoints.

5. **Validación de uploads por magic bytes**: El tipo MIME se detecta del buffer real del archivo (magic bytes), no del header `Content-Type` del cliente. Prevención de path traversal con `assertSafeTenantKey()` que verifica separadores, null bytes, y `..` en cada segmento.

6. **Encriptación a nivel de campo**: AES-256-GCM con derivación de clave HKDF-SHA-256 por tenant para campos sensibles (valuation, serial number). Secretos MFA encriptados con claves derivadas por usuario. Cifrado autenticado previene manipulación.

7. **Política de contraseñas**: 12-128 caracteres con mayúscula, minúscula, dígito y especial. Bcrypt rounds=12.

8. **Pipeline de guards**: `app.module.ts` tiene orden documentado: Throttler → JWT → MFA → Roles → GuestExp. Las capas están en orden correcto.

9. **Manejo de errores uniforme**: Login retorna "Invalid credentials" para todos los modos de fallo (usuario no existe, inactivo, contraseña incorrecta) — previene enumeración por mensaje de error.

10. **Registro atómico**: Creación de tenant + user en una sola transacción DB previene registros huérfanos.

11. **Mensajes de error consistentes**: El `NotFoundException` no revela si el recurso existe o no — previene enumeración de IDs.

---

## Metodología

Esta auditoría fue realizada siguiendo el skill `backend-security-auditor` con el siguiente proceso:

1. **Mapeo de superficie de ataque**: enumeración de todos los controladores (19), endpoints (118), guards, decoradores, DTOs, y módulos.
2. **Trazado de flujos de datos**: autenticación → autorización → acceso a DB → respuesta.
3. **Verificación de controles**: authN, authZ, inyección, SSRF, criptografía, secretos, logging, rate limiting, y seguridad de LLM.
4. **Reporte estructurado**: cada hallazgo con ID, severidad, mapeo OWASP, ubicación, descripción, escenario de explotación, impacto, solución, y verificación.

**Archivos de referencia utilizados**:
- `references/owasp-2025.md` — OWASP Top 10:2025 + API Top 10:2023
- `references/auth-and-crypto.md` — JWT, MFA, secretos
- `references/fix-patterns.md` — patrones de fix por tecnología (Node.js/NestJS)
- `references/tech-specific.md` — riesgos específicos de Node.js/NestJS/MongoDB/PostgreSQL
- `references/api-protocols.md` — REST, WebSocket
- `references/ai-security.md` — seguridad de integraciones LLM (Gemini)
