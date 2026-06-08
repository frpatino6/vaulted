# Input Validation — Zod & Injection Prevention Guide

Guidance for validating, sanitizing, and safely handling untrusted input — covering schema validation with Zod and SQL/NoSQL injection prevention.

## Core Principles
- **Validate at the boundary**: every external input (HTTP body/query/params, file uploads, message-queue payloads, third-party API responses) must be validated before use.
- **Allowlist, don't denylist**: define what valid input looks like (type, format, length, range) rather than trying to block known-bad patterns.
- **Fail closed**: on validation failure, reject the request with a generic error — do not attempt to "fix" or partially process invalid input.
- **Validate, then trust internally**: once input passes the boundary schema, internal code should not re-validate defensively (per Vaulted convention — only validate at system boundaries).

## Schema Validation with Zod

```typescript
import { z } from 'zod';

const CreateItemSchema = z.object({
  name: z.string().trim().min(1).max(200),
  category: z.enum(['Furniture', 'Art & Collectibles', 'Electronics', 'Wardrobe']),
  purchasePrice: z.number().positive().max(100_000_000).optional(),
  tags: z.array(z.string().max(50)).max(20).optional(),
});

export function validateCreateItem(raw: unknown) {
  const result = CreateItemSchema.safeParse(raw);
  if (!result.success) {
    throw new Error('Invalid item payload');
  }
  return result.data; // typed, validated, safe to use
}
```

### Zod best practices
- Always use `.safeParse()` at boundaries and handle the `success: false` branch explicitly — avoid `.parse()` which throws and can leak internals if uncaught.
- Constrain strings with `min`/`max` length and `regex`/`email`/`url` where applicable to prevent oversized payloads (DoS) and malformed data.
- Use `.enum()` / `.union()` for closed sets of values instead of free-form strings.
- Strip unknown keys with `.strict()` (or the default behavior, depending on Zod version) to prevent mass-assignment of unexpected fields.
- Compose schemas with `.extend()`/`.merge()` to avoid duplication, and export the inferred TypeScript types with `z.infer<typeof Schema>`.

### NestJS integration (Vaulted convention)
- Vaulted uses `class-validator` DTOs as the primary validation mechanism for controllers — apply the same allowlist/length/format principles there (`@IsString()`, `@MaxLength()`, `@IsEnum()`, etc.).
- Reserve Zod for contexts outside the NestJS request pipeline (e.g., validating AI model output, third-party webhook payloads, queue job data).

## SQL / NoSQL Injection Prevention

### SQL (PostgreSQL / TypeORM)
- Always use parameterized queries or the query builder — never interpolate user input into raw SQL strings.

```typescript
// NEVER:
// `SELECT * FROM users WHERE email = '${email}'`

// ALWAYS — positional parameters:
const { rows } = await pool.query(
  'SELECT id, email, role FROM users WHERE email = $1',
  [email],
);

// TypeORM query builder:
await userRepo
  .createQueryBuilder('user')
  .where('user.email = :email', { email })
  .getOne();
```

- Avoid `query(rawSql)` / `.query()` escape hatches with string concatenation; if raw SQL is unavoidable, use the driver's parameter-binding API.

### NoSQL (MongoDB / Mongoose)
- Never pass raw user-controlled objects directly into query filters — an attacker can inject operators like `{"$ne": null}` or `{"$gt": ""}` to bypass logic (NoSQL injection).
- Validate that query-bound fields are primitives of the expected type before use:

```typescript
// Vulnerable: req.body.email could be { "$ne": null }
await User.findOne({ email: req.body.email });

// Safe: validate type first (Zod/class-validator), then query
const { email } = validateLoginInput(req.body); // ensures string
await User.findOne({ email });
```

- Use libraries like `mongo-sanitize` or schema validation to strip `$`-prefixed keys from user input before constructing queries.
- Apply Mongoose schema types and `strict: true` (default) so unexpected fields are dropped rather than persisted.

## File Upload Validation
- Validate file type by content (magic-byte sniffing), not just by extension or `Content-Type` header.
- Enforce size limits and a maximum count (Vaulted: up to 10 photos per item).
- Store uploads outside the web root or in object storage with randomized names; never trust the original filename for storage paths (path traversal).

## Quick Checklist
- [ ] Every external input validated with a schema (Zod / class-validator DTO) before use
- [ ] Schemas constrain type, length, format, and allowed values (allowlist)
- [ ] Unknown/extra fields stripped (no mass assignment)
- [ ] All SQL access parameterized or via query builder — no string-built queries
- [ ] MongoDB queries never pass raw user objects as filters — `$`-operator injection blocked
- [ ] File uploads validated by content, size-limited, stored with safe generated names

## References
- OWASP Input Validation Cheat Sheet
- OWASP SQL Injection Prevention Cheat Sheet
- OWASP NoSQL Injection guidance
- Zod documentation — https://zod.dev
