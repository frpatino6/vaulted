import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI, Part } from '@google/generative-ai';
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
  private readonly genAI: GoogleGenerativeAI;
  private readonly model: string;
  private readonly appUrl: string;

  constructor(
    private readonly config: ConfigService,
    private readonly costLogger: AiCostLoggerService,
  ) {
    this.genAI = new GoogleGenerativeAI(
      config.getOrThrow<string>('GOOGLE_GENAI_API_KEY'),
    );
    this.model = config.get<string>('AI_VISION_MODEL') ?? 'gemini-2.5-flash';
    this.appUrl = config.get<string>('APP_URL') ?? 'http://localhost:3000';
  }

  async analyzeItem(
    tenantId: string,
    userId: string,
    dto: AnalyzeItemDto,
  ): Promise<AnalyzeItemResult> {
    const productPart = this.resolveImageToPart(dto.productImageUrl);
    const invoicePart = dto.invoiceImageUrl
      ? this.resolveImageToPart(dto.invoiceImageUrl)
      : null;

    const prompt = this.buildPrompt(dto.propertyRooms ?? [], !!invoicePart);
    const parts: Part[] = [productPart];
    if (invoicePart) parts.push(invoicePart);
    parts.push({ text: prompt });

    this.logger.log(`Analyzing item for tenant=${tenantId}`);

    const geminiModel = this.genAI.getGenerativeModel({ model: this.model });
    const result = await geminiModel.generateContent(parts);
    const response = result.response;
    const usage = response.usageMetadata;

    await this.costLogger.log({
      tenantId,
      userId,
      feature: 'ai_vision',
      model: this.model,
      inputTokens: usage?.promptTokenCount ?? 0,
      outputTokens: usage?.candidatesTokenCount ?? 0,
    });

    const raw = response.text();
    return this.parseResponse(raw, dto.propertyRooms ?? []);
  }

  private resolveImageToPart(imageUrl: string): Part {
    const localPath = imageUrl.startsWith(this.appUrl)
      ? imageUrl.replace(this.appUrl, '')
      : imageUrl;

    const filePath = path.join('/app', localPath);

    if (!fs.existsSync(filePath)) {
      throw new BadRequestException(`Image not found: ${localPath}`);
    }

    const data = fs.readFileSync(filePath).toString('base64');
    return {
      inlineData: {
        mimeType: 'image/jpeg',
        data,
      },
    };
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
