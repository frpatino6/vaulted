import {
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { AuditService } from '../audit/audit.service';
import { Role } from '../../common/enums/role.enum';
import { CompleteStepDto } from './dto/complete-step.dto';
import { CreatePlanDto } from './dto/create-plan.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';
import {
  OrchestratorPlan,
  OrchestratorPlanDocument,
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

  constructor(
    @InjectModel(OrchestratorPlan.name)
    private readonly planModel: Model<OrchestratorPlanDocument>,
    private readonly auditService: AuditService,
  ) {}

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

    return { items, total };
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
      plan.taskGroups = filteredGroups;
    }

    return plan;
  }

  async update(
    tenantId: string,
    planId: string,
    userId: string,
    dto: UpdatePlanDto,
  ): Promise<OrchestratorPlanDocument> {
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
  ): Promise<OrchestratorPlanDocument> {
    const plan = await this.planModel
      .findOneAndUpdate(
        { _id: planId, tenantId },
        { $set: { status: 'cancelled', cancelledAt: new Date() } },
        { new: true },
      )
      .exec();

    if (!plan) throw new NotFoundException('Plan not found');

    await this.auditService.log({
      tenantId,
      userId,
      action: 'plan.cancelled',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: {},
    });

    return plan;
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
      return filteredPlan;
    }

    return plan;
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
      return plan;
    });
  }
}
