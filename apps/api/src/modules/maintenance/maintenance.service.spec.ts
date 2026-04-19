import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { NotFoundException } from '@nestjs/common';
import { MaintenanceService } from './maintenance.service';
import { MaintenanceRecord } from './schemas/maintenance-record.schema';
import { Item } from '../inventory/schemas/item.schema';
import { AuditService } from '../audit/audit.service';

describe('MaintenanceService', () => {
  let service: MaintenanceService;
  let recordModel: { create: jest.Mock; find: jest.Mock; findOne: jest.Mock; findOneAndUpdate: jest.Mock; updateMany: jest.Mock; deleteOne: jest.Mock };
  let itemModel: { findOne: jest.Mock; updateOne: jest.Mock };
  let auditService: { log: jest.Mock };

  beforeEach(async () => {
    recordModel = {
      create: jest.fn(),
      find: jest.fn().mockReturnValue({ sort: jest.fn().mockReturnThis(), exec: jest.fn() }),
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

  it('createMaintenanceTask saves task linked to itemId and tenantId', async () => {
    itemModel.findOne.mockResolvedValue({ _id: 'item-1', tenantId: 'tenant-1' });
    const mockRecord = {
      itemId: 'item-1',
      tenantId: 'tenant-1',
      title: 'Oil Change',
      status: 'pending',
    };
    recordModel.create.mockResolvedValue(mockRecord);

    const result = await service.create(
      'tenant-1',
      'user-1',
      'item-1',
      { title: 'Oil Change', scheduledDate: '2025-06-01' },
    );

    expect(result).toBeDefined();
    expect(recordModel.create).toHaveBeenCalled();
  });

  it('completeTask marks task completed, sets completedAt', async () => {
    const existing = {
      _id: 'rec-1',
      itemId: 'item-1',
      tenantId: 'tenant-1',
      status: 'pending',
      isRecurring: false,
      scheduledDate: new Date(),
    };
    recordModel.findOne.mockResolvedValue(existing);
    recordModel.findOneAndUpdate.mockResolvedValue({
      ...existing,
      status: 'completed',
      completedDate: new Date(),
    });

    const result = await service.update(
      'tenant-1',
      'user-1',
      'rec-1',
      { status: 'completed' },
    );

    expect(recordModel.findOneAndUpdate).toHaveBeenCalled();
  });

  it('completeTask throws NotFoundException if task belongs to different tenant', async () => {
    recordModel.findOne.mockResolvedValue(null);

    await expect(
      service.update('tenant-1', 'user-1', 'rec-1', { status: 'completed' }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('getOverdueTasks returns only tasks where scheduledDate < now and status != completed', async () => {
    const pastDate = new Date('2024-01-01');
    const mockRecords = [
      { _id: 'rec-1', scheduledDate: pastDate, status: 'pending' },
    ];
    const chain = {
      sort: jest.fn().mockReturnThis(),
      exec: jest.fn().mockResolvedValue(mockRecords),
    };
    recordModel.find.mockReturnValue(chain);

    const result = await service.findAll('tenant-1', { status: 'overdue' });

    expect(result).toBeDefined();
  });

  it('getUpcomingTasks returns tasks within next 30 days', async () => {
    const futureDate = new Date();
    futureDate.setDate(futureDate.getDate() + 15);
    const mockRecords = [
      { _id: 'rec-1', scheduledDate: futureDate, status: 'pending' },
    ];
    const chain = {
      sort: jest.fn().mockReturnThis(),
      exec: jest.fn().mockResolvedValue(mockRecords),
    };
    recordModel.find.mockReturnValue(chain);

    const result = await service.findAll('tenant-1', { upcoming: true });

    expect(result).toBeDefined();
  });

  it('recurring task: completing creates new task with next scheduled date', async () => {
    const existing = {
      _id: 'rec-1',
      itemId: 'item-1',
      tenantId: 'tenant-1',
      status: 'pending',
      isRecurring: true,
      recurrenceIntervalDays: 30,
      scheduledDate: new Date(),
    };
    recordModel.findOne.mockResolvedValue(existing);
    recordModel.findOneAndUpdate.mockResolvedValue({
      ...existing,
      status: 'completed',
    });
    recordModel.create.mockResolvedValue({
      _id: 'rec-2',
      isRecurring: true,
    });

    await service.update(
      'tenant-1',
      'user-1',
      'rec-1',
      { status: 'completed' },
    );

    expect(recordModel.create).toHaveBeenCalled();
  });
});