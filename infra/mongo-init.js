// MongoDB initialization — runs once on first container start
// Creates application user with least-privilege access (readWrite on vaulted only)
// Root credentials (MONGO_INITDB_ROOT_*) are separate and not used by the API

db = db.getSiblingDB('vaulted');

db.createUser({
  user: process.env.MONGO_APP_USER,
  pwd:  process.env.MONGO_APP_PASSWORD,
  roles: [{ role: 'readWrite', db: 'vaulted' }],
});

// Indexes critical for security (tenantId isolation on hot collections)
db.items.createIndex({ tenantId: 1, _id: 1 });
db.items.createIndex({ tenantId: 1, propertyId: 1 });
db.movements.createIndex({ tenantId: 1, _id: 1 });
db.audit_logs.createIndex({ tenantId: 1, createdAt: -1 });
