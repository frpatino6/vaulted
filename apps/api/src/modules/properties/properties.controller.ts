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
  UseGuards,
} from '@nestjs/common';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { Role } from '../../common/enums/role.enum';
import { AnomalyGuard } from '../../common/guards/anomaly.guard';
import { AuditService } from '../audit/audit.service';
import { AddFloorDto } from './dto/add-floor.dto';
import { AddRoomDto } from './dto/add-room.dto';
import { AddSectionDto } from './dto/add-section.dto';
import { AddSectionsDto } from './dto/add-sections.dto';
import { UpdateSectionDto } from './dto/update-section.dto';
import { CreatePropertyDto } from './dto/create-property.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { PropertiesService } from './properties.service';
import { PropertyDocument } from './schemas/property.schema';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

@UseGuards(AnomalyGuard)
@ApiTags('Properties')
@Controller('properties')
export class PropertiesController {
  constructor(
    private readonly propertiesService: PropertiesService,
    private readonly auditService: AuditService,
  ) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Post()
  @ApiOperation({ summary: 'Create a new property' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Property created' })
  async create(@CurrentUser() user: JwtPayload, @Body() dto: CreatePropertyDto) {
    // tenantId always from JWT — never from request body or headers
    const property = await this.propertiesService.create(user.tenantId, dto);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.create',
      entityType: 'property',
      entityId: String((property as unknown as PropertyDocument)._id),
    });

    return property;
  }

  @Get()
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @ApiOperation({ summary: 'Get all properties' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Properties retrieved' })
  findAll(@CurrentUser() user: JwtPayload) {
    return this.propertiesService.findAll(user.tenantId, user.role, user.sub);
  }

  @Get(':id')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @ApiOperation({ summary: 'Get property by ID' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Property retrieved' })
  @ApiResponse({ status: 404, description: 'Property not found' })
  findById(@CurrentUser() user: JwtPayload, @Param('id') propertyId: string) {
    return this.propertiesService.findById(user.tenantId, propertyId, user.role, user.sub);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put(':id')
  @ApiOperation({ summary: 'Update property' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Property updated' })
  async update(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Body() dto: UpdatePropertyDto,
  ) {
    const property = await this.propertiesService.update(user.tenantId, propertyId, dto);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.update',
      entityType: 'property',
      entityId: propertyId,
    });

    return property;
  }

  @Roles(Role.OWNER)
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete property' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Property deleted' })
  async delete(@CurrentUser() user: JwtPayload, @Param('id') propertyId: string) {
    await this.propertiesService.delete(user.tenantId, propertyId);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.delete',
      entityType: 'property',
      entityId: propertyId,
    });

    return { deleted: true };
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/floors')
  @ApiOperation({ summary: 'Add floor to property' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Floor added' })
  async addFloor(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Body() dto: AddFloorDto,
  ) {
    const property = await this.propertiesService.addFloor(user.tenantId, propertyId, dto);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.add_floor',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorName: dto.name },
    });

    return property;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put(':id/floors/:floorId')
  @ApiOperation({ summary: 'Update floor' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Floor updated' })
  async updateFloor(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Body() dto: AddFloorDto,
  ) {
    const property = await this.propertiesService.updateFloor(user.tenantId, propertyId, floorId, dto.name);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.update_floor',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorId, floorName: dto.name },
    });

    return property;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete(':id/floors/:floorId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete floor' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Floor deleted' })
  async deleteFloor(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
  ) {
    const property = await this.propertiesService.deleteFloor(user.tenantId, propertyId, floorId);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.delete_floor',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorId },
    });

    return property;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/floors/:floorId/rooms')
  @ApiOperation({ summary: 'Add room to floor' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Room added' })
  async addRoom(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Body() dto: AddRoomDto,
  ) {
    const property = await this.propertiesService.addRoom(user.tenantId, propertyId, floorId, dto);

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.add_room',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorId, roomName: dto.name },
    });

    return property;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put(':id/floors/:floorId/rooms/:roomId')
  @ApiOperation({ summary: 'Update room' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Room updated' })
  async updateRoom(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Param('roomId') roomId: string,
    @Body() dto: UpdateRoomDto,
  ) {
    const property = await this.propertiesService.updateRoom(
      user.tenantId,
      propertyId,
      floorId,
      roomId,
      dto,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.update_room',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorId, roomId },
    });

    return property;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete(':id/floors/:floorId/rooms/:roomId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete room' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Room deleted' })
  async deleteRoom(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Param('roomId') roomId: string,
  ) {
    const property = await this.propertiesService.deleteRoom(
      user.tenantId,
      propertyId,
      floorId,
      roomId,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.delete_room',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorId, roomId },
    });

    return property;
  }

  // ── Sections ──────────────────────────────────────────────────────────────

  @Get(':id/floors/:floorId/rooms/:roomId/sections')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @ApiOperation({ summary: 'Get sections in room' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Sections retrieved' })
  getSections(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Param('roomId') roomId: string,
  ) {
    return this.propertiesService.getSections(
      user.tenantId,
      propertyId,
      floorId,
      roomId,
      user.role,
      user.sub,
    );
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/floors/:floorId/rooms/:roomId/sections')
  @ApiOperation({ summary: 'Add section to room' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Section added' })
  async addSection(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Param('roomId') roomId: string,
    @Body() dto: AddSectionDto,
  ) {
    const property = await this.propertiesService.addSection(
      user.tenantId, propertyId, floorId, roomId, dto,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.add_section',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorId, roomId, sectionCode: dto.code },
    });

    return property;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/floors/:floorId/rooms/:roomId/sections/bulk')
  @ApiOperation({ summary: 'Add multiple sections' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Sections added' })
  async addSections(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Param('roomId') roomId: string,
    @Body() body: AddSectionsDto,
  ) {
    const property = await this.propertiesService.addSections(
      user.tenantId, propertyId, floorId, roomId, body.sections,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.add_sections_bulk',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorId, roomId, count: body.sections.length },
    });

    return property;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put(':id/floors/:floorId/rooms/:roomId/sections/:sectionId')
  @ApiOperation({ summary: 'Update section' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Section updated' })
  async updateSection(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Param('roomId') roomId: string,
    @Param('sectionId') sectionId: string,
    @Body() dto: UpdateSectionDto,
  ) {
    const property = await this.propertiesService.updateSection(
      user.tenantId, propertyId, floorId, roomId, sectionId, dto,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.update_section',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorId, roomId, sectionId },
    });

    return property;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete(':id/floors/:floorId/rooms/:roomId/sections/:sectionId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete section' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Section deleted' })
  async deleteSection(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Param('roomId') roomId: string,
    @Param('sectionId') sectionId: string,
  ) {
    const property = await this.propertiesService.deleteSection(
      user.tenantId, propertyId, floorId, roomId, sectionId,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'property.delete_section',
      entityType: 'property',
      entityId: propertyId,
      metadata: { floorId, roomId, sectionId },
    });

    return property;
  }
}
