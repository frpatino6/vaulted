import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Roles } from '../../../common/decorators/roles.decorator';
import { Role } from '../../../common/enums/role.enum';
import { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AiHelpResponse, AiHelpService } from './ai-help.service';
import { HelpFeedbackDto } from './dto/help-feedback.dto';
import { HelpRequestDto } from './dto/help-request.dto';

@ApiTags('AI Help')
@ApiBearerAuth()
@Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR, Role.GUEST)
@Controller('ai/help')
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
    return this.aiHelpService.chat(user.tenantId, user.sub, dto);
  }

  @Post('feedback')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Submit helpfulness feedback for a Vaulted Guide response' })
  @ApiResponse({ status: 204, description: 'Feedback recorded' })
  async feedback(
    @CurrentUser() user: JwtPayload,
    @Body() dto: HelpFeedbackDto,
  ): Promise<void> {
    return this.aiHelpService.submitFeedback(user.tenantId, user.sub, dto);
  }
}
