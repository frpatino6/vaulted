#!/usr/bin/env node
/**
 * seed-location-detail.js
 *
 * Populates locationDetail for existing items based on their category and room name.
 * Run this on the GCP VM AFTER deploying the updated backend:
 *
 *   node infra/seed-location-detail.js
 *
 * Requires: node, and the API must be running.
 */

const API = process.env.API_URL || 'http://localhost:3000/api';
const EMAIL = process.env.SEED_EMAIL || 'owner@test.com';
const PASSWORD = process.env.SEED_PASSWORD || 'Test1234!Secure';

// ── Location rules ────────────────────────────────────────────────────────────
// Map: category (and optional roomName keywords) → locationDetail
function inferLocation(item, roomName = '') {
  const room = (roomName || '').toLowerCase();
  const cat = (item.category || '').toLowerCase();
  const subcat = (item.subcategory || '').toLowerCase();
  const name = (item.name || '').toLowerCase();

  // Closet / wardrobe items
  if (room.includes('closet') || room.includes('wardrobe') || room.includes('walk-in')) {
    if (subcat.includes('shoe') || name.includes('shoe') || name.includes('boot'))
      return 'Closet — Section D (Footwear)';
    if (subcat.includes('suit') || name.includes('suit') || name.includes('tuxedo'))
      return 'Closet — Section A (Formal Wear)';
    if (subcat.includes('dress') || name.includes('dress') || name.includes('gown'))
      return 'Closet — Section B (Dresses)';
    if (name.includes('bag') || name.includes('purse') || name.includes('handbag'))
      return 'Closet — Section E (Bags & Accessories)';
    if (name.includes('watch') || name.includes('jewelry') || name.includes('bracelet') || name.includes('necklace'))
      return 'Closet — Drawer 1 (Jewelry & Watches)';
    return 'Closet — Section C (Casual)';
  }

  // Kitchen items
  if (room.includes('kitchen') || room.includes('pantry')) {
    if (name.includes('plate') || name.includes('bowl') || name.includes('dish'))
      return 'Cabinet 3, Section A (Dishware)';
    if (name.includes('glass') || name.includes('cup') || name.includes('mug'))
      return 'Cabinet 3, Section B (Glassware)';
    if (name.includes('pot') || name.includes('pan') || name.includes('skillet'))
      return 'Cabinet 2 (Cookware)';
    if (name.includes('knife') || name.includes('cutlery') || name.includes('utensil'))
      return 'Drawer 2 (Cutlery)';
    if (cat === 'technology' || cat === 'appliances')
      return 'Counter — Left Side';
    return 'Cabinet 1';
  }

  // Living room
  if (room.includes('living') || room.includes('lounge') || room.includes('sala')) {
    if (cat === 'art') return 'East Wall';
    if (cat === 'technology') return 'Entertainment Unit';
    if (cat === 'furniture') return 'Center of Room';
    return 'Living Room';
  }

  // Dining room
  if (room.includes('dining')) {
    if (name.includes('china') || name.includes('plate')) return 'China Cabinet, Shelf 1';
    if (name.includes('glass') || name.includes('crystal')) return 'China Cabinet, Shelf 2';
    return 'Dining Room';
  }

  // Bedroom
  if (room.includes('bedroom') || room.includes('master')) {
    if (cat === 'wardrobe') return 'Closet — Section A';
    if (name.includes('watch') || name.includes('jewelry')) return 'Nightstand Drawer';
    if (cat === 'technology') return 'Desk';
    return 'Bedroom';
  }

  // Office / study
  if (room.includes('office') || room.includes('study') || room.includes('library')) {
    if (cat === 'technology') return 'Desk';
    if (cat === 'art') return 'Bookshelf, Row 1';
    return 'Office Shelf';
  }

  // Garage / vehicles
  if (room.includes('garage') || cat === 'vehicles') return 'Garage Bay';

  // Wine cellar
  if (room.includes('wine') || room.includes('cellar') || cat === 'wine')
    return 'Wine Rack, Row 1';

  // Gym / sports
  if (room.includes('gym') || room.includes('sport') || cat === 'sports')
    return 'Equipment Rack';

  // Storage
  if (room.includes('storage') || room.includes('utility'))
    return 'Storage Unit A';

  return null; // skip — no rule matched
}

// ── HTTP helpers ──────────────────────────────────────────────────────────────
async function post(path, body, token) {
  const res = await fetch(`${API}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });
  return res.json();
}

async function get(path, token) {
  const res = await fetch(`${API}${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  return res.json();
}

async function put(path, body, token) {
  const res = await fetch(`${API}${path}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(body),
  });
  return res.json();
}

// ── Main ──────────────────────────────────────────────────────────────────────
async function main() {
  console.log(`\n🔐 Logging in as ${EMAIL}…`);
  const loginRes = await post('/auth/login', { email: EMAIL, password: PASSWORD });
  const token = loginRes?.data?.accessToken;
  if (!token) {
    console.error('❌ Login failed:', JSON.stringify(loginRes));
    process.exit(1);
  }
  console.log('✅ Authenticated');

  // Get properties to build roomId → roomName map
  console.log('\n📦 Fetching properties…');
  const propsRes = await get('/properties', token);
  const properties = propsRes?.data || [];
  console.log(`   Found ${properties.length} property(ies)`);

  const roomNameById = {};
  for (const prop of properties) {
    for (const floor of prop.floors || []) {
      for (const room of floor.rooms || []) {
        roomNameById[room.roomId] = room.name;
      }
    }
  }

  // Fetch all items
  console.log('\n📋 Fetching all items…');
  const itemsRes = await get('/items', token);
  const items = itemsRes?.data || [];
  console.log(`   Found ${items.length} item(s)`);

  let updated = 0;
  let skipped = 0;

  for (const item of items) {
    // Skip items that already have locationDetail
    if (item.locationDetail) {
      skipped++;
      continue;
    }

    const roomName = roomNameById[item.roomId] || '';
    const location = inferLocation(item, roomName);

    if (!location) {
      skipped++;
      continue;
    }

    process.stdout.write(`   Updating "${item.name}" → "${location}"… `);
    const res = await put(`/items/${item._id || item.id}`, { locationDetail: location }, token);
    if (res?.data || res?.id || res?._id) {
      console.log('✅');
      updated++;
    } else {
      console.log('⚠️  unexpected response:', JSON.stringify(res).slice(0, 80));
    }
  }

  console.log(`\n🎉 Done! Updated: ${updated} | Skipped: ${skipped}`);

  // Trigger AI chat reindex so embeddings include the new locationDetail
  if (updated > 0) {
    console.log('\n🔄 Triggering AI chat reindex…');
    const reindex = await post('/ai/chat/reindex', {}, token);
    console.log('   Reindex result:', JSON.stringify(reindex).slice(0, 120));
  }
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
