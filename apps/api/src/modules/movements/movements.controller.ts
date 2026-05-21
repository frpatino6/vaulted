import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  Req,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { Request } from 'express';
import { MovementsService } from './movements.service';
import { CreateMovementDto } from './dto/create-movement.dto';
import { UpdateMovementDto } from './dto/update-movement.dto';
import { AddMovementItemDto } from './dto/add-movement-item.dto';
import { QuickTransferDto } from './dto/quick-transfer.dto';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { AuditService } from '../audit/audit.service';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Movements')
@Controller('movements')
export class MovementsController {
  constructor(
    private readonly movementsService: MovementsService,
    private readonly auditService: AuditService,
  ) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Post()
  @ApiOperation({ summary: 'Create movement' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Movement created' })
  async create(
    @Body() dto: CreateMovementDto,
    @CurrentUser() user: JwtPayload,
    @Req() req: Request,
  ) {
    const movement = await this.movementsService.create(dto, user);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'movement.created',
      entityType: 'movement',
      entityId: (movement as any)._id?.toString(),
      metadata: { operationType: dto.operationType, title: dto.title },
      ipAddress: req.ip ?? 'unknown',
    });
    return movement;
  }

  @Get()
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @ApiOperation({ summary: 'Get all movements' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Movements retrieved' })
  async findAll(
    @CurrentUser() user: JwtPayload,
    @Query('status') status?: string,
    @Query('operationType') operationType?: string,
  ) {
    return this.movementsService.findAll(user, {
      status,
      operationType,
    });
  }

  @Get('draft')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @ApiOperation({ summary: 'Get active draft movements' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Drafts retrieved' })
  async getActiveDrafts(@CurrentUser() user: JwtPayload) {
    return this.movementsService.findActiveDrafts(user.sub, user.tenantId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('quick-transfer')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Immediately transfer a single item to another room' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Transfer completed' })
  async quickTransfer(
    @Body() dto: QuickTransferDto,
    @CurrentUser() user: JwtPayload,
    @Req() req: Request,
  ) {
    const movement = await this.movementsService.quickTransfer(dto, user);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'movement.quick_transfer',
      entityType: 'movement',
      entityId: (movement as any)._id?.toString(),
      metadata: {
        itemId: dto.itemId,
        destinationPropertyId: dto.destinationPropertyId,
        destinationRoomId: dto.destinationRoomId,
      },
      ipAddress: req.ip ?? 'unknown',
    });
    return movement;
  }

  @Get(':id')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @ApiOperation({ summary: 'Get movement by ID' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Movement retrieved' })
  async findOne(@Param('id') id: string, @CurrentUser() user: JwtPayload) {
    return this.movementsService.findOne(id, user.tenantId, user);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Patch(':id')
  @ApiOperation({ summary: 'Update movement' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Movement updated' })
  async update(
    @Param('id') id: string,
    @Body() dto: UpdateMovementDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.movementsService.update(id, dto, user.tenantId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/items')
  @ApiOperation({ summary: 'Add item to movement' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Item added' })
  async addItem(
    @Param('id') movementId: string,
    @Body() dto: AddMovementItemDto,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.movementsService.addItem(movementId, dto.itemId, user);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete(':id/items/:itemId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Remove item from movement' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Item removed' })
  async removeItem(
    @Param('id') movementId: string,
    @Param('itemId') itemId: string,
    @CurrentUser() user: JwtPayload,
  ) {
    return this.movementsService.removeItem(movementId, itemId, user.tenantId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/activate')
  @HttpCode(HttpStatus.OK)
  async activate(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
    @Req() req: Request,
  ) {
    const movement = await this.movementsService.activate(id, user);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'movement.activated',
      entityType: 'movement',
      entityId: id,
      metadata: { itemCount: (movement as any).items?.length },
      ipAddress: req.ip ?? 'unknown',
    });
    return movement;
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @Post(':id/checkin')
  @HttpCode(HttpStatus.OK)
  async checkinItem(
    @Param('id') movementId: string,
    @Body() body: { itemId: string },
    @CurrentUser() user: JwtPayload,
  ) {
    return this.movementsService.checkinItem(movementId, body.itemId, user);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @Post(':id/complete')
  @HttpCode(HttpStatus.OK)
  async complete(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
    @Req() req: Request,
  ) {
    const movement = await this.movementsService.complete(id, user);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'movement.completed',
      entityType: 'movement',
      entityId: id,
      metadata: { finalStatus: (movement as any).status },
      ipAddress: req.ip ?? 'unknown',
    });
    return movement;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/cancel')
  @HttpCode(HttpStatus.OK)
  async cancel(
    @Param('id') id: string,
    @CurrentUser() user: JwtPayload,
    @Req() req: Request,
  ) {
    const movement = await this.movementsService.cancel(id, user);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'movement.cancelled',
      entityType: 'movement',
      entityId: id,
      metadata: {},
      ipAddress: req.ip ?? 'unknown',
    });
    return movement;
  }
}
