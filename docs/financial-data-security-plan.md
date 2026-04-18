# Plan de Seguridad — Datos Financieros y Patrimoniales
**Vaulted · Fecha: 2026-04-18 · Versión: 1.0**

---

## Contexto y Amenaza

Vaulted almacena el inventario completo de familias ultra-HNW: qué poseen, dónde está físicamente,
cuánto vale cada pieza, y fotos de todo. Un breach no es solo un problema de privacidad — es un
vector de riesgo físico real: robo planificado, extorsión, o secuestro basado en información de
riqueza y ubicación.

### Activos en riesgo

| Dato | Sensibilidad | Impacto de exposición |
|---|---|---|
| `valuation.currentValue` por ítem | Muy alta | Mapa de valor por habitación |
| `totalValuation` aggregado | Crítica | Patrimonio total de la familia |
| Fotos de facturas y documentos | Alta | Precios de compra exactos |
| `propertyId` + valuaciones | Crítica | Riqueza + ubicación física combinadas |
| Pólizas de seguro con coberturas | Alta | Confirma existencia y valor de activos |

### Estado actual del código

| Aspecto | Estado |
|---|---|
| Valuaciones en MongoDB | **Plaintext** — sin cifrado a nivel de campo |
| Stripping por rol en inventario | ✅ Implementado (`findAll`, `findById`, `search`) |
| Filtrado por propiedad en dashboard | ❌ MANAGER ve totales de todas las propiedades |
| Auditoría de escritura | ✅ PostgreSQL inmutable |
| **Auditoría de lectura financiera** | ❌ No se registra quién consulta valuaciones |
| Valuaciones en módulo insurance | ❌ Expuestas al rol AUDITOR sin redacción |
| Redis cache con `totalValuation` | ❌ Agregado financiero cacheado en claro |
| `CryptoService` AES-256-GCM | ✅ Existe pero solo usado para MFA secrets |

---

## Fases del Plan

---

### Fase 1 — Protección Estructural (Antes del primer cliente pagador)

**Objetivo:** Cerrar los gaps que exponen datos financieros hoy, sin refactors grandes.
**Duración estimada:** 1–2 semanas

---

#### 1.1 Field-Level Encryption en MongoDB para valuaciones

**Agente: Claude Code**
_(Decisión de arquitectura + seguridad — no delegar a Cursor/Codex)_

**Qué hacer:**
Extender el `CryptoService` existente para encriptar/desencriptar campos de valuación en el
`InventoryService`. La clave de cifrado debe ser **derivada por tenant** usando el `tenantId`
como contexto, nunca una clave global.

**Archivos afectados:**
```
apps/api/src/common/services/crypto.service.ts        ← agregar deriveKey(tenantId)
apps/api/src/modules/inventory/inventory.service.ts   ← encriptar antes de save, desencriptar en read
apps/api/src/modules/inventory/schemas/item.schema.ts ← documentar campos cifrados
```

**Campos a cifrar:**
```typescript
valuation.purchasePrice
valuation.currentValue
valuation.lastAppraisalDate
```

**Criterio de aceptación:**
- Los valores en MongoDB deben aparecer como `"iv:authTag:ciphertext"` en consulta directa
- Los endpoints de inventory devuelven números normales para OWNER/MANAGER
- Un dump directo de MongoDB no revela valores monetarios

**Riesgo de no hacerlo:** Un dump de MongoDB Atlas (misconfigured, breach interno, o compromiso de
credenciales) expone patrimonio completo de todos los tenants en plaintext.

---

#### 1.2 Audit logging de lecturas financieras

**Agente: Claude Code**
_(Decisión de qué constituye un evento auditable — requiere criterio de seguridad)_

**Qué hacer:**
Registrar en `audit_logs` cuando se accede a datos de valuación, no solo cuando se modifican.
Los valores no se loguean directamente — solo rangos o hashes.

**Archivos afectados:**
```
apps/api/src/modules/inventory/inventory.service.ts   ← log en findById cuando incluye valuation
apps/api/src/modules/dashboard/dashboard.service.ts   ← log en getStats
apps/api/src/modules/insurance/insurance.service.ts   ← log en getCoverageGaps
```

**Nuevos action types a agregar:**
```typescript
'dashboard.valuation.view'      // { tenantId, range: '$X–$Y' }  — nunca el total exacto
'item.valuation.view'           // { itemId, category }
'insurance.coverage_gaps.view'  // { tenantId, itemCount }
```

**Criterio de aceptación:**
- El OWNER puede ver en la app un log de "quién accedió a datos financieros y cuándo"
- Los valores exactos nunca aparecen en los logs — solo rangos/categorías

---

#### 1.3 Stripping de valuaciones para AUDITOR en módulo insurance

**Agente: Cursor**
_(Cambio mecánico: aplicar el mismo patrón que ya existe en inventory)_

**Qué hacer:**
Aplicar `accessControl.stripValuation()` en `getCoverageGaps()` cuando el rol es AUDITOR.
El gap de cobertura puede calcularse sin exponer el `currentValue` exacto — mostrar
`coveredPercentage` y `coverageStatus` en lugar del monto bruto.

**Archivos afectados:**
```
apps/api/src/modules/insurance/insurance.service.ts   ← redactar currentValue para AUDITOR
apps/api/src/modules/insurance/insurance.controller.ts ← verificar que AUDITOR solo llega a endpoints read
```

**Criterio de aceptación:**
- AUDITOR recibe `{ coverageStatus: 'underinsured', gap: 'high' }` en lugar de `{ currentValue: 285000, coveredValue: 100000 }`

---

#### 1.4 Filtrado por propiedad en dashboard de MANAGER

**Agente: Cursor**
_(Cambio de query en pipeline MongoDB existente)_

**Qué hacer:**
El pipeline de `$group` en `dashboard.service.ts` debe recibir el array `propertyIds` del usuario
y filtrar con `$match` antes de agregar. Un MANAGER con acceso solo a la casa de Miami no debe
ver el total consolidado de las 4 propiedades del tenant.

**Archivos afectados:**
```
apps/api/src/modules/dashboard/dashboard.service.ts   ← agregar $match por propertyIds si rol != OWNER
apps/api/src/modules/dashboard/dashboard.controller.ts ← pasar user.propertyIds al service
```

**Criterio de aceptación:**
- MANAGER con `propertyIds: ['prop_miami']` recibe solo métricas de esa propiedad
- OWNER sigue recibiendo totales consolidados de todas las propiedades

---

### Fase 2 — Defensa en Profundidad (Primeros 3 meses post-launch)

**Objetivo:** Reducir la superficie de extracción masiva y añadir trazabilidad avanzada.
**Duración estimada:** 3–4 semanas (puede implementarse en sprints paralelos)

---

#### 2.1 Rate limiting específico en endpoints de valuación

**Agente: Cursor**
_(Configuración de throttler sobre guardas ya existentes)_

**Qué hacer:**
Aplicar límites más restrictivos a endpoints que devuelven datos financieros versus endpoints
de inventario general. Implementar detección de extracción sistemática.

**Archivos afectados:**
```
apps/api/src/modules/inventory/inventory.controller.ts  ← @Throttle() decorators específicos
apps/api/src/modules/dashboard/dashboard.controller.ts  ← límite más bajo en getStats
apps/api/src/common/guards/                             ← guard de anomalía: >50 req/min a valuación
```

**Parámetros sugeridos:**
```typescript
// Endpoints generales: 100 req / 15min
// Endpoints con valuación: 20 req / 15min
// Dashboard: 10 req / 5min
// Alerta automática: >3x el límite normal en 1 hora → log de seguridad + notificación al Owner
```

**Criterio de aceptación:**
- Un token comprometido que hace scraping sistematico es bloqueado y genera alerta antes de extraer >100 ítems con valuación

---

#### 2.2 Tokenización de URLs de media (facturas y documentos)

**Agente: Cursor**
_(Generación de tokens firmados — patrón estándar)_

**Qué hacer:**
Las URLs de documentos sensibles (facturas, pólizas, appraisals) deben ser tokens firmados con
expiración, no paths predecibles. Un atacante con acceso a una URL no debe poder derivar otras.

**Archivos afectados:**
```
apps/api/src/modules/media/media.service.ts     ← generar signed URL con TTL configurable
apps/api/src/modules/media/media.controller.ts  ← endpoint GET /media/:token (valida + redirige)
apps/api/src/modules/inventory/inventory.service.ts ← usar signed URLs en photos y documents
```

**Implementación:**
```typescript
// Token = JWT firmado con { fileId, tenantId, userId, exp: +15min }
// Nunca exponer paths directos como /uploads/tenant_123/item_456/factura.pdf
```

**Criterio de aceptación:**
- Las URLs de documentos en la respuesta de la API expiran en 15 minutos
- Una URL de factura de Tenant A no funciona para un usuario de Tenant B
- El path real en el filesystem nunca se expone en la API

---

#### 2.3 Rangos de valuación para rol MANAGER en UI Flutter

**Agente: Cursor**
_(Transformación de display — no afecta lógica de negocio)_

**Qué hacer:**
En la app móvil, los usuarios con rol MANAGER ven rangos en lugar de valores exactos
para ítems de alta valuación. El backend devuelve el valor exacto pero la capa de presentación
lo transforma.

**Archivos afectados:**
```
apps/mobile/lib/features/inventory/presentation/item_detail_screen.dart
apps/mobile/lib/features/inventory/data/models/item_model.dart
apps/mobile/lib/core/utils/valuation_formatter.dart   ← nuevo utility
```

**Lógica de rangos:**
```dart
// < $10K    → mostrar exacto
// $10K–$100K → redondear a múltiplos de $5K
// > $100K   → mostrar rango ±10%  (ej: "$270K–$300K")
// > $1M     → mostrar rango ±5%
// Para OWNER: siempre exacto
```

**Criterio de aceptación:**
- MANAGER ve `$270,000 – $300,000` en lugar de `$285,000`
- La suma del dashboard para MANAGER usa los valores exactos para el cálculo, pero muestra el total redondeado

---

#### 2.4 Privacy Screen en Flutter (toggle de valores)

**Agente: Flutter Implementer (Claude)**
_(UX + integración con secure storage — requiere criterio de diseño)_

**Qué hacer:**
Botón global en la navegación que oculta todos los valores monetarios de la UI (reemplaza con `●●●●●`).
El estado se persiste en `flutter_secure_storage` y sobrevive navegación pero no sesión.

**Archivos afectados:**
```
apps/mobile/lib/core/providers/privacy_screen_provider.dart   ← nuevo Riverpod provider
apps/mobile/lib/shared/widgets/valuation_text.dart            ← nuevo widget que respeta el toggle
apps/mobile/lib/shared/widgets/app_bottom_nav.dart            ← icono de ojo en nav bar
apps/mobile/lib/features/inventory/presentation/             ← reemplazar Text(valuation) con ValuationText()
apps/mobile/lib/features/dashboard/presentation/             ← ocultar KPIs de valor total
```

**Criterio de aceptación:**
- Un tap en el icono de ojo oculta todos los valores monetarios en toda la app
- El modo privado activo se indica visualmente (icono cambia a ojo tachado)
- Las capturas de pantalla tomadas en modo privado no revelan valores

---

### Fase 3 — Arquitectura Zero-Knowledge (Pre-escala: 50+ clientes)

**Objetivo:** Que el patrimonio total nunca exista como dato en el servidor.
**Duración estimada:** 4–6 semanas
**Prerequisito:** Completar Fases 1 y 2

---

#### 3.1 Cálculo de patrimonio total en el cliente

**Agente: Claude Code**
_(Decisión de arquitectura — desplaza agregación financiera al cliente)_

**Qué hacer:**
Eliminar el campo `totalValuation` del endpoint de dashboard. El total consolidado se calcula
en Flutter sumando los ítems ya descifrados localmente. El backend nunca recibe ni devuelve
un "patrimonio total".

**Backend — archivos afectados:**
```
apps/api/src/modules/dashboard/dashboard.service.ts   ← remover $sum de currentValue del pipeline
apps/api/src/modules/dashboard/dto/dashboard-stats.dto.ts ← remover totalValuation
```

**Flutter — archivos afectados:**
```
apps/mobile/lib/features/dashboard/domain/dashboard_notifier.dart  ← calcular total localmente
apps/mobile/lib/features/dashboard/presentation/dashboard_screen.dart ← usar valor local
```

**Criterio de aceptación:**
- Una búsqueda en Redis/MongoDB/logs no puede reconstruir el patrimonio total de ningún tenant
- El total en la app coincide con la suma manual de ítems
- Los tests de regresión del dashboard pasan con la nueva implementación

---

#### 3.2 Claves de cifrado por tenant con rotación

**Agente: Claude Code**
_(Diseño de key management — no delegar a Cursor/Codex)_

**Qué hacer:**
Evolucionar el sistema de cifrado de la Fase 1. Cada tenant tiene su propia `dataKey` almacenada
en un secrets manager separado (Vault o GCP Secret Manager). La `masterKey` en env solo descifra
las `dataKeys` — nunca cifra datos directamente.

**Nueva arquitectura:**
```
GCP Secret Manager
  └── master_encryption_key (rotada cada 90 días)
        └── tenant_{id}_data_key (única por tenant, cifrada con master)
              └── item.valuation.* (cifrado con data key del tenant)
```

**Archivos afectados:**
```
apps/api/src/common/services/crypto.service.ts      ← envelope encryption
apps/api/src/common/services/key-manager.service.ts ← nuevo: gestión de data keys
apps/api/src/modules/auth/                          ← provisionar data key en creación de tenant
```

**Criterio de aceptación:**
- Comprometer la `masterKey` no expone datos sin las `dataKeys` individuales
- Comprometer la DB no expone datos sin acceso al secrets manager
- La rotación de `masterKey` re-cifra las `dataKeys` sin tocar los datos de items

---

#### 3.3 Geofencing de acceso a datos financieros

**Agente: Claude Code**
_(Lógica de seguridad + auth — no delegar)_

**Qué hacer:**
Permitir al OWNER configurar que valuaciones y documentos sensibles solo sean accesibles desde
países/IPs específicos. Un token JWT válido desde una IP inesperada requiere re-autenticación
para acceder a datos de valuación.

**Archivos afectados:**
```
apps/api/src/common/guards/geo-restriction.guard.ts   ← nuevo guard
apps/api/src/modules/tenants/schemas/tenant.schema.ts ← agregar allowedCountries: string[]
apps/api/src/modules/inventory/inventory.controller.ts ← @UseGuards(GeoRestrictionGuard) en endpoints de valuación
apps/mobile/lib/features/settings/                    ← UI para configurar países permitidos
```

**Criterio de aceptación:**
- OWNER puede definir lista blanca de países (ej: `['US', 'MX', 'ES']`)
- Acceso desde país no autorizado devuelve `403` con mensaje claro
- El OWNER recibe notificación push cuando un acceso fue bloqueado por geofencing

---

### Fase 4 — Certificación y Confianza (Post-Product-Market-Fit)

**Objetivo:** Convertir la seguridad en argumento de venta y barrera competitiva.
**Duración estimada:** 3–6 meses (proceso externo)

---

#### 4.1 SOC 2 Type II

**Agente: Humano (proceso de auditoría externa)**

Contratar un auditor certificado. Las Fases 1–3 deben estar completas y documentadas.
Los controles técnicos requeridos ya estarán implementados; el auditor verifica proceso y evidencia.

**Preparación técnica:**
- Exportar audit logs de PostgreSQL en formato requerido por el auditor
- Documentar el modelo de acceso RBAC y la política de rotación de tokens
- Evidencia de pen tests periódicos (ver 4.2)

**Valor:** Para clientes HNW con family offices o asesores de patrimonio, SOC 2 Type II es
frecuentemente un **requisito contractual no negociable**.

---

#### 4.2 Penetration Testing periódico

**Agente: Tercero especializado**

Contratar pen test externo antes del primer cliente pagador y cada 12 meses después.
Scope mínimo: endpoints de autenticación, endpoints de valuación, pipeline de media uploads,
acceso cross-tenant.

---

#### 4.3 UX de Transparencia para el cliente

**Agente: Flutter Implementer (Claude)**

Implementar en la app el "Centro de Privacidad" visible para el OWNER:

- Log de accesos recientes: "Manager García accedió a inventario de Miami el 15 Apr a las 14:32"
- Estado del cifrado: "Sus datos están cifrados con AES-256-GCM. Clave única para su cuenta."
- Sesiones activas: listado de dispositivos con opción de revocar
- Exportar mis datos: descarga ZIP con todo el inventario (CCPA compliance)
- Eliminar mi cuenta: borrado completo con confirmación en dos pasos

**Archivos afectados:**
```
apps/mobile/lib/features/settings/presentation/privacy_center_screen.dart  ← nueva pantalla
apps/api/src/modules/audit/audit.controller.ts                              ← endpoint GET /audit/my-activity
apps/api/src/modules/auth/                                                  ← GET /auth/sessions + DELETE /auth/sessions/:id
```

---

## Resumen de Fases y Agentes

| Fase | Tarea | Agente | Prioridad | Esfuerzo |
|---|---|---|---|---|
| **1.1** | Field-level encryption valuaciones | **Claude Code** | Crítica | 3–4 días |
| **1.2** | Audit logging de lecturas financieras | **Claude Code** | Crítica | 1–2 días |
| **1.3** | Stripping valuaciones AUDITOR en insurance | **Cursor** | Crítica | 0.5 días |
| **1.4** | Filtrado por propiedad en dashboard MANAGER | **Cursor** | Crítica | 1 día |
| **2.1** | Rate limiting en endpoints de valuación | **Cursor** | Alta | 1 día |
| **2.2** | Tokenización de URLs de media | **Cursor** | Alta | 2–3 días |
| **2.3** | Rangos de valuación para MANAGER en UI | **Cursor** | Media | 1–2 días |
| **2.4** | Privacy Screen toggle en Flutter | **Claude Code** | Media | 2 días |
| **3.1** | Patrimonio total calculado en cliente | **Claude Code** | Media | 2–3 días |
| **3.2** | Envelope encryption por tenant | **Claude Code** | Alta | 4–5 días |
| **3.3** | Geofencing de acceso financiero | **Claude Code** | Media | 2–3 días |
| **4.1** | SOC 2 Type II | Auditor externo | Alta | 3–6 meses |
| **4.2** | Pen testing periódico | Tercero | Alta | 1–2 semanas |
| **4.3** | Privacy Center UX | **Claude Code** | Media | 3–4 días |

---

## Regla de asignación de agentes

```
Claude Code  → auth/seguridad, diseño de claves, decisiones cross-módulo, RBAC
Cursor       → cambios mecánicos, aplicar patrones existentes, configuración de guards
Codex        → scaffolding de DTOs, tests unitarios de los cambios anteriores
Humano       → procesos de certificación, contratos con auditores, pen testers
```

> **Regla del CLAUDE.md:** "Nunca delegar a Cursor/Codex: auth/security logic, DB schema design,
> RBAC, cross-module decisions."

---

## Mensaje para clientes (propuesta de copy)

> *"Vaulted cifra cada valuación individualmente con su clave única. Ni siquiera nosotros
> podemos ver cuánto vale su colección. Sus datos de patrimonio existen solo en su dispositivo
> y en forma cifrada en nuestros servidores — diseñado para que un breach técnico nunca
> se convierta en un riesgo para su familia."*

---

*Documento generado: 2026-04-18 · Próxima revisión recomendada: antes del primer cliente pagador*
