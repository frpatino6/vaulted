#!/usr/bin/env node
'use strict';

/**
 * restore-valuations.js
 *
 * Recorre todos los items en MongoDB, detecta campos de valuación cifrados
 * con la clave anterior (que ya no se puede descifrar), y los reemplaza con
 * valores estimados en USD cifrados con la clave actual de .env.prod.
 *
 * Los valores se estiman por categoría, subcategoría, marca y nombre del item.
 *
 * Uso (en el VM, desde la raíz del repo):
 *   ENCRYPTION_KEY=<valor> ENCRYPTION_SALT=<valor> MONGODB_URI=<uri> \
 *     node infra/restore-valuations.js
 *
 * O cargando desde .env.prod:
 *   set -a && source .env.prod && set +a
 *   node infra/restore-valuations.js
 */

const crypto = require('crypto');
const { MongoClient } = require('mongodb');

// ─── Crypto (replica exacta de CryptoService) ────────────────────────────────

const ENCRYPTION_KEY = process.env.ENCRYPTION_KEY;
const ENCRYPTION_SALT = process.env.ENCRYPTION_SALT || 'vaulted-salt';
const MONGODB_URI = process.env.MONGODB_URI;

if (!ENCRYPTION_KEY) { console.error('ENCRYPTION_KEY no está definido'); process.exit(1); }
if (!MONGODB_URI)     { console.error('MONGODB_URI no está definido');     process.exit(1); }

const masterKey = crypto.scryptSync(ENCRYPTION_KEY, ENCRYPTION_SALT, 32);

function deriveKey(tenantId) {
  return Buffer.from(
    crypto.hkdfSync('sha256', masterKey, Buffer.alloc(0),
      Buffer.from(`vaulted-fle:${tenantId}`, 'utf8'), 32),
  );
}

function encryptField(value, tenantId) {
  const key = deriveKey(tenantId);
  const iv  = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv('aes-256-gcm', key, iv);
  const enc = Buffer.concat([cipher.update(String(value), 'utf8'), cipher.final()]);
  return `${iv.toString('hex')}:${cipher.getAuthTag().toString('hex')}:${enc.toString('hex')}`;
}

const CIPHERTEXT_RE = /^[0-9a-f]+:[0-9a-f]+:[0-9a-f]+$/i;
function isEncrypted(v) { return typeof v === 'string' && CIPHERTEXT_RE.test(v); }

// ─── Tabla de valores estimados (USD) ────────────────────────────────────────
// Estructura: category → { purchasePrice, currentValue }
// currentValue ≈ 80% del purchasePrice por depreciación general

const BASE_VALUES = {
  // Furniture
  'furniture':             { p: 8000,   c: 6500  },
  'sofa':                  { p: 5000,   c: 4000  },
  'dining table':          { p: 4000,   c: 3200  },
  'bed':                   { p: 3500,   c: 2800  },
  'dresser':               { p: 2500,   c: 2000  },
  'chair':                 { p: 1200,   c: 900   },
  'bookcase':              { p: 1500,   c: 1200  },
  'cabinet':               { p: 2000,   c: 1600  },

  // Art & Collectibles
  'art':                   { p: 25000,  c: 30000 },
  'art & collectibles':    { p: 25000,  c: 30000 },
  'painting':              { p: 20000,  c: 24000 },
  'sculpture':             { p: 15000,  c: 18000 },
  'collectible':           { p: 5000,   c: 6000  },
  'antique':               { p: 10000,  c: 12000 },

  // Technology
  'technology':            { p: 3000,   c: 1800  },
  'appliances & technology': { p: 3000, c: 1800  },
  'laptop':                { p: 2500,   c: 1500  },
  'television':            { p: 3000,   c: 2000  },
  'phone':                 { p: 1200,   c: 700   },
  'tablet':                { p: 1000,   c: 600   },
  'camera':                { p: 2000,   c: 1400  },
  'audio':                 { p: 4000,   c: 3000  },
  'appliance':             { p: 1500,   c: 1000  },

  // Wardrobe
  'wardrobe':              { p: 2000,   c: 1600  },
  'clothing':              { p: 500,    c: 350   },
  'footwear':              { p: 800,    c: 600   },
  'accessories':           { p: 1500,   c: 1200  },

  // Jewelry & Watches
  'jewelry':               { p: 15000,  c: 18000 },
  'jewelry & watches':     { p: 15000,  c: 18000 },
  'watch':                 { p: 12000,  c: 14000 },
  'ring':                  { p: 8000,   c: 9500  },
  'necklace':              { p: 5000,   c: 6000  },
  'bracelet':              { p: 4000,   c: 4800  },
  'earrings':              { p: 3000,   c: 3500  },

  // Vehicles
  'vehicles':              { p: 80000,  c: 65000 },
  'car':                   { p: 80000,  c: 65000 },
  'truck':                 { p: 60000,  c: 50000 },
  'motorcycle':            { p: 15000,  c: 12000 },
  'boat':                  { p: 120000, c: 100000 },
  'yacht':                 { p: 500000, c: 450000 },

  // Wine & Spirits
  'wine & spirits':        { p: 800,    c: 1000  },
  'wine':                  { p: 500,    c: 700   },
  'spirits':               { p: 300,    c: 400   },
  'whiskey':               { p: 250,    c: 350   },
  'champagne':             { p: 400,    c: 600   },

  // Sports
  'sports equipment':      { p: 2000,   c: 1500  },
  'golf':                  { p: 3000,   c: 2500  },
  'bicycle':               { p: 4000,   c: 3200  },
  'ski':                   { p: 2500,   c: 2000  },

  // Musical Instruments
  'musical instruments':   { p: 5000,   c: 4500  },
  'piano':                 { p: 20000,  c: 18000 },
  'guitar':                { p: 3000,   c: 2500  },

  // Household
  'household supplies':    { p: 1000,   c: 700   },
  'books':                 { p: 200,    c: 100   },

  // Brands premium (override cuando se detecta en nombre/marca)
  'rolex':    { p: 25000,  c: 28000 },
  'patek':    { p: 80000,  c: 90000 },
  'hermes':   { p: 12000,  c: 14000 },
  'louis vuitton': { p: 5000, c: 6000 },
  'chanel':   { p: 8000,   c: 9000  },
  'ferrari':  { p: 250000, c: 230000 },
  'porsche':  { p: 120000, c: 110000 },
  'lamborghini': { p: 300000, c: 280000 },
  'bentley':  { p: 200000, c: 185000 },
  'rolls royce': { p: 350000, c: 330000 },
  'steinway': { p: 90000,  c: 85000 },
  'apple':    { p: 2000,   c: 1200  },

  // Default
  'default':  { p: 1500,   c: 1100  },
};

function estimateValue(item) {
  const tokens = [
    item.name,
    item.category,
    item.subcategory,
    item.brand,
    ...(item.tags || []),
  ]
    .filter(Boolean)
    .join(' ')
    .toLowerCase();

  // Busca primero por marca premium
  for (const key of Object.keys(BASE_VALUES)) {
    if (tokens.includes(key) && BASE_VALUES[key].p > 10000) {
      return BASE_VALUES[key];
    }
  }
  // Luego por subcategoría
  if (item.subcategory) {
    const sub = item.subcategory.toLowerCase();
    if (BASE_VALUES[sub]) return BASE_VALUES[sub];
  }
  // Luego por categoría
  if (item.category) {
    const cat = item.category.toLowerCase();
    if (BASE_VALUES[cat]) return BASE_VALUES[cat];
  }
  // Finalmente por keyword en nombre
  for (const key of Object.keys(BASE_VALUES)) {
    if (tokens.includes(key)) return BASE_VALUES[key];
  }
  return BASE_VALUES['default'];
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  const client = new MongoClient(MONGODB_URI);
  await client.connect();
  console.log('✅ Conectado a MongoDB\n');

  const db = client.db();
  const items = db.collection('items');

  const all = await items.find({}).toArray();
  console.log(`📦 Total items encontrados: ${all.length}\n`);

  let updated = 0;
  let skipped = 0;

  for (const item of all) {
    const v = item.valuation;

    const priceEncrypted = v && isEncrypted(v.purchasePrice);
    const valueEncrypted = v && isEncrypted(v.currentValue);
    const dateEncrypted  = v && isEncrypted(v.lastAppraisalDate);

    if (!priceEncrypted && !valueEncrypted && !dateEncrypted) {
      skipped++;
      continue;
    }

    const tenantId = item.tenantId;
    const est = estimateValue(item);

    const update = { $set: {} };
    if (priceEncrypted) update.$set['valuation.purchasePrice'] = encryptField(est.p, tenantId);
    if (valueEncrypted) update.$set['valuation.currentValue']  = encryptField(est.c, tenantId);
    if (dateEncrypted)  update.$set['valuation.lastAppraisalDate'] = encryptField(new Date().toISOString(), tenantId);

    await items.updateOne({ _id: item._id }, update);

    const name = item.name || String(item._id);
    const cat  = [item.category, item.subcategory].filter(Boolean).join(' / ');
    console.log(`✅ ${name} (${cat || 'sin categoría'}) → $${est.p.toLocaleString()} compra / $${est.c.toLocaleString()} actual`);
    updated++;
  }

  console.log(`\n────────────────────────────────`);
  console.log(`✅ Actualizados: ${updated}`);
  console.log(`⏭  Sin cambios:  ${skipped}`);
  console.log(`────────────────────────────────`);

  await client.close();
}

main().catch(err => { console.error('❌ Error:', err.message); process.exit(1); });
