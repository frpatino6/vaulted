import { Body, Controller, Post } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AiHelpResponse, AiHelpService } from './ai-help.service';
import { HelpRequestDto } from './dto/help-request.dto';

@ApiTags('AI Help')
@Controller('ai/help')
// TODO: Claude Code will add @Roles() and guards
export class AiHelpController {
  constructor(private readonly aiHelpService: AiHelpService) {}

  @Post('chat')
  @ApiOperation({ summary: 'Ask the Vaulted Guide how to use the app' })
  @ApiResponse({ status: 201, description: 'Help answer returned' })
  @ApiResponse({ status: 429, description: 'Rate limit exceeded' })
  async chat(
    @CurrentUser() user: JwtPayload,
    @Body() dto: HelpRequestDto,
  ): Promise<AiHelpResponse> {
    // TODO: audit log
    return this.aiHelpService.chat(user.tenantId, user.sub, dto);
  }
}
