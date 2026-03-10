import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument, Schema as MongooseSchema } from 'mongoose';

export type ItemDocument = HydratedDocument<Item>;

@Schema({ _id: false })
export class ItemValuation {
  @Prop()
  purchasePrice?: number;

  @Prop()
  purchaseDate?: Date;

  @Prop()
  currentValue?: number;

  @Prop({ default: 'USD' })
  currency?: string;

  @Prop()
  lastAppraisalDate?: Date;
}

@Schema({ timestamps: true, collection: 'items' })
export class Item {
  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true, index: true })
  propertyId!: string;

  @Prop({ required: true })
  roomId!: string;

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

  @Prop({ required: true })
  createdBy!: string;
}

export const ItemValuationSchema = SchemaFactory.createForClass(ItemValuation);
export const ItemSchema = SchemaFactory.createForClass(Item);

ItemSchema.index({ name: 'text', tags: 'text', subcategory: 'text' });
