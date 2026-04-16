# Insurance Module — API Contract

> Branch: `feature/insurance-module`
> Last updated: 2026-04-15
> Base URL (production): `https://api-vaulted.casacam.net/api`

---

## 1. Endpoints

All paths are prefixed with `/api` (global prefix set in `main.ts`).

| Method | Full path | Roles allowed | Description |
|--------|-----------|---------------|-------------|
| `POST` | `/api/insurance/policies` | OWNER, MANAGER | Create a new insurance policy |
| `GET` | `/api/insurance/policies` | OWNER, MANAGER, AUDITOR | List all policies for tenant (optional status filter) |
| `GET` | `/api/insurance/policies/:id` | OWNER, MANAGER, AUDITOR | Get single policy with its insured items |
| `PUT` | `/api/insurance/policies/:id` | OWNER, MANAGER | Update a policy |
| `DELETE` | `/api/insurance/policies/:id` | OWNER only | Delete policy and all its insured items |
| `POST` | `/api/insurance/policies/:id/items` | OWNER, MANAGER | Attach an inventory item to a policy |
| `DELETE` | `/api/insurance/policies/:id/items/:itemId` | OWNER, MANAGER | Detach an inventory item from a policy |
| `GET` | `/api/insurance/coverage-gaps` | OWNER, MANAGER, AUDITOR | Coverage gap analysis across all items |

---

## 2. Request Payloads (DTOs)

### `POST /api/insurance/policies`

```json
{
  "provider": "string (required, 1–255 chars)",
  "policyNumber": "string (required, 1–100 chars)",
  "coverageType": "string (required, enum — see section 4)",
  "totalCoverageAmount": "number (required, positive)",
  "premium": "number (optional, >= 0)",
  "currency": "string (optional, exactly 3 chars — defaults to 'USD')",
  "startDate": "string (required, ISO 8601 date string)",
  "expiresAt": "string (required, ISO 8601 date string)",
  "notes": "string (optional, no length limit)"
}
```

### `PUT /api/insurance/policies/:id`

All fields optional. Only provided fields are updated.

```json
{
  "provider": "string (optional, 1–255 chars)",
  "policyNumber": "string (optional, 1–100 chars)",
  "coverageType": "string (optional, enum — see section 4)",
  "totalCoverageAmount": "number (optional, positive)",
  "premium": "number (optional, >= 0)",
  "startDate": "string (optional, ISO 8601 date string)",
  "expiresAt": "string (optional, ISO 8601 date string)",
  "status": "string (optional, enum — see section 4)",
  "notes": "string (optional)"
}
```

> `currency` is **not** in `UpdatePolicyDto` — it cannot be changed after creation.

### `GET /api/insurance/policies`

Optional query parameter:

```
?status=active | expired | cancelled
```

No request body. If `status` is omitted, all policies for the tenant are returned.
If an invalid value is passed, no error is thrown — the query silently returns empty results.
**There is no DTO validation on this query param.**

### `POST /api/insurance/policies/:id/items`

```json
{
  "itemId": "string (required, valid MongoDB ObjectId — 24-char hex)",
  "coveredValue": "number (required, positive)",
  "currency": "string (optional, exactly 3 chars — defaults to parent policy currency)"
}
```

### `DELETE /api/insurance/policies/:id/items/:itemId`

No request body.
`:itemId` in the path is the **MongoDB ObjectId string** (24-char hex),
**not** the `InsuredItem.id` UUID.

### `GET /api/insurance/policies/:id` · `DELETE /api/insurance/policies/:id` · `GET /api/insurance/coverage-gaps`

No request body.

---

## 3. Response Shapes

All responses are wrapped by the global `ResponseInterceptor`:

```json
{
  "success": true,
  "data": "<payload described below>"
}
```

---

### `POST /api/insurance/policies` → `InsurancePolicy`

```json
{
  "success": true,
  "data": {
    "id": "string (UUID)",
    "tenantId": "string (UUID)",
    "provider": "string",
    "policyNumber": "string",
    "coverageType": "string (enum value)",
    "totalCoverageAmount": "string ⚠️",
    "premium": "string | null ⚠️",
    "currency": "string",
    "startDate": "string (ISO 8601 datetime)",
    "expiresAt": "string (ISO 8601 datetime)",
    "status": "string (always 'active' on create)",
    "notes": "string | null",
    "createdAt": "string (ISO 8601 datetime)",
    "updatedAt": "string (ISO 8601 datetime)"
  }
}
```

> ⚠️ **TypeORM numeric warning**: PostgreSQL `numeric` columns are returned by TypeORM
> as **strings**, not JavaScript numbers. `totalCoverageAmount` and `premium` will be
> strings like `"1500000.00"` in the JSON response. Flutter must parse these with
> `double.parse()`.

---

### `GET /api/insurance/policies` → `InsurancePolicy[]`

```json
{
  "success": true,
  "data": [
    {
      "id": "string (UUID)",
      "tenantId": "string (UUID)",
      "provider": "string",
      "policyNumber": "string",
      "coverageType": "string (enum)",
      "totalCoverageAmount": "string ⚠️",
      "premium": "string | null ⚠️",
      "currency": "string",
      "startDate": "string (ISO 8601)",
      "expiresAt": "string (ISO 8601)",
      "status": "string (enum)",
      "notes": "string | null",
      "createdAt": "string (ISO 8601)",
      "updatedAt": "string (ISO 8601)"
    }
  ]
}
```

Ordered by `createdAt DESC`.
Lazy expiration: if any policy's `expiresAt` has passed and its status was `active`,
the response will show `status: "expired"` (updated in-memory before returning).

---

### `GET /api/insurance/policies/:id` → `PolicyWithItems`

This is the **only endpoint that returns insured items embedded in the policy**.
The response is a spread of `InsurancePolicy` plus an `insuredItems` array.

```json
{
  "success": true,
  "data": {
    "id": "string (UUID)",
    "tenantId": "string (UUID)",
    "provider": "string",
    "policyNumber": "string",
    "coverageType": "string (enum)",
    "totalCoverageAmount": "string ⚠️",
    "premium": "string | null ⚠️",
    "currency": "string",
    "startDate": "string (ISO 8601)",
    "expiresAt": "string (ISO 8601)",
    "status": "string (enum)",
    "notes": "string | null",
    "createdAt": "string (ISO 8601)",
    "updatedAt": "string (ISO 8601)",
    "insuredItems": [
      {
        "id": "string (UUID)",
        "tenantId": "string (UUID)",
        "policyId": "string (UUID)",
        "itemId": "string (MongoDB ObjectId, 24-char hex)",
        "coveredValue": "string ⚠️",
        "currency": "string",
        "createdAt": "string (ISO 8601)",
        "updatedAt": "string (ISO 8601)"
      }
    ]
  }
}
```

`insuredItems` ordered by `createdAt DESC`. Can be an empty array `[]`.

---

### `PUT /api/insurance/policies/:id` → `InsurancePolicy`

Returns the full updated policy. Same shape as the `POST` response (no `insuredItems`).

---

### `DELETE /api/insurance/policies/:id` → void

```json
{
  "success": true
}
```

`data` key is absent. The service returns `void`; the interceptor maps `undefined`,
which is dropped by JSON serialization.

---

### `POST /api/insurance/policies/:id/items` → `InsuredItem`

```json
{
  "success": true,
  "data": {
    "id": "string (UUID)",
    "tenantId": "string (UUID)",
    "policyId": "string (UUID)",
    "itemId": "string (MongoDB ObjectId, 24-char hex)",
    "coveredValue": "string ⚠️",
    "currency": "string",
    "createdAt": "string (ISO 8601)",
    "updatedAt": "string (ISO 8601)"
  }
}
```

---

### `DELETE /api/insurance/policies/:id/items/:itemId` → void

```json
{
  "success": true
}
```

Same as policy delete — `data` key is absent.

---

### `GET /api/insurance/coverage-gaps` → `CoverageGapReport`

```json
{
  "success": true,
  "data": {
    "uncovered": [
      {
        "itemId": "string (MongoDB ObjectId)",
        "name": "string",
        "category": "string",
        "currentValue": "number (true JS number, NOT string)",
        "coveredValue": 0,
        "gap": "number",
        "currency": "string"
      }
    ],
    "underinsured": [
      {
        "itemId": "string (MongoDB ObjectId)",
        "name": "string",
        "category": "string",
        "currentValue": "number",
        "coveredValue": "number",
        "gap": "number",
        "currency": "string"
      }
    ],
    "expiredPolicies": [
      {
        "id": "string (UUID)",
        "provider": "string",
        "policyNumber": "string",
        "expiresAt": "string (ISO 8601)"
      }
    ],
    "totalUncoveredValue": "number",
    "totalUnderinsuredGap": "number"
  }
}
```

> In `coverage-gaps`, all numeric values (`currentValue`, `coveredValue`, `gap`,
> `totalUncoveredValue`, `totalUnderinsuredGap`) are **true JavaScript numbers**,
> not strings. The service applies explicit `Number()` conversions.
> This is different from the entity responses above.

---

## 4. Enums / Status Values

### `CoverageType` — used in `InsurancePolicy.coverageType`

```
all-risk
named-peril
liability
scheduled
```

### `PolicyStatus` — used in `InsurancePolicy.status` and `?status=` query param

```
active
expired
cancelled
```

> There is **no `CoverageStatus` enum** in this module.
> Items are classified by their presence in the `uncovered` or `underinsured` arrays
> in the gap report. There is no per-item status field returned by any endpoint.

---

## 5. Example Real Responses

### `GET /api/insurance/policies`

```json
{
  "success": true,
  "data": [
    {
      "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
      "tenantId": "f0e1d2c3-b4a5-6789-cdef-012345678901",
      "provider": "Chubb Insurance",
      "policyNumber": "CHB-2024-00142",
      "coverageType": "all-risk",
      "totalCoverageAmount": "5000000.00",
      "premium": "12500.00",
      "currency": "USD",
      "startDate": "2024-01-01T00:00:00.000Z",
      "expiresAt": "2025-01-01T00:00:00.000Z",
      "status": "active",
      "notes": "Covers all properties in Miami and Aspen",
      "createdAt": "2024-01-15T10:30:00.000Z",
      "updatedAt": "2024-01-15T10:30:00.000Z"
    },
    {
      "id": "b2c3d4e5-f6a7-8901-bcde-f12345678902",
      "tenantId": "f0e1d2c3-b4a5-6789-cdef-012345678901",
      "provider": "AXA Art",
      "policyNumber": "AXA-ART-9921",
      "coverageType": "scheduled",
      "totalCoverageAmount": "2000000.00",
      "premium": null,
      "currency": "USD",
      "startDate": "2023-06-01T00:00:00.000Z",
      "expiresAt": "2024-06-01T00:00:00.000Z",
      "status": "expired",
      "notes": null,
      "createdAt": "2023-06-10T08:00:00.000Z",
      "updatedAt": "2024-06-02T00:01:00.000Z"
    }
  ]
}
```

---

### `GET /api/insurance/policies/:id`

```json
{
  "success": true,
  "data": {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "tenantId": "f0e1d2c3-b4a5-6789-cdef-012345678901",
    "provider": "Chubb Insurance",
    "policyNumber": "CHB-2024-00142",
    "coverageType": "all-risk",
    "totalCoverageAmount": "5000000.00",
    "premium": "12500.00",
    "currency": "USD",
    "startDate": "2024-01-01T00:00:00.000Z",
    "expiresAt": "2025-01-01T00:00:00.000Z",
    "status": "active",
    "notes": "Covers all properties in Miami and Aspen",
    "createdAt": "2024-01-15T10:30:00.000Z",
    "updatedAt": "2024-01-15T10:30:00.000Z",
    "insuredItems": [
      {
        "id": "c3d4e5f6-a7b8-9012-cdef-123456789012",
        "tenantId": "f0e1d2c3-b4a5-6789-cdef-012345678901",
        "policyId": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
        "itemId": "64b1f2e3c4d5e6f7a8b9c0d1",
        "coveredValue": "45000.00",
        "currency": "USD",
        "createdAt": "2024-01-20T14:00:00.000Z",
        "updatedAt": "2024-01-20T14:00:00.000Z"
      }
    ]
  }
}
```

---

### `GET /api/insurance/coverage-gaps`

```json
{
  "success": true,
  "data": {
    "uncovered": [
      {
        "itemId": "64b1f2e3c4d5e6f7a8b9c0d2",
        "name": "Patek Philippe Nautilus",
        "category": "wardrobe",
        "currentValue": 85000,
        "coveredValue": 0,
        "gap": 85000,
        "currency": "USD"
      }
    ],
    "underinsured": [
      {
        "itemId": "64b1f2e3c4d5e6f7a8b9c0d1",
        "name": "Basquiat Painting",
        "category": "art",
        "currentValue": 120000,
        "coveredValue": 45000,
        "gap": 75000,
        "currency": "USD"
      }
    ],
    "expiredPolicies": [
      {
        "id": "b2c3d4e5-f6a7-8901-bcde-f12345678902",
        "provider": "AXA Art",
        "policyNumber": "AXA-ART-9921",
        "expiresAt": "2024-06-01T00:00:00.000Z"
      }
    ],
    "totalUncoveredValue": 85000,
    "totalUnderinsuredGap": 75000
  }
}
```

---

## 6. Field Mapping Notes

### PostgreSQL fields — tables `insurance_policies` and `insured_items`

All fields on `InsurancePolicy` and `InsuredItem` responses come from PostgreSQL.

| JSON field | DB column |
|------------|-----------|
| `id` | `id` |
| `tenantId` | `tenant_id` |
| `policyNumber` | `policy_number` |
| `coverageType` | `coverage_type` |
| `totalCoverageAmount` | `total_coverage_amount` |
| `startDate` | `start_date` |
| `expiresAt` | `expires_at` |
| `createdAt` | `created_at` |
| `updatedAt` | `updated_at` |
| `policyId` *(InsuredItem)* | `policy_id` |
| `itemId` *(InsuredItem)* | `item_id` |
| `coveredValue` | `covered_value` |

### MongoDB reference

`InsuredItem.itemId` is a 24-character hex MongoDB ObjectId string stored as a plain
`VARCHAR(24)` column in PostgreSQL. This is a **logical reference only** — there is no
foreign key constraint. It links to documents in the MongoDB `items` collection.

No MongoDB data is returned in policy or insured item responses.

### MongoDB fields used only in `GET /api/insurance/coverage-gaps`

The service queries MongoDB selecting: `_id`, `name`, `category`, `valuation`, `status`.

| `CoverageGapItem` field | MongoDB source |
|-------------------------|----------------|
| `itemId` | `String(item._id)` |
| `name` | `item.name` |
| `category` | `item.category` |
| `currentValue` | `item.valuation.currentValue` → fallback `item.valuation.purchasePrice` → fallback `0` |
| `currency` | `item.valuation.currency` → fallback `'USD'` |

### Service-layer transformations

| Transformation | Where applied |
|----------------|---------------|
| Numeric string → JS number via `Number()` | `getCoverageGaps()` only — for coverage map computation |
| `status: 'active'` → `'expired'` in-memory mutation | `syncExpiredStatuses()` called on all read paths |
| Multiple policy coverage summed per item | `getCoverageGaps()` — `coveredValue` is the **sum** across all policies |
| Items with `currentValue === 0` excluded | `getCoverageGaps()` — silently skipped |

---

## 7. Validation Rules

### Required fields by endpoint

| Endpoint | Required fields |
|----------|-----------------|
| `POST /policies` | `provider`, `policyNumber`, `coverageType`, `totalCoverageAmount`, `startDate`, `expiresAt` |
| `POST /policies/:id/items` | `itemId`, `coveredValue` |

### Business rules enforced in the service

| Rule | Endpoint | HTTP error |
|------|----------|------------|
| `expiresAt` must be strictly after `startDate` | POST + PUT policies | `400 Bad Request` |
| Policy `status` must not be `cancelled` to update | PUT `/policies/:id` | `400 Bad Request` |
| Policy `status` must be `active` to attach an item | POST `.../items` | `400 Bad Request` |
| Item must exist in MongoDB and belong to same `tenantId` | POST `.../items` | `404 Not Found` |
| Item must not have `status: 'disposed'` in MongoDB | POST `.../items` | `400 Bad Request` |
| Same item cannot be attached to the same policy twice | POST `.../items` | `409 Conflict` |
| Item must be attached to the policy to detach | DELETE `.../items/:itemId` | `404 Not Found` |
| Policy must belong to tenant | All policy endpoints | `404 Not Found` |

### Additional notes

- `status` is **not settable on create** — `CreatePolicyDto` has no `status` field.
  The service hardcodes `status: 'active'` on creation. Sending `status` in the
  `POST` body will return `400` due to `forbidNonWhitelisted: true` in the global pipe.
- `tenantId` is **never accepted from the request body or headers** — it is always
  extracted from the verified JWT.

---

## 8. Known Limitations

| # | Description |
|---|-------------|
| 1 | **Numeric fields returned as strings**: `totalCoverageAmount`, `premium`, and `coveredValue` are PostgreSQL `numeric` type and TypeORM returns them as strings (e.g. `"1500000.00"`). Flutter must parse with `double.parse()`. This does **not** affect coverage-gaps numbers which are converted in the service. |
| 2 | **`currency` is immutable after creation**: `UpdatePolicyDto` does not include `currency`. There is no endpoint to change it. |
| 3 | **No validation on `?status` query param**: Invalid values return empty arrays silently instead of `400`. |
| 4 | **`GET /policies/:id` does not enrich `insuredItems` with MongoDB data**: `insuredItems` contains only PostgreSQL fields. To display item names, the Flutter client must call the inventory endpoint separately using each `itemId`. |
| 5 | **Multi-currency gap totals**: `totalUncoveredValue` and `totalUnderinsuredGap` sum raw amounts across all currencies. If items mix USD and EUR, the total is meaningless. The per-item `currency` field must be used for accurate display. |
| 6 | **Hard delete**: `DELETE /policies/:id` permanently removes the policy and all `insured_items` rows. There is no soft delete or `deleted_at` field. |
| 7 | **No pagination on list**: `GET /policies` returns all policies for the tenant with no `page`, `limit`, or cursor support. |
| 8 | **Lazy expiration is fire-and-forget**: If the background DB write in `syncExpiredStatuses` fails, the response shows `expired` but the DB row still reads `active` until the next request. |
