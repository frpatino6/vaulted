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
} from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { CreateMaintenanceDto } from './dto/create-maintenance.dto';
import { UpdateMaintenanceDto } from './dto/update-maintenance.dto';
import { MaintenanceService } from './maintenance.service';

@Controller()
export class MaintenanceController {
  constructor(private readonly maintenanceService: MaintenanceService) {}

  // GET /maintenance — all maintenance records for the tenant (with optional filters)
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @Get('maintenance')
  async findAll(
    @CurrentUser() user: JwtPayload,
    @Query('status') status?: string,
    @Query('itemId') itemId?: string,
    @Query('upcoming') upcoming?: string,
    @Query('daysAhead') daysAhead?: string,
  ) {
    return this.maintenanceService.findAll(user.tenantId, {
      itemId,
      status,
      upcoming: upcoming === 'true',
      daysAhead: daysAhead ? Number(daysAhead) : undefined,
    });
  }

  // GET /items/:itemId/maintenance — all records for a specific item
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Get('items/:itemId/maintenance')
  async findByItem(
    @CurrentUser() user: JwtPayload,
    @Param('itemId') itemId: string,
  ) {
    return this.maintenanceService.findByItem(user.tenantId, itemId);
  }

  // POST /items/:itemId/maintenance — schedule a maintenance event
  @Roles(Role.OWNER, Role.MANAGER)
  @Post('items/:itemId/maintenance')
  async create(
    @CurrentUser() user: JwtPayload,
    @Param('itemId') itemId: string,
    @Body() dto: CreateMaintenanceDto,
  ) {
    return this.maintenanceService.create(user.tenantId, user.sub, itemId, dto);
  }

  // PUT /maintenance/:id — update a maintenance record (mark complete, add cost, etc.)
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF)
  @Put('maintenance/:id')
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
    @Body() dto: UpdateMaintenanceDto,
  ) {
    return this.maintenanceService.update(user.tenantId, user.sub, id, dto);
  }

  // DELETE /maintenance/:id — cancel / remove a maintenance record
  @Roles(Role.OWNER, Role.MANAGER)
  @HttpCode(HttpStatus.NO_CONTENT)
  @Delete('maintenance/:id')
  async delete(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ) {
    return this.maintenanceService.delete(user.tenantId, user.sub, id);
  }
}
