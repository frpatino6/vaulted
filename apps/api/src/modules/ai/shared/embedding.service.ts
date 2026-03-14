import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

export interface ItemEmbeddingInput {
  _id: unknown;
  name: string;
  category?: string;
  subcategory?: string;
  tags?: string[];
  status?: string;
  attributes?: Record<string, unknown>;
  valuation?: { currentValue?: number; currency?: string };
  serialNumber?: string;
}

@Injectable()
export class EmbeddingService {
  private readonly logger = new Logger(EmbeddingService.name);
  private readonly genAI: GoogleGenerativeAI;
  private readonly model: string;

  constructor(private readonly config: ConfigService) {
    this.genAI = new GoogleGenerativeAI(config.getOrThrow<string>('GOOGLE_GENAI_API_KEY'));
    this.model = config.get<string>('AI_EMBEDDING_MODEL') ?? 'text-embedding-004';
  }

  buildItemText(item: ItemEmbeddingInput): string {
    const parts: string[] = [item.name];
    if (item.category) parts.push(item.category);
    if (item.subcategory) parts.push(item.subcategory);
    if (item.tags?.length) parts.push(item.tags.join(', '));
    if (item.status) parts.push(`status: ${item.status}`);
    if (item.serialNumber) parts.push(`serial: ${item.serialNumber}`);
    if (item.valuation?.currentValue) {
      parts.push(`value: ${item.valuation.currentValue} ${item.valuation.currency ?? 'USD'}`);
    }
    return parts.join(' | ');
  }

  async generateEmbedding(text: string): Promise<number[]> {
    const embeddingModel = this.genAI.getGenerativeModel({ model: this.model });
    const result = await embeddingModel.embedContent(text);
    return result.embedding.values;
  }
}
