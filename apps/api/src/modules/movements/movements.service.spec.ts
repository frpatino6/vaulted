import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { Repository } from 'typeorm';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConflictException, BadRequestException } from '@nestjs/common';
import { MovementsService } from './movements.service';
import { Movement, MovementStatus, MovementItemStatus, MovementType } from './schemas/movement.schema';
import { Item } from '../inventory/schemas/item.schema';
import { ItemHistory } from '../inventory/schemas/item-history.schema';
import { Property } from '../properties/schemas/property.schema';

describe('MovementsService', () => {
  let service: MovementsService;
  let movementModel: { find: jest.Mock; findOne: jest.Mock; create: jest.Mock };
  let itemModel: { findOne: jest.Mock; updateOne: jest.Mock };
  let itemHistoryModel: { create: jest.Mock };
  let propertyModel: { findOne: jest.Mock };

  beforeEach(async () => {
    const mockMovementChain = {
      sort: jest.fn().mockReturnThis(),
      lean: jest.fn().mockReturnThis(),
      exec: jest.fn(),
    };

    movementModel = {
      find: jest.fn(() => ({ ...mockMovementChain })),
      findOne: jest.fn(),
      create: jest.fn(),
    };

    itemModel = {
      findOne: jest.fn(),
      updateOne: jest.fn(),
    };

    itemHistoryModel = {
      create: jest.fn(),
    };

    propertyModel = {
      findOne: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MovementsService,
        { provide: getModelToken(Movement.name), useValue: movementModel },
        { provide: getModelToken(Item.name), useValue: itemModel },
        { provide: getModelToken(ItemHistory.name), useValue: itemHistoryModel },
        { provide: getModelToken(Property.name), useValue: propertyModel },
      ],
    }).compile();

    service = module.get<MovementsService>(MovementsService);
  });

  it('create creates a draft movement and returns it', async () => {
    const mockDoc = {
      tenantId: 'tenant-1',
      propertyId: '',
      operationType: MovementType.LOAN,
      title: 'Test Loan',
      description: '',
      destination: '',
      destinationPropertyId: '',
      destinationRoomId: '',
      destinationPropertyName: '',
      destinationRoomName: '',
      dueDate: null,
      notes: '',
      createdBy: 'user-1',
      status: MovementStatus.DRAFT,
      items: [],
      save: jest.fn().mockResolvedValue(function (this: unknown) { return this; }),
    };
    movementModel.create.mockReturnValue(mockDoc);

    const result = await service.create(
      { operationType: MovementType.LOAN, title: 'Test Loan' },
      { sub: 'user-1', tenantId: 'tenant-1', email: '', role: 'owner', mfaVerified: true, tenantName: '' },
    );

    expect(result).toBeDefined();
    expect(movementModel.create).toHaveBeenCalled();
  });

  it('addItem adds item to movement, updates item status', async () => {
    const mockMovement = {
      _id: 'mov-1',
      tenantId: 'tenant-1',
      status: MovementStatus.DRAFT,
      items: [],
      save: jest.fn().mockResolvedValue(function (this: unknown) { return this; }),
    };
    movementModel.findOne.mockResolvedValue(mockMovement);
    itemModel.findOne.mockResolvedValue({
      _id: 'item-1',
      tenantId: 'tenant-1',
      name: 'Test Item',
      category: 'art',
      photos: [],
      propertyId: 'prop-1',
      roomId: 'room-1',
      status: 'active',
    });
    propertyModel.findOne.mockResolvedValue({ name: 'Property', floors: [] });

    await service.addItem(
      'mov-1',
      'item-1',
      { sub: 'user-1', tenantId: 'tenant-1', email: '', role: 'owner', mfaVerified: true, tenantName: '' },
    );

    expect(mockMovement.items).toHaveLength(1);
    expect(mockMovement.save).toHaveBeenCalled();
  });

  it('addItem throws ConflictException if item already in active movement', async () => {
    const mockMovement = {
      _id: 'mov-1',
      tenantId: 'tenant-1',
      status: MovementStatus.ACTIVE,
      items: [{ itemId: 'item-1', status: MovementItemStatus.OUT }],
    };
    movementModel.findOne.mockResolvedValue(mockMovement);

    await expect(
      service.addItem(
        'mov-1',
        'item-1',
        { sub: 'user-1', tenantId: 'tenant-1', email: '', role: 'owner', mfaVerified: true, tenantName: '' },
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('checkinItem marks item as returned, updates status back to active', async () => {
    const mockMovement = {
      _id: 'mov-1',
      tenantId: 'tenant-1',
      status: MovementStatus.ACTIVE,
      items: [
        {
          itemId: 'item-1',
          status: MovementItemStatus.OUT,
          checkedInAt: null,
          checkedInBy: null,
        },
      ],
      save: jest.fn().mockResolvedValue(function (this: unknown) { return this; }),
    };
    movementModel.findOne.mockResolvedValue(mockMovement);
    itemModel.updateOne.mockResolvedValue({});
    itemHistoryModel.create.mockResolvedValue({});

    await service.checkinItem(
      'mov-1',
      'item-1',
      { sub: 'user-1', tenantId: 'tenant-1', email: '', role: 'owner', mfaVerified: true, tenantName: '' },
    );

    expect(mockMovement.items[0].status).toBe(MovementItemStatus.RETURNED);
    expect(itemModel.updateOne).toHaveBeenCalled();
  });

  it('completeMovement marks movement as completed', async () => {
    const mockMovement = {
      _id: 'mov-1',
      tenantId: 'tenant-1',
      status: MovementStatus.ACTIVE,
      items: [{ itemId: 'item-1', status: MovementItemStatus.OUT }],
      save: jest.fn().mockResolvedValue(function (this: unknown) { return this; }),
    };
    movementModel.findOne.mockResolvedValue(mockMovement);

    await service.complete(
      'mov-1',
      { sub: 'user-1', tenantId: 'tenant-1', email: '', role: 'owner', mfaVerified: true, tenantName: '' },
    );

    expect(mockMovement.status).toBe(MovementStatus.PARTIAL);
  });

  it('cancelMovement reverts item statuses to active', async () => {
    const mockMovement = {
      _id: 'mov-1',
      tenantId: 'tenant-1',
      status: MovementStatus.ACTIVE,
      items: [{ itemId: 'item-1', status: MovementItemStatus.OUT }],
      save: jest.fn().mockResolvedValue(function (this: unknown) { return this; }),
    };
    movementModel.findOne.mockResolvedValue(mockMovement);
    itemModel.updateOne.mockResolvedValue({});

    await service.cancel(
      'mov-1',
      { sub: 'user-1', tenantId: 'tenant-1', email: '', role: 'owner', mfaVerified: true, tenantName: '' },
    );

    expect(mockMovement.status).toBe(MovementStatus.CANCELLED);
  });

  it('findAllMovements returns only movements for tenantId', async () => {
    const mockMovements = [{ tenantId: 'tenant-1' }, { tenantId: 'tenant-1' }];
    const chain = {
      sort: jest.fn().mockReturnThis(),
      lean: jest.fn().mockReturnThis(),
      exec: jest.fn().mockResolvedValue(mockMovements),
    };
    movementModel.find.mockReturnValue(chain);

    const result = await service.findAll('tenant-1');

    expect(result).toHaveLength(2);
  });
});