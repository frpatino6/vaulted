# Scripts

## seed-inventory.mjs

Creates test data via the Vaulted API:

1. **One new property** – "Lakeside Estate" (vacation, Lake Tahoe) with 2 floors and 6 rooms.
2. **More rooms on the existing property** – If you already have a property, adds 2 rooms per existing floor (or 1 new floor + 2 rooms if there were no floors).
3. **At least 10 items per room** – Every room (new + existing) gets 10 items with name, category, subcategory, serial number, valuation, and tags.

### Requirements

- API running (e.g. `npm run start:dev` in `apps/api`).
- A tenant user (owner or manager). If the user has MFA enabled, complete MFA once or use a user without MFA for seeding.

### Usage

From the repo root:

```bash
# Default: http://localhost:3000/api, owner@example.com / changeme
node scripts/seed-inventory.mjs

# With your credentials
LOGIN_EMAIL=you@example.com LOGIN_PASSWORD=yourpassword node scripts/seed-inventory.mjs

# Custom API base (e.g. Android emulator host)
API_BASE_URL=http://10.0.2.2:3000/api node scripts/seed-inventory.mjs
```

### Environment variables

| Variable         | Default                     | Description              |
|-----------------|-----------------------------|--------------------------|
| `API_BASE_URL`  | `http://localhost:3000/api`  | API base URL (no trailing slash) |
| `LOGIN_EMAIL`    | `owner@example.com`         | User email               |
| `LOGIN_PASSWORD`| `changeme`                  | User password            |
