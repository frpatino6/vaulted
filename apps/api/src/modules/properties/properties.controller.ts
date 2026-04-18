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
} from '@nestjs/common';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { Role } from '../../common/enums/role.enum';
import { AuditService } from '../audit/audit.service';
import { AddFloorDto } from './dto/add-floor.dto';
import { AddRoomDto } from './dto/add-room.dto';
import { AddSectionDto } from './dto/add-section.dto';
import { UpdateSectionDto } from './dto/update-section.dto';
import { CreatePropertyDto } from './dto/create-property.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { PropertiesService } from './properties.service';
import { PropertyDocument } from './schemas/property.schema';

@Controller('properties')
export class PropertiesController {
  constructor(
    private readonly propertiesService: PropertiesService,
    private readonly auditService: AuditService,
  ) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Post()
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
  findAll(@CurrentUser() user: JwtPayload) {
    return this.propertiesService.findAll(user.tenantId, user.role, user.sub);
  }

  @Get(':id')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  findById(@CurrentUser() user: JwtPayload, @Param('id') propertyId: string) {
    return this.propertiesService.findById(user.tenantId, propertyId, user.role, user.sub);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put(':id')
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
  @HttpCode(HttpStatus.OK)
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
  @Post(':id/floors/:floorId/rooms')
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
  @HttpCode(HttpStatus.OK)
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
  getSections(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Param('roomId') roomId: string,
  ) {
    return this.propertiesService.getSections(user.tenantId, propertyId, floorId, roomId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post(':id/floors/:floorId/rooms/:roomId/sections')
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
  async addSections(
    @CurrentUser() user: JwtPayload,
    @Param('id') propertyId: string,
    @Param('floorId') floorId: string,
    @Param('roomId') roomId: string,
    @Body() body: { sections: AddSectionDto[] },
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
  @HttpCode(HttpStatus.OK)
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
