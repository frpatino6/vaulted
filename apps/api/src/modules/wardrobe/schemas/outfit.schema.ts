import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type OutfitDocument = HydratedDocument<Outfit>;

@Schema({ timestamps: true, collection: 'outfits' })
export class Outfit {
  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({ trim: true })
  description?: string;

  @Prop({ type: [String], default: [] })
  itemIds!: string[];

  @Prop({ enum: ['spring_summer', 'fall_winter', 'all_season'] })
  season?: 'spring_summer' | 'fall_winter' | 'all_season';

  @Prop({ trim: true })
  occasion?: string;

  @Prop({ type: [String], default: [] })
  photos!: string[];

  @Prop({ type: String, default: null, index: true })
  ownerMemberId?: string | null;

  @Prop({ required: true })
  createdBy!: string;
}

export const OutfitSchema = SchemaFactory.createForClass(Outfit);

OutfitSchema.index({ tenantId: 1, createdAt: -1 });
OutfitSchema.index({ tenantId: 1, ownerMemberId: 1, createdAt: -1 });
