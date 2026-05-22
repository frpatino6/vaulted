import { HttpException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { GeminiClient } from '../shared/gemini.client';
import { AiHelpService } from './ai-help.service';

jest.mock('uuid', () => ({ v4: jest.fn(() => 'help-session-id') }));

describe('AiHelpService', () => {
  let redis: jest.Mocked<Pick<Redis, 'incr' | 'expire' | 'get' | 'set'>>;
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
    };

    geminiClient = {
      chat: jest.fn().mockResolvedValue({
        text: '1. Open Inventory.\n2. Tap Add.',
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

    expect(result).toEqual({
      answer: '1. Open Inventory.\n2. Tap Add.',
      sessionId: 'help-session-id',
      suggestions: [
        'How do I add a new item?',
        'How do I filter items by room?',
        'How do I find items on loan?',
      ],
    });
    expect(geminiClient.chat).toHaveBeenCalledWith(
      expect.stringContaining('Screen: inventory'),
      [],
      'How do I add an item?',
    );
    expect(redis.set).toHaveBeenCalledWith(
      'ai:help:session:tenant-1:user-1:help-session-id',
      JSON.stringify([
        { role: 'user', content: 'How do I add an item?' },
        { role: 'model', content: '1. Open Inventory.\n2. Tap Add.' },
      ]),
      'EX',
      3600,
    );
  });

  it('loads existing tenant and user scoped session history', async () => {
    redis.get.mockResolvedValue(
      JSON.stringify([
        { role: 'user', content: 'How do I loan an item?' },
        { role: 'model', content: 'Open Movements.' },
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
        { role: 'model', content: 'Open Movements.' },
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
});
