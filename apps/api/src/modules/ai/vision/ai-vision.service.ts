import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Anthropic from '@anthropic-ai/sdk';
import * as fs from 'fs';
import * as path from 'path';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { AnalyzeItemDto, PropertyRoomDto } from './dto/analyze-item.dto';

export interface RoomSuggestion {
  roomId: string;
  name: string;
  reasoning: string;
}

export interface InvoiceData {
  purchasePrice: number | null;
  purchaseDate: string | null;
  serialNumber: string | null;
  store: string | null;
  warrantyMonths: number | null;
}

export interface AnalyzeItemResult {
  name: string;
  category: string;
  subcategory: string;
  brand: string | null;
  estimatedValue: number | null;
  attributes: Record<string, unknown>;
  confidence: number;
  suggestedRoom: RoomSuggestion | null;
  invoiceData: InvoiceData | null;
}

@Injectable()
export class AiVisionService {
  private readonly logger = new Logger(AiVisionService.name);
  private readonly client: Anthropic;
  private readonly model: string;
  private readonly appUrl: string;

  constructor(
    private readonly config: ConfigService,
    private readonly costLogger: AiCostLoggerService,
  ) {
    this.client = new Anthropic({
      apiKey: config.getOrThrow<string>('ANTHROPIC_API_KEY'),
    });
    this.model = config.get<string>('AI_VISION_MODEL') ?? 'claude-opus-4-5';
    this.appUrl = config.get<string>('APP_URL') ?? 'http://localhost:3000';
  }

  async analyzeItem(
    tenantId: string,
    userId: string,
    dto: AnalyzeItemDto,
  ): Promise<AnalyzeItemResult> {
    const productBase64 = this.resolveImageToBase64(dto.productImageUrl);
    const invoiceBase64 = dto.invoiceImageUrl
      ? this.resolveImageToBase64(dto.invoiceImageUrl)
      : null;

    const prompt = this.buildPrompt(dto.propertyRooms ?? [], !!invoiceBase64);
    const messages = this.buildMessages(productBase64, invoiceBase64, prompt);

    this.logger.log(`Analyzing item for tenant=${tenantId}`);

    const response = await this.client.messages.create({
      model: this.model,
      max_tokens: 1024,
      messages,
    });

    const usage = response.usage;
    await this.costLogger.log({
      tenantId,
      userId,
      feature: 'ai_vision',
      model: this.model,
      inputTokens: usage.input_tokens,
      outputTokens: usage.output_tokens,
    });

    const raw = (response.content[0] as { type: string; text: string }).text;
    return this.parseResponse(raw, dto.propertyRooms ?? []);
  }

  private resolveImageToBase64(imageUrl: string): string {
    // Strip the APP_URL prefix to get local file path
    const localPath = imageUrl.startsWith(this.appUrl)
      ? imageUrl.replace(this.appUrl, '')
      : imageUrl;

    // Map URL path to filesystem path
    const filePath = path.join('/app', localPath);

    if (!fs.existsSync(filePath)) {
      throw new BadRequestException(`Image not found: ${localPath}`);
    }

    return fs.readFileSync(filePath).toString('base64');
  }

  private buildPrompt(rooms: PropertyRoomDto[], hasInvoice: boolean): string {
    const roomList =
      rooms.length > 0
        ? `\nAvailable rooms in this property:\n${rooms.map((r) => `- roomId="${r.roomId}" name="${r.name}" type="${r.type}"`).join('\n')}`
        : '';

    const invoiceInstruction = hasInvoice
      ? `\nA second image (invoice/receipt) is also provided. Extract from it: purchasePrice (number), purchaseDate (YYYY-MM-DD), serialNumber, store name, warrantyMonths (number).`
      : '';

    return `Analyze the household item image(s) and return ONLY valid JSON with no markdown.${invoiceInstruction}${roomList}

JSON schema:
{
  "name": string,
  "category": "furniture" | "art" | "technology" | "wardrobe" | "vehicles" | "wine" | "sports" | "other",
  "subcategory": string,
  "brand": string | null,
  "estimatedValue": number | null,
  "attributes": object,
  "confidence": number (0-1),
  "suggestedRoomId": string | null,
  "suggestedRoomReasoning": string | null,
  "invoiceData": {
    "purchasePrice": number | null,
    "purchaseDate": string | null,
    "serialNumber": string | null,
    "store": string | null,
    "warrantyMonths": number | null
  } | null
}

Rules:
- suggestedRoomId must be one of the roomId values listed above, or null if no rooms provided.
- If no invoice image, set invoiceData to null.
- Return ONLY the JSON object, no explanation.`;
  }

  private buildMessages(
    productBase64: string,
    invoiceBase64: string | null,
    prompt: string,
  ): Anthropic.MessageParam[] {
    const content: Anthropic.ContentBlockParam[] = [
      {
        type: 'image',
        source: { type: 'base64', media_type: 'image/jpeg', data: productBase64 },
      },
    ];

    if (invoiceBase64) {
      content.push({
        type: 'image',
        source: { type: 'base64', media_type: 'image/jpeg', data: invoiceBase64 },
      });
    }

    content.push({ type: 'text', text: prompt });

    return [{ role: 'user', content }];
  }

  private parseResponse(raw: string, rooms: PropertyRoomDto[]): AnalyzeItemResult {
    let parsed: Record<string, unknown>;
    try {
      const clean = raw.replace(/```json|```/g, '').trim();
      parsed = JSON.parse(clean) as Record<string, unknown>;
    } catch {
      this.logger.error(`Failed to parse AI response: ${raw}`);
      throw new BadRequestException('AI returned an invalid response. Please try again.');
    }

    const suggestedRoomId = parsed['suggestedRoomId'] as string | null;
    const matchedRoom = rooms.find((r) => r.roomId === suggestedRoomId) ?? null;

    return {
      name: (parsed['name'] as string) ?? 'Unknown item',
      category: (parsed['category'] as string) ?? 'other',
      subcategory: (parsed['subcategory'] as string) ?? '',
      brand: (parsed['brand'] as string | null) ?? null,
      estimatedValue: (parsed['estimatedValue'] as number | null) ?? null,
      attributes: (parsed['attributes'] as Record<string, unknown>) ?? {},
      confidence: (parsed['confidence'] as number) ?? 0.5,
      suggestedRoom: matchedRoom
        ? {
            roomId: matchedRoom.roomId,
            name: matchedRoom.name,
            reasoning: (parsed['suggestedRoomReasoning'] as string) ?? '',
          }
        : null,
      invoiceData: parsed['invoiceData']
        ? (parsed['invoiceData'] as InvoiceData)
        : null,
    };
  }
}
