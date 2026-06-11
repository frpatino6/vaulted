jest.mock('uuid', () => ({ v4: jest.fn(() => 'test-uuid') }));

import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { PropertiesService } from './properties.service';
import { Property } from './schemas/property.schema';
import { Item } from '../inventory/schemas/item.schema';
import { AccessControlService } from '../../common/services/access-control.service';
import { MediaService } from '../media/media.service';

describe('PropertiesService', () => {
  let service: PropertiesService;
  let propertyModel: {
    findOne: jest.Mock;
    findOneAndUpdate: jest.Mock;
    create: jest.Mock;
    find: jest.Mock;
    deleteOne: jest.Mock;
  };
  let itemModel: {
    updateMany: jest.Mock;
    countDocuments: jest.Mock;
  };

  beforeEach(async () => {
    propertyModel = {
      findOne: jest.fn().mockReturnValue({ exec: jest.fn() }),
      findOneAndUpdate: jest.fn().mockReturnValue({ exec: jest.fn() }),
      create: jest.fn(),
      find: jest.fn().mockReturnValue({ exec: jest.fn() }),
      deleteOne: jest.fn().mockReturnValue({ exec: jest.fn() }),
    };

    itemModel = {
      updateMany: jest.fn(),
      countDocuments: jest.fn().mockReturnValue({ exec: jest.fn() }),
    };

    const accessControl = {
      getAllowedPropertyIds: jest.fn(),
    };

    const module = await Test.createTestingModule({
      providers: [
        PropertiesService,
        { provide: getModelToken(Property.name), useValue: propertyModel },
        { provide: getModelToken(Item.name), useValue: itemModel },
        { provide: AccessControlService, useValue: accessControl },
        {
          provide: MediaService,
          useValue: { generateFileToken: jest.fn() },
        },
        {
          provide: ConfigService,
          useValue: { get: jest.fn() },
        },
      ],
    }).compile();

    service = module.get<PropertiesService>(PropertiesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('delete', () => {
    it('throws conflict when the property still contains items', async () => {
      propertyModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue({ _id: 'property-1' }),
      });
      itemModel.countDocuments.mockReturnValue({
        exec: jest.fn().mockResolvedValue(1),
      });

      await expect(service.delete('tenant-1', 'property-1')).rejects.toThrow(
        'Cannot delete a property that still contains items. Move or dispose them first.',
      );
      expect(itemModel.countDocuments).toHaveBeenCalledWith({
        tenantId: 'tenant-1',
        propertyId: 'property-1',
      });
      expect(propertyModel.deleteOne).not.toHaveBeenCalled();
    });

    it('deletes the property when it contains no items', async () => {
      propertyModel.findOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue({ _id: 'property-1' }),
      });
      itemModel.countDocuments.mockReturnValue({
        exec: jest.fn().mockResolvedValue(0),
      });
      propertyModel.deleteOne.mockReturnValue({
        exec: jest.fn().mockResolvedValue({ deletedCount: 1 }),
      });

      await expect(service.delete('tenant-1', 'property-1')).resolves.toBeUndefined();
      expect(propertyModel.deleteOne).toHaveBeenCalledWith({
        _id: 'property-1',
        tenantId: 'tenant-1',
      });
    });
  });
});
