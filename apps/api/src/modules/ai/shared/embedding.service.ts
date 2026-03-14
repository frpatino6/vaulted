import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';

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
  private readonly ai: GoogleGenAI;
  private readonly model: string;

  constructor(private readonly config: ConfigService) {
    this.ai = new GoogleGenAI({
      apiKey: config.getOrThrow<string>('GOOGLE_GENAI_API_KEY'),
      httpOptions: { apiVersion: 'v1' },
    });
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
    const result = await this.ai.models.embedContent({
      model: this.model,
      contents: text,
    });
    const values = result.embeddings?.[0]?.values;
    if (!values) throw new Error('No embedding returned from Gemini');
    return values;
  }

  async indexItem(item: ItemEmbeddingInput): Promise<void> {
    const text = this.buildItemText(item);
    const embedding = await this.generateEmbedding(text);
    this.logger.debug(`Embedding generated for item ${String(item._id)}, dims=${embedding.length}`);
    // Caller stores the result via DataSource — see AiChatModule
    (item as ItemEmbeddingInput & { __embedding?: number[] }).__embedding = embedding;
  }
}
