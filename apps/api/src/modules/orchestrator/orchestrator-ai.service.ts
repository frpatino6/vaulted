import {
  HttpException,
  HttpStatus,
  Injectable,
  Logger,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { DataSource } from 'typeorm';
import { v4 as uuidv4 } from 'uuid';
import { InjectRedis } from '../../common/decorators/inject-redis.decorator';
import Redis from 'ioredis';
import { EmbeddingService } from '../ai/shared/embedding.service';
import { GeminiClient } from '../ai/shared/gemini.client';
import { AiCostLoggerService } from '../ai/shared/ai-cost-logger.service';
import { Item, ItemDocument } from '../inventory/schemas/item.schema';
import { Property, PropertyDocument } from '../properties/schemas/property.schema';
import { ParseCommandDto } from './dto/parse-command.dto';
import {
  ParsedBoundingBox,
  ParsedPlanDto,
  ParsedStepDto,
  ParsedTaskGroupDto,
} from './dto/parsed-plan.dto';

type CommandType = 'prepare' | 'pack' | 'move' | 'inspect' | 'general';

const SYSTEM_PROMPT = `You are an estate operations planner for an ultra-high-net-worth household.
Your job is to convert a natural-language command into a structured operational
work plan that staff can execute item by item.
Always respond ONLY with valid JSON matching the schema provided.
Never fabricate items — only reference items from the provided inventory context.
Be concise and action-oriented. Each instruction should be a single imperative sentence.`;

const PROMPT_TAIL: Record<CommandType, string> = {
  prepare: 'Group by preparation phase: layout, setting, decoration.',
  pack: 'Group items by container or category for packing.',
  move: 'Create one group per destination room or container.',
  inspect:
    'Group by urgency based on maintenance status. Include risk score in instruction if available.',
  general: 'Group by logical operational sequence.',
};

interface GeminiStepRaw {
  stepId?: unknown;
  itemId?: unknown;
  instruction?: unknown;
}

interface GeminiGroupRaw {
  groupId?: unknown;
  title?: unknown;
  steps?: unknown;
}

interface GeminiPlanRaw {
  commandType?: unknown;
  title?: unknown;
  aiSummary?: unknown;
  targetDate?: unknown;
  destinationPropertyId?: unknown;
  taskGroups?: unknown;
}

interface ItemLocationContext {
  item: ItemDocument;
  propertyName: string;
  roomName: string;
  roomPhoto: string | undefined;
  sectionId: string | undefined;
  sectionCode: string | undefined;
  sectionFurnitureName: string | undefined;
  sectionPhoto: string | undefined;
  boundingBox: ParsedBoundingBox | undefined;
}

@Injectable()
export class OrchestratorAiService {
  private readonly logger = new Logger(OrchestratorAiService.name);
  private readonly rateLimit: number;

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
    this.rateLimit =
      config.get<number>('AI_ORCHESTRATOR_RATE_LIMIT_PER_MINUTE') ?? 10;
  }

  async parseCommand(tenantId: string, dto: ParseCommandDto): Promise<ParsedPlanDto> {
    await this.enforceRateLimit(tenantId);

    // Stage 1 — Retrieval
    const embedding = await this.embeddingService.generateEmbedding(dto.command);
    const vectorRows = await this.vectorSearch(tenantId, embedding, dto.propertyId);
    const itemIds = vectorRows.map((r) => r.item_id);

    const locationContexts = await this.fetchItemsWithLocation(tenantId, itemIds);

    const contextBlock = locationContexts
      .map(({ item, propertyName, roomName, sectionCode, sectionFurnitureName }) => {
        const loc = `${propertyName} → ${roomName} → ${sectionCode ?? 'unknown'}:${sectionFurnitureName ?? 'unknown'}`;
        return `- [${String(item._id)}] ${item.name} (${item.category}) | location: ${loc}`;
      })
      .join('\n');

    // Stage 2 — Plan generation
    const commandType = this.detectCommandType(dto.command);
    const propertyName = dto.propertyId
      ? await this.resolvePropertyName(tenantId, dto.propertyId)
      : null;

    const userMessage = `Command: "${dto.command}"
Target date hint: ${dto.targetDate ?? 'not specified'}
Property scope: ${propertyName ?? 'all properties'}

Relevant inventory items:
${contextBlock || '(no matching items found)'}

Produce a JSON work plan:
{
  "commandType": "prepare|pack|move|inspect|general",
  "title": "short plan title (max 80 chars)",
  "aiSummary": "1-2 sentence description",
  "targetDate": "ISO-8601 date or null",
  "destinationPropertyId": "propertyId or null",
  "taskGroups": [
    {
      "groupId": "uuid-v4",
      "title": "group action label",
      "steps": [
        {
          "stepId": "uuid-v4",
          "itemId": "exact itemId from context",
          "instruction": "one imperative sentence"
        }
      ]
    }
  ]
}
Do not create more than 6 groups. Do not include items not present in the context.
${PROMPT_TAIL[commandType]}`;

    const result = await this.geminiClient.chat(SYSTEM_PROMPT, [], userMessage);

    void this.costLogger.log({
      tenantId,
      userId: 'system',
      feature: 'orchestrator',
      model: this.config.get<string>('AI_CHAT_MODEL') ?? 'gemini-2.5-flash',
      inputTokens: result.inputTokens,
      outputTokens: result.outputTokens,
    });

    const rawPlan = this.parseGeminiResponse(result.text);

    // Build a lookup map for location data
    const locationMap = new Map<string, ItemLocationContext>(
      locationContexts.map((ctx) => [String(ctx.item._id), ctx]),
    );

    const taskGroups = this.buildTaskGroups(rawPlan, locationMap, dto.propertyId);

    const plan: ParsedPlanDto = {
      commandType: this.sanitizeCommandType(rawPlan.commandType),
      title: String(rawPlan.title ?? 'Untitled Plan').slice(0, 200),
      aiSummary: String(rawPlan.aiSummary ?? ''),
      targetDate:
        rawPlan.targetDate && rawPlan.targetDate !== 'null'
          ? String(rawPlan.targetDate)
          : undefined,
      targetPropertyId: dto.propertyId,
      destinationPropertyId:
        rawPlan.destinationPropertyId && rawPlan.destinationPropertyId !== 'null'
          ? String(rawPlan.destinationPropertyId)
          : undefined,
      taskGroups,
    };

    return plan;
  }

  private async vectorSearch(
    tenantId: string,
    embedding: number[],
    propertyId?: string,
  ): Promise<Array<{ item_id: string }>> {
    const vector = `[${embedding.join(',')}]`;
    const rows = await this.dataSource.query<Array<{ item_id: string }>>(
      `SELECT item_id
       FROM item_embeddings
       WHERE tenant_id = $2
       ORDER BY embedding <=> $1::vector
       LIMIT 30`,
      [vector, tenantId],
    );

    if (!propertyId) return rows;

    const propertyItems = await this.itemModel
      .find({ propertyId, tenantId })
      .select('_id')
      .lean()
      .exec();
    const allowed = new Set(propertyItems.map((i) => String(i._id)));
    return rows.filter((r) => allowed.has(r.item_id));
  }

  private async fetchItemsWithLocation(
    tenantId: string,
    itemIds: string[],
  ): Promise<ItemLocationContext[]> {
    if (!itemIds.length) return [];

    const items = await this.itemModel
      .find({ _id: { $in: itemIds }, tenantId })
      .lean()
      .exec();

    const propertyIds = [...new Set(items.map((i) => String(i.propertyId)))];
    const properties = await this.propertyModel
      .find({ _id: { $in: propertyIds }, tenantId })
      .select('_id name floors photos')
      .lean()
      .exec();

    const propertyMap = new Map(properties.map((p) => [String(p._id), p]));

    return items.map((item) => {
      const property = propertyMap.get(String(item.propertyId));
      const propertyName = property?.name ?? 'Unknown Property';
      const propertyRoomPhoto: string | undefined = property?.photos?.[0];

      let roomName = 'Unknown Room';
      let roomPhoto: string | undefined;
      let sectionId: string | undefined;
      let sectionCode: string | undefined;
      let sectionFurnitureName: string | undefined;
      let sectionPhoto: string | undefined;
      let boundingBox: ParsedBoundingBox | undefined;

      if (property && item.roomId) {
        outerLoop: for (const floor of property.floors ?? []) {
          for (const room of floor.rooms ?? []) {
            if (room.roomId === String(item.roomId)) {
              roomName = room.name;
              // Property-level photo used as room overview fallback
              roomPhoto = propertyRoomPhoto;

              if (item.sectionId) {
                const section = (room.sections ?? []).find(
                  (s) => s.sectionId === String(item.sectionId),
                );
                if (section) {
                  sectionId = section.sectionId;
                  sectionCode = section.code;
                  sectionFurnitureName = section.furnitureName;
                  sectionPhoto = section.photo;
                  if (section.boundingBox) {
                    boundingBox = {
                      x: section.boundingBox.x,
                      y: section.boundingBox.y,
                      width: section.boundingBox.width,
                      height: section.boundingBox.height,
                    };
                  }
                }
              }
              break outerLoop;
            }
          }
        }
      }

      return {
        item: item as unknown as ItemDocument,
        propertyName,
        roomName,
        roomPhoto,
        sectionId,
        sectionCode,
        sectionFurnitureName,
        sectionPhoto,
        boundingBox,
      };
    });
  }

  private async resolvePropertyName(
    tenantId: string,
    propertyId: string,
  ): Promise<string | null> {
    const property = await this.propertyModel
      .findOne({ _id: propertyId, tenantId })
      .select('name')
      .lean()
      .exec();
    return property?.name ?? null;
  }

  private detectCommandType(command: string): CommandType {
    const lower = command.toLowerCase();
    if (/prepare|set up|arrange/.test(lower)) return 'prepare';
    if (/pack|suitcase|trip|travel/.test(lower)) return 'pack';
    if (/move|transfer|send|bring/.test(lower)) return 'move';
    if (/inspect|check|maintenance|repair/.test(lower)) return 'inspect';
    return 'general';
  }

  private parseGeminiResponse(raw: string): GeminiPlanRaw {
    try {
      const cleaned = raw
        .replace(/```json\n?/g, '')
        .replace(/```\n?/g, '')
        .trim();
      return JSON.parse(cleaned) as GeminiPlanRaw;
    } catch {
      this.logger.warn('Failed to parse Gemini orchestrator response');
      throw new UnprocessableEntityException(
        'AI plan generation failed — please rephrase your command.',
      );
    }
  }

  private sanitizeCommandType(raw: unknown): CommandType {
    const valid: CommandType[] = ['prepare', 'pack', 'move', 'inspect', 'general'];
    if (typeof raw === 'string' && (valid as string[]).includes(raw)) {
      return raw as CommandType;
    }
    return 'general';
  }

  private buildTaskGroups(
    rawPlan: GeminiPlanRaw,
    locationMap: Map<string, ItemLocationContext>,
    scopedPropertyId?: string,
  ): ParsedTaskGroupDto[] {
    if (!Array.isArray(rawPlan.taskGroups)) return [];

    const groups: ParsedTaskGroupDto[] = [];

    for (const rawGroup of rawPlan.taskGroups as GeminiGroupRaw[]) {
      const groupId =
        typeof rawGroup.groupId === 'string' && rawGroup.groupId.length > 0
          ? rawGroup.groupId
          : uuidv4();

      const steps: ParsedStepDto[] = [];

      if (Array.isArray(rawGroup.steps)) {
        for (const rawStep of rawGroup.steps as GeminiStepRaw[]) {
          const itemId = typeof rawStep.itemId === 'string' ? rawStep.itemId.trim() : '';
          if (!itemId) continue;

          const ctx = locationMap.get(itemId);
          // Skip items not found in the context (AI hallucination guard)
          if (!ctx) continue;

          const stepId =
            typeof rawStep.stepId === 'string' && rawStep.stepId.length > 0
              ? rawStep.stepId
              : uuidv4();

          const item = ctx.item;
          const photos: string[] = (item.photos as string[] | undefined) ?? [];

          const step: ParsedStepDto = {
            stepId,
            itemId,
            itemName: item.name,
            itemCategory: String(item.category),
            itemPhoto: photos[0],
            roomId: item.roomId ?? undefined,
            roomName: ctx.roomName !== 'Unknown Room' ? ctx.roomName : undefined,
            roomPhoto: ctx.roomPhoto,
            sectionId: ctx.sectionId ?? item.sectionId ?? undefined,
            sectionPhoto: ctx.sectionPhoto,
            sectionCode: ctx.sectionCode,
            sectionFurnitureName: ctx.sectionFurnitureName,
            boundingBox: ctx.boundingBox,
            instruction: typeof rawStep.instruction === 'string'
              ? rawStep.instruction
              : `Handle ${item.name}.`,
          };

          steps.push(step);
        }
      }

      groups.push({
        groupId,
        title: typeof rawGroup.title === 'string' ? rawGroup.title : 'Task group',
        steps,
      });
    }

    // Remove groups with no resolved steps (AI generated empty groups)
    // then honour the spec: max 6 groups
    return groups.filter((g) => g.steps.length > 0).slice(0, 6);
  }

  private async enforceRateLimit(tenantId: string): Promise<void> {
    const key = `ai:orchestrator:ratelimit:${tenantId}`;
    const count = await this.redis.incr(key);
    if (count === 1) await this.redis.expire(key, 60);
    if (count > this.rateLimit) {
      throw new HttpException(
        'AI orchestrator rate limit exceeded',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }
}
