import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI, Content } from '@google/genai';

export interface GeminiChatMessage {
  role: 'user' | 'model';
  content: string;
}

export interface GeminiChatResult {
  text: string;
  inputTokens: number;
  outputTokens: number;
}

@Injectable()
export class GeminiClient {
  private readonly logger = new Logger(GeminiClient.name);
  private readonly ai: GoogleGenAI;
  private readonly model: string;

  constructor(private readonly config: ConfigService) {
    this.ai = new GoogleGenAI({ apiKey: config.getOrThrow<string>('GOOGLE_GENAI_API_KEY') });
    this.model = config.get<string>('AI_CHAT_MODEL') ?? 'gemini-2.0-flash';
  }

  async chat(
    systemPrompt: string,
    history: GeminiChatMessage[],
    userMessage: string,
  ): Promise<GeminiChatResult> {
    const contents: Content[] = [
      ...history.map((m) => ({
        role: m.role,
        parts: [{ text: m.content }],
      })),
      { role: 'user' as const, parts: [{ text: userMessage }] },
    ];

    const response = await this.ai.models.generateContent({
      model: this.model,
      contents,
      config: { systemInstruction: systemPrompt },
    });

    const text = response.text ?? '';
    const usage = response.usageMetadata;

    this.logger.debug(
      `Gemini chat: in=${usage?.promptTokenCount ?? 0} out=${usage?.candidatesTokenCount ?? 0}`,
    );

    return {
      text,
      inputTokens: usage?.promptTokenCount ?? 0,
      outputTokens: usage?.candidatesTokenCount ?? 0,
    };
  }
}
