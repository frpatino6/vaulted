import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Schema as MongooseSchema } from 'mongoose';

export type ItemDocument = HydratedDocument<Item>;

/**
 * Fields marked [FLE] are stored as AES-256-GCM ciphertext in MongoDB
 * ("iv:authTag:ciphertext", all hex). InventoryService transparently
 * encrypts on write and decrypts on read — callers always receive
 * plaintext numbers / dates via the HTTP API.
 *
 * Encryption is per-tenant: each tenant's valuation data is encrypted
 * with a key derived from the master ENCRYPTION_KEY + tenantId via
 * HKDF-SHA-256, so a DB dump cannot expose cross-tenant financial data.
 */
@Schema({ _id: false })
export class ItemValuation {
  // [FLE] plaintext type: number — stored as AES-256-GCM ciphertext
  @Prop({ type: String })
  purchasePrice?: number;

  @Prop()
  purchaseDate?: Date;

  // [FLE] plaintext type: number — stored as AES-256-GCM ciphertext
  @Prop({ type: String })
  currentValue?: number;

  @Prop({ default: 'USD' })
  currency?: string;

  // [FLE] plaintext type: Date (ISO-8601) — stored as AES-256-GCM ciphertext
  @Prop({ type: String })
  lastAppraisalDate?: Date;
}

@Schema({ timestamps: true, collection: 'items' })
export class Item {
  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true, index: true })
  propertyId!: string;

  @Prop({ type: String, required: false, default: null, index: true })
  roomId?: string | null;

  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({
    required: true,
    enum: [
      'furniture',
      'art',
      'technology',
      'wardrobe',
      'vehicles',
      'wine',
      'sports',
      'other',
    ],
  })
  category!:
    | 'furniture'
    | 'art'
    | 'technology'
    | 'wardrobe'
    | 'vehicles'
    | 'wine'
    | 'sports'
    | 'other';

  @Prop({ trim: true })
  subcategory?: string;

  @Prop({ type: MongooseSchema.Types.Mixed })
  attributes?: Record<string, unknown>;

  @Prop({ type: ItemValuation })
  valuation?: ItemValuation;

  @Prop({
    enum: ['active', 'loaned', 'repair', 'storage', 'disposed'],
    default: 'active',
  })
  status!: 'active' | 'loaned' | 'repair' | 'storage' | 'disposed';

  @Prop({ type: [String], default: [] })
  photos!: string[];

  @Prop({ type: [String], default: [] })
  documents!: string[];

  @Prop()
  qrCode?: string;

  @Prop({ type: [String], default: [] })
  tags!: string[];

  @Prop()
  serialNumber?: string;

  @Prop({ trim: true })
  locationDetail?: string;

  @Prop({ type: String, required: false, default: null, index: true })
  sectionId?: string | null;

  @Prop({ required: true })
  createdBy!: string;

  @Prop({ default: null })
  nextMaintenanceDate?: Date;

  @Prop({ default: 0 })
  maintenanceDueCount!: number;
}

export const ItemValuationSchema = SchemaFactory.createForClass(ItemValuation);
export const ItemSchema = SchemaFactory.createForClass(Item);

ItemSchema.index({ name: 'text', tags: 'text', subcategory: 'text' });
