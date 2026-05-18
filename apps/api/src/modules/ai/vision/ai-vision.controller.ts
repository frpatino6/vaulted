import { Body, Controller, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Role } from '../../../common/enums/role.enum';
import { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AiVisionService, AnalyzeItemResult } from './ai-vision.service';
import { AnalyzeItemDto } from './dto/analyze-item.dto';
import { AnalyzeSectionsDto, AnalyzeSectionsResult } from './dto/analyze-sections.dto';

@ApiTags('AI Vision')
@Controller('ai/vision')
@Roles(Role.OWNER, Role.MANAGER)
export class AiVisionController {
  constructor(private readonly aiVisionService: AiVisionService) {}

  @Post('analyze')
  @ApiOperation({ summary: 'Analyze product image for auto-cataloging' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Item attributes and valuation suggested' })
  async analyze(
    @CurrentUser() user: JwtPayload,
    @Body() dto: AnalyzeItemDto,
  ): Promise<AnalyzeItemResult> {
    return this.aiVisionService.analyzeItem(user.tenantId, user.sub, dto);
  }

  @Post('analyze-sections')
  @ApiOperation({ summary: 'Detect storage sections in a furniture photo' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Detected sections with bounding boxes' })
  async analyzeSections(
    @CurrentUser() user: JwtPayload,
    @Body() dto: AnalyzeSectionsDto,
  ): Promise<AnalyzeSectionsResult> {
    return this.aiVisionService.analyzeSections(user.tenantId, user.sub, dto);
  }
}
