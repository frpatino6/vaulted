import { Controller, Param, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Roles } from '../../../common/decorators/roles.decorator';
import { Role } from '../../../common/enums/role.enum';
import { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AiMaintenanceService } from './ai-maintenance.service';

@ApiTags('AI Maintenance')
@Controller('ai/maintenance')
export class AiMaintenanceController {
  constructor(private readonly aiMaintenanceService: AiMaintenanceService) {}

  /**
   * POST /ai/maintenance/analyze/:itemId
   * Triggers AI maintenance analysis for a single item.
   * Creates a MaintenanceRecord if risk score >= 60.
   */
  @Roles(Role.OWNER, Role.MANAGER)
  @Post('analyze/:itemId')
  @ApiOperation({ summary: 'Run AI maintenance risk analysis for an item' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Risk analysis completed' })
  async analyzeItem(
    @CurrentUser() user: JwtPayload,
    @Param('itemId') itemId: string,
  ) {
    return this.aiMaintenanceService.analyzeItem(user, itemId);
  }
}
