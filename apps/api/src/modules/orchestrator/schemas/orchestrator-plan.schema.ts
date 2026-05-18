import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

export type OrchestratorPlanDocument = HydratedDocument<OrchestratorPlan>;

export type CommandType = 'prepare' | 'pack' | 'move' | 'inspect' | 'general';
export type PlanStatus = 'draft' | 'published' | 'in_progress' | 'completed' | 'cancelled';
export type GroupStatus = 'pending' | 'in_progress' | 'completed';
export type StepStatus = 'pending' | 'done' | 'skipped' | 'orphaned';

export interface BoundingBox {
  x: number;
  y: number;
  width: number;
  height: number;
}

@Schema({ _id: false })
export class OrchestratorStep {
  @Prop({ required: true })
  stepId!: string;

  @Prop({ required: true })
  itemId!: string;

  @Prop({ required: true })
  itemName!: string;

  @Prop({ required: true })
  itemCategory!: string;

  @Prop()
  itemPhoto?: string;

  @Prop()
  roomId?: string;

  @Prop()
  roomName?: string;

  @Prop()
  roomPhoto?: string;

  @Prop()
  sectionId?: string;

  @Prop()
  sectionPhoto?: string;

  @Prop()
  sectionCode?: string;

  @Prop()
  sectionFurnitureName?: string;

  @Prop({ type: Object })
  boundingBox?: BoundingBox;

  @Prop({ required: true })
  instruction!: string;

  @Prop({
    type: String,
    enum: ['pending', 'done', 'skipped', 'orphaned'],
    default: 'pending',
  })
  status!: StepStatus;

  @Prop()
  completedByUserId?: string;

  @Prop()
  completedAt?: Date;

  @Prop()
  note?: string;

  @Prop()
  completionPhotoUrl?: string;
}

export const OrchestratorStepSchema = SchemaFactory.createForClass(OrchestratorStep);

@Schema({ _id: false })
export class OrchestratorTaskGroup {
  @Prop({ required: true })
  groupId!: string;

  @Prop({ required: true })
  title!: string;

  @Prop()
  assignedUserId?: string;

  @Prop()
  assignedUserName?: string;

  @Prop({
    type: String,
    enum: ['pending', 'in_progress', 'completed'],
    default: 'pending',
  })
  status!: GroupStatus;

  @Prop({ type: [OrchestratorStepSchema], default: [] })
  steps!: OrchestratorStep[];

  @Prop()
  startedAt?: Date;

  @Prop()
  completedAt?: Date;
}

export const OrchestratorTaskGroupSchema = SchemaFactory.createForClass(OrchestratorTaskGroup);

@Schema({ timestamps: true, collection: 'orchestrator_plans' })
export class OrchestratorPlan {
  @Prop({ required: true, index: true })
  tenantId!: string;

  @Prop({ required: true, trim: true, maxlength: 200 })
  title!: string;

  @Prop({ required: true, trim: true, maxlength: 2000 })
  originalCommand!: string;

  @Prop({
    type: String,
    enum: ['prepare', 'pack', 'move', 'inspect', 'general'],
    default: 'general',
  })
  commandType!: CommandType;

  @Prop()
  targetDate?: Date;

  @Prop()
  targetPropertyId?: string;

  @Prop()
  targetRoomId?: string;

  @Prop()
  destinationPropertyId?: string;

  @Prop({
    type: String,
    enum: ['draft', 'published', 'in_progress', 'completed', 'cancelled'],
    default: 'draft',
  })
  status!: PlanStatus;

  @Prop({ default: '' })
  aiSummary!: string;

  @Prop({ type: [OrchestratorTaskGroupSchema], default: [] })
  taskGroups!: OrchestratorTaskGroup[];

  @Prop({ required: true })
  createdBy!: string;

  @Prop()
  publishedAt?: Date;

  @Prop()
  completedAt?: Date;

  @Prop()
  cancelledAt?: Date;
}

export const OrchestratorPlanSchema = SchemaFactory.createForClass(OrchestratorPlan);

OrchestratorPlanSchema.index({ tenantId: 1, status: 1 });
OrchestratorPlanSchema.index({ tenantId: 1, createdAt: -1 });
OrchestratorPlanSchema.index({ tenantId: 1, 'taskGroups.assignedUserId': 1 });
