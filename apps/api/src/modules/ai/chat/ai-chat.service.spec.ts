import { ConflictException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { getModelToken } from '@nestjs/mongoose';
import { Test } from '@nestjs/testing';
import { DataSource } from 'typeorm';

import { REDIS_CLIENT } from '../../../common/decorators/inject-redis.decorator';
import { AccessControlService } from '../../access-control/access-control.service';
import { Item } from '../../inventory/schemas/item.schema';
import { MediaService } from '../../media/media.service';
import { Property } from '../../properties/schemas/property.schema';
import { AiChatService } from './ai-chat.service';
import { AiCostLoggerService } from '../ai-cost-logger.service';
import { EmbeddingService } from '../embedding.service';
import { GeminiClient } from '../gemini.client';

describe('AiChatService reindex', () => {
  let service: AiChatService;
  const redis = {
    set: jest.fn(),
    get: jest.fn(),
    del: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();

    const moduleRef = await Test.createTestingModule({
      providers: [
        AiChatService,
        { provide: getModelToken(Item.name), useValue: {} },
        { provide: getModelToken(Property.name), useValue: {} },
        { provide: REDIS_CLIENT, useValue: redis },
        { provide: DataSource, useValue: {} },
        { provide: EmbeddingService, useValue: {} },
        { provide: GeminiClient, useValue: {} },
        { provide: AiCostLoggerService, useValue: {} },
        { provide: ConfigService, useValue: {} },
        { provide: MediaService, useValue: {} },
        { provide: AccessControlService, useValue: {} },
      ],
    }).compile();

    service = moduleRef.get(AiChatService);
  });

  it('rejects a second reindex while the tenant lock is held', async () => {
    redis.set.mockResolvedValue(null);

    await expect(service.reindex('tenant-1')).rejects.toThrow(ConflictException);
    expect(redis.set).toHaveBeenCalledWith(
      'ai:reindex:lock:tenant-1',
      '1',
      'EX',
      900,
      'NX',
    );
  });
});