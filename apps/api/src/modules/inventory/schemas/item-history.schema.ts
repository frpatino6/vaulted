import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type ItemHistoryDocument = HydratedDocument<ItemHistory>;

@Schema({ collection: 'item_history' })
export class ItemHistory {
  @Prop({ required: true, index: true })
  itemId!: string;

  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({
    required: true,
    enum: [
      'moved',
      'loaned',
      'returned',
      'repaired',
      'valued',
      'status_changed',
      'maintenance_scheduled',
      'maintenance_completed',
      'maintenance_ai_suggested',
    ],
  })
  action!:
    | 'moved'
    | 'loaned'
    | 'returned'
    | 'repaired'
    | 'valued'
    | 'status_changed'
    | 'maintenance_scheduled'
    | 'maintenance_completed'
    | 'maintenance_ai_suggested';

  @Prop()
  fromPropertyId?: string;

  @Prop()
  toPropertyId?: string;

  @Prop()
  fromRoomId?: string;

  @Prop()
  toRoomId?: string;

  @Prop({ required: true })
  performedBy!: string;

  @Prop()
  notes?: string;

  @Prop({ default: Date.now })
  timestamp!: Date;
}

export const ItemHistorySchema = SchemaFactory.createForClass(ItemHistory);
