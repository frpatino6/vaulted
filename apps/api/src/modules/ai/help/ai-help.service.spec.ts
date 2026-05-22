import { HttpException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DataSource } from 'typeorm';
import Redis from 'ioredis';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { EmbeddingService } from '../shared/embedding.service';
import { GeminiClient } from '../shared/gemini.client';
import { AiHelpService } from './ai-help.service';

jest.mock('uuid', () => ({ v4: jest.fn(() => 'help-session-id') }));

const MOCK_EMBEDDING = Array.from({ length: 3072 }, (_, i) => i * 0.001);

const MOCK_CHUNK_ROW = {
  chunk_id: 'asset-directory',
  title: 'Asset Directory — Browse, Search & Filter',
  content: 'The main inventory screen is called Asset Directory.',
};

describe('AiHelpService', () => {
  let redis: jest.Mocked<Pick<Redis, 'incr' | 'expire' | 'get' | 'set' | 'lpush' | 'ltrim'>>;
  let dataSource: jest.Mocked<Pick<DataSource, 'query'>>;
  let embeddingService: jest.Mocked<Pick<EmbeddingService, 'generateEmbedding'>>;
  let geminiClient: jest.Mocked<Pick<GeminiClient, 'chat'>>;
  let costLogger: jest.Mocked<Pick<AiCostLoggerService, 'log'>>;
  let config: jest.Mocked<Pick<ConfigService, 'get'>>;
  let service: AiHelpService;

  beforeEach(() => {
    redis = {
      incr: jest.fn().mockResolvedValue(1),
      expire: jest.fn().mockResolvedValue(1),
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockResolvedValue('OK'),
      lpush: jest.fn().mockResolvedValue(1),
      ltrim: jest.fn().mockResolvedValue('OK'),
    };

    dataSource = {
      query: jest.fn().mockResolvedValue([MOCK_CHUNK_ROW]),
    };

    embeddingService = {
      generateEmbedding: jest.fn().mockResolvedValue(MOCK_EMBEDDING),
    };

    geminiClient = {
      chat: jest.fn().mockResolvedValue({
        text: '1. Open Asset Directory.\n2. Tap Add.',
        inputTokens: 12,
        outputTokens: 8,
      }),
    };

    costLogger = {
      log: jest.fn().mockResolvedValue(undefined),
    };

    config = {
      get: jest.fn((key: string) => {
        if (key === 'AI_HELP_RATE_LIMIT_PER_MINUTE') return 30;
        if (key === 'AI_CHAT_MODEL') return 'gemini-2.5-flash';
        return undefined;
      }),
    } as jest.Mocked<Pick<ConfigService, 'get'>>;

    service = new AiHelpService(
      redis as unknown as Redis,
      dataSource as unknown as DataSource,
      embeddingService as unknown as EmbeddingService,
      geminiClient as unknown as GeminiClient,
      costLogger as unknown as AiCostLoggerService,
      config as unknown as ConfigService,
    );
  });

  it('returns a help answer with a generated session id and screen suggestions', async () => {
    const result = await service.chat('tenant-1', 'user-1', {
      query: 'How do I add an item?',
      currentScreen: 'inventory',
    });

    expect(result.answer).toBe('1. Open Asset Directory.\n2. Tap Add.');
    expect(result.sessionId).toBe('help-session-id');
    expect(result.suggestions).toEqual([
      'How do I add a new item?',
      'How do I filter items by status?',
      'How do I find items currently on loan?',
    ]);

    expect(embeddingService.generateEmbedding).toHaveBeenCalledWith('How do I add an item?');
    expect(geminiClient.chat).toHaveBeenCalledWith(
      expect.stringContaining('Asset Directory'),
      [],
      'How do I add an item?',
    );
  });

  it('loads existing tenant and user scoped session history', async () => {
    redis.get.mockResolvedValue(
      JSON.stringify([
        { role: 'user', content: 'How do I loan an item?' },
        { role: 'model', content: 'Open Operations.' },
      ]),
    );

    await service.chat('tenant-1', 'user-1', {
      query: 'How do I return it?',
      sessionId: 'existing-session',
      currentScreen: 'movements',
    });

    expect(redis.get).toHaveBeenCalledWith('ai:help:session:tenant-1:user-1:existing-session');
    expect(geminiClient.chat).toHaveBeenCalledWith(
      expect.any(String),
      [
        { role: 'user', content: 'How do I loan an item?' },
        { role: 'model', content: 'Open Operations.' },
      ],
      'How do I return it?',
    );
  });

  it('throws when the tenant rate limit is exceeded', async () => {
    redis.incr.mockResolvedValue(31);

    await expect(
      service.chat('tenant-1', 'user-1', {
        query: 'How do I add an item?',
      }),
    ).rejects.toBeInstanceOf(HttpException);

    expect(geminiClient.chat).not.toHaveBeenCalled();
  });

  it('falls back to full KB when RAG retrieval fails', async () => {
    dataSource.query.mockRejectedValue(new Error('DB down'));

    const result = await service.chat('tenant-1', 'user-1', {
      query: 'How do I add an item?',
    });

    expect(result.answer).toBe('1. Open Asset Directory.\n2. Tap Add.');
    expect(geminiClient.chat).toHaveBeenCalledWith(
      expect.stringContaining('Asset Directory'),
      [],
      'How do I add an item?',
    );
  });
});
