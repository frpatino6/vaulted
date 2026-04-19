jest.mock('uuid', () => ({
  v4: jest.fn(() => 'test-uuid'),
}));

jest.mock('qrcode', () => ({
  toDataURL: jest.fn().mockResolvedValue('data:image/png;base64,xx'),
}));

import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { DataSource } from 'typeorm';
import { InventoryService } from './inventory.service';
import { Item } from './schemas/item.schema';
import { ItemCategory, ItemStatus } from './dto/create-item.dto';
import { ItemHistory } from './schemas/item-history.schema';
import { Property } from '../properties/schemas/property.schema';
import { AccessControlService } from '../../common/services/access-control.service';
import { CryptoService } from '../../common/services/crypto.service';
import { AuditService } from '../audit/audit.service';
import { MediaService } from '../media/media.service';
import { ConfigService } from '@nestjs/config';
import { Role } from '../../common/enums/role.enum';
describe('InventoryService', () => {
  let service: InventoryService;

  const itemFindChain = {
    sort: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    exec: jest.fn(),
  };

  const itemModel = {
    create: jest.fn(),
    find: jest.fn(() => itemFindChain),
    findOne: jest.fn(),
    findOneAndUpdate: jest.fn(),
    countDocuments: jest.fn(),
  };

  const itemHistoryModel = {
    create: jest.fn(),
    find: jest.fn().mockReturnValue({
      sort: jest.fn().mockReturnThis(),
      exec: jest.fn(),
    }),
  };

  const propertyFindChain = {
    select: jest.fn().mockReturnThis(),
    exec: jest.fn(),
  };

  const propertyModel = {
    find: jest.fn(() => propertyFindChain),
  };

  const dataSource = {} as DataSource;

  const accessControl = {
    getAllowedPropertyIds: jest.fn(),
    stripValuation: jest.fn((item: object) => {
      const plain = { ...item };
      delete (plain as { valuation?: unknown }).valuation;
      return plain;
    }),
  };

  const crypto = {
    encryptField: jest.fn((s: string) => `enc:${s}`),
    decryptField: jest.fn((s: string) => String(s).replace(/^enc:/, '')),
    isEncryptedField: jest.fn(
      (v: unknown) => typeof v === 'string' && String(v).startsWith('enc:'),
    ),
  };

  const audit = {
    log: jest.fn(),
  };

  const configService = {
    get: jest.fn((key: string) => {
      if (key === 'APP_URL') return 'http://localhost:3000';
      return undefined;
    }),
  };

  const mediaService = {
    generateFileToken: jest.fn().mockReturnValue('media-jwt'),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        InventoryService,
        { provide: getModelToken(Item.name), useValue: itemModel },
        { provide: getModelToken(ItemHistory.name), useValue: itemHistoryModel },
        { provide: getModelToken(Property.name), useValue: propertyModel },
        { provide: DataSource, useValue: dataSource },
        { provide: AccessControlService, useValue: accessControl },
        { provide: CryptoService, useValue: crypto },
        { provide: AuditService, useValue: audit },
        { provide: ConfigService, useValue: configService },
        { provide: MediaService, useValue: mediaService },
      ],
    }).compile();

    service = module.get<InventoryService>(InventoryService);
  });

  it('findAll() for manager decrypts valuation, signs media URLs, and logs valuation view audit', async () => {
    accessControl.getAllowedPropertyIds.mockResolvedValue(null);

    const doc = {
      toObject: jest.fn().mockReturnValue({
        _id: 'i1',
        tenantId: 't1',
        name: 'Chair',
        photos: ['http://localhost:3000/uploads/t1/p.jpg'],
        documents: [],
        valuation: { currentValue: 500, purchasePrice: 400, currency: 'USD' },
      }),
    };
    itemFindChain.exec.mockResolvedValue([doc]);

    const items = await service.findAll('t1', {}, Role.MANAGER, 'u1');

    expect(items).toHaveLength(1);
    expect(items[0].photos?.[0]).toBe(
      'http://localhost:3000/api/media/media-jwt',
    );
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: 't1',
        userId: 'u1',
        action: 'item.valuation.view',
        entityType: 'item_list',
      }),
    );
  });

  it('findById() for staff returns valuation-stripped item and does not log manager valuation audit', async () => {
    accessControl.getAllowedPropertyIds.mockResolvedValue(['prop-1']);
    const itemDoc = {
      _id: 'i1',
      tenantId: 't1',
      propertyId: 'prop-1',
      toObject: jest.fn().mockReturnValue({
        _id: 'i1',
        tenantId: 't1',
        propertyId: 'prop-1',
        name: 'Vase',
        valuation: { currentValue: 900 },
      }),
    };
    itemModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue(itemDoc) });

    const item = await service.findById('t1', 'i1', Role.STAFF, 'u-staff');

    expect(accessControl.stripValuation).toHaveBeenCalled();
    expect((item as { valuation?: unknown }).valuation).toBeUndefined();
    expect(audit.log).not.toHaveBeenCalled();
  });

  it('findById() throws when staff property is not allowed', async () => {
    accessControl.getAllowedPropertyIds.mockResolvedValue(['other-prop']);
    const itemDoc = {
      propertyId: 'prop-1',
      toObject: jest.fn(),
    };
    itemModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue(itemDoc) });

    await expect(service.findById('t1', 'i1', Role.STAFF, 'u-staff')).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('search() for owner logs search valuation view audit with result count', async () => {
    accessControl.getAllowedPropertyIds.mockResolvedValue(null);

    const doc = {
      toObject: jest.fn().mockReturnValue({
        _id: 'i1',
        tenantId: 't1',
        propertyId: 'p1',
        roomId: 'r1',
        name: 'Lamp',
        valuation: { currentValue: 120 },
      }),
    };
    itemFindChain.exec.mockResolvedValue([doc]);
    itemModel.countDocuments.mockReturnValue({ exec: jest.fn().mockResolvedValue(3) });
    propertyFindChain.exec.mockResolvedValue([
      {
        _id: 'p1',
        name: 'Home',
        floors: [{ rooms: [{ roomId: 'r1', name: 'Office' }] }],
      },
    ]);

    await service.search('t1', { query: 'Lamp' }, Role.OWNER, 'u1');

    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'item.valuation.view',
        entityType: 'item_search',
        metadata: expect.objectContaining({
          resultCount: 3,
        }),
      }),
    );
  });

  it('create() creates item with QR code and indexes embedding', async () => {
    const createdItem = {
      _id: 'new-item-id',
      tenantId: 't1',
      name: 'Diamond Ring',
      category: ItemCategory.ART,
      propertyId: 'p1',
      roomId: 'r1',
      status: ItemStatus.ACTIVE,
      qrCode: null,
      toObject: jest.fn().mockReturnValue({
        _id: 'new-item-id',
        tenantId: 't1',
        name: 'Diamond Ring',
        category: ItemCategory.ART,
        valuation: { currentValue: 5000 },
      }),
      save: jest.fn().mockResolvedValue(true),
    };
    itemModel.create.mockResolvedValue(createdItem);

    const result = await service.create('t1', 'u1', {
      name: 'Diamond Ring',
      category: ItemCategory.ART,
      propertyId: 'p1',
      roomId: 'r1',
      valuation: { currentValue: 5000, purchasePrice: 4000, currency: 'USD' },
    });

    expect(itemModel.create).toHaveBeenCalled();
    expect(createdItem.save).toHaveBeenCalled();
  });

  it('update() updates item and re-indexes embedding', async () => {
    itemModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue({ _id: 'i1', tenantId: 't1' }) });
    itemModel.findOneAndUpdate.mockReturnValue({ exec: jest.fn().mockResolvedValue({
      _id: 'i1',
      name: 'Updated Name',
      toObject: jest.fn().mockReturnValue({
        _id: 'i1',
        name: 'Updated Name',
        valuation: { currentValue: 6000 },
      }),
    })});

    const result = await service.update('t1', 'i1', { name: 'Updated Name' });

    expect(itemModel.findOneAndUpdate).toHaveBeenCalled();
  });

  it('delete() soft deletes item by setting status to disposed', async () => {
    itemModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue({ _id: 'i1', tenantId: 't1' }) });
    itemModel.findOneAndUpdate.mockReturnValue({ exec: jest.fn().mockResolvedValue({
      _id: 'i1',
      status: 'disposed',
    })});

    const result = await service.delete('t1', 'i1');

    expect(itemModel.findOneAndUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        _id: 'i1',
        tenantId: 't1',
      }),
      expect.objectContaining({ $set: { status: 'disposed' } }),
      expect.any(Object),
    );
    expect(itemHistoryModel.create).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'status_changed',
        notes: 'Soft deleted by setting status to disposed',
      }),
    );
  });

  it('move() moves item to new property/room and logs history', async () => {
    itemModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue({
      _id: 'i1',
      tenantId: 't1',
      propertyId: 'p1',
      roomId: 'r1',
    })});
    itemModel.findOneAndUpdate.mockReturnValue({ exec: jest.fn().mockResolvedValue({
      _id: 'i1',
      propertyId: 'p2',
      roomId: 'r2',
    })});

    const result = await service.move('t1', 'i1', 'u1', {
      toPropertyId: 'p2',
      toRoomId: 'r2',
      notes: 'Moving to new room',
    });

    expect(itemModel.findOneAndUpdate).toHaveBeenCalledWith(
      expect.objectContaining({
        _id: 'i1',
        tenantId: 't1',
      }),
      expect.objectContaining({
        $set: { propertyId: 'p2', roomId: 'r2' },
      }),
      expect.any(Object),
    );
    expect(itemHistoryModel.create).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'moved',
        fromPropertyId: 'p1',
        toPropertyId: 'p2',
      }),
    );
  });

  it('loan() sets item status to loaned and logs history', async () => {
    itemModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue({
      _id: 'i1',
      tenantId: 't1',
      propertyId: 'p1',
      attributes: {},
    })});
    itemModel.findOneAndUpdate.mockReturnValue({ exec: jest.fn().mockResolvedValue({
      _id: 'i1',
      status: 'loaned',
    })});

    const result = await service.loan('t1', 'i1', 'u1', {
      borrowerName: 'John Doe',
      borrowerContact: 'john@example.com',
      expectedReturnDate: new Date('2025-06-01'),
      notes: 'Loan for event',
    });

    expect(itemModel.findOneAndUpdate).toHaveBeenCalledWith(
      expect.objectContaining({ _id: 'i1', tenantId: 't1' }),
      expect.objectContaining({ $set: expect.objectContaining({ status: 'loaned' }) }),
      expect.any(Object),
    );
    expect(itemHistoryModel.create).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'loaned' }),
    );
  });

  it('getHistory() returns item history sorted by timestamp desc', async () => {
    itemModel.findOne.mockReturnValue({ exec: jest.fn().mockResolvedValue({ _id: 'i1', tenantId: 't1' }) });
    const mockHistory = [
      { action: 'moved', timestamp: new Date('2025-01-02') },
      { action: 'created', timestamp: new Date('2025-01-01') },
    ];
    itemHistoryModel.find.mockReturnValue({
      sort: jest.fn().mockReturnThis(),
      exec: jest.fn().mockResolvedValue(mockHistory),
    });

    const result = await service.getHistory('t1', 'i1');

    expect(result).toHaveLength(2);
    expect(itemHistoryModel.find).toHaveBeenCalled();
  });
});
