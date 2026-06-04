import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI, Content, HarmCategory, HarmBlockThreshold } from '@google/generative-ai';

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
    this.model = config.get<string>('AI_CHAT_MODEL') ?? 'gemini-2.5-flash';
  }

  async chat(
    systemPrompt: string,
    history: GeminiChatMessage[],
    userMessage: string,
  ): Promise<GeminiChatResult> {
    const geminiModel = this.genAI.getGenerativeModel({
      model: this.model,
      systemInstruction: systemPrompt,
      safetySettings: [
        { category: HarmCategory.HARM_CATEGORY_HARASSMENT, threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH },
        { category: HarmCategory.HARM_CATEGORY_HATE_SPEECH, threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH },
        { category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT, threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH },
        { category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT, threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH },
      ],
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
