import { Test, TestingModule } from '@nestjs/testing';
import { getModelToken } from '@nestjs/mongoose';
import { DataSource } from 'typeorm';
import { HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AiChatService } from './ai-chat.service';
import { Item } from '../../inventory/schemas/item.schema';
import { Property } from '../../properties/schemas/property.schema';
import { REDIS_CLIENT } from '../../../common/decorators/inject-redis.decorator';
import { EmbeddingService } from '../shared/embedding.service';
import { GeminiClient } from '../shared/gemini.client';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';

describe('AiChatService', () => {
  let service: AiChatService;
  let itemModel: { find: jest.Mock; aggregate: jest.Mock };
  let propertyModel: { find: jest.Mock };
  let redis: { incr: jest.Mock; expire: jest.Mock; get: jest.Mock; set: jest.Mock };
  let dataSource: { query: jest.Mock };
  let embeddingService: { generateEmbedding: jest.Mock };
  let geminiClient: { chat: jest.Mock };
  let costLogger: { log: jest.Mock };
  let config: { get: jest.Mock };

  beforeEach(async () => {
    itemModel = {
      find: jest.fn().mockReturnValue({ lean: jest.fn().mockReturnThis(), exec: jest.fn() }),
      aggregate: jest.fn().mockReturnValue({ exec: jest.fn() }),
    };

    propertyModel = {
      find: jest.fn().mockReturnValue({ lean: jest.fn().mockReturnThis(), exec: jest.fn() }),
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
      ],
    }).compile();

    service = module.get<AiChatService>(AiChatService);
  });

  it('chat builds RAG context from MongoDB vector search results', async () => {
    redis.incr.mockResolvedValue(1);
    redis.get.mockResolvedValue(null);
    embeddingService.generateEmbedding.mockResolvedValue([0.1, 0.2]);
    dataSource.query.mockResolvedValue([{ item_id: 'item-1', score: '0.9' }]);
    itemModel.find.mockReturnValue({
      lean: jest.fn().mockReturnThis(),
      exec: jest.fn().mockResolvedValue([
        { _id: 'item-1', name: 'Watch', category: 'jewelry', subcategory: null, status: 'active', photos: [], propertyId: 'prop-1', roomId: null, propertyName: null, roomName: null, valuation: null },
      ]),
    });
    geminiClient.chat.mockResolvedValue({
      text: 'Found it',
      inputTokens: 100,
      outputTokens: 50,
    });

    const result = await service.chat('tenant-1', 'user-1', { query: 'Find my watch' });

    expect(result.answer).toBeDefined();
    expect(costLogger.log).toHaveBeenCalled();
  });

  it('chat falls back to empty context if no embeddings found', async () => {
    redis.incr.mockResolvedValue(1);
    redis.get.mockResolvedValue(null);
    embeddingService.generateEmbedding.mockResolvedValue([0.1, 0.2]);
    dataSource.query.mockResolvedValue([]);
    geminiClient.chat.mockResolvedValue({
      text: 'No items found',
      inputTokens: 50,
      outputTokens: 20,
    });

    const result = await service.chat('tenant-1', 'user-1', { query: 'Find something' });

    expect(result.items).toHaveLength(0);
  });

  it('chat enforces rate limit', async () => {
    redis.incr.mockResolvedValue(21);

    await expect(
      service.chat('tenant-1', 'user-1', { query: 'Test' }),
    ).rejects.toBeInstanceOf(HttpException);
  });

  it('chat logs token usage', async () => {
    redis.incr.mockResolvedValue(1);
    redis.get.mockResolvedValue(null);
    embeddingService.generateEmbedding.mockResolvedValue([0.1, 0.2]);
    dataSource.query.mockResolvedValue([]);
    geminiClient.chat.mockResolvedValue({
      text: 'Answer',
      inputTokens: 150,
      outputTokens: 75,
    });

    await service.chat('tenant-1', 'user-1', { query: 'Test' });

    expect(costLogger.log).toHaveBeenCalledWith(
      expect.objectContaining({
        tenantId: 'tenant-1',
        feature: 'chat',
      }),
    );
  });
});