import { getModelToken } from '@nestjs/mongoose';
import { Test } from '@nestjs/testing';

import { Role } from '../../common/enums/role.enum';
import { NotificationsService } from '../notifications/notifications.service';
import { DryCleaningRecord } from './schemas/dry-cleaning-record.schema';
import { WardrobeOverdueJob } from './wardrobe-overdue.job';

describe('WardrobeOverdueJob', () => {
  it('passes the dry-cleaning overdue notification type', async () => {
    const dryCleaningRecordModel = {
      find: jest.fn().mockReturnValue({
        select: jest.fn().mockReturnValue({
          lean: jest.fn().mockReturnValue({
            exec: jest.fn().mockResolvedValue([
              {
                _id: 'record-1',
                tenantId: 'tenant-1',
                itemId: 'item-1',
                sentDate: new Date('2026-01-01T00:00:00Z'),
                cleanerName: 'Cleaner',
              },
            ]),
          }),
        }),
      }),
    };
    const notificationsService = {
      notifyTenantRoles: jest.fn().mockResolvedValue(undefined),
    };

    const module = await Test.createTestingModule({
      providers: [
        WardrobeOverdueJob,
        {
          provide: getModelToken(DryCleaningRecord.name),
          useValue: dryCleaningRecordModel,
        },
        { provide: NotificationsService, useValue: notificationsService },
      ],
    }).compile();

    await module.get(WardrobeOverdueJob).checkOverdueItems();

    expect(notificationsService.notifyTenantRoles).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: 'tenant-1',
        roles: [Role.OWNER, Role.MANAGER],
        type: 'dry_cleaning_overdue',
      }),
    );
  });
});
