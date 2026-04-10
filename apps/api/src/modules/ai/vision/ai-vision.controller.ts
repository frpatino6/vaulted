import { Body, Controller, Post } from '@nestjs/common';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Role } from '../../../common/enums/role.enum';
import { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AiVisionService, AnalyzeItemResult } from './ai-vision.service';
import { AnalyzeItemDto } from './dto/analyze-item.dto';

@Controller('ai/vision')
@Roles(Role.OWNER, Role.MANAGER)
export class AiVisionController {
  constructor(private readonly aiVisionService: AiVisionService) {}

  @Post('analyze')
  async analyze(
    @CurrentUser() user: JwtPayload,
    @Body() dto: AnalyzeItemDto,
  ): Promise<AnalyzeItemResult> {
    return this.aiVisionService.analyzeItem(user.tenantId, user.sub, dto);
  }
}
