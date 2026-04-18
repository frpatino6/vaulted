# Prompt: Generar / actualizar unit tests para cambios recientes

Pega esto en Cursor chat cuando quieras generar o actualizar tests.

---

**Tarea:** Revisar los archivos modificados en este branch y crear o actualizar sus unit tests.

**Paso 1 — Identificar archivos modificados:**
Ejecuta `git diff main...HEAD --name-only` y filtra los archivos relevantes:
- Backend: archivos `*.service.ts` en `apps/api/src/modules/`
- Flutter: archivos `*_notifier.dart` o `*_provider.dart` en `apps/mobile/lib/`
- Ignora: controllers, DTOs, schemas, entities, modules — no tienen tests directos.

**Paso 2 — Por cada archivo de servicio/notifier modificado:**
1. Lee el archivo fuente completo.
2. Busca si ya existe un `.spec.ts` (o `_test.dart`) co-ubicado. Si existe, léelo.
3. Identifica qué métodos son nuevos o modificados comparando con `git diff main...HEAD -- <archivo>`.

**Paso 3 — Crear o actualizar el test siguiendo estas reglas:**

Para NestJS (`*.service.ts`):
- Usa `@nestjs/testing` con `Test.createTestingModule`.
- Mockea TODAS las dependencias como objetos con `jest.fn()` — sin DB real, sin Redis real.
- `beforeEach`: `jest.clearAllMocks()` → configurar mocks → compilar módulo.
- Nombre de tests: `'methodName() describe el comportamiento esperado'`
- Cubre por método: happy path · cada excepción posible · que `auditService.log` se llama en writes · que NO se llama en operaciones fallidas · aislamiento por `tenantId`.
- Para métodos con lógica de roles (OWNER/MANAGER/AUDITOR): un test por rol relevante.
- Para endpoints financieros: verifica que AUDITOR/STAFF no reciben `currentValue` en la respuesta.

Para Flutter (`*_notifier.dart`):
- Usa `ProviderContainer` con `overrides` — nunca mocks globales.
- Cubre: estado inicial · transición a `AsyncData` · transición a `AsyncError` · estado `AsyncLoading`.
- Si el widget muestra valuaciones: agrega test con `privacyModeProvider` overrideado a `true` → verifica que aparece `●●●●●`.

**Paso 4 — Restricciones:**
- No toques archivos fuera de los `.spec.ts` / `_test.dart` correspondientes.
- No modifiques los archivos fuente.
- No agregues dependencias nuevas al `package.json` o `pubspec.yaml`.
- Si un método ya tiene test y no fue modificado, no lo toques.
- Coloca el `.spec.ts` co-ubicado con el servicio (`foo.service.spec.ts` junto a `foo.service.ts`).
- Para Flutter: `apps/mobile/test/features/<feature>/` espejando `lib/features/<feature>/`.
