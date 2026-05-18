import { Body, Controller, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Role } from '../../../common/enums/role.enum';
import { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AiChatService, ChatResponse } from './ai-chat.service';
import { ChatRequestDto } from './dto/chat-request.dto';

@ApiTags('AI Chat')
@Controller('ai/chat')
@Roles(Role.OWNER, Role.MANAGER, Role.AUDITOR)
export class AiChatController {
  constructor(private readonly aiChatService: AiChatService) {}

  @Post()
  @ApiOperation({ summary: 'Send a RAG chat query' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Chat response with sources' })
  async chat(
    @CurrentUser() user: JwtPayload,
    @Body() dto: ChatRequestDto,
  ): Promise<ChatResponse> {
    return this.aiChatService.chat(user.tenantId, user.sub, dto);
  }

  @Post('reindex')
  @Roles(Role.OWNER)
  @ApiOperation({ summary: 'Reindex tenant inventory embeddings' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Reindex completed' })
  async reindex(@CurrentUser() user: JwtPayload): Promise<{ indexed: number }> {
    return this.aiChatService.reindex(user.tenantId);
  }
}
