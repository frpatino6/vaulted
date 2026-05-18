---
name: nestjs-swagger
description: Document NestJS API endpoints and DTOs with OpenAPI (@nestjs/swagger). Use when adding or modifying routes in apps/api, controllers, request/response DTOs, or when the user asks for Swagger/OpenAPI/api-docs documentation.
---

# NestJS Swagger — Vaulted API

OpenAPI is served at **`/api-docs`** (global API prefix: `/api`). Follow existing modules: `auth.controller.ts`, `inventory.controller.ts`, `insurance.controller.ts`.

## When to apply

Apply this skill whenever you **create or change**:

- `apps/api/src/modules/**/*.controller.ts`
- `apps/api/src/modules/**/dto/*.dto.ts` used as `@Body()`, `@Query()`, or composite request types

Do **not** skip Swagger because the task was "small" — undocumented endpoints break `/api-docs` consistency.

---

## Controller checklist

1. **Class level**
   - `@ApiTags('ModuleName')` — PascalCase, matches feature (e.g. `Insurance`, `Wardrobe`, `AI Chat`).
   - Import from `@nestjs/swagger`.

2. **Every route handler**
   - `@ApiOperation({ summary: '...' })` — short imperative phrase.
   - `@ApiBearerAuth()` — on all JWT-protected routes (default in Vaulted).
   - `@ApiResponse({ status: <code>, description: '...' })` — at least success; add 401/403/404 when relevant.
   - `@Public()` routes: **no** `@ApiBearerAuth()`; still document `@ApiResponse`.

3. **Query / params**
   - `@ApiQuery({ name: '...', required: false })` for each optional query param.
   - Path params are usually inferred; document 404 in `@ApiResponse` if applicable.

4. **Multipart**
   - `@ApiConsumes('multipart/form-data')` on upload endpoints (see `media.controller.ts`).

5. **HTTP status codes**
   - `POST` create → `201` in `@ApiResponse`.
   - `DELETE` that returns no body → `@HttpCode(HttpStatus.NO_CONTENT)` + `@ApiResponse({ status: 204, ... })`.
   - Do not document `200` for DELETE when the handler uses 204.

---

## DTO checklist

1. Import `ApiProperty`, `ApiPropertyOptional` from `@nestjs/swagger`.

2. **Required fields** → `@ApiProperty({ description, example, ... })` **above** class-validator decorators.

3. **Optional fields** → `@ApiPropertyOptional({ description, example, required: false })`.

4. **Enums** — use `enum: MyEnum` or string array matching `@IsEnum()`:
   ```typescript
   @ApiProperty({ enum: ItemStatus, example: ItemStatus.ACTIVE })
   @IsEnum(ItemStatus)
   status!: ItemStatus;
   ```

5. **Arrays** — `type: [String]` or `isArray: true` as needed; include `example: ['...']`.

6. **Nested DTOs** — `@ApiProperty({ type: () => ChildDto })` + `@ValidateNested()` + `@Type(() => ChildDto)`.

7. **Update DTOs** — extend via Swagger `PartialType`, not mapped-types:
   ```typescript
   import { PartialType } from '@nestjs/swagger';
   export class UpdateItemDto extends PartialType(CreateItemDto) {}
   ```

8. **MongoDB IDs** — `example: '64f1b2c3d4e5f6789012abcd'` (24-char hex).

---

## Reference patterns

### Protected POST

```typescript
@Roles(Role.OWNER, Role.MANAGER)
@Post()
@ApiOperation({ summary: 'Create insurance policy' })
@ApiBearerAuth()
@ApiResponse({ status: 201, description: 'Policy created' })
createPolicy(@CurrentUser() user: JwtPayload, @Body() dto: CreatePolicyDto) {
  return this.insuranceService.createPolicy(user.tenantId, user.sub, dto);
}
```

### DELETE (no body)

```typescript
@Delete(':id')
@HttpCode(HttpStatus.NO_CONTENT)
@ApiOperation({ summary: 'Delete policy' })
@ApiBearerAuth()
@ApiResponse({ status: 204, description: 'Policy deleted' })
deletePolicy(@CurrentUser() user: JwtPayload, @Param('id') policyId: string) {
  return this.insuranceService.deletePolicy(user.tenantId, user.sub, policyId);
}
```

### Request DTO field

```typescript
@ApiProperty({ description: 'Policy number', example: 'POL-2025-001', maxLength: 100 })
@IsString()
@Length(1, 100)
policyNumber!: string;
```

---

## Done criteria

Before finishing an API task, verify:

- [ ] Controller has `@ApiTags` and every new/changed handler has `@ApiOperation` + `@ApiResponse` (+ `@ApiBearerAuth` if protected).
- [ ] All request DTO fields touched have `@ApiProperty` or `@ApiPropertyOptional`.
- [ ] `PartialType` imports come from `@nestjs/swagger` where used.
- [ ] `npm run build` in `apps/api` passes (no missing `@nestjs/swagger` imports).

---

## Out of scope

- Response-only types and internal service interfaces (unless exposed in Swagger explicitly).
- Flutter/mobile code — never add Swagger there.
- Do not add business logic, guards, or audit calls — only OpenAPI decorators per project conventions.
