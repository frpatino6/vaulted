import { HttpException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { AiInsuranceService } from './ai-insurance.service';
import { GeminiClient } from '../shared/gemini.client';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { InsuranceService } from '../../insurance/insurance.service';
import { Role } from '../../../common/enums/role.enum';
import { REDIS_CLIENT } from '../../../common/decorators/inject-redis.decorator';

describe('AiInsuranceService', () => {
  let service: AiInsuranceService;

  const redis = {
    incr: jest.fn(),
    expire: jest.fn(),
  };

  const geminiClient = {
    chat: jest.fn(),
  };

  const costLogger = {
    log: jest.fn(),
  };

  const insuranceService = {
    findPolicyById: jest.fn(),
    getCoverageGaps: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    redis.incr.mockResolvedValue(1);

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiInsuranceService,
        { provide: REDIS_CLIENT, useValue: redis },
        { provide: GeminiClient, useValue: geminiClient },
        { provide: AiCostLoggerService, useValue: costLogger },
        { provide: InsuranceService, useValue: insuranceService },
      ],
    }).compile();

    service = module.get<AiInsuranceService>(AiInsuranceService);
  });

  it('analyzeCoverage() requests coverage gaps with manager role for full numeric AI context', async () => {
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 120);

    insuranceService.findPolicyById.mockResolvedValue({
      provider: 'Acme',
      policyNumber: 'P-1',
      coverageType: 'home',
      totalCoverageAmount: 1_000_000,
      currency: 'USD',
      status: 'active',
      expiresAt,
      insuredItems: [],
    });

    insuranceService.getCoverageGaps.mockResolvedValue({
      uncovered: [],
      underinsured: [],
      expiredPolicies: [],
      totalUncoveredValue: 0,
      totalUnderinsuredGap: 0,
    });

    geminiClient.chat.mockResolvedValue({
      text: JSON.stringify({
        overallRisk: 'low',
        summary: 'ok',
        recommendations: [],
        priorityItems: [],
        renewalUrgency: 'none',
      }),
      inputTokens: 1,
      outputTokens: 2,
    });

    await service.analyzeCoverage('tenant-1', 'user-1', 'policy-1');

    expect(insuranceService.getCoverageGaps).toHaveBeenCalledWith(
      'tenant-1',
      'user-1',
      Role.MANAGER,
    );
    expect(costLogger.log).toHaveBeenCalled();
  });

  it('analyzeCoverage() throws when hourly rate limit is exceeded', async () => {
    redis.incr.mockResolvedValue(11);

    await expect(service.analyzeCoverage('tenant-1', 'user-1', 'policy-1')).rejects.toBeInstanceOf(
      HttpException,
    );
  });
});
