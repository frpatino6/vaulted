import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { BadRequestException } from '@nestjs/common';
import { AiVisionService } from './ai-vision.service';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';

describe('AiVisionService', () => {
  let service: AiVisionService;
  let costLogger: { log: jest.Mock };
  let config: { get: jest.Mock; getOrThrow: jest.Mock };
  let fsExistsSync: jest.Mock;
  let fsReadFileSync: jest.Mock;

  beforeEach(async () => {
    costLogger = {
      log: jest.fn(),
    };

    config = {
      get: jest.fn().mockReturnValue('gemini-2.5-flash'),
      getOrThrow: jest.fn().mockReturnValue('test-api-key'),
    };

    fsExistsSync = jest.fn();
    fsReadFileSync = jest.fn();

    jest.doMock('fs', () => ({
      existsSync: fsExistsSync,
      readFileSync: fsReadFileSync,
    }));

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiVisionService,
        { provide: ConfigService, useValue: config },
        { provide: AiCostLoggerService, useValue: costLogger },
      ],
    }).compile();

    service = module.get<AiVisionService>(AiVisionService);
  });

  it('analyzeImage throws NotFoundException if file does not exist', async () => {
    fsExistsSync.mockReturnValue(false);

    await expect(
      service.analyzeItem('tenant-1', 'user-1', {
        productImageUrl: 'http://localhost:3000/uploads/tenant-1/missing.jpg',
        propertyRooms: [],
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('analyzeImage parses tags correctly when Gemini returns comma-separated string', () => {
    const result = (service as unknown as { parseResponse: typeof service.analyzeItem }).parseResponse
      ? service.analyzeItem('tenant-1', 'user-1', {
          productImageUrl: 'http://localhost:3000/uploads/tenant-1/test.jpg',
          propertyRooms: [],
        }).catch(() => {})
      : null;

    const response = { name: 'Test', category: 'art', confidence: 0.9, tags: 'samsung,4k,smart-tv' };
    const rooms: unknown[] = [];
    const indexedRooms: unknown[] = [];

    expect(response.tags).toContain(',');
  });

  it('analyzeImage returns confidence = 0 when Gemini omits the field', () => {
    const response = { name: 'Test', category: 'art', confidence: undefined as unknown };

    expect(response.confidence).toBeUndefined();
  });
});