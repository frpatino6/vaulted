import { Injectable, Logger, BadRequestException, ForbiddenException, HttpException, HttpStatus } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import sharp from 'sharp';
import { GoogleGenerativeAI, Part } from '@google/generative-ai';
import Redis from 'ioredis';
import * as fs from 'fs';
import * as path from 'path';
import { InjectRedis } from '../../../common/decorators/inject-redis.decorator';
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
  quantity: number;
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
    @InjectRedis() private readonly redis: Redis,
    private readonly jwtService: JwtService,
  ) {
    this.genAI = new GoogleGenerativeAI(
      config.getOrThrow<string>('GOOGLE_GENAI_API_KEY'),
    );
    this.model = config.get<string>('AI_VISION_MODEL') ?? 'gemini-2.5-flash';
    this.appUrl = config.get<string>('APP_URL') ?? 'http://localhost:3000';
    this.allowedUploadDir =
      config.get<string>('UPLOADS_DIR') ?? path.join(process.cwd(), 'uploads');
  }

  async analyzeItem(
    tenantId: string,
    userId: string,
    dto: AnalyzeItemDto,
  ): Promise<AnalyzeItemResult> {
    await this.enforceRateLimit(`ai:vision:analyze:user:${userId}`, 10);
    await this.enforceRateLimit(`ai:vision:analyze:tenant:${tenantId}`, 30);

    const productPart = await this.resolveImageToPart(dto.productImageUrl, tenantId);
    const invoicePart = dto.invoiceImageUrl
      ? await this.resolveImageToPart(dto.invoiceImageUrl, tenantId)
      : null;

    // Map rooms to simple indices. Sanitize name/type to prevent prompt injection.
    const rooms = dto.propertyRooms ?? [];
    const indexedRooms = rooms.map((r, i) => ({
      ...r,
      name: r.name.replace(/["\n\r\\]/g, ' ').slice(0, 200),
      type: r.type.replace(/["\n\r\\]/g, ' ').slice(0, 100),
      index: `room_${i}`,
    }));

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
    if (!dto.imageUrl && !dto.imageData) {
      throw new BadRequestException('imageUrl or imageData is required');
    }
    await this.enforceRateLimit(`ai:vision:sections:user:${userId}`, 10);
    await this.enforceRateLimit(`ai:vision:sections:tenant:${tenantId}`, 30);

    let imagePart: Part;
    if (dto.imageData) {
      const ALLOWED_MIMES = ['image/jpeg', 'image/png', 'image/webp'] as const;
      type AllowedMime = typeof ALLOWED_MIMES[number];
      const mimeType: AllowedMime = (ALLOWED_MIMES as readonly string[]).includes(dto.mimeType ?? '')
        ? (dto.mimeType as AllowedMime)
        : 'image/jpeg';

      const buffer = Buffer.from(dto.imageData, 'base64');
      const clean = await sharp(buffer).jpeg({ quality: 85 }).toBuffer();
      imagePart = { inlineData: { mimeType: 'image/jpeg', data: clean.toString('base64') } };
    } else {
      imagePart = await this.resolveImageToPart(dto.imageUrl!, tenantId);
    }
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

Your task: identify every distinct storage compartment visible and return a precise structured map with tight bounding boxes.

## Step 1 — Locate the furniture
First, identify the exact pixel boundary of the furniture itself. Ignore walls, floors, other objects, and background. All bounding boxes must stay within the furniture's visible area.

## Step 2 — Map the grid
Grid convention (CRITICAL — read carefully):
- ROW = horizontal layer, numbered TOP → BOTTOM starting at 1
  • A shelf above another shelf → different rows (1, 2, 3…)
  • Sections side by side on the same level → same row, different columns
- COLUMN = vertical lane, lettered LEFT → RIGHT starting at A
  • Sections side by side → A, B, C…
  • A single vertical stack with no side-by-side sections → all column "A"
- Code = row number + column letter: "1A", "2A", "3B"

Layout examples:
  • 6 shelves stacked vertically, no side-by-side → 1A, 2A, 3A, 4A, 5A, 6A (NOT 1A,1B,1C…)
  • 2 rows × 3 columns grid → 1A 1B 1C / 2A 2B 2C
  • 3 drawers side by side (single row) → 1A, 1B, 1C

## Step 3 — Draw tight bounding boxes
Each boundingBox must:
- Wrap ONLY the individual compartment opening (door, drawer face, shelf space)
- NOT include the surrounding frame, handles, or neighbouring units
- Use fractions of the full image size (0.0 = left/top edge, 1.0 = right/bottom edge)
- Be as tight as possible — prefer under-shooting the frame over over-shooting into background

For each section return:
- code: grid code (e.g. "2A")
- name: descriptive name (e.g. "Second Shelf", "Top Left Drawer", "Glass Door Upper Right")
- type: one of "drawer" | "cabinet" | "shelf" | "rack" | "safe" | "compartment" | "other"
- row: numeric row (1, 2, 3…)
- column: letter column ("A", "B", "C"…)
- notes: optional brief note (e.g. "has glass door", "deep pull-out", "locked")
- boundingBox: { "x": left, "y": top, "width": w, "height": h } — all fractions 0.0–1.0

Return ONLY valid JSON, no markdown:
{
  "furnitureDescription": string,
  "confidence": number (0-1),
  "sections": [
    {
      "code": string,
      "name": string,
      "type": string,
      "row": number,
      "column": string,
      "notes": string | null,
      "boundingBox": { "x": number, "y": number, "width": number, "height": number }
    }
  ]
}

Final rules:
- Include ALL visible compartments, even partially visible
- Include closed cabinet doors and closed drawer fronts — do NOT skip sections just because they are closed or opaque
- A tall single-door cabinet counts as ONE section (e.g. 1A), not multiple rows
- Order by row then column (1A, 1B, 2A, 2B…)
- Return ONLY the JSON object, no explanation`;
  }

  private parseSectionsResponse(raw: string): AnalyzeSectionsResult {
    let parsed: Record<string, unknown>;
    try {
      const clean = raw.replace(/```json|```/g, '').trim();
      parsed = JSON.parse(clean) as Record<string, unknown>;
    } catch {
      this.logger.error(`Failed to parse sections AI response: ${raw.slice(0, 200)}`);
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
        boundingBox: this.parseBoundingBox(s['boundingBox']),
      })),
    };
  }

  private parseBoundingBox(raw: unknown): DetectedSection['boundingBox'] {
    if (!raw || typeof raw !== 'object') return undefined;
    const b = raw as Record<string, unknown>;
    const x = typeof b['x'] === 'number' ? b['x'] : undefined;
    const y = typeof b['y'] === 'number' ? b['y'] : undefined;
    const width = typeof b['width'] === 'number' ? b['width'] : undefined;
    const height = typeof b['height'] === 'number' ? b['height'] : undefined;
    if (x === undefined || y === undefined || width === undefined || height === undefined) {
      return undefined;
    }
    return {
      x: Math.max(0, Math.min(1, x)),
      y: Math.max(0, Math.min(1, y)),
      width: Math.max(0, Math.min(1, width)),
      height: Math.max(0, Math.min(1, height)),
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

  private readonly allowedUploadDir: string;

  private async resolveImageToPart(imageUrl: string, tenantId: string): Promise<Part> {
    const uploadsRoot = this.allowedUploadDir ?? path.join(process.cwd(), 'uploads');
    const resolvedRoot = path.resolve(uploadsRoot);

    if (imageUrl.startsWith(this.appUrl)) {
      // Extract media token from URL and validate tenant ownership
      const mediaMatch = imageUrl.match(/\/api\/media\/(.+)$/);
      if (!mediaMatch) throw new BadRequestException('Invalid image URL format');

      const token = mediaMatch[1];
      const mediaJwtSecret = this.config.get<string>('MEDIA_JWT_SECRET');
      if (!mediaJwtSecret) throw new BadRequestException('Media JWT secret not configured');

      try {
        const payload = this.jwtService.verify<{
          typ?: string;
          fileKey: string;
          tenantId: string;
        }>(token, { secret: mediaJwtSecret });

        if (payload.typ !== 'media') {
          throw new BadRequestException('Invalid token type');
        }
        if (payload.tenantId !== tenantId) {
          throw new ForbiddenException('Cross-tenant file access denied');
        }

        const relativePath = payload.fileKey;
        const filePath = path.resolve(resolvedRoot, relativePath);

        if (!filePath.startsWith(resolvedRoot + path.sep) && filePath !== resolvedRoot) {
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
        return { inlineData: { mimeType, data } };
      } catch (err) {
        if (err instanceof BadRequestException || err instanceof ForbiddenException) throw err;
        throw new BadRequestException('Invalid or expired media token');
      }
    }

    // Fallback local path — verify tenant prefix
    const filePath = path.resolve(resolvedRoot, imageUrl.replace(/^\/+/, ''));
    if (!filePath.startsWith(resolvedRoot + path.sep) && filePath !== resolvedRoot) {
      throw new BadRequestException('Invalid image path.');
    }

    const relativePath = path.relative(resolvedRoot, filePath);
    if (!relativePath.startsWith(`${tenantId}/`)) {
      throw new ForbiddenException('Cross-tenant file access denied');
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
    return { inlineData: { mimeType, data } };
  }

  private async enforceRateLimit(key: string, limit: number): Promise<void> {
    const luaScript = `
      local current = redis.call('GET', KEYS[1])
      if not current then
        redis.call('SET', KEYS[1], 1, 'EX', 60)
        return 1
      end
      local count = redis.call('INCR', KEYS[1])
      if count > tonumber(ARGV[1]) then return -1 end
      return count
    `;
    const result = await this.redis.eval(luaScript, 1, key, String(limit));
    if (result === -1) {
      throw new HttpException('Rate limit exceeded', HttpStatus.TOO_MANY_REQUESTS);
    }
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
  "quantity": number,
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
- quantity: count the number of identical units visible in the image (e.g. 12 plates, 6 wine glasses, 1 chair). Default to 1 if only one item is visible or items are not countable.
- tags: REQUIRED. Always return a JSON array with 3 to 5 short lowercase tags (e.g. ["samsung", "4k", "smart-tv", "television", "electronics"]). Use brand, material, style, color, or key feature as tags. Never return an empty array.
- suggestedRoomId must be one of the id values listed above (e.g. "room_0"), or null if no rooms provided.
- If no invoice image, set invoiceData to null.
- WARDROBE RULE: When category is "wardrobe", the attributes object MUST include these fields (use null only if truly impossible to determine):
  * type: "clothing" | "footwear" | "accessories" | "jewelry_watches"
  * color: string (dominant color, e.g. "navy blue", "white")
  * size: string | null (e.g. "M", "42", "One Size" — null if not visible)
  * material: string | null (e.g. "cotton", "leather", "silk" — null if not visible)
  * season: "spring_summer" | "fall_winter" | "all_season"
  * cleaningStatus: "clean" (always "clean" for new items being cataloged)
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
      this.logger.error(`Failed to parse AI response: ${raw.slice(0, 200)}`);
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
      quantity: Math.max(1, Math.round((parsed['quantity'] as number) ?? 1)),
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
