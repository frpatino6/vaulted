/**
 * One-time migration: replaces wrong APP_URL in item photo/document URLs.
 *
 * Background
 * ----------
 * The initial production deploy had APP_URL=http://34.57.81.166:3000 (the
 * internal container address). Every uploaded photo was stored in MongoDB
 * with that prefix, making the URLs completely unreachable from the Flutter
 * app and web browsers.
 *
 * This script rewrites all affected URLs to use the correct public base URL.
 *
 * Usage
 * -----
 * On the VM, inside the vaulted directory:
 *
 *   npx ts-node -e "$(cat apps/api/src/migrations/fix-photo-urls.ts)" \
 *     -- --from="http://34.57.81.166:3000" --to="https://api-vaulted.casacam.net"
 *
 * Or run via npm:
 *
 *   npm run migrate:fix-urls --workspace=apps/api
 *
 * Environment variables required:
 *   MONGODB_URI  — MongoDB Atlas connection string (same as in .env.prod)
 *
 * The script is idempotent: running it multiple times is safe.
 */

import { MongoClient } from 'mongodb';

const OLD_BASE =
  process.env['OLD_PHOTO_BASE'] ?? 'http://34.57.81.166:3000';
const NEW_BASE =
  process.env['NEW_PHOTO_BASE'] ?? 'https://api-vaulted.casacam.net';
const MONGODB_URI = process.env['MONGODB_URI'];

if (!MONGODB_URI) {
  console.error('ERROR: MONGODB_URI environment variable is not set.');
  process.exit(1);
}

function rewriteUrl(url: string): string {
  if (typeof url === 'string' && url.startsWith(OLD_BASE)) {
    return NEW_BASE + url.slice(OLD_BASE.length);
  }
  return url;
}

async function run(): Promise<void> {
  const client = new MongoClient(MONGODB_URI!);

  try {
    await client.connect();
    console.log('Connected to MongoDB');

    const db = client.db(); // uses database name from URI

    // ------------------------------------------------------------------ items
    const items = db.collection('items');
    const cursor = items.find({
      $or: [
        { photos: { $regex: OLD_BASE.replace(/\//g, '\\/') } },
        { documents: { $regex: OLD_BASE.replace(/\//g, '\\/') } },
      ],
    });

    let updatedItems = 0;

    for await (const item of cursor) {
      const newPhotos: string[] = (item.photos ?? []).map(rewriteUrl);
      const newDocs: string[] = (item.documents ?? []).map(rewriteUrl);

      await items.updateOne(
        { _id: item._id },
        { $set: { photos: newPhotos, documents: newDocs } },
      );
      updatedItems++;
    }

    console.log(`Updated ${updatedItems} item(s).`);

    // ------------------------------------------------------------- properties
    const properties = db.collection('properties');
    const propCursor = properties.find({
      photos: { $regex: OLD_BASE.replace(/\//g, '\\/') },
    });

    let updatedProps = 0;

    for await (const prop of propCursor) {
      const newPhotos: string[] = (prop.photos ?? []).map(rewriteUrl);
      await properties.updateOne(
        { _id: prop._id },
        { $set: { photos: newPhotos } },
      );
      updatedProps++;
    }

    console.log(`Updated ${updatedProps} property photo(s).`);
    console.log('Migration complete.');
  } finally {
    await client.close();
  }
}

run().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
