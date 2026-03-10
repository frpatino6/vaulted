import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type PropertyDocument = HydratedDocument<Property>;

@Schema({ _id: false })
export class Address {
  @Prop({ required: true, trim: true })
  street!: string;

  @Prop({ required: true, trim: true })
  city!: string;

  @Prop({ required: true, trim: true })
  state!: string;

  @Prop({ required: true, trim: true })
  zip!: string;

  @Prop({ required: true, trim: true })
  country!: string;
}

@Schema({ _id: false })
export class Room {
  @Prop({ required: true })
  roomId!: string;

  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({ required: true, trim: true })
  type!: string;
}

@Schema({ _id: false })
export class Floor {
  @Prop({ required: true })
  floorId!: string;

  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({ type: [Room], default: [] })
  rooms!: Room[];
}

@Schema({ timestamps: true, collection: 'properties' })
export class Property {
  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true, trim: true })
  name!: string;

  @Prop({
    required: true,
    enum: ['primary', 'vacation', 'rental'],
  })
  type!: 'primary' | 'vacation' | 'rental';

  @Prop({ type: Address, required: true })
  address!: Address;

  @Prop({ type: [Floor], default: [] })
  floors!: Floor[];

  @Prop({ type: [String], default: [] })
  photos!: string[];
}

export const AddressSchema = SchemaFactory.createForClass(Address);
export const RoomSchema = SchemaFactory.createForClass(Room);
export const FloorSchema = SchemaFactory.createForClass(Floor);
export const PropertySchema = SchemaFactory.createForClass(Property);
