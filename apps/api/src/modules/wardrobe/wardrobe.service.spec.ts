jest.mock('uuid', () => ({ v4: jest.fn(() => 'test-uuid') }));

import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { WardrobeService } from './wardrobe.service';
import { Outfit } from './schemas/outfit.schema';
import { DryCleaningRecord } from './schemas/dry-cleaning-record.schema';
import { Item } from '../inventory/schemas/item.schema';
import { InventoryService } from '../inventory/inventory.service';
import { REDIS_CLIENT } from '../../common/decorators/inject-redis.decorator';

describe('WardrobeService', () => {
  let service: WardrobeService;

  beforeEach(async () => {
    const outfitModel = {
      find: jest.fn().mockReturnValue({ sort: () => ({ exec: jest.fn() }) }),
      create: jest.fn(),
      findOneAndUpdate: jest.fn(),
      deleteOne: jest.fn(),
      countDocuments: jest.fn(),
      distinct: jest.fn(),
    };

    const dryCleaningRecordModel = {
      find: jest.fn(),
      create: jest.fn(),
      findOneAndUpdate: jest.fn(),
    };

    const itemModel = {
      countDocuments: jest.fn(),
      findOne: jest.fn(),
      aggregate: jest.fn(),
    };

    const inventoryService = {
      findById: jest.fn(),
      update: jest.fn(),
    };

    const redis = {
      get: jest.fn(),
      set: jest.fn(),
      del: jest.fn(),
    };

    const module = await Test.createTestingModule({
      providers: [
        WardrobeService,
        { provide: getModelToken(Outfit.name), useValue: outfitModel },
        { provide: getModelToken(DryCleaningRecord.name), useValue: dryCleaningRecordModel },
        { provide: getModelToken(Item.name), useValue: itemModel },
        { provide: InventoryService, useValue: inventoryService },
        { provide: REDIS_CLIENT, useValue: redis },
      ],
    }).compile();

    service = module.get<WardrobeService>(WardrobeService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});