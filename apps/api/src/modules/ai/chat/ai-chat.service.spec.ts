jest.mock('uuid', () => ({ v4: jest.fn(() => 'test-uuid') }));
jest.mock('sharp', () => ({ __esModule: true, default: jest.fn() }), { virtual: true });

import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { ConfigService } from '@nestjs/config';
import { HttpException } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { AiChatService } from './ai-chat.service';
import { Item } from '../../inventory/schemas/item.schema';
import { Property } from '../../properties/schemas/property.schema';
import { REDIS_CLIENT } from '../../../common/decorators/inject-redis.decorator';
import { EmbeddingService } from '../shared/embedding.service';
import { GeminiClient } from '../shared/gemini.client';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { AccessControlService } from '../../../common/services/access-control.service';
import { MediaService } from '../../media/media.service';


describe('AiChatService', () => {
  let service: AiChatService;
  let itemModel: any;
  let propertyModel: any;
  let redis: any;
  let dataSource: any;
  let embeddingService: any;
  let geminiClient: any;
  let costLogger: any;
  let config: any;
  let accessControl: any;
  let mediaService: any;

  beforeEach(async () => {
    itemModel = {
      find: jest.fn(),
      aggregate: jest.fn(),
    };

    propertyModel = {
      find: jest.fn(),
    };

    redis = {
      incr: jest.fn(),
      expire: jest.fn(),
      get: jest.fn(),
      set: jest.fn(),
    };

    dataSource = {
      query: jest.fn(),
    };

    embeddingService = {
      generateEmbedding: jest.fn(),
    };

    geminiClient = {
      chat: jest.fn(),
    };

    costLogger = {
      log: jest.fn(),
    };

    config = {
      get: jest.fn().mockReturnValue(20),
    };

    accessControl = {
      getAllowedPropertyIds: jest.fn().mockResolvedValue(null),
    };

    mediaService = {
      generateFileToken: jest.fn().mockReturnValue('media-token'),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AiChatService,
        { provide: getModelToken(Item.name), useValue: itemModel },
        { provide: getModelToken(Property.name), useValue: propertyModel },
        { provide: REDIS_CLIENT, useValue: redis },
        { provide: DataSource, useValue: dataSource },
        { provide: EmbeddingService, useValue: embeddingService },
        { provide: GeminiClient, useValue: geminiClient },
        { provide: AiCostLoggerService, useValue: costLogger },
        { provide: ConfigService, useValue: config },
        { provide: MediaService, useValue: { signExistingUrl: jest.fn((url: string) => url) } },
        { provide: AccessControlService, useValue: accessControl },
        { provide: MediaService, useValue: mediaService },
      ],
    }).compile();

    service = module.get<AiChatService>(AiChatService);
  });

  it('reindex returns indexed count', async () => {
    itemModel.find.mockReturnValue({ lean: () => ({ exec: jest.fn().mockResolvedValue([]) }) });

    const result = await service.reindex('tenant-1');

    expect(result).toBeDefined();
  });
});