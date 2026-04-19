import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { WardrobeService } from './wardrobe.service';
import { Outfit } from './schemas/outfit.schema';
import { DryCleaningRecord } from './schemas/dry-cleaning-record.schema';
import { Item } from '../inventory/schemas/item.schema';
import { InventoryService } from '../inventory/inventory.service';
import { REDIS_CLIENT } from '../../common/decorators/inject-redis.decorator';
import Redis from 'ioredis';

describe('WardrobeService', () => {
  let service: WardrobeService;
  let outfitModel: { find: jest.Mock; create: jest.Mock; findOneAndUpdate: jest.Mock; deleteOne: jest.Mock; countDocuments: jest.Mock; distinct: jest.Mock };
  let dryCleaningRecordModel: { find: jest.Mock; create: jest.Mock; findOneAndUpdate: jest.Mock };
  let itemModel: { countDocuments: jest.Mock; aggregate: jest.Mock };
  let inventoryService: { findById: jest.Mock; update: jest.Mock };
  let redis: { get: jest.Mock; set: jest.Mock; del: jest.Mock };

  beforeEach(async () => {
    outfitModel = {
      find: jest.fn().mockReturnValue({ sort: jest.fn().mockReturnThis(), exec: jest.fn() }),
      create: jest.fn(),
      findOneAndUpdate: jest.fn(),
      deleteOne: jest.fn(),
      countDocuments: jest.fn(),
      distinct: jest.fn(),
    };

    dryCleaningRecordModel = {
      find: jest.fn().mockReturnValue({ sort: jest.fn().mockReturnThis(), exec: jest.fn() }),
      create: jest.fn(),
      findOneAndUpdate: jest.fn(),
    };

    itemModel = {
      countDocuments: jest.fn(),
      aggregate: jest.fn().mockReturnValue({ exec: jest.fn() }),
    };

    inventoryService = {
      findById: jest.fn(),
      update: jest.fn(),
    };

    redis = {
      get: jest.fn(),
      set: jest.fn(),
      del: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
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

  it('createOutfit saves outfit with selected item ids', async () => {
    const mockOutfit = {
      tenantId: 'tenant-1',
      name: 'Summer Look',
      itemIds: ['item-1', 'item-2'],
    };
    itemModel.countDocuments.mockResolvedValue(2);
    outfitModel.create.mockResolvedValue(mockOutfit);

    const result = await service.createOutfit(
      'tenant-1',
      'user-1',
      { name: 'Summer Look', itemIds: ['item-1', 'item-2'] },
    );

    expect(result).toBeDefined();
    expect(outfitModel.create).toHaveBeenCalled();
  });

  it('createOutfit throws BadRequestException if itemId not in tenant', async () => {
    itemModel.countDocuments.mockResolvedValue(1);

    await expect(
      service.createOutfit('tenant-1', 'user-1', { name: 'Look', itemIds: ['item-1', 'item-invalid'] }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('deleteOutfit throws NotFoundException if outfit wrong tenant', async () => {
    outfitModel.find.mockReturnValue({
      sort: jest.fn().mockReturnThis(),
      exec: jest.fn().mockResolvedValue([]),
    });

    await expect(
      service.deleteOutfit('other-tenant', 'outfit-1'),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('getStats returns correct counts', async () => {
    const mockAggResult = [{ _id: 'clothing', count: 10 }];
    itemModel.countDocuments.mockResolvedValue(50);
    itemModel.aggregate.mockReturnValue({
      exec: jest.fn().mockResolvedValue(mockAggResult),
    });
    outfitModel.countDocuments.mockResolvedValue(5);
    outfitModel.distinct.mockResolvedValue(['item-1', 'item-2']);
    redis.get.mockResolvedValue(null);

    const result = await service.getStats('tenant-1');

    expect(result.totalItems).toBe(50);
    expect(result.outfitsCount).toBe(5);
  });
});