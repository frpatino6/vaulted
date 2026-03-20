import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type MaintenanceRecordDocument = HydratedDocument<MaintenanceRecord>;

export type MaintenanceStatus = 'pending' | 'completed' | 'overdue' | 'cancelled';

@Schema({ timestamps: true, collection: 'maintenance_records' })
export class MaintenanceRecord {
  @Prop({ required: true, index: true })
  itemId!: string;

  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true, trim: true })
  title!: string;

  @Prop({ trim: true })
  description?: string;

  @Prop({
    enum: ['pending', 'completed', 'overdue', 'cancelled'],
    default: 'pending',
    index: true,
  })
  status!: MaintenanceStatus;

  @Prop({ required: true, index: true })
  scheduledDate!: Date;

  @Prop()
  completedDate?: Date;

  @Prop({ default: false })
  isRecurring!: boolean;

  @Prop()
  recurrenceIntervalDays?: number;

  @Prop()
  nextScheduledDate?: Date;

  @Prop({ trim: true })
  providerName?: string;

  @Prop({ trim: true })
  providerContact?: string;

  @Prop()
  cost?: number;

  @Prop({ default: 'USD' })
  currency!: string;

  @Prop({ trim: true })
  notes?: string;

  @Prop({ type: [String], default: [] })
  documents!: string[];

  @Prop({ default: false })
  isAiSuggested!: boolean;

  @Prop()
  aiRiskScore?: number;

  @Prop({ trim: true })
  aiReason?: string;

  @Prop({ required: true })
  createdBy!: string;
}

export const MaintenanceRecordSchema = SchemaFactory.createForClass(MaintenanceRecord);

MaintenanceRecordSchema.index({ tenantId: 1, scheduledDate: 1 });
MaintenanceRecordSchema.index({ itemId: 1, status: 1 });
