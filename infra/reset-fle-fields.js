#!/usr/bin/env node
'use strict';

/**
 * reset-fle-fields.js
 *
 * Detecta campos FLE en insurance_policies e insured_items que no pueden
 * descifrarse con la clave actual y los reemplaza por valores vacíos
 * correctamente cifrados con esa misma clave.
 *
 * Úsalo cuando ENCRYPTION_KEY/ENCRYPTION_SALT cambió y los datos anteriores
 * son irrecuperables. Los registros quedarán con campos vacíos para que
 * el usuario los re-ingrese desde la app.
 *
 * Uso (desde el VM, sin dependencias externas):
 *   node infra/reset-fle-fields.js .env.prod
 *
 * El único argumento es la ruta al archivo .env (relativa al directorio actual).
 */

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
// Resuelve pg desde múltiples ubicaciones posibles (host o contenedor Docker)
const pgCandidates = [
  '/app/node_modules/pg',
  path.join(process.cwd(), 'node_modules', 'pg'),
  path.join(process.cwd(), '..', 'apps', 'api', 'node_modules', 'pg'),
].map(p => path.resolve(p)); // nosemgrep: path-join-resolve-traversal — hardcoded paths, no user input
const pgDir = pgCandidates.find(p => { try { return fs.statSync(p).isDirectory(); } catch { return false; } });
if (!pgDir) {
  console.error('ERROR: módulo pg no encontrado. Rutas probadas:\n' + pgCandidates.join('\n'));
  process.exit(1);
}
const { Client } = require(pgDir);

// ── Carga .env sin dotenv ─────────────────────────────────────────────────────

const envFile = process.argv[2];
if (envFile) {
  const lines = fs.readFileSync(path.resolve(envFile), 'utf8').split('\n');
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    let val = trimmed.slice(eq + 1).trim();
    if ((val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))) {
      val = val.slice(1, -1);
    }
    if (!(key in process.env)) process.env[key] = val;
  }
}

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;
const CIPHERTEXT_RE = /^[0-9a-f]+:[0-9a-f]+:[0-9a-f]+$/i;

// ── Crypto helpers (misma lógica que CryptoService) ──────────────────────────

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY;
const ENCRYPTION_SALT = process.env.ENCRYPTION_SALT;

if (!ENCRYPTION_KEY || !ENCRYPTION_SALT) {
  console.error('ERROR: ENCRYPTION_KEY y ENCRYPTION_SALT son obligatorios.');
  process.exit(1);
}
if (ENCRYPTION_SALT.length < 32) {
  console.error('ERROR: ENCRYPTION_SALT debe tener al menos 32 caracteres.');
  process.exit(1);
}

const masterKey = crypto.scryptSync(ENCRYPTION_KEY, ENCRYPTION_SALT, 32);

function deriveKey(tenantId) {
  return Buffer.from(
    crypto.hkdfSync(
      'sha256',
      masterKey,
      Buffer.alloc(0),
      Buffer.from(`vaulted-fle:${tenantId}`, 'utf8'),
      32,
    ),
  );
}

function isEncrypted(value) {
  return typeof value === 'string' && CIPHERTEXT_RE.test(value);
}

function canDecrypt(ciphertext, tenantId) {
  if (!isEncrypted(ciphertext)) return true;
  try {
    const [ivHex, authTagHex, encryptedHex] = ciphertext.split(':');
    const key = deriveKey(tenantId);
    const decipher = crypto.createDecipheriv(
      ALGORITHM,
      key,
      Buffer.from(ivHex, 'hex'),
      { authTagLength: 16 },
    );
    decipher.setAuthTag(Buffer.from(authTagHex, 'hex'));
    decipher.update(Buffer.from(encryptedHex, 'hex'));
    decipher.final();
    return true;
  } catch {
    return false;
  }
}

function encryptField(value, tenantId) {
  const key = deriveKey(tenantId);
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv(ALGORITHM, key, iv, { authTagLength: 16 });
  const encrypted = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
}

// ── Lógica principal ──────────────────────────────────────────────────────────

async function main() {
  const db = new Client({ connectionString: process.env.DATABASE_URL });
  await db.connect();
  console.log('Conectado a PostgreSQL.\n');

  let totalFixed = 0;

  // ── insurance_policies ────────────────────────────────────────────────────
  const { rows: policies } = await db.query(
    `SELECT id, "tenantId", provider, "policyNumber", "totalCoverageAmount", premium, notes
     FROM insurance_policies`,
  );

  console.log(`insurance_policies: ${policies.length} registros encontrados.`);

  for (const p of policies) {
    const tid = p.tenantId;
    const updates = {};

    // Campos string — reset a cadena vacía
    for (const field of ['provider', 'policyNumber', 'notes']) {
      const val = p[field];
      if (val !== null && isEncrypted(val) && !canDecrypt(val, tid)) {
        updates[field] = encryptField('', tid);
      }
    }

    // totalCoverageAmount — reset a '0'
    if (isEncrypted(p.totalCoverageAmount) && !canDecrypt(p.totalCoverageAmount, tid)) {
      updates['totalCoverageAmount'] = encryptField('0', tid);
    }

    // premium — nullable; reset a '0' si tenía valor
    if (p.premium !== null && isEncrypted(p.premium) && !canDecrypt(p.premium, tid)) {
      updates['premium'] = encryptField('0', tid);
    }

    if (Object.keys(updates).length === 0) continue;

    const cols = Object.keys(updates);
    const setClauses = cols.map((c, i) => `"${c}" = $${i + 2}`).join(', ');
    await db.query(
      `UPDATE insurance_policies SET ${setClauses} WHERE id = $1`,
      [p.id, ...cols.map((c) => updates[c])],
    );
    console.log(`  [policy ${p.id}] reseteado: ${cols.join(', ')}`);
    totalFixed++;
  }

  // ── insured_items ─────────────────────────────────────────────────────────
  const { rows: items } = await db.query(
    `SELECT id, "tenantId", "coveredValue" FROM insured_items`,
  );

  console.log(`\ninsured_items: ${items.length} registros encontrados.`);

  for (const it of items) {
    if (!isEncrypted(it.coveredValue) || canDecrypt(it.coveredValue, it.tenantId)) continue;

    await db.query(
      `UPDATE insured_items SET "coveredValue" = $1 WHERE id = $2`,
      [encryptField('0', it.tenantId), it.id],
    );
    console.log(`  [insured_item ${it.id}] reseteado: coveredValue`);
    totalFixed++;
  }

  await db.end();
  console.log(`\nListo. ${totalFixed} registros actualizados.`);
  if (totalFixed > 0) {
    console.log('Los campos vacios quedaron cifrados con la clave actual.');
    console.log('El usuario puede re-ingresar los valores desde la app.');
  } else {
    console.log('No se encontraron campos con error de descifrado.');
  }
}

main().catch((err) => {
  console.error('Error fatal:', err.message);
  process.exit(1);
});
