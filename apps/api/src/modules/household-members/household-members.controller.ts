import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { AuditService } from '../audit/audit.service';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { CreateHouseholdMemberDto } from './dto/create-household-member.dto';
import { UpdateHouseholdMemberDto } from './dto/update-household-member.dto';
import { HouseholdMembersService } from './household-members.service';

@ApiTags('Household Members')
@Controller('household-members')
export class HouseholdMembersController {
  constructor(
    private readonly householdMembersService: HouseholdMembersService,
    private readonly auditService: AuditService,
  ) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Post()
  @ApiOperation({ summary: 'Create a household member' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Household member created' })
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateHouseholdMemberDto,
    @Req() req: Request,
  ) {
    const member = await this.householdMembersService.create(user.tenantId, user.sub, dto);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'household_member.created',
      entityType: 'household_member',
      entityId: (member as any)._id?.toString() ?? (member as any).id?.toString(),
      metadata: { name: dto.name },
      ipAddress: req.ip ?? 'unknown',
    });
    return member;
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Get()
  @ApiOperation({ summary: 'List household members' })
  @ApiBearerAuth()
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  @ApiResponse({ status: 200, description: 'Household members retrieved' })
  findAll(
    @CurrentUser() user: JwtPayload,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.householdMembersService.findAll(
      user.tenantId,
      includeInactive === 'true',
    );
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Patch(':id')
  @ApiOperation({ summary: 'Update a household member' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Household member updated' })
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') memberId: string,
    @Body() dto: UpdateHouseholdMemberDto,
    @Req() req: Request,
  ) {
    const member = await this.householdMembersService.update(user.tenantId, memberId, dto);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'household_member.updated',
      entityType: 'household_member',
      entityId: memberId,
      metadata: { fields: Object.keys(dto) },
      ipAddress: req.ip ?? 'unknown',
    });
    return member;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete(':id')
  @ApiOperation({ summary: 'Archive a household member' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Household member archived' })
  async archive(
    @CurrentUser() user: JwtPayload,
    @Param('id') memberId: string,
    @Req() req: Request,
  ) {
    const result = await this.householdMembersService.archive(user.tenantId, memberId);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'household_member.archived',
      entityType: 'household_member',
      entityId: memberId,
      metadata: {},
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }
}
