import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { CreateUserDirectDto } from './dto/create-user-direct.dto';
import { InviteUserDto } from './dto/invite-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';
import { AuditService } from '../audit/audit.service';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Users')
@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly auditService: AuditService,
  ) {}

  @Roles(Role.OWNER)
  @Post()
  async createDirect(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateUserDirectDto,
    @Req() req: Request,
  ) {
    const created = await this.usersService.createDirect(user.tenantId, dto);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'user.create_direct',
      entityType: 'user',
      entityId: created.id,
      metadata: { role: created.role, propertyCount: created.propertyIds.length },
      ipAddress: req.ip ?? 'unknown',
    });
    return created;
  }

  @Roles(Role.OWNER)
  @Post('invite')
  @ApiOperation({ summary: 'Invite a new user' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'User invited' })
  async invite(
    @CurrentUser() user: JwtPayload,
    @Body() dto: InviteUserDto,
    @Req() req: Request,
  ) {
    const result = await this.usersService.invite(user.tenantId, user.sub, user.role, dto);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'user.invite',
      entityType: 'user',
      entityId: result.email,
      metadata: { role: dto.role, propertyCount: dto.propertyIds.length },
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  @Roles(Role.OWNER)
  @Get()
  @ApiOperation({ summary: 'Get all users' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Users retrieved' })
  findAll(@CurrentUser() user: JwtPayload) {
    return this.usersService.findAllByTenant(user.tenantId);
  }

  @Roles(Role.OWNER)
  @Get(':id')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'User retrieved' })
  findById(@CurrentUser() user: JwtPayload, @Param('id') userId: string) {
    return this.usersService.findSanitizedById(user.tenantId, userId);
  }

  @Roles(Role.OWNER)
  @Put(':id')
  @ApiOperation({ summary: 'Update user' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'User updated' })
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') userId: string,
    @Body() dto: UpdateUserDto,
    @Req() req: Request,
  ) {
    const updated = await this.usersService.updateUser(
      user.tenantId,
      user.sub,
      user.role,
      userId,
      dto,
    );
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'user.update',
      entityType: 'user',
      entityId: userId,
      metadata: {
        roleChanged: dto.role !== undefined,
        activeChanged: dto.isActive !== undefined,
        propertyIdsChanged: dto.propertyIds !== undefined,
      },
      ipAddress: req.ip ?? 'unknown',
    });
    return updated;
  }

  @Roles(Role.OWNER)
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Deactivate user' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'User deactivated' })
  async delete(
    @CurrentUser() user: JwtPayload,
    @Param('id') userId: string,
    @Req() req: Request,
  ) {
    const result = await this.usersService.deactivateUser(user.tenantId, user.sub, userId);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'user.deactivate',
      entityType: 'user',
      entityId: userId,
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }
}
