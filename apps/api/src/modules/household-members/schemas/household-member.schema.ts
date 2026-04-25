import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type HouseholdMemberDocument = HydratedDocument<HouseholdMember>;

@Schema({ timestamps: true, collection: 'household_members' })
export class HouseholdMember {
  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({ trim: true })
  relationship?: string;

  @Prop({ default: false })
  isMinor!: boolean;

  @Prop({ default: true })
  isActive!: boolean;

  @Prop({ default: null, index: true })
  linkedUserId?: string | null;

  @Prop({ trim: true })
  notes?: string;

  @Prop({ required: true })
  createdBy!: string;
}

export const HouseholdMemberSchema =
  SchemaFactory.createForClass(HouseholdMember);

HouseholdMemberSchema.index({ tenantId: 1, isActive: 1, name: 1 });
