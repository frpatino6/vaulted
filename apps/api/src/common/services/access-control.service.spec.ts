import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { AccessControlService } from './access-control.service';
import { User } from '../../modules/users/entities/user.entity';
import { Role } from '../enums/role.enum';

describe('AccessControlService', () => {
  let service: AccessControlService;
  let userRepository: { findOne: jest.Mock };

  beforeEach(async () => {
    userRepository = {
      findOne: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AccessControlService,
        { provide: getRepositoryToken(User), useValue: userRepository },
      ],
    }).compile();

    service = module.get<AccessControlService>(AccessControlService);
  });

  it('getAllowedPropertyIds returns null for OWNER', async () => {
    const result = await service.getAllowedPropertyIds('user-1', Role.OWNER);
    expect(result).toBeNull();
  });

  it('getAllowedPropertyIds returns null for MANAGER', async () => {
    const result = await service.getAllowedPropertyIds('user-1', Role.MANAGER);
    expect(result).toBeNull();
  });

  it('getAllowedPropertyIds returns propertyIds for STAFF', async () => {
    userRepository.findOne.mockResolvedValue({ propertyIds: ['p1', 'p2'] });
    const result = await service.getAllowedPropertyIds('user-1', Role.STAFF);
    expect(result).toEqual(['p1', 'p2']);
  });

  it('getAllowedPropertyIds returns empty array when STAFF has no properties', async () => {
    userRepository.findOne.mockResolvedValue({ propertyIds: [] });
    const result = await service.getAllowedPropertyIds('user-1', Role.STAFF);
    expect(result).toEqual([]);
  });

  it('getAllowedPropertyIds returns propertyIds for AUDITOR', async () => {
    userRepository.findOne.mockResolvedValue({ propertyIds: ['p1'] });
    const result = await service.getAllowedPropertyIds('user-1', Role.AUDITOR);
    expect(result).toEqual(['p1']);
  });

  it('stripValuation removes valuation field from item', () => {
    const item = {
      id: 'item-1',
      name: 'Test Item',
      valuation: { currentValue: 5000, purchasePrice: 4000 },
    };

    const result = service.stripValuation(item);

    expect((result as { valuation?: unknown }).valuation).toBeUndefined();
    expect(result).toHaveProperty('id', 'item-1');
    expect(result).toHaveProperty('name', 'Test Item');
  });

  it('stripValuation handles item with toObject method', () => {
    const item = {
      toObject() {
        return { id: 'item-2', name: 'Test', valuation: { currentValue: 1000 } };
      },
    };

    const result = service.stripValuation(item);

    expect((result as { valuation?: unknown }).valuation).toBeUndefined();
  });
});