import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { PropertiesService } from './properties.service';
import { Property } from './schemas/property.schema';
import { Item } from '../inventory/schemas/item.schema';
import { AccessControlService } from '../../common/services/access-control.service';
import { Role } from '../../common/enums/role.enum';
import { PropertyType } from './dto/create-property.dto';

describe('PropertiesService', () => {
  let service: PropertiesService;
  let propertyModel: { findOneAndUpdate: jest.Mock; findOne: jest.Mock; create: jest.Mock; find: jest.Mock };
  let itemModel: { updateMany: jest.Mock };
  let accessControl: { getAllowedPropertyIds: jest.Mock };

  beforeEach(async () => {
    propertyModel = {
      findOneAndUpdate: jest.fn(),
      findOne: jest.fn(),
      create: jest.fn(),
      find: jest.fn(),
    };

    itemModel = {
      updateMany: jest.fn(),
    };

    accessControl = {
      getAllowedPropertyIds: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PropertiesService,
        { provide: getModelToken(Property.name), useValue: propertyModel },
        { provide: getModelToken(Item.name), useValue: itemModel },
        { provide: AccessControlService, useValue: accessControl },
      ],
    }).compile();

    service = module.get<PropertiesService>(PropertiesService);
  });

  it('createProperty saves and returns new property for tenantId', async () => {
    const mockProperty = {
      tenantId: 'tenant-1',
      name: 'Main Residence',
      type: PropertyType.PRIMARY,
    };
    propertyModel.create.mockResolvedValue(mockProperty);

    const result = await service.create('tenant-1', { name: 'Main Residence', type: PropertyType.PRIMARY });

    expect(result).toBeDefined();
    expect(propertyModel.create).toHaveBeenCalled();
  });

  it('addFloor adds floor to existing property', async () => {
    const existingProperty = { _id: 'prop-1', tenantId: 'tenant-1', floors: [] };
    propertyModel.findOne.mockResolvedValue(existingProperty);
    propertyModel.findOneAndUpdate.mockResolvedValue({
      ...existingProperty,
      floors: [{ floorId: 'floor-1', name: 'Ground', rooms: [] }],
    });

    const result = await service.addFloor('tenant-1', 'prop-1', { name: 'Ground' });

    expect(propertyModel.findOneAndUpdate).toHaveBeenCalled();
  });

  it('addFloor throws NotFoundException if property not found', async () => {
    propertyModel.findOne.mockResolvedValue(null);

    await expect(
      service.addFloor('tenant-1', 'prop-1', { name: 'Ground' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('addRoom adds room to existing floor', async () => {
    const existingProperty = {
      _id: 'prop-1',
      tenantId: 'tenant-1',
      floors: [{ floorId: 'floor-1', name: 'Ground', rooms: [] }],
    };
    propertyModel.findOne.mockResolvedValue(existingProperty);
    propertyModel.findOneAndUpdate.mockResolvedValue({
      ...existingProperty,
      floors: [{
        floorId: 'floor-1',
        name: 'Ground',
        rooms: [{ roomId: 'room-1', name: 'Living Room', type: 'living' }],
      }],
    });

    const result = await service.addRoom('tenant-1', 'prop-1', 'floor-1', { name: 'Living Room', type: 'living' });

    expect(propertyModel.findOneAndUpdate).toHaveBeenCalled();
  });

  it('addRoom throws NotFoundException if floor not found', async () => {
    propertyModel.findOne.mockResolvedValue({ _id: 'prop-1', floors: [] });

    await expect(
      service.addRoom('tenant-1', 'prop-1', 'floor-1', { name: 'Living', type: 'living' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('deleteRoom updates items roomId null', async () => {
    const existingProperty = {
      _id: 'prop-1',
      tenantId: 'tenant-1',
      floors: [
        {
          floorId: 'floor-1',
          rooms: [{ roomId: 'room-1', name: 'Living' }],
        },
      ],
    };
    propertyModel.findOne.mockResolvedValue(existingProperty);
    propertyModel.findOneAndUpdate.mockResolvedValue({
      ...existingProperty,
      floors: [{ floorId: 'floor-1', rooms: [] }],
    });
    itemModel.updateMany.mockResolvedValue({ modifiedCount: 5 });

    await service.deleteRoom('tenant-1', 'prop-1', 'floor-1', 'room-1');

    expect(itemModel.updateMany).toHaveBeenCalled();
    expect(propertyModel.findOneAndUpdate).toHaveBeenCalled();
  });

  it('findById throws NotFoundException if property belongs to different tenant', async () => {
    propertyModel.findOne.mockResolvedValue({ _id: 'prop-1', tenantId: 'other-tenant' });
    accessControl.getAllowedPropertyIds.mockResolvedValue(['prop-1']);

    await expect(
      service.findById('tenant-1', 'prop-1', Role.MANAGER, 'user-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});