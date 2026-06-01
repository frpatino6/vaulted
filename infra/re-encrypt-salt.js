#!/usr/bin/env node
'use strict';

/**
 * re-encrypt-salt.js
 *
 * Re-cifra todos los campos FLE cuando se cambia ENCRYPTION_SALT.
 * Afecta: insurance_policies, insured_items, users.mfa_secret (PostgreSQL)
 *         items.valuation (MongoDB)
 *
 * Uso:
 *   cd apps/api
 *   OLD_SALT='vaulted-salt' \
 *   NEW_SALT='<nuevo-salt-de-openssl>' \
 *   ENCRYPTION_KEY='<igual-que-en-.env.prod>' \
 *   DATABASE_URL='<postgres-neon-url>' \
 *   MONGODB_URI='<mongodb-atlas-url>' \
 *   node ../../infra/re-encrypt-salt.js
 *
 * Generar nuevo salt:  openssl rand -hex 32
 *
 * IMPORTANTE:
 *   1. Hacer un backup de la BD antes de correr este script.
 *   2. El API debe estar DETENIDO (o sin tráfico) durante la migración.
 *   3. Después de correr el script exitosamente, agregar ENCRYPTION_SALT=<NEW_SALT>
 *      a .env.prod y redeployar el API.
 */

const crypto = require('crypto');

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;
const CIPHERTEXT_RE = /^[0-9a-f]+:[0-9a-f]+:[0-9a-f]+$/i;

// ── Helpers de cifrado (misma lógica que CryptoService) ──────────────────────

function deriveRootKey(secret, salt) {
  return crypto.scryptSync(secret, salt, 32);
}

function derivePerTenantKey(rootKey, tenantId) {
  return Buffer.from(
    crypto.hkdfSync(
      'sha256',
      rootKey,
      Buffer.alloc(0),
      Buffer.from(`vaulted-fle:${tenantId}`, 'utf8'),
      32,
    ),
  );
}

function isEncrypted(value) {
  return typeof value === 'string' && CIPHERTEXT_RE.test(value);
}

function decrypt(ciphertext, key) {
  const parts = ciphertext.split(':');
  if (parts.length !== 3) throw new Error(`Formato inválido: ${ciphertext.slice(0, 20)}...`);
  const [ivHex, authTagHex, encryptedHex] = parts;
  const iv = Buffer.from(ivHex, 'hex');
  const authTag = Buffer.from(authTagHex, 'hex');
  const encrypted = Buffer.from(encryptedHex, 'hex');
  const decipher = crypto.createDecipheriv(ALGORITHM, key, iv);
  decipher.setAuthTag(authTag);
  return decipher.update(encrypted).toString('utf8') + decipher.final('utf8');
}

function encrypt(plaintext, key) {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv);
  const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
}

function reencrypt(ciphertext, oldKey, newKey) {
  return encrypt(decrypt(ciphertext, oldKey), newKey);
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY;
  const OLD_SALT       = process.env.OLD_SALT ?? 'vaulted-salt';
  const NEW_SALT       = process.env.NEW_SALT;
  const DATABASE_URL   = process.env.DATABASE_URL;
  const MONGODB_URI    = process.env.MONGODB_URI;

  if (!ENCRYPTION_KEY) { console.error('❌  Falta ENCRYPTION_KEY'); process.exit(1); }
  if (!NEW_SALT)        { console.error('❌  Falta NEW_SALT'); process.exit(1); }
  if (!DATABASE_URL)    { console.error('❌  Falta DATABASE_URL'); process.exit(1); }
  if (!MONGODB_URI)     { console.error('❌  Falta MONGODB_URI'); process.exit(1); }
  if (OLD_SALT === NEW_SALT) {
    console.error('❌  OLD_SALT y NEW_SALT son iguales — nada que migrar');
    process.exit(1);
  }

  const oldRootKey = deriveRootKey(ENCRYPTION_KEY, OLD_SALT);
  const newRootKey = deriveRootKey(ENCRYPTION_KEY, NEW_SALT);

  console.log('\n🔑  Migración de salt de cifrado');
  console.log(`    OLD_SALT: "${OLD_SALT}"  →  root key: ${oldRootKey.toString('hex').slice(0, 12)}...`);
  console.log(`    NEW_SALT: "${NEW_SALT}"  →  root key: ${newRootKey.toString('hex').slice(0, 12)}...`);
  console.log('\n⚠️   Asegurate de que el API esté detenido durante este proceso.\n');

  let totalUpdated = 0;
  let totalErrors  = 0;

  // ── PostgreSQL ──────────────────────────────────────────────────────────────
  const { Client } = require('pg');
  const pg = new Client({
    connectionString: DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  await pg.connect();
  console.log('✅  PostgreSQL conectado\n');

  try {
    // 1. insurance_policies
    {
      const { rows } = await pg.query(
        `SELECT id, tenant_id, provider, policy_number, total_coverage_amount, premium, notes
         FROM insurance_policies`,
      );
      console.log(`📋  insurance_policies: ${rows.length} filas`);

      for (const row of rows) {
        const oldKey = derivePerTenantKey(oldRootKey, row.tenant_id);
        const newKey = derivePerTenantKey(newRootKey, row.tenant_id);

        const cols = {
          provider:               row.provider,
          policy_number:          row.policy_number,
          total_coverage_amount:  row.total_coverage_amount,
          premium:                row.premium,
          notes:                  row.notes,
        };

        const updates = {};
        try {
          for (const [col, val] of Object.entries(cols)) {
            if (isEncrypted(val)) updates[col] = reencrypt(val, oldKey, newKey);
          }

          if (Object.keys(updates).length > 0) {
            const set = Object.keys(updates).map((c, i) => `"${c}" = $${i + 2}`).join(', ');
            await pg.query(
              `UPDATE insurance_policies SET ${set} WHERE id = $1`,
              [row.id, ...Object.values(updates)],
            );
            totalUpdated++;
          }
        } catch (err) {
          console.error(`  ❌  policy ${row.id} (tenant ${row.tenant_id}): ${err.message}`);
          totalErrors++;
        }
      }
      console.log(`    ✔  completado\n`);
    }

    // 2. insured_items
    {
      const { rows } = await pg.query(
        `SELECT id, tenant_id, covered_value FROM insured_items`,
      );
      console.log(`📋  insured_items: ${rows.length} filas`);

      for (const row of rows) {
        if (!isEncrypted(row.covered_value)) continue;

        const oldKey = derivePerTenantKey(oldRootKey, row.tenant_id);
        const newKey = derivePerTenantKey(newRootKey, row.tenant_id);

        try {
          const newVal = reencrypt(row.covered_value, oldKey, newKey);
          await pg.query(
            `UPDATE insured_items SET covered_value = $2 WHERE id = $1`,
            [row.id, newVal],
          );
          totalUpdated++;
        } catch (err) {
          console.error(`  ❌  insured_item ${row.id}: ${err.message}`);
          totalErrors++;
        }
      }
      console.log(`    ✔  completado\n`);
    }

    // 3. users.mfa_secret  (usa la root key directamente, no per-tenant HKDF)
    {
      const { rows } = await pg.query(
        `SELECT id, mfa_secret FROM users WHERE mfa_secret IS NOT NULL`,
      );
      console.log(`📋  users.mfa_secret: ${rows.length} usuarios con MFA`);

      for (const row of rows) {
        if (!isEncrypted(row.mfa_secret)) continue;

        try {
          const newVal = reencrypt(row.mfa_secret, oldRootKey, newRootKey);
          await pg.query(
            `UPDATE users SET mfa_secret = $2 WHERE id = $1`,
            [row.id, newVal],
          );
          totalUpdated++;
        } catch (err) {
          console.error(`  ❌  user ${row.id}: ${err.message}`);
          totalErrors++;
        }
      }
      console.log(`    ✔  completado\n`);
    }
  } finally {
    await pg.end();
  }

  // ── MongoDB ─────────────────────────────────────────────────────────────────
  const mongoose = require('mongoose');
  await mongoose.connect(MONGODB_URI);
  console.log('✅  MongoDB conectado\n');

  try {
    const db = mongoose.connection.db;
    const itemsCol = db.collection('items');

    const total = await itemsCol.countDocuments({ valuation: { $ne: null } });
    console.log(`📦  items (MongoDB): ${total} con valuation`);

    let mongoUpdated = 0;
    const cursor = itemsCol.find({ valuation: { $ne: null } });

    for await (const item of cursor) {
      const tenantId = String(item.tenantId);
      const v = item.valuation;
      if (!v) continue;

      const oldKey = derivePerTenantKey(oldRootKey, tenantId);
      const newKey = derivePerTenantKey(newRootKey, tenantId);

      const $set = {};
      try {
        for (const field of ['purchasePrice', 'currentValue', 'lastAppraisalDate']) {
          if (isEncrypted(v[field])) {
            $set[`valuation.${field}`] = reencrypt(v[field], oldKey, newKey);
          }
        }

        if (Object.keys($set).length > 0) {
          await itemsCol.updateOne({ _id: item._id }, { $set });
          mongoUpdated++;
          totalUpdated++;
        }
      } catch (err) {
        console.error(`  ❌  item ${String(item._id)}: ${err.message}`);
        totalErrors++;
      }
    }

    console.log(`    ✔  ${mongoUpdated} ítems actualizados\n`);
  } finally {
    await mongoose.disconnect();
  }

  // ── Resumen ──────────────────────────────────────────────────────────────────
  console.log('──────────────────────────────────────────────');
  if (totalErrors > 0) {
    console.error(`❌  Completado con ${totalErrors} error(es). Revisá los mensajes arriba.`);
    console.error('    NO actualices ENCRYPTION_SALT en .env.prod hasta resolver los errores.');
    process.exit(1);
  } else {
    console.log(`✅  ${totalUpdated} registros re-cifrados exitosamente.`);
    console.log('\nPróximos pasos:');
    console.log(`  1. Agregar a .env.prod:  ENCRYPTION_SALT=${NEW_SALT}`);
    console.log('  2. Subir el .env.prod actualizado a la VM:  ./infra/upload-env.sh');
    console.log('  3. Redeployar el API:  ./start-prod.sh down && ./start-prod.sh up -d');
    console.log('  4. Verificar health:   curl https://api-vaulted.casacam.net/health\n');
  }
}

main().catch((err) => {
  console.error('\n💥  Error fatal:', err.message);
  process.exit(1);
});
