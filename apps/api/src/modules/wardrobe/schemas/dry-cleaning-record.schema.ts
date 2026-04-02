import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type DryCleaningRecordDocument = HydratedDocument<DryCleaningRecord>;

@Schema({
  timestamps: { createdAt: true, updatedAt: false },
  collection: 'dry_cleaning_records',
})
export class DryCleaningRecord {
  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true, index: true })
  itemId!: string;

  @Prop({ required: true })
  sentDate!: Date;

  @Prop({ default: null })
  returnedDate?: Date | null;

  @Prop({ trim: true })
  cleanerName?: string;

  @Prop()
  cost?: number;

  @Prop({ default: 'USD' })
  currency!: string;

  @Prop({ trim: true })
  notes?: string;

  @Prop({ required: true })
  createdBy!: string;

  @Prop({ required: true, default: Date.now })
  createdAt!: Date;
}

export const DryCleaningRecordSchema =
  SchemaFactory.createForClass(DryCleaningRecord);

DryCleaningRecordSchema.index({ tenantId: 1, itemId: 1, sentDate: -1 });
