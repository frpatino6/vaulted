import { Body, Controller, Get, HttpCode, HttpStatus, Post } from '@nestjs/common';
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
    return this.aiChatService.chat(user.tenantId, user.sub, user.role, dto);
  }

  @Post('reindex')
  @HttpCode(HttpStatus.ACCEPTED)
  @Roles(Role.OWNER)
  @ApiOperation({ summary: 'Reindex tenant inventory embeddings' })
  @ApiBearerAuth()
  @ApiResponse({ status: 202, description: 'Reindex started' })
  @ApiResponse({ status: 409, description: 'Reindex already running' })
  async reindex(@CurrentUser() user: JwtPayload): Promise<{ status: 'started' }> {
    return this.aiChatService.reindex(user.tenantId);
  }
  @Get('reindex/status')
  @ApiOperation({ summary: 'Get tenant inventory embedding reindex status' })
  @ApiBearerAuth()
  @ApiResponse({ status: 202, description: 'Reindex started' })
  async reindexStatus(
    @CurrentUser() user: JwtPayload,
  ): Promise<{ status: string; processed: number; total: number }> {
    return this.aiChatService.reindexStatus(user.tenantId);
  }
}
