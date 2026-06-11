#!/usr/bin/env node
/**
 * Seed script: creates one new property, adds more rooms to the existing one,
 * and creates at least 10 items per room (all rooms from both properties).
 *
 * Usage:
 *   LOGIN_EMAIL=owner@example.com LOGIN_PASSWORD=yourpassword node scripts/seed-inventory.mjs
 *   API_BASE_URL=http://localhost:3000/api  (default)
 *
 * Requires: API running, valid tenant user (owner/manager). If MFA is enabled, use a user without MFA or complete MFA first.
 */

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:3000/api';
const LOGIN_EMAIL = process.env.LOGIN_EMAIL || 'owner@example.com';
const LOGIN_PASSWORD = process.env.LOGIN_PASSWORD || 'changeme';

const CATEGORIES = [
  'furniture',
  'art',
  'technology',
  'wardrobe',
  'vehicles',
  'wine',
  'sports',
  'other',
];

const ITEM_NAMES_BY_CATEGORY = {
  furniture: ['Chesterfield Sofa', 'Eames Lounge Chair', 'Dining Table', 'Bookshelf', 'Coffee Table', 'Bed Frame', 'Nightstand', 'Wardrobe', 'Desk', 'Sideboard'],
  art: ['Oil Painting', 'Sculpture Bronze', 'Watercolor', 'Photograph', 'Ceramic Vase', 'Wall Art', 'Sculpture Marble', 'Lithograph', 'Sketch', 'Mixed Media'],
  technology: ['Smart TV', 'Laptop', 'Speaker System', 'Tablet', 'Camera', 'Monitor', 'Router', 'Smart Hub', 'Headphones', 'Charger Dock'],
  wardrobe: ['Suit Jacket', 'Evening Gown', 'Leather Jacket', 'Designer Handbag', 'Watch', 'Shoes Formal', 'Coat', 'Scarf Silk', 'Belt', 'Sunglasses'],
  vehicles: ['Sedan', 'SUV', 'Motorcycle', 'Boat', 'Bicycle', 'Golf Cart', 'ATV', 'Classic Car', 'Jet Ski', 'Trailer'],
  wine: ['Bordeaux Red', 'Chardonnay', 'Champagne', 'Pinot Noir', 'Cabernet', 'Whiskey', 'Vintage Port', 'Rosé', 'Burgundy', 'Barolo'],
  sports: ['Tennis Racket', 'Golf Clubs', 'Skis', 'Bicycle', 'Treadmill', 'Weights Set', 'Yoga Mat', 'Kayak', 'Surfboard', 'Camping Gear'],
  other: ['Antique Clock', 'Rug Persian', 'Chandelier', 'Mirror', 'Lamp Table', 'Vase', 'Candle Holder', 'Frame', 'Basket', 'Box Decorative'],
};

function id(obj) {
  return obj?.id ?? obj?._id ?? obj;
}

async function request(path, options = {}) {
  const url = `${API_BASE_URL.replace(/\/$/, '')}/${path.replace(/^\//, '')}`;
  const headers = {
    'Content-Type': 'application/json',
    ...options.headers,
  };
  const fetchOptions = {
    method: options.method || 'GET',
    headers,
  };
  if (options.body !== undefined) {
    fetchOptions.body = typeof options.body === 'string' ? options.body : JSON.stringify(options.body);
  }
  const res = await fetch(url, fetchOptions);
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = body?.error?.message ?? (Array.isArray(body?.message) ? body.message.join(', ') : body?.message) ?? res.statusText;
    throw new Error(`${res.status} ${path}: ${msg}`);
  }
  return body?.data ?? body;
}

async function login() {
  const data = await request('auth/login', {
    method: 'POST',
    body: JSON.stringify({ email: LOGIN_EMAIL, password: LOGIN_PASSWORD }),
  });
  if (data.mfaRequired) {
    throw new Error('MFA is required. Disable MFA for this user in the DB (mfa_enabled = false), restart the API, then run the script again.');
  }
  if (!data.accessToken) throw new Error('Login failed.');
  return data.accessToken;
}

async function getProperties(token) {
  return request('properties', { headers: { Authorization: `Bearer ${token}` } });
}

async function createProperty(token, dto) {
  const body = JSON.stringify(dto);
  return request('properties', {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body,
  });
}

async function addFloor(token, propertyId, name) {
  return request(`properties/${propertyId}/floors`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: JSON.stringify({ name }),
  });
}

async function addRoom(token, propertyId, floorId, name, type = 'living') {
  return request(`properties/${propertyId}/floors/${floorId}/rooms`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: JSON.stringify({ name, type }),
  });
}

async function createItem(token, body) {
  return request('items', {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}` },
    body: JSON.stringify(body),
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function* allRooms(properties) {
  for (const prop of properties) {
    const propId = id(prop);
    if (!propId) continue;
    const floors = prop.floors || [];
    for (const floor of floors) {
      const floorId = floor.floorId;
      if (!floorId) continue;
      const rooms = floor.rooms || [];
      for (const room of rooms) {
        const roomId = room.roomId;
        if (roomId) yield { propertyId: propId, roomId, roomName: room.name };
      }
    }
  }
}

async function main() {
  console.log('API base:', API_BASE_URL);
  console.log('Logging in as', LOGIN_EMAIL, '...');

  const token = await login();
  console.log('Logged in.\n');

  let properties = await getProperties(token);
  if (!Array.isArray(properties)) properties = [];
  const existingPropertyId = properties.length > 0 ? id(properties[0]) : null;

  if (existingPropertyId) {
    console.log('Existing property id (will add rooms):', existingPropertyId);
  }

  // 1) Create one new property
  const newProperty = await createProperty(token, {
    name: 'Lakeside Estate',
    type: 'vacation',
    address: {
      street: '100 Shore Drive',
      city: 'Lake Tahoe',
      state: 'CA',
      zip: '96150',
      country: 'USA',
    },
  });
  const newPropertyId = id(newProperty);
  console.log('Created new property:', newProperty.name, 'id:', newPropertyId);

  // 2) Add floors and rooms to the NEW property
  let propWithFloors = await addFloor(token, newPropertyId, 'Ground Floor');
  const groundFloorId = propWithFloors.floors?.slice(-1)[0]?.floorId;
  if (!groundFloorId) throw new Error('Failed to get new floor id');
  await addRoom(token, newPropertyId, groundFloorId, 'Living Room', 'living');
  await addRoom(token, newPropertyId, groundFloorId, 'Dining Room', 'dining');
  await addRoom(token, newPropertyId, groundFloorId, 'Kitchen', 'kitchen');

  propWithFloors = await addFloor(token, newPropertyId, 'Upper Floor');
  const upperFloorId = propWithFloors.floors?.slice(-1)[0]?.floorId;
  if (!upperFloorId) throw new Error('Failed to get upper floor id');
  await addRoom(token, newPropertyId, upperFloorId, 'Master Bedroom', 'bedroom');
  await addRoom(token, newPropertyId, upperFloorId, 'Guest Bedroom', 'bedroom');
  await addRoom(token, newPropertyId, upperFloorId, 'Office', 'office');

  console.log('Added 2 floors and 3 rooms each to new property.');

  // 3) Add more rooms to the EXISTING property
  if (existingPropertyId) {
    const existing = properties.find((p) => id(p) === existingPropertyId) || (await getProperties(token)).find((p) => id(p) === existingPropertyId);
    const existingFloors = existing?.floors || [];
    if (existingFloors.length === 0) {
      const updated = await addFloor(token, existingPropertyId, 'Main Floor');
      const newFloorId = updated.floors?.slice(-1)[0]?.floorId;
      if (newFloorId) {
        await addRoom(token, existingPropertyId, newFloorId, 'Guest Room', 'guest');
        await addRoom(token, existingPropertyId, newFloorId, 'Study', 'office');
      }
    } else {
      for (const f of existingFloors) {
        await addRoom(token, existingPropertyId, f.floorId, 'Guest Room', 'guest');
        await addRoom(token, existingPropertyId, f.floorId, 'Storage', 'storage');
      }
    }
    console.log('Added more rooms to existing property.');
  }

  // 4) Fetch all properties to get every room
  properties = await getProperties(token);
  const roomsList = [...allRooms(properties)];
  console.log('Total rooms across all properties:', roomsList.length, '\n');

  const ITEMS_PER_ROOM = 10;
  let totalItems = 0;
  console.log('Waiting 65s for rate-limit window to reset...');
  await sleep(65000);
  for (const { propertyId, roomId, roomName } of roomsList) {
    const namesByCat = { ...ITEM_NAMES_BY_CATEGORY };
    for (let i = 0; i < ITEMS_PER_ROOM; i++) {
      const category = CATEGORIES[i % CATEGORIES.length];
      const names = namesByCat[category];
      const name = (names[i % names.length] || 'Item') + ` – ${roomName}`;
      await createItem(token, {
        propertyId,
        roomId,
        name,
        category,
        subcategory: roomName.toLowerCase().replace(/\s/g, '-'),
        serialNumber: `SN-${Date.now()}-${totalItems}`,
        valuation: {
          purchasePrice: 500 + (i % 20) * 250,
          currentValue: 400 + (i % 20) * 300,
          currency: 'USD',
        },
        tags: ['seed', category],
      });
      totalItems++;
      await sleep(700);
    }
    console.log('Created', ITEMS_PER_ROOM, 'items for room:', roomName);
  }

  console.log('\nDone. Total items created:', totalItems);
}

main().catch((err) => {
  console.error(err.message || err);
  process.exit(1);
});
