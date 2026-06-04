import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  Req,
} from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { AddGroupDto } from './dto/add-group.dto';
import { AddManualStepDto } from './dto/add-manual-step.dto';
import { CompleteStepDto } from './dto/complete-step.dto';
import { CreatePlanDto } from './dto/create-plan.dto';
import { ParseCommandDto } from './dto/parse-command.dto';
import { UpdatePlanDto } from './dto/update-plan.dto';
import { AuditService } from '../audit/audit.service';
import { OrchestratorAiService } from './orchestrator-ai.service';
import { OrchestratorService } from './orchestrator.service';
import type { Request } from 'express';

@Controller('orchestrator')
export class OrchestratorController {
  constructor(
    private readonly orchestratorService: OrchestratorService,
    private readonly orchestratorAiService: OrchestratorAiService,
    private readonly auditService: AuditService,
  ) {}

  // POST /orchestrator/parse
  @Roles(Role.OWNER, Role.MANAGER)
  @HttpCode(HttpStatus.OK)
  @Post('parse')
  async parseCommand(
    @CurrentUser() user: JwtPayload,
    @Body() dto: ParseCommandDto,
  ) {
    return this.orchestratorAiService.parseCommand(user.tenantId, dto);
  }

  // POST /orchestrator/plans
  @Roles(Role.OWNER, Role.MANAGER)
  @Post('plans')
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreatePlanDto,
    @Req() req: Request,
  ) {
    const result = await this.orchestratorService.create(user.tenantId, user.sub, dto);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'orchestrator.plan.create',
      entityType: 'orchestrator_plan',
      entityId: String(result._id),
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  // GET /orchestrator/plans/my-tasks — must be declared before :id route
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @Get('plans/my-tasks')
  async getMyTasks(@CurrentUser() user: JwtPayload) {
    return this.orchestratorService.getMyTasks(user.tenantId, user.sub);
  }

  // GET /orchestrator/plans
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @Get('plans')
  async findAll(
    @CurrentUser() user: JwtPayload,
    @Query('status') status?: string,
    @Query('propertyId') propertyId?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.orchestratorService.findAll(
      user.tenantId,
      user.sub,
      user.role,
      {
        status,
        propertyId,
        page: page ? Number(page) : undefined,
        limit: limit ? Number(limit) : undefined,
      },
    );
  }

  // GET /orchestrator/plans/:id
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @Get('plans/:id')
  async findOne(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.orchestratorService.findOne(
      user.tenantId,
      id,
      user.sub,
      user.role,
    );
  }

  // PATCH /orchestrator/plans/:id
  @Roles(Role.OWNER, Role.MANAGER)
  @Patch('plans/:id')
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdatePlanDto,
    @Req() req: Request,
  ) {
    const result = await this.orchestratorService.update(user.tenantId, id, user.sub, dto);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'orchestrator.plan.update',
      entityType: 'orchestrator_plan',
      entityId: id,
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  // POST /orchestrator/plans/:id/publish
  @Roles(Role.OWNER, Role.MANAGER)
  @HttpCode(HttpStatus.OK)
  @Post('plans/:id/publish')
  async publish(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Req() req: Request,
  ) {
    const result = await this.orchestratorService.publishPlan(user.tenantId, id, user.sub);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'orchestrator.plan.publish',
      entityType: 'orchestrator_plan',
      entityId: id,
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  // PATCH /orchestrator/plans/:planId/groups/:groupId/steps/:stepId/complete
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @Patch('plans/:planId/groups/:groupId/steps/:stepId/complete')
  async completeStep(
    @CurrentUser() user: JwtPayload,
    @Param('planId') planId: string,
    @Param('groupId') groupId: string,
    @Param('stepId') stepId: string,
    @Body() dto: CompleteStepDto,
    @Req() req: Request,
  ) {
    const result = await this.orchestratorService.completeStep(
      user.tenantId,
      planId,
      groupId,
      stepId,
      user.sub,
      user.role,
      dto,
    );
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'orchestrator.step.complete',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: { groupId, stepId },
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  // GET /orchestrator/plans/:id/progress
  @Roles(Role.OWNER, Role.MANAGER)
  @Get('plans/:id/progress')
  async getProgress(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.orchestratorService.getProgress(user.tenantId, id);
  }

  // POST /orchestrator/plans/:planId/groups
  @Roles(Role.OWNER, Role.MANAGER)
  @Post('plans/:planId/groups')
  async addGroup(
    @CurrentUser() user: JwtPayload,
    @Param('planId') planId: string,
    @Body() dto: AddGroupDto,
    @Req() req: Request,
  ) {
    const result = await this.orchestratorService.addGroup(user.tenantId, planId, user.sub, dto);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'orchestrator.plan.add_group',
      entityType: 'orchestrator_plan',
      entityId: planId,
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  // POST /orchestrator/plans/:planId/groups/:groupId/steps
  @Roles(Role.OWNER, Role.MANAGER)
  @Post('plans/:planId/groups/:groupId/steps')
  async addManualStep(
    @CurrentUser() user: JwtPayload,
    @Param('planId') planId: string,
    @Param('groupId') groupId: string,
    @Body() dto: AddManualStepDto,
    @Req() req: Request,
  ) {
    const result = await this.orchestratorService.addManualStep(
      user.tenantId,
      planId,
      groupId,
      user.sub,
      dto,
    );
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'orchestrator.step.add',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: { groupId },
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  // DELETE /orchestrator/plans/:planId/groups/:groupId
  @Roles(Role.OWNER, Role.MANAGER)
  @Delete('plans/:planId/groups/:groupId')
  @HttpCode(HttpStatus.OK)
  async removeGroup(
    @CurrentUser() user: JwtPayload,
    @Param('planId') planId: string,
    @Param('groupId') groupId: string,
    @Req() req: Request,
  ) {
    const result = await this.orchestratorService.removeGroup(
      user.tenantId,
      planId,
      groupId,
      user.sub,
    );
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'orchestrator.plan.remove_group',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: { groupId },
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  // DELETE /orchestrator/plans/:planId/groups/:groupId/steps/:stepId
  @Roles(Role.OWNER, Role.MANAGER)
  @Delete('plans/:planId/groups/:groupId/steps/:stepId')
  @HttpCode(HttpStatus.OK)
  async removeStep(
    @CurrentUser() user: JwtPayload,
    @Param('planId') planId: string,
    @Param('groupId') groupId: string,
    @Param('stepId') stepId: string,
    @Req() req: Request,
  ) {
    const result = await this.orchestratorService.removeStep(
      user.tenantId,
      planId,
      groupId,
      stepId,
      user.sub,
    );
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'orchestrator.step.remove',
      entityType: 'orchestrator_plan',
      entityId: planId,
      metadata: { groupId, stepId },
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }
}
