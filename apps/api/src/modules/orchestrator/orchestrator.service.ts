import {
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';
import { AuditService } from '../audit/audit.service';
import { MediaService } from '../media/media.service';
import { NotificationsService } from '../notifications/notifications.service';
import { Item, ItemDocument } from '../inventory/schemas/item.schema';
import { Role } from '../../common/enums/role.enum';
import { AddGroupDto } from './dto/add-group.dto';
import { AddManualStepDto } from './dto/add-manual-step.dto';
import { CompleteStepDto } from './dto/complete-step.dto';
import { CreatePlanDto } from './dto/create-plan.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';
import { OrchestratorGateway } from './orchestrator.gateway';
import {
  OrchestratorPlan,
  OrchestratorPlanDocument,
  OrchestratorStep,
} from './schemas/orchestrator-plan.schema';

export interface PlanListQuery {
  status?: string;
  propertyId?: string;
  page?: number;
  limit?: number;
}

export interface PlanProgressDto {
  planId: string;
  status: string;
  totalSteps: number;
  completedSteps: number;
  percentComplete: number;
  byGroup: Array<{
    groupId: string;
    title: string;
    assignedUserId: string;
    assignedUserName: string;
    status: string;
    totalSteps: number;
    completedSteps: number;
  }>;
}

@Injectable()
export class OrchestratorService {
  private readonly logger = new Logger(OrchestratorService.name);

  private readonly appUrl: string;

  constructor(
    @InjectModel(OrchestratorPlan.name)
    private readonly planModel: Model<OrchestratorPlanDocument>,
    @InjectModel(Item.name)
    private readonly itemModel: Model<ItemDocument>,
    private readonly auditService: AuditService,
    private readonly mediaService: MediaService,
    private readonly notificationsService: NotificationsService,
    private readonly orchestratorGateway: OrchestratorGateway,
    config: ConfigService,
  ) {
    this.appUrl = (config.get<string>('APP_URL') ?? 'http://localhost:3000').replace(/\/+$/, '');
  }

  /**
   * Signs all photo URLs inside every step of every task group.
   * Photos are stored as raw file keys (e.g. "tenantId/uuid.jpg") and must be
   * converted to short-lived signed media tokens before being sent to the client.
   */
  private signPlanPhotos(
    plan: OrchestratorPlanDocument,
    tenantId: string,
    userId: string,
  ): OrchestratorPlanDocument {
    const sign = (url: string | undefined): string | undefined => {
      if (!url) return undefined;
      const token = this.mediaService.generateFileToken(url, tenantId, userId);
      return `${this.appUrl}/api/media/${token}`;
    };

    const signedGroups = plan.taskGroups.map((group) => {
      const signedSteps = group.steps.map((step) => {
        const obj = (step.toObject ? step.toObject() : { ...step }) as OrchestratorStep;
        return {
          ...obj,
          itemPhoto: sign(obj.itemPhoto),
          roomPhoto: sign(obj.roomPhoto),
          sectionPhoto: sign(obj.sectionPhoto),
        };
      });
      const groupObj = group.toObject ? group.toObject() : { ...group };
      return { ...groupObj, steps: signedSteps };
    });

    const planObj = plan.toObject();
    return { ...planObj, taskGroups: signedGroups } as unknown as OrchestratorPlanDocument;
  }

  async create(
    tenantId: string,
    userId: string,
    dto: CreatePlanDto,
  ): Promise<OrchestratorPlanDocument> {
    const plan = await this.planModel.create({
      tenantId,
      title: dto.title,
      originalCommand: dto.originalCommand,
      commandType: dto.commandType ?? 'general',
      targetDate: dto.targetDate ? new Date(dto.targetDate) : undefined,
      targetPropertyId: dto.targetPropertyId,
      targetRoomId: dto.targetRoomId,
      destinationPropertyId: dto.destinationPropertyId,
      aiSummary: dto.aiSummary ?? '',
      taskGroups: dto.taskGroups,
      status: 'draft',
      createdBy: userId,
    });

    await this.auditService.log({
      tenantId,
      userId,
      action: 'plan.created',
      entityType: 'orchestrator_plan',
      entityId: String(plan._id),
      metadata: { title: dto.title, commandType: plan.commandType },
    });

    return plan;
  }

  async findAll(
    tenantId: string,
    userId: string,
    role: Role,
    query: PlanListQuery,
  ): Promise<{ items: OrchestratorPlanDocument[]; total: number }> {
    const page = query.page ?? 1;
    const limit = Math.min(query.limit ?? 20, 100);
    const skip = (page - 1) * limit;

    const filter: Record<string, unknown> = { tenantId };

    if (query.status) {
      filter.status = query.status;
    }

    if (query.propertyId) {
      filter.targetPropertyId = query.propertyId;
    }

    if (role === Role.STAFF) {
      filter['taskGroups.assignedUserId'] = userId;
    }

    const [items, total] = await Promise.all([
      this.planModel.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).exec(),
      this.planModel.countDocuments(filter).exec(),
    ]);

    return {
      items: items.map((plan) => this.signPlanPhotos(plan, tenantId, userId)),
      total,
    };
  }

  async findOne(
    tenantId: string,
    planId: string,
    userId: string,
    role: Role,
  ): Promise<OrchestratorPlanDocument> {
    const plan = await this.planModel
      .findOne({ _id: planId, tenantId })
      .exec();

    if (!plan) {
      throw new NotFoundException('Plan not found');
    }

    if (role === Role.STAFF) {
      const filteredGroups = plan.taskGroups.filter(
        (g) => g.assignedUserId === userId,
      );

      if (filteredGroups.length === 0) {
        throw new ForbiddenException('Plan not found for assigned staff user');
      }

      plan.taskGroups = filteredGroups;
    }

    return this.signPlanPhotos(plan, tenantId, userId);
  }

  async update(
    tenantId: string,
    planId: string,
    userId: string,
    dto: UpdatePlanDto,
  ): Promise<OrchestratorPlanDocument | { deleted: true }> {
    const existing = await this.planModel
      .findOne({ _id: planId, tenantId })
      .exec();

    if (!existing) {
      throw new NotFoundException('Plan not found');
    }

    if (dto.status === 'cancelled') {
      return this.cancel(tenantId, planId, userId);
    }

    const updateData: Record<string, unknown> = {};

    if (dto.title !== undefined) updateData.title = dto.title;
    if (dto.targetDate !== undefined) updateData.targetDate = new Date(dto.targetDate);

    if (dto.taskGroups !== undefined) {
      const updatedGroups = existing.taskGroups.map((group) => {
        const patch = dto.taskGroups!.find((g) => g.groupId === group.groupId);
        if (!patch) return group;
        return {
          ...group.toObject(),
          title: patch.title ?? group.title,
          assignedUserId: patch.assignedUserId ?? group.assignedUserId,
          assignedUserName: patch.assignedUserName ?? group.assignedUserName,
        };
      });
      updateData.taskGroups = updatedGroups;
    }

    const updated = await this.planModel
      .findOneAndUpdate(
        { _id: planId, tenantId },
        { $set: updateData },
        { new: true },
      )
      .exec();

    if (!updated) throw new NotFoundException('Plan not found');

    await this.auditService.log({
      tenantId,
      userId,
      action: 'plan.updated',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: { fields: Object.keys(updateData) },
    });

    return updated;
  }

  async cancel(
    tenantId: string,
    planId: string,
    userId: string,
  ): Promise<OrchestratorPlanDocument | { deleted: true }> {
    const plan = await this.planModel
      .findOne({ _id: planId, tenantId })
      .exec();

    if (!plan) throw new NotFoundException('Plan not found');

    if (plan.status === 'draft') {
      await this.planModel.findOneAndDelete({ _id: planId, tenantId }).exec();

      await this.auditService.log({
        tenantId,
        userId,
        action: 'plan.deleted',
        entityType: 'orchestrator_plan',
        entityId: planId,
        metadata: { reason: 'cancelled_while_draft' },
      });

      return { deleted: true };
    }

    const cancelled = await this.planModel
      .findOneAndUpdate(
        { _id: planId, tenantId },
        { $set: { status: 'cancelled', cancelledAt: new Date() } },
        { new: true },
      )
      .exec();

    if (!cancelled) throw new NotFoundException('Plan not found');

    await this.auditService.log({
      tenantId,
      userId,
      action: 'plan.cancelled',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: {},
    });

    return cancelled;
  }

  async publishPlan(
    tenantId: string,
    planId: string,
    userId: string,
  ): Promise<OrchestratorPlanDocument> {
    const plan = await this.planModel
      .findOne({ _id: planId, tenantId })
      .exec();

    if (!plan) throw new NotFoundException('Plan not found');

    if (plan.status !== 'draft') {
      throw new ForbiddenException('Only draft plans can be published');
    }

    const unassigned = plan.taskGroups.filter((g) => !g.assignedUserId);
    if (unassigned.length > 0) {
      throw new ForbiddenException(
        'All task groups must have an assigned user before publishing',
      );
    }

    const published = await this.planModel
      .findOneAndUpdate(
        { _id: planId, tenantId },
        { $set: { status: 'published', publishedAt: new Date() } },
        { new: true },
      )
      .exec();

    if (!published) throw new NotFoundException('Plan not found');

    await this.auditService.log({
      tenantId,
      userId,
      action: 'plan.published',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: { groupCount: plan.taskGroups.length },
    });

    const assigneeIds = [
      ...new Set(
        plan.taskGroups
          .map((g) => g.assignedUserId)
          .filter((id): id is string => typeof id === 'string' && id.length > 0),
      ),
    ];

    if (assigneeIds.length > 0) {
      try {
        await this.notificationsService.sendPush({
          tenantId,
          userIds: assigneeIds,
          title: 'New task plan assigned',
          body: `You have been assigned to: ${plan.title}`,
          data: { type: 'orchestrator_assigned', planId, planTitle: plan.title },
        });
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        this.logger.warn(`orchestrator_assigned push failed: ${message}`);
      }
    }

    return published;
  }

  async completeStep(
    tenantId: string,
    planId: string,
    groupId: string,
    stepId: string,
    userId: string,
    role: Role,
    dto: CompleteStepDto,
  ): Promise<OrchestratorPlanDocument> {
    const plan = await this.planModel
      .findOne({ _id: planId, tenantId })
      .exec();

    if (!plan) throw new NotFoundException('Plan not found');

    const group = plan.taskGroups.find((g) => g.groupId === groupId);
    if (!group) throw new NotFoundException('Task group not found');

    const isOwnerOrManager = role === Role.OWNER || role === Role.MANAGER;
    if (!isOwnerOrManager && group.assignedUserId !== userId) {
      throw new ForbiddenException('You are not assigned to this task group');
    }

    const step = group.steps.find((s) => s.stepId === stepId);
    if (!step) throw new NotFoundException('Step not found');

    step.status = 'done';
    step.completedByUserId = userId;
    step.completedAt = new Date();
    if (dto.note !== undefined) step.note = dto.note;
    if (dto.completionPhotoUrl !== undefined) step.completionPhotoUrl = dto.completionPhotoUrl;

    if (group.status === 'pending') {
      group.status = 'in_progress';
      group.startedAt = group.startedAt ?? new Date();
    }

    const allStepsDone = group.steps.every((s) => s.status === 'done' || s.status === 'skipped');
    if (allStepsDone) {
      group.status = 'completed';
      group.completedAt = new Date();
    }

    const allGroupsDone = plan.taskGroups.every((g) => g.status === 'completed');
    if (allGroupsDone) {
      plan.status = 'completed';
      plan.completedAt = new Date();
    } else if (plan.status === 'published') {
      plan.status = 'in_progress';
    }

    plan.markModified('taskGroups');
    await plan.save();

    const totalSteps = plan.taskGroups.reduce((sum, g) => sum + g.steps.length, 0);
    const completedStepsCount = plan.taskGroups.reduce(
      (sum, g) => sum + g.steps.filter((s) => s.status === 'done' || s.status === 'skipped').length,
      0,
    );
    const percentComplete =
      totalSteps > 0 ? Math.round((completedStepsCount / totalSteps) * 100) : 0;

    this.orchestratorGateway.emitStepCompleted(tenantId, {
      planId,
      groupId,
      stepId,
      completedByUserId: userId,
      percentComplete,
    });

    if (plan.status === 'completed') {
      this.orchestratorGateway.emitPlanCompleted(tenantId, {
        planId,
        title: plan.title,
      });

      try {
        await this.notificationsService.notifyTenantRoles({
          tenantId,
          roles: [Role.OWNER, Role.MANAGER],
          type: 'orchestrator_completed',
          title: 'Plan completed',
          body: `The plan "${plan.title}" has been fully completed.`,
          data: { type: 'orchestrator_completed', planId, planTitle: plan.title },
        });
      } catch (err) {
        const message = err instanceof Error ? err.message : String(err);
        this.logger.warn(`orchestrator_completed notification failed: ${message}`);
      }
    }

    await this.auditService.log({
      tenantId,
      userId,
      action: 'step.completed',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: { groupId, stepId, planCompleted: plan.status === 'completed' },
    });

    if (role === Role.STAFF) {
      const filteredPlan = await this.planModel
        .findOne({ _id: planId, tenantId })
        .exec();
      if (!filteredPlan) throw new NotFoundException('Plan not found');
      filteredPlan.taskGroups = filteredPlan.taskGroups.filter(
        (g) => g.assignedUserId === userId,
      );
      return this.signPlanPhotos(filteredPlan, tenantId, userId);
    }

    return this.signPlanPhotos(plan, tenantId, userId);
  }

  async getProgress(
    tenantId: string,
    planId: string,
  ): Promise<PlanProgressDto> {
    const plan = await this.planModel
      .findOne({ _id: planId, tenantId })
      .exec();

    if (!plan) throw new NotFoundException('Plan not found');

    let totalSteps = 0;
    let completedSteps = 0;

    const byGroup = plan.taskGroups.map((group) => {
      const groupTotal = group.steps.length;
      const groupCompleted = group.steps.filter(
        (s) => s.status === 'done',
      ).length;
      totalSteps += groupTotal;
      completedSteps += groupCompleted;

      return {
        groupId: group.groupId,
        title: group.title,
        assignedUserId: group.assignedUserId ?? '',
        assignedUserName: group.assignedUserName ?? '',
        status: group.status,
        totalSteps: groupTotal,
        completedSteps: groupCompleted,
      };
    });

    const percentComplete =
      totalSteps > 0 ? Math.round((completedSteps / totalSteps) * 100) : 0;

    return {
      planId: String(plan._id),
      status: plan.status,
      totalSteps,
      completedSteps,
      percentComplete,
      byGroup,
    };
  }

  async getMyTasks(
    tenantId: string,
    userId: string,
  ): Promise<OrchestratorPlanDocument[]> {
    const plans = await this.planModel
      .find({
        tenantId,
        'taskGroups.assignedUserId': userId,
        status: { $in: ['published', 'in_progress'] },
      })
      .sort({ createdAt: -1 })
      .exec();

    return plans.map((plan) => {
      plan.taskGroups = plan.taskGroups.filter(
        (g) => g.assignedUserId === userId,
      );
      return this.signPlanPhotos(plan, tenantId, userId);
    });
  }

  async addGroup(
    tenantId: string,
    planId: string,
    userId: string,
    dto: AddGroupDto,
  ): Promise<OrchestratorPlanDocument> {
    const plan = await this.planModel
      .findOne({ _id: planId, tenantId })
      .exec();

    if (!plan) throw new NotFoundException('Plan not found');

    if (plan.status !== 'draft') {
      throw new ForbiddenException('Groups can only be added to draft plans');
    }

    plan.taskGroups.push({
      groupId: uuidv4(),
      title: dto.title,
      status: 'pending',
      steps: [],
    } as unknown as (typeof plan.taskGroups)[number]);

    plan.markModified('taskGroups');
    await plan.save();

    await this.auditService.log({
      tenantId,
      userId,
      action: 'plan.group.added',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: { title: dto.title },
    });

    return this.signPlanPhotos(plan, tenantId, userId);
  }

  async addManualStep(
    tenantId: string,
    planId: string,
    groupId: string,
    userId: string,
    dto: AddManualStepDto,
  ): Promise<OrchestratorPlanDocument> {
    const plan = await this.planModel
      .findOne({ _id: planId, tenantId })
      .exec();

    if (!plan) throw new NotFoundException('Plan not found');

    if (plan.status !== 'draft') {
      throw new ForbiddenException('Steps can only be added to draft plans');
    }

    const group = plan.taskGroups.find((g) => g.groupId === groupId);
    if (!group) throw new NotFoundException('Task group not found');

    const item = await this.itemModel
      .findOne({ _id: dto.itemId, tenantId })
      .exec();

    if (!item) throw new NotFoundException('Item not found');

    const step: OrchestratorStep = {
      stepId: uuidv4(),
      itemId: item._id.toString(),
      itemName: item.name,
      itemCategory: String(item.category),
      itemPhoto: item.photos?.[0] ?? undefined,
      roomId: item.roomId ?? undefined,
      roomName: (item as ItemDocument & { roomName?: string }).roomName ?? undefined,
      sectionId: item.sectionId ?? undefined,
      sectionCode: (item as ItemDocument & { sectionCode?: string }).sectionCode ?? undefined,
      sectionFurnitureName: (item as ItemDocument & { sectionFurnitureName?: string }).sectionFurnitureName ?? undefined,
      sectionPhoto: (item as ItemDocument & { sectionPhoto?: string }).sectionPhoto ?? undefined,
      boundingBox: (item as ItemDocument & { sectionBoundingBox?: OrchestratorStep['boundingBox'] }).sectionBoundingBox ?? undefined,
      instruction: dto.instruction,
      status: 'pending',
    };

    group.steps.push(step);
    plan.markModified('taskGroups');
    await plan.save();

    await this.auditService.log({
      tenantId,
      userId,
      action: 'plan.step.added',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: { groupId, itemId: dto.itemId, itemName: item.name },
    });

    return this.signPlanPhotos(plan, tenantId, userId);
  }
}
