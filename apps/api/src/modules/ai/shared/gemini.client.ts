import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI, Content } from '@google/generative-ai';

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
  private readonly genAI: GoogleGenerativeAI;
  private readonly model: string;

  constructor(private readonly config: ConfigService) {
    this.genAI = new GoogleGenerativeAI(config.getOrThrow<string>('GOOGLE_GENAI_API_KEY'));
    this.model = config.get<string>('AI_CHAT_MODEL') ?? 'gemini-2.0-flash';
  }

  async chat(
    systemPrompt: string,
    history: GeminiChatMessage[],
    userMessage: string,
  ): Promise<GeminiChatResult> {
    const geminiModel = this.genAI.getGenerativeModel({
      model: this.model,
      systemInstruction: systemPrompt,
    });

    const contents: Content[] = history.map((m) => ({
      role: m.role,
      parts: [{ text: m.content }],
    }));

    const chat = geminiModel.startChat({ history: contents });
    const result = await chat.sendMessage(userMessage);
    const response = result.response;
    const usage = response.usageMetadata;

    this.logger.debug(
      `Gemini chat: in=${usage?.promptTokenCount ?? 0} out=${usage?.candidatesTokenCount ?? 0}`,
    );

    return {
      text: response.text(),
      inputTokens: usage?.promptTokenCount ?? 0,
      outputTokens: usage?.candidatesTokenCount ?? 0,
    };
  }
}
