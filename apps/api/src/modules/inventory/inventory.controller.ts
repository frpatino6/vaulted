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
  Query,
  Req,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { Request } from 'express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AnomalyGuard } from '../../common/guards/anomaly.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { AuditService } from '../audit/audit.service';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { CreateItemDto } from './dto/create-item.dto';
import { LoanItemDto } from './dto/loan-item.dto';
import { MoveItemDto } from './dto/move-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { InventoryService } from './inventory.service';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

@ApiTags('Inventory')
@Controller('items')
export class InventoryController {
  constructor(
    private readonly inventoryService: InventoryService,
    private readonly auditService: AuditService,
  ) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Post()
  @ApiOperation({ summary: 'Create a new inventory item' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Item created successfully' })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 403, description: 'Forbidden - insufficient role' })
  async create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateItemDto,
    @Req() req: Request,
  ) {
    const item = await this.inventoryService.create(user.tenantId, user.sub, dto);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'inventory.create',
      entityType: 'item',
      entityId: String((item as { _id?: unknown })._id),
      ipAddress: req.ip,
    });

    return item;
  }

  @Get()
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @ApiOperation({ summary: 'Get all inventory items with filters' })
  @ApiBearerAuth()
  @ApiQuery({ name: 'propertyId', required: false })
  @ApiQuery({ name: 'roomId', required: false })
  @ApiQuery({ name: 'category', required: false })
  @ApiQuery({ name: 'status', required: false })
  @ApiQuery({ name: 'unlocated', required: false })
  @ApiQuery({ name: 'limit', required: false })
  @ApiResponse({ status: 200, description: 'Items retrieved successfully' })
  findAll(
    @CurrentUser() user: JwtPayload,
    @Query('propertyId') propertyId?: string,
    @Query('roomId') roomId?: string,
    @Query('category') category?: string,
    @Query('status') status?: string,
    @Query('unlocated') unlocated?: string,
    @Query('limit') limit?: string,
  ) {
    return this.inventoryService.findAll(
      user.tenantId,
      {
        propertyId,
        roomId,
        category,
        status,
        unlocated: unlocated === 'true',
        limit: limit ? parseInt(limit, 10) : undefined,
      },
      user.role,
      user.sub,
    );
  }

  @Get('search')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @ApiOperation({ summary: 'Search inventory items' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Search results' })
  search(
    @CurrentUser() user: JwtPayload,
    @Query('q') query?: string,
    @Query('category') category?: string,
    @Query('propertyId') propertyId?: string,
    @Query('status') status?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.inventoryService.search(
      user.tenantId,
      {
        query,
        category,
        propertyId,
        status,
        page: page ? Number(page) : undefined,
        limit: limit ? Number(limit) : undefined,
      },
      user.role,
      user.sub,
    );
  }

  @UseGuards(AnomalyGuard)
  @Throttle({ 'inventory-valuation': { ttl: 900_000, limit: 20 } })
  @Get(':id')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @ApiOperation({ summary: 'Get item by ID' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Item retrieved successfully' })
  @ApiResponse({ status: 404, description: 'Item not found' })
  findById(@CurrentUser() user: JwtPayload, @Param('id') itemId: string) {
    return this.inventoryService.findById(user.tenantId, itemId, user.role, user.sub);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put(':id')
  @ApiOperation({ summary: 'Update an inventory item' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Item updated successfully' })
  @ApiResponse({ status: 404, description: 'Item not found' })
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') itemId: string,
    @Body() dto: UpdateItemDto,
    @Req() req: Request,
  ) {
    const item = await this.inventoryService.update(user.tenantId, itemId, dto);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'inventory.update',
      entityType: 'item',
      entityId: itemId,
      ipAddress: req.ip,
    });

    return item;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete an inventory item' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Item deleted successfully' })
  @ApiResponse({ status: 404, description: 'Item not found' })
  async delete(
    @CurrentUser() user: JwtPayload,
    @Param('id') itemId: string,
    @Req() req: Request,
  ) {
    const item = await this.inventoryService.delete(user.tenantId, itemId);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'inventory.delete',
      entityType: 'item',
      entityId: itemId,
      ipAddress: req.ip,
    });

    return item;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/move')
  @ApiOperation({ summary: 'Move item to different property/room' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Item moved successfully' })
  async move(
    @CurrentUser() user: JwtPayload,
    @Param('id') itemId: string,
    @Body() dto: MoveItemDto,
    @Req() req: Request,
  ) {
    const item = await this.inventoryService.move(user.tenantId, itemId, user.sub, dto);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'inventory.move',
      entityType: 'item',
      entityId: itemId,
      metadata: {
        toPropertyId: dto.toPropertyId,
        toRoomId: dto.toRoomId,
      },
      ipAddress: req.ip,
    });

    return item;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/loan')
  @ApiOperation({ summary: 'Loan an item to someone' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Item loaned successfully' })
  async loan(
    @CurrentUser() user: JwtPayload,
    @Param('id') itemId: string,
    @Body() dto: LoanItemDto,
    @Req() req: Request,
  ) {
    const item = await this.inventoryService.loan(user.tenantId, itemId, user.sub, dto);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'inventory.loan',
      entityType: 'item',
      entityId: itemId,
      metadata: {
        borrowerName: dto.borrowerName,
        expectedReturnDate: dto.expectedReturnDate,
      },
      ipAddress: req.ip,
    });

    return item;
  }

  @Get(':id/history')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @ApiOperation({ summary: 'Get item history' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'History retrieved successfully' })
  getHistory(@CurrentUser() user: JwtPayload, @Param('id') itemId: string) {
    return this.inventoryService.getHistory(
      user.tenantId,
      itemId,
      user.role,
      user.sub,
    );
  }
}
