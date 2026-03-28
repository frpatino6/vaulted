import { HttpException, HttpStatus, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { DataSource } from 'typeorm';
import { InjectRedis } from '../../../common/decorators/inject-redis.decorator';
import Redis from 'ioredis';
import { v4 as uuidv4 } from 'uuid';
import { EmbeddingService } from '../shared/embedding.service';
import { GeminiClient, GeminiChatMessage } from '../shared/gemini.client';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { ChatRequestDto } from './dto/chat-request.dto';
import { Item, ItemDocument } from '../../inventory/schemas/item.schema';
import { Property, PropertyDocument } from '../../properties/schemas/property.schema';

const SYSTEM_PROMPT = `You are Vaulted, a premium AI assistant for high-net-worth family inventory management.
You help owners find items, get valuations, and manage their collections across multiple properties.
Answer concisely in English. When listing items, be specific about location (property + room).
If you cannot find relevant items, say so honestly. Never fabricate item details.`;

export interface ChatItemResult {
  id: string;
  name: string;
  category: string;
  status: string;
  propertyName: string | null;
  roomName: string | null;
  photos: string[];
  valuation: { currentValue: number; currency: string } | null;
  score: number;
}

export interface ChatResponse {
  answer: string;
  items: ChatItemResult[];
  sessionId: string;
  sources: string[];
}

interface SessionTurn {
  role: 'user' | 'model';
  content: string;
}

@Injectable()
export class AiChatService {
  private readonly logger = new Logger(AiChatService.name);
  private readonly rateLimit: number;
  private readonly sessionTtl = 3600;
  private readonly maxHistoryTurns = 10;

  constructor(
    @InjectModel(Item.name) private readonly itemModel: Model<ItemDocument>,
    @InjectModel(Property.name) private readonly propertyModel: Model<PropertyDocument>,
    @InjectRedis() private readonly redis: Redis,
    private readonly dataSource: DataSource,
    private readonly embeddingService: EmbeddingService,
    private readonly geminiClient: GeminiClient,
    private readonly costLogger: AiCostLoggerService,
    private readonly config: ConfigService,
  ) {
    this.rateLimit = config.get<number>('AI_CHAT_RATE_LIMIT_PER_MINUTE') ?? 20;
  }

  async chat(tenantId: string, userId: string, dto: ChatRequestDto): Promise<ChatResponse> {
    await this.enforceRateLimit(tenantId);

    const sessionId = dto.sessionId ?? uuidv4();
    const history = await this.getSessionHistory(sessionId);

    const queryEmbedding = await this.embeddingService.generateEmbedding(dto.query);
    const vectorRows = await this.vectorSearch(tenantId, queryEmbedding, dto.propertyId);
    const itemIds = vectorRows.map((r) => r.item_id);
    const scoreMap = new Map(vectorRows.map((r) => [r.item_id, r.score]));

    const items = await this.fetchItemsWithLocation(tenantId, itemIds);

    const context = items
      .map((item) => {
        const val = item.valuation;
        const valuePart =
          val?.currentValue ? ` | value: ${val.currentValue} ${(val.currency as string | undefined) ?? 'USD'}` : '';
        return (
          `- ${item.name} (${item.category}${item.subcategory ? '/' + String(item.subcategory) : ''})` +
          ` | status: ${item.status}` +
          ` | location: ${item.propertyName ?? 'unknown'} → ${item.roomName ?? 'unknown room'}${item.locationDetail ? ' → ' + String(item.locationDetail) : ''}` +
          valuePart
        );
      })
      .join('\n');

    const userMessage = context
      ? `Context (relevant inventory items):\n${context}\n\nQuestion: ${dto.query}`
      : dto.query;

    const geminiHistory: GeminiChatMessage[] = history.map((t) => ({
      role: t.role,
      content: t.content,
    }));

    const result = await this.geminiClient.chat(SYSTEM_PROMPT, geminiHistory, userMessage);

    void this.costLogger.log({
      tenantId,
      userId,
      feature: 'chat',
      model: this.config.get<string>('AI_CHAT_MODEL') ?? 'gemini-2.0-flash',
      inputTokens: result.inputTokens,
      outputTokens: result.outputTokens,
    });

    await this.updateSessionHistory(sessionId, dto.query, result.text);

    const chatItems: ChatItemResult[] = items
      .map((item) => ({
        id: item.id,
        name: item.name,
        category: String(item.category),
        status: String(item.status ?? 'active'),
        propertyName: item.propertyName,
        roomName: item.roomName,
        photos: (item.photos as string[] | undefined) ?? [],
        valuation:
          item.valuation?.currentValue
            ? {
                currentValue: item.valuation.currentValue as number,
                currency: (item.valuation.currency as string | undefined) ?? 'USD',
              }
            : null,
        score: scoreMap.get(item.id) ?? 0,
      }))
      .sort((a, b) => b.score - a.score)
      .slice(0, 5);

    return { answer: result.text, items: chatItems, sessionId, sources: chatItems.map((i) => i.name) };
  }

  async reindex(tenantId: string): Promise<{ indexed: number }> {
    const items = await this.itemModel.find({ tenantId }).lean().exec();
    let indexed = 0;

    for (let i = 0; i < items.length; i += 10) {
      const batch = items.slice(i, i + 10);
      await Promise.allSettled(
        batch.map(async (item) => {
          try {
            const text = this.embeddingService.buildItemText(item);
            const embedding = await this.embeddingService.generateEmbedding(text);
            await this.upsertEmbedding(String(item._id), tenantId, embedding);
            indexed++;
          } catch (err) {
            this.logger.error(`Reindex failed for item ${String(item._id)}`, err);
          }
        }),
      );
    }

    return { indexed };
  }

  async upsertEmbedding(itemId: string, tenantId: string, embedding: number[]): Promise<void> {
    const vector = `[${embedding.join(',')}]`;
    await this.dataSource.query(
      `INSERT INTO item_embeddings (item_id, tenant_id, embedding, updated_at)
       VALUES ($1, $2, $3::vector, NOW())
       ON CONFLICT (item_id) DO UPDATE
         SET embedding = EXCLUDED.embedding, updated_at = NOW()`,
      [itemId, tenantId, vector],
    );
  }

  private async vectorSearch(
    tenantId: string,
    embedding: number[],
    propertyId?: string,
  ): Promise<Array<{ item_id: string; score: number }>> {
    const vector = `[${embedding.join(',')}]`;
    const rows = await this.dataSource.query<Array<{ item_id: string; score: string }>>(
      `SELECT item_id, 1 - (embedding <=> $1::vector) AS score
       FROM item_embeddings
       WHERE tenant_id = $2
       ORDER BY embedding <=> $1::vector
       LIMIT 20`,
      [vector, tenantId],
    );

    // propertyId filter applied post-query to avoid JOIN complexity
    if (!propertyId) return rows.map((r) => ({ item_id: r.item_id, score: Number(r.score) }));

    const propertyItems = await this.itemModel
      .find({ propertyId, tenantId })
      .select('_id')
      .lean()
      .exec();
    const allowed = new Set(propertyItems.map((i) => String(i._id)));
    return rows
      .filter((r) => allowed.has(r.item_id))
      .map((r) => ({ item_id: r.item_id, score: Number(r.score) }));
  }

  private async fetchItemsWithLocation(
    tenantId: string,
    itemIds: string[],
  ): Promise<Array<ItemDocument & { id: string; propertyName: string | null; roomName: string | null }>> {
    if (!itemIds.length) return [];

    const items = await this.itemModel
      .find({ _id: { $in: itemIds }, tenantId })
      .lean()
      .exec();

    const propertyIds = [...new Set(items.map((i) => String(i.propertyId)))];
    const properties = await this.propertyModel
      .find({ _id: { $in: propertyIds }, tenantId })
      .select('_id name floors')
      .lean()
      .exec();

    const propertyMap = new Map(properties.map((p) => [String(p._id), p]));

    return items.map((item) => {
      const property = propertyMap.get(String(item.propertyId));
      const propertyName = property?.name ?? null;
      let roomName: string | null = null;
      if (property && item.roomId) {
        for (const floor of property.floors ?? []) {
          const room = floor.rooms?.find((r) => r.roomId === String(item.roomId));
          if (room) { roomName = room.name; break; }
        }
      }
      return { ...item, id: String(item._id), propertyName, roomName } as ItemDocument & {
        id: string;
        propertyName: string | null;
        roomName: string | null;
      };
    });
  }

  private async enforceRateLimit(tenantId: string): Promise<void> {
    const key = `ai:chat:ratelimit:${tenantId}`;
    const count = await this.redis.incr(key);
    if (count === 1) await this.redis.expire(key, 60);
    if (count > this.rateLimit) {
      throw new HttpException('AI chat rate limit exceeded', HttpStatus.TOO_MANY_REQUESTS);
    }
  }

  private async getSessionHistory(sessionId: string): Promise<SessionTurn[]> {
    const raw = await this.redis.get(`ai:chat:session:${sessionId}`);
    if (!raw) return [];
    try {
      return JSON.parse(raw) as SessionTurn[];
    } catch {
      return [];
    }
  }

  private async updateSessionHistory(
    sessionId: string,
    userMessage: string,
    modelResponse: string,
  ): Promise<void> {
    const history = await this.getSessionHistory(sessionId);
    history.push({ role: 'user', content: userMessage });
    history.push({ role: 'model', content: modelResponse });
    const trimmed = history.slice(-this.maxHistoryTurns * 2);
    await this.redis.set(
      `ai:chat:session:${sessionId}`,
      JSON.stringify(trimmed),
      'EX',
      this.sessionTtl,
    );
  }
}
