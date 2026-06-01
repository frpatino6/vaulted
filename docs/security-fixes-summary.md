# Vaulted Security Fixes Summary — Codex

Fecha: 2026-06-01
Rama: `codex/security-hardening-media-auth-mobile`

## Nota de sincronización con `main`

Se intentó ejecutar `git fetch origin main && git pull origin main` antes de aplicar cambios, pero el checkout local no tiene remote `origin` configurado. La rama de fixes se creó desde el estado local disponible (`work`, commit `94999c0`).

## Estado de vulnerabilidades reanalizadas y mitigadas

| Hallazgo | Severidad previa | Estado | Fix aplicado |
|---|---:|---|---|
| Path traversal en media local (`tenant/../../`) | Alta | Mitigado | Validación canónica de keys por tenant, rechazo de `..`, paths absolutos, backslashes, segmentos vacíos y null bytes; resolución local dentro de `uploadsRoot`. |
| Media privada expuesta por `/uploads` | Alta | Mitigado | Eliminado el montaje de Express static assets para `/uploads`; uploads locales/GCS devuelven URL firmada `/api/media/:token`. |
| Refresh token replay por rotación sin invalidación | Alta | Mitigado | Refresh token pasa a ser one-time-use: se exige membresía en sesión Redis, se blacklist/srem el JTI usado y se invalida todo ante replay. |
| MFA obligatorio no forzado para Owner/Manager sin setup | Media | Mitigado backend | Login/invite ahora devuelven `mfaRequired=true` y `mfaSetupRequired=true` para roles obligatorios sin MFA; access token queda `mfaVerified=false`. |
| Rate limit MFA verify demasiado alto | Media | Mitigado | `/auth/mfa/verify` reducido de 100/min a 5/min. |
| Flutter release podría usar HTTP/WS por default | Media | Mitigado | Release exige `API_BASE_URL` HTTPS y `WS_BASE_URL` WSS; HTTP localhost queda solo para debug. |
| PostgreSQL TLS con `rejectUnauthorized=false` | Media | Mitigado | Producción con `DATABASE_URL` usa `rejectUnauthorized: true` y soporta `POSTGRES_CA_CERT`. |
| Objetos flexibles con claves NoSQL peligrosas | Media | Mitigado parcial/enfocado | `inventory.attributes` rechaza claves `$`, `.`, `__proto__`, `constructor`, `prototype`, arrays muy grandes, strings extensos y profundidad excesiva. |
| Tokens en almacenamiento inseguro móvil | Baja/positivo | Confirmado y reforzado | Refresh token sigue en `flutter_secure_storage`; iOS ahora usa Keychain accessibility `first_unlock_this_device`. |
| Permisos móviles | Baja | Mitigado | `INTERNET` agregado al Android manifest principal; permisos sensibles existentes se mantienen justificados. |
| CORS dev/prod mezclado | Baja | Mitigado | Orígenes productivos y desarrollo separados; override por `CORS_ALLOWED_ORIGINS`. |
| Firebase web config hardcoded | Baja | Mitigado | Service worker carga `web/firebase-config.js` generado en deploy; se agregó ejemplo sin valores reales y gitignore para el runtime config. |

## Riesgo residual / seguimiento recomendado

1. **UX de MFA setup en Flutter:** el backend ya fuerza `mfaSetupRequired`, pero el flujo móvil debería mostrar QR/secret de `/auth/mfa/setup` para roles Owner/Manager sin MFA configurado.
2. **Normalización de media histórica:** si existen registros antiguos con URLs `/uploads`, se siguen normalizando, pero el acceso público directo ya no existe. Validar migración de datos si hay clientes activos.
3. **Firebase web service worker:** ya no contiene config hardcoded; despliegue debe generar `web/firebase-config.js` desde secretos/variables de CI antes de publicar.
4. **Validación de ObjectId por DTO/pipe:** Mongo queries mantienen `tenantId`; se recomienda añadir pipes de ObjectId de forma transversal en una fase posterior.

## Checks ejecutados

- `npm run build` en `apps/api` — OK.
- `npm test -- media.service.spec.ts auth.service.spec.ts inventory.service.spec.ts --runInBand` en `apps/api` — OK.
- `dart format lib/core/config/app_config.dart lib/core/storage/secure_storage.dart lib/main.dart && flutter analyze` en `apps/mobile` — no ejecutable en este contenedor: falta `dart` en PATH.
- `flutter analyze` en `apps/mobile` — no ejecutable en este contenedor: falta `flutter` en PATH.

