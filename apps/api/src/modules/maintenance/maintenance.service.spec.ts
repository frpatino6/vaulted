import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { NotFoundException } from '@nestjs/common';
import { MaintenanceService } from './maintenance.service';
import { MaintenanceRecord } from './schemas/maintenance-record.schema';
import { Item } from '../inventory/schemas/item.schema';
import { AuditService } from '../audit/audit.service';

describe('MaintenanceService', () => {
  let service: MaintenanceService;
  let recordModel: any;
  let itemModel: any;
  let auditService: any;

  beforeEach(async () => {
    recordModel = {
      create: jest.fn(),
      find: jest.fn(),
      findOne: jest.fn(),
      findOneAndUpdate: jest.fn(),
      updateMany: jest.fn(),
      deleteOne: jest.fn(),
    };

    itemModel = {
      findOne: jest.fn(),
      updateOne: jest.fn(),
    };

    auditService = {
      log: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MaintenanceService,
        { provide: getModelToken(MaintenanceRecord.name), useValue: recordModel },
        { provide: getModelToken(Item.name), useValue: itemModel },
        { provide: AuditService, useValue: auditService },
      ],
    }).compile();

    service = module.get<MaintenanceService>(MaintenanceService);
  });

  it('findUpcomingInDays returns pending tasks within days', async () => {
    recordModel.find.mockReturnValue({ exec: jest.fn().mockResolvedValue([{ _id: 'rec-1' }]) });

    const result = await service.findUpcomingInDays(30);

    expect(result).toHaveLength(1);
  });

  it('markOverdueRecords updates pending records', async () => {
    recordModel.updateMany.mockReturnValue({ exec: jest.fn().mockResolvedValue({ modifiedCount: 2 }) });

    const result = await service.markOverdueRecords();

    expect(result).toBe(2);
  });
});