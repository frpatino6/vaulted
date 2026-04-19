jest.mock('uuid', () => ({ v4: jest.fn(() => 'test-uuid') }));

import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { PropertiesService } from './properties.service';
import { Property } from './schemas/property.schema';
import { Item } from '../inventory/schemas/item.schema';
import { AccessControlService } from '../../common/services/access-control.service';
import { Role } from '../../common/enums/role.enum';

describe('PropertiesService', () => {
  let service: PropertiesService;

  beforeEach(async () => {
    const propertyModel = {
      findOne: jest.fn().mockReturnValue({ exec: jest.fn() }),
      findOneAndUpdate: jest.fn().mockReturnValue({ exec: jest.fn() }),
      create: jest.fn(),
      find: jest.fn().mockReturnValue({ exec: jest.fn() }),
    };

    const itemModel = {
      updateMany: jest.fn(),
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
      ],
    }).compile();

    service = module.get<PropertiesService>(PropertiesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});