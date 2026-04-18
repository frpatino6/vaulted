import {
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { v4 as uuidv4 } from 'uuid';
import { Role } from '../../common/enums/role.enum';
import { AccessControlService } from '../../common/services/access-control.service';
import { AddFloorDto } from './dto/add-floor.dto';
import { AddRoomDto } from './dto/add-room.dto';
import { AddSectionDto } from './dto/add-section.dto';
import { UpdateSectionDto } from './dto/update-section.dto';
import { CreatePropertyDto } from './dto/create-property.dto';
import { UpdatePropertyDto } from './dto/update-property.dto';
import { UpdateRoomDto } from './dto/update-room.dto';
import { Property, PropertyDocument, RoomSection } from './schemas/property.schema';

@Injectable()
export class PropertiesService {
  constructor(
    @InjectModel(Property.name)
    private readonly propertyModel: Model<PropertyDocument>,
    private readonly accessControl: AccessControlService,
  ) {}

  async create(tenantId: string, dto: CreatePropertyDto): Promise<Property> {
    const property = await this.propertyModel.create({
      tenantId,
      name: dto.name,
      type: dto.type,
      address: dto.address,
      floors: dto.floors ?? [],
      photos: dto.photos ?? [],
    });

    // TODO: audit log
    return property;
  }

  async findAll(tenantId: string, role: Role, userId: string): Promise<Property[]> {
    const allowedPropertyIds = await this.accessControl.getAllowedPropertyIds(userId, role);
    if (allowedPropertyIds !== null) {
      if (allowedPropertyIds.length === 0) return [];
      return this.propertyModel
        .find({ tenantId, _id: { $in: allowedPropertyIds } })
        .sort({ createdAt: -1 })
        .exec();
    }
    return this.propertyModel.find({ tenantId }).sort({ createdAt: -1 }).exec();
  }

  async findById(tenantId: string, propertyId: string, role: Role, userId: string): Promise<Property> {
    const property = await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    const allowedPropertyIds = await this.accessControl.getAllowedPropertyIds(userId, role);
    if (allowedPropertyIds !== null && !allowedPropertyIds.includes(propertyId)) {
      throw new NotFoundException('Property not found');
    }
    return property;
  }

  async update(
    tenantId: string,
    propertyId: string,
    dto: UpdatePropertyDto,
  ): Promise<Property> {
    await this.findOwnedPropertyOrThrow(tenantId, propertyId);

    const property = await this.propertyModel
      .findOneAndUpdate(
        { _id: propertyId, tenantId },
        {
          $set: {
            ...(dto.name !== undefined ? { name: dto.name } : {}),
            ...(dto.type !== undefined ? { type: dto.type } : {}),
            ...(dto.address !== undefined ? { address: dto.address } : {}),
            ...(dto.floors !== undefined ? { floors: dto.floors } : {}),
            ...(dto.photos !== undefined ? { photos: dto.photos } : {}),
          },
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!property) {
      throw new NotFoundException('Property not found');
    }

    // TODO: audit log
    return property;
  }

  async delete(tenantId: string, propertyId: string): Promise<void> {
    await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    await this.propertyModel.deleteOne({ _id: propertyId, tenantId }).exec();
    // TODO: audit log
  }

  async addFloor(
    tenantId: string,
    propertyId: string,
    dto: AddFloorDto,
  ): Promise<Property> {
    await this.findOwnedPropertyOrThrow(tenantId, propertyId);

    const property = await this.propertyModel
      .findOneAndUpdate(
        { _id: propertyId, tenantId },
        {
          $push: {
            floors: {
              floorId: uuidv4(),
              name: dto.name,
              rooms: [],
            },
          },
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!property) {
      throw new NotFoundException('Property not found');
    }

    // TODO: audit log
    return property;
  }

  async addRoom(
    tenantId: string,
    propertyId: string,
    floorId: string,
    dto: AddRoomDto,
  ): Promise<Property> {
    const property = await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    const floorExists = property.floors.some((floor) => floor.floorId === floorId);

    if (!floorExists) {
      throw new NotFoundException('Floor not found');
    }

    const updatedProperty = await this.propertyModel
      .findOneAndUpdate(
        { _id: propertyId, tenantId, 'floors.floorId': floorId },
        {
          $push: {
            'floors.$.rooms': {
              roomId: uuidv4(),
              name: dto.name,
              type: dto.type,
            },
          },
        },
        { new: true, runValidators: true },
      )
      .exec();

    if (!updatedProperty) {
      throw new NotFoundException('Property not found');
    }

    // TODO: audit log
    return updatedProperty;
  }

  async updateRoom(
    tenantId: string,
    propertyId: string,
    floorId: string,
    roomId: string,
    dto: UpdateRoomDto,
  ): Promise<Property> {
    const property = await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    const floor = property.floors.find((f) => f.floorId === floorId);
    if (!floor) throw new NotFoundException('Floor not found');
    const roomExists = floor.rooms.some((r) => r.roomId === roomId);
    if (!roomExists) throw new NotFoundException('Room not found');

    const setFields: Record<string, string> = {};
    if (dto.name !== undefined) setFields['floors.$[floor].rooms.$[room].name'] = dto.name;
    if (dto.type !== undefined) setFields['floors.$[floor].rooms.$[room].type'] = dto.type;

    const updatedProperty = await this.propertyModel
      .findOneAndUpdate(
        { _id: propertyId, tenantId },
        { $set: setFields },
        {
          arrayFilters: [{ 'floor.floorId': floorId }, { 'room.roomId': roomId }],
          new: true,
          runValidators: true,
        },
      )
      .exec();

    if (!updatedProperty) throw new NotFoundException('Property not found');
    return updatedProperty;
  }

  async deleteRoom(
    tenantId: string,
    propertyId: string,
    floorId: string,
    roomId: string,
  ): Promise<Property> {
    const property = await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    const floor = property.floors.find((f) => f.floorId === floorId);
    if (!floor) throw new NotFoundException('Floor not found');
    const roomExists = floor.rooms.some((r) => r.roomId === roomId);
    if (!roomExists) throw new NotFoundException('Room not found');

    const updatedProperty = await this.propertyModel
      .findOneAndUpdate(
        { _id: propertyId, tenantId, 'floors.floorId': floorId },
        { $pull: { 'floors.$.rooms': { roomId } } },
        { new: true },
      )
      .exec();

    if (!updatedProperty) throw new NotFoundException('Property not found');
    return updatedProperty;
  }

  async getSections(
    tenantId: string,
    propertyId: string,
    floorId: string,
    roomId: string,
  ): Promise<RoomSection[]> {
    const property = await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    const floor = property.floors.find((f) => f.floorId === floorId);
    if (!floor) throw new NotFoundException('Floor not found');
    const room = floor.rooms.find((r) => r.roomId === roomId);
    if (!room) throw new NotFoundException('Room not found');
    return room.sections ?? [];
  }

  async addSection(
    tenantId: string,
    propertyId: string,
    floorId: string,
    roomId: string,
    dto: AddSectionDto,
  ): Promise<Property> {
    const property = await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    const floor = property.floors.find((f) => f.floorId === floorId);
    if (!floor) throw new NotFoundException('Floor not found');
    const roomExists = floor.rooms.some((r) => r.roomId === roomId);
    if (!roomExists) throw new NotFoundException('Room not found');

    const newSection: RoomSection = {
      sectionId: uuidv4(),
      code: dto.code,
      name: dto.name,
      type: dto.type,
      notes: dto.notes,
    };

    const updatedProperty = await this.propertyModel
      .findOneAndUpdate(
        { _id: propertyId, tenantId },
        { $push: { 'floors.$[floor].rooms.$[room].sections': newSection } },
        {
          arrayFilters: [{ 'floor.floorId': floorId }, { 'room.roomId': roomId }],
          new: true,
          runValidators: true,
        },
      )
      .exec();

    if (!updatedProperty) throw new NotFoundException('Property not found');
    return updatedProperty;
  }

  async addSections(
    tenantId: string,
    propertyId: string,
    floorId: string,
    roomId: string,
    sections: AddSectionDto[],
  ): Promise<Property> {
    const property = await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    const floor = property.floors.find((f) => f.floorId === floorId);
    if (!floor) throw new NotFoundException('Floor not found');
    const roomExists = floor.rooms.some((r) => r.roomId === roomId);
    if (!roomExists) throw new NotFoundException('Room not found');

    const newSections: RoomSection[] = sections.map((dto) => ({
      sectionId: uuidv4(),
      code: dto.code,
      name: dto.name,
      type: dto.type,
      notes: dto.notes,
    }));

    const updatedProperty = await this.propertyModel
      .findOneAndUpdate(
        { _id: propertyId, tenantId },
        { $push: { 'floors.$[floor].rooms.$[room].sections': { $each: newSections } } },
        {
          arrayFilters: [{ 'floor.floorId': floorId }, { 'room.roomId': roomId }],
          new: true,
          runValidators: true,
        },
      )
      .exec();

    if (!updatedProperty) throw new NotFoundException('Property not found');
    return updatedProperty;
  }

  async updateSection(
    tenantId: string,
    propertyId: string,
    floorId: string,
    roomId: string,
    sectionId: string,
    dto: UpdateSectionDto,
  ): Promise<Property> {
    const property = await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    const floor = property.floors.find((f) => f.floorId === floorId);
    if (!floor) throw new NotFoundException('Floor not found');
    const room = floor.rooms.find((r) => r.roomId === roomId);
    if (!room) throw new NotFoundException('Room not found');
    const sectionExists = (room.sections ?? []).some((s) => s.sectionId === sectionId);
    if (!sectionExists) throw new NotFoundException('Section not found');

    const setFields: Record<string, string> = {};
    if (dto.code !== undefined)
      setFields['floors.$[floor].rooms.$[room].sections.$[section].code'] = dto.code;
    if (dto.name !== undefined)
      setFields['floors.$[floor].rooms.$[room].sections.$[section].name'] = dto.name;
    if (dto.type !== undefined)
      setFields['floors.$[floor].rooms.$[room].sections.$[section].type'] = dto.type;
    if (dto.notes !== undefined)
      setFields['floors.$[floor].rooms.$[room].sections.$[section].notes'] = dto.notes;

    const updatedProperty = await this.propertyModel
      .findOneAndUpdate(
        { _id: propertyId, tenantId },
        { $set: setFields },
        {
          arrayFilters: [
            { 'floor.floorId': floorId },
            { 'room.roomId': roomId },
            { 'section.sectionId': sectionId },
          ],
          new: true,
          runValidators: true,
        },
      )
      .exec();

    if (!updatedProperty) throw new NotFoundException('Property not found');
    return updatedProperty;
  }

  async deleteSection(
    tenantId: string,
    propertyId: string,
    floorId: string,
    roomId: string,
    sectionId: string,
  ): Promise<Property> {
    const property = await this.findOwnedPropertyOrThrow(tenantId, propertyId);
    const floor = property.floors.find((f) => f.floorId === floorId);
    if (!floor) throw new NotFoundException('Floor not found');
    const room = floor.rooms.find((r) => r.roomId === roomId);
    if (!room) throw new NotFoundException('Room not found');
    const sectionExists = (room.sections ?? []).some((s) => s.sectionId === sectionId);
    if (!sectionExists) throw new NotFoundException('Section not found');

    const updatedProperty = await this.propertyModel
      .findOneAndUpdate(
        { _id: propertyId, tenantId },
        {
          $pull: {
            'floors.$[floor].rooms.$[room].sections': { sectionId },
          },
        },
        {
          arrayFilters: [{ 'floor.floorId': floorId }, { 'room.roomId': roomId }],
          new: true,
        },
      )
      .exec();

    if (!updatedProperty) throw new NotFoundException('Property not found');
    return updatedProperty;
  }

  private async findOwnedPropertyOrThrow(
    tenantId: string,
    propertyId: string,
  ): Promise<PropertyDocument> {
    const property = await this.propertyModel
      .findOne({ _id: propertyId, tenantId })
      .exec();

    if (!property) {
      throw new NotFoundException('Property not found');
    }

    return property;
  }
}
