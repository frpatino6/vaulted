import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI, Part } from '@google/generative-ai';
import * as fs from 'fs';
import * as path from 'path';
import { AiCostLoggerService } from '../shared/ai-cost-logger.service';
import { AnalyzeItemDto, PropertyRoomDto } from './dto/analyze-item.dto';
import {
  AnalyzeSectionsDto,
  AnalyzeSectionsResult,
  DetectedSection,
} from './dto/analyze-sections.dto';

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
  tags: string[];
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

    // Map rooms to simple indices so Gemini doesn't have to copy MongoDB ObjectIDs
    const rooms = dto.propertyRooms ?? [];
    const indexedRooms = rooms.map((r, i) => ({ ...r, index: `room_${i}` }));

    const prompt = this.buildPrompt(indexedRooms, !!invoicePart);
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
    return this.parseResponse(raw, rooms, indexedRooms);
  }

  async analyzeSections(
    tenantId: string,
    userId: string,
    dto: AnalyzeSectionsDto,
  ): Promise<AnalyzeSectionsResult> {
    const imagePart = this.resolveImageToPart(dto.imageUrl);
    const prompt = this.buildSectionsPrompt();
    const parts: Part[] = [imagePart, { text: prompt }];

    this.logger.log(`Analyzing sections for tenant=${tenantId}`);

    const geminiModel = this.genAI.getGenerativeModel({ model: this.model });
    const result = await geminiModel.generateContent(parts);
    const response = result.response;
    const usage = response.usageMetadata;

    await this.costLogger.log({
      tenantId,
      userId,
      feature: 'ai_section_mapping',
      model: this.model,
      inputTokens: usage?.promptTokenCount ?? 0,
      outputTokens: usage?.candidatesTokenCount ?? 0,
    });

    const raw = response.text();
    return this.parseSectionsResponse(raw);
  }

  private buildSectionsPrompt(): string {
    return `You are analyzing a photo of storage furniture (cabinets, drawers, shelves, closets, etc.) in a luxury home.

Your task: identify every distinct storage unit visible in the image and return a structured map.

Grid convention:
- Rows: numbered top-to-bottom starting at 1 (1 = top row, 2 = second row, etc.)
- Columns: lettered left-to-right starting at A (A = leftmost, B = next, etc.)
- Code: combine row + column, e.g. "1A", "2B", "3C"

For each storage unit, determine:
- code: grid code (e.g. "1A")
- name: descriptive name (e.g. "Top Left Drawer", "Center Cabinet", "Glass Door Upper Right")
- type: one of "drawer" | "cabinet" | "shelf" | "rack" | "safe" | "compartment" | "other"
- row: numeric row (1, 2, 3...)
- column: letter column ("A", "B", "C"...)
- notes: optional brief note (e.g. "has glass door", "deep pull-out", "corner unit")

Return ONLY valid JSON with no markdown:
{
  "furnitureDescription": string,
  "confidence": number (0-1),
  "sections": [
    { "code": string, "name": string, "type": string, "row": number, "column": string, "notes": string | null }
  ]
}

Rules:
- Include ALL visible storage units, even partially visible ones
- If the same physical piece has multiple doors/drawers, each is a separate section
- Order sections by row then column (1A, 1B, 1C, 2A, 2B...)
- Return ONLY the JSON object, no explanation`;
  }

  private parseSectionsResponse(raw: string): AnalyzeSectionsResult {
    let parsed: Record<string, unknown>;
    try {
      const clean = raw.replace(/```json|```/g, '').trim();
      parsed = JSON.parse(clean) as Record<string, unknown>;
    } catch {
      this.logger.error(`Failed to parse sections AI response: ${raw}`);
      throw new BadRequestException('AI returned an invalid response. Please try again.');
    }

    const rawSections = Array.isArray(parsed['sections']) ? parsed['sections'] : [];

    return {
      furnitureDescription: (parsed['furnitureDescription'] as string) ?? '',
      confidence: (parsed['confidence'] as number) ?? 0.5,
      sections: rawSections.map((s: Record<string, unknown>) => ({
        code: (s['code'] as string) ?? '',
        name: (s['name'] as string) ?? '',
        type: this.coerceSectionType(s['type']),
        row: (s['row'] as number) ?? 1,
        column: (s['column'] as string) ?? 'A',
        notes: (s['notes'] as string | null) ?? undefined,
      })),
    };
  }

  private coerceSectionType(raw: unknown): DetectedSection['type'] {
    if (typeof raw !== 'string') return 'other';
    const v = raw.toLowerCase();
    switch (v) {
      case 'drawer':
      case 'cabinet':
      case 'shelf':
      case 'rack':
      case 'safe':
      case 'compartment':
      case 'other':
        return v;
      default:
        return 'other';
    }
  }

  private readonly ALLOWED_UPLOAD_DIR = path.resolve('/app/uploads');

  private resolveImageToPart(imageUrl: string): Part {
    const localPath = imageUrl.startsWith(this.appUrl)
      ? imageUrl.replace(this.appUrl, '')
      : imageUrl;

    // Resolve to absolute path and verify it stays within the uploads directory
    const filePath = path.resolve('/app', localPath.replace(/^\/+/, ''));
    if (!filePath.startsWith(this.ALLOWED_UPLOAD_DIR + path.sep) &&
        filePath !== this.ALLOWED_UPLOAD_DIR) {
      throw new BadRequestException('Invalid image path.');
    }

    if (!fs.existsSync(filePath)) {
      throw new BadRequestException('Image not found.');
    }

    const ext = path.extname(filePath).toLowerCase();
    const mimeMap: Record<string, string> = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
    };
    const mimeType = mimeMap[ext] ?? 'image/jpeg';

    const data = fs.readFileSync(filePath).toString('base64');
    return {
      inlineData: { mimeType, data },
    };
  }

  private buildPrompt(
    indexedRooms: Array<PropertyRoomDto & { index: string }>,
    hasInvoice: boolean,
  ): string {
    const roomList =
      indexedRooms.length > 0
        ? `\nAvailable rooms in this property:\n${indexedRooms.map((r) => `- id="${r.index}" name="${r.name}" type="${r.type}"`).join('\n')}`
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
  "estimatedValue": number,
  "attributes": object,
  "confidence": number (0-1),
  "tags": string[],
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
- estimatedValue: always provide a conservative USD market value estimate based on the item's category, visible brand, condition, and approximate age. Never return null — if uncertain, provide a reasonable range midpoint for that item category.
- tags: REQUIRED. Always return a JSON array with 3 to 5 short lowercase tags (e.g. ["samsung", "4k", "smart-tv", "television", "electronics"]). Use brand, material, style, color, or key feature as tags. Never return an empty array.
- suggestedRoomId must be one of the id values listed above (e.g. "room_0"), or null if no rooms provided.
- If no invoice image, set invoiceData to null.
- Return ONLY the JSON object, no explanation.`;
  }

  private parseResponse(
    raw: string,
    rooms: PropertyRoomDto[],
    indexedRooms: Array<PropertyRoomDto & { index: string }>,
  ): AnalyzeItemResult {
    let parsed: Record<string, unknown>;
    try {
      const clean = raw.replace(/```json|```/g, '').trim();
      parsed = JSON.parse(clean) as Record<string, unknown>;
    } catch {
      this.logger.error(`Failed to parse AI response: ${raw}`);
      throw new BadRequestException('AI returned an invalid response. Please try again.');
    }

    // Map the simple index back to the real roomId
    const suggestedIndex = parsed['suggestedRoomId'] as string | null;
    const indexedMatch = indexedRooms.find((r) => r.index === suggestedIndex) ?? null;
    const matchedRoom = indexedMatch
      ? (rooms.find((r) => r.roomId === indexedMatch.roomId) ?? null)
      : null;

    return {
      name: (parsed['name'] as string) ?? 'Unknown item',
      category: (parsed['category'] as string) ?? 'other',
      subcategory: (parsed['subcategory'] as string) ?? '',
      brand: (parsed['brand'] as string | null) ?? null,
      estimatedValue: (parsed['estimatedValue'] as number) ?? null,
      attributes: (parsed['attributes'] as Record<string, unknown>) ?? {},
      confidence: (parsed['confidence'] as number) ?? 0.5,
      tags: (() => {
        const raw = parsed['tags'];
        if (Array.isArray(raw)) return (raw as string[]).slice(0, 5);
        if (typeof raw === 'string' && raw.trim())
          return raw.split(',').map((t) => t.trim()).filter(Boolean).slice(0, 5);
        return [];
      })(),
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
