import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type MovementDocument = HydratedDocument<Movement>;

export enum MovementType {
  TRANSFER = 'transfer',
  LOAN = 'loan',
  REPAIR = 'repair',
  DISPOSAL = 'disposal',
}

export enum MovementStatus {
  DRAFT = 'draft',
  ACTIVE = 'active',
  COMPLETED = 'completed',
  PARTIAL = 'partial',
  CANCELLED = 'cancelled',
}

export enum MovementItemStatus {
  OUT = 'out',
  RETURNED = 'returned',
  MISSING = 'missing',
}

@Schema({ _id: false })
export class MovementItem {
  @Prop({ required: true })
  itemId!: string;

  @Prop({ required: true })
  itemName!: string;

  @Prop({ default: '' })
  itemCategory!: string;

  @Prop({ default: '' })
  itemPhoto!: string;

  @Prop({ default: '' })
  fromPropertyId!: string;

  @Prop({ default: '' })
  fromRoomId!: string;

  @Prop({ default: '' })
  fromPropertyName!: string;

  @Prop({ default: '' })
  fromRoomName!: string;

  @Prop({ default: Date.now })
  scannedAt!: Date;

  @Prop({ type: Date, default: null })
  checkedInAt!: Date | null;

  @Prop({ default: null })
  checkedInBy!: string | null;

  @Prop({
    type: String,
    enum: Object.values(MovementItemStatus),
    default: MovementItemStatus.OUT,
  })
  status!: string;
}

export const MovementItemSchema = SchemaFactory.createForClass(MovementItem);

@Schema({ timestamps: true, collection: 'movements' })
export class Movement {
  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ default: '' })
  propertyId!: string;

  @Prop({ required: true, type: String, enum: Object.values(MovementType) })
  operationType!: string;

  @Prop({
    type: String,
    enum: Object.values(MovementStatus),
    default: MovementStatus.DRAFT,
    index: true,
  })
  status!: string;

  @Prop({ required: true, maxlength: 120 })
  title!: string;

  @Prop({ default: '' })
  description!: string;

  @Prop({ default: '' })
  destination!: string;

  @Prop({ type: [MovementItemSchema], default: [] })
  items!: MovementItem[];

  @Prop({ required: true })
  createdBy!: string;

  @Prop({ type: Date, default: null })
  activatedAt!: Date | null;

  @Prop({ type: Date, default: null })
  completedAt!: Date | null;

  @Prop({ type: Date, default: null })
  dueDate!: Date | null;

  @Prop({ default: '' })
  notes!: string;
}

export const MovementSchema = SchemaFactory.createForClass(Movement);
MovementSchema.index({ tenantId: 1, status: 1 });
MovementSchema.index({ tenantId: 1, createdAt: -1 });
