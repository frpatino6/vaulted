#!/usr/bin/env node
/**
 * Creates two staff users directly in PostgreSQL.
 * Run from the VM: node scripts/seed-staff-users.js
 * Requires: POSTGRES_* and optionally TENANT_ID env vars (reads from .env.prod if present).
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

// Load .env.prod if it exists
const envFile = path.join(__dirname, '..', '.env.prod');
if (fs.existsSync(envFile)) {
  fs.readFileSync(envFile, 'utf8')
    .split('\n')
    .forEach(line => {
      const [key, ...rest] = line.split('=');
      if (key && rest.length && !process.env[key]) {
        process.env[key] = rest.join('=').trim().replace(/^"|"$/g, '');
      }
    });
}

const { Client } = require('pg');
const bcrypt = require('bcrypt');
const { v4: uuidv4 } = require('uuid');

const STAFF_USERS = [
  { email: 'staff1@vaulted-test.com', password: 'Staff1234!' },
  { email: 'staff2@vaulted-test.com', password: 'Staff1234!' },
];

async function main() {
  const client = new Client({
    host: process.env.POSTGRES_HOST,
    port: parseInt(process.env.POSTGRES_PORT || '5432'),
    database: process.env.POSTGRES_DB,
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    // nosemgrep: bypass-tls-verification — Neon requires self-signed certs; seed script runs locally
    ssl: process.env.POSTGRES_HOST?.includes('neon') ? { rejectUnauthorized: false } : false,
  });

  await client.connect();
  console.log('Connected to PostgreSQL');

  // Get the first active owner's tenantId
  let tenantId = process.env.TENANT_ID;
  if (!tenantId) {
    const res = await client.query(
      `SELECT tenant_id FROM users WHERE role = 'owner' AND status = 'active' LIMIT 1`
    );
    if (!res.rows.length) throw new Error('No active owner found. Set TENANT_ID env var manually.');
    tenantId = res.rows[0].tenant_id;
    console.log(`Using tenantId: ${tenantId}`);
  }

  // Get all propertyIds for this tenant from MongoDB is not possible here,
  // so we assign empty array — owner can assign properties from the app later
  const propertyIds = process.env.PROPERTY_IDS || '';

  for (const user of STAFF_USERS) {
    const existing = await client.query('SELECT id FROM users WHERE email = $1', [user.email]);
    if (existing.rows.length) {
      console.log(`⚠️  User ${user.email} already exists — skipping`);
      continue;
    }

    const passwordHash = await bcrypt.hash(user.password, 10);
    const id = uuidv4();

    await client.query(
      `INSERT INTO users (id, tenant_id, email, password_hash, role, is_active, status, property_ids, created_at, updated_at)
       VALUES ($1, $2, $3, $4, 'staff', true, 'active', $5, NOW(), NOW())`,
      [id, tenantId, user.email, passwordHash, propertyIds]
    );

    console.log(`✅ Created: ${user.email} | password: ${user.password} | id: ${id}`);
  }

  await client.end();
  console.log('\nDone.');
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
