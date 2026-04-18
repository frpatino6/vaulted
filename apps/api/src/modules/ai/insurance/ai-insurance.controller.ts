import { Body, Controller, Param, Post } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Roles } from '../../../common/decorators/roles.decorator';
import { Role } from '../../../common/enums/role.enum';
import { JwtPayload } from '../../auth/strategies/jwt.strategy';
import { AiInsuranceService } from './ai-insurance.service';
import { DraftClaimDto } from './dto/draft-claim.dto';

@Controller('ai/insurance')
@Roles(Role.OWNER, Role.MANAGER)
export class AiInsuranceController {
  constructor(private readonly aiInsuranceService: AiInsuranceService) {}

  /**
   * POST /ai/insurance/policies/:policyId/analyze
   * Analyzes coverage health for a specific policy using Gemini AI.
   */
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('policies/:policyId/analyze')
  async analyzeCoverage(
    @CurrentUser() user: JwtPayload,
    @Param('policyId') policyId: string,
  ) {
    return this.aiInsuranceService.analyzeCoverage(user.tenantId, user.sub, policyId);
  }

  /**
   * POST /ai/insurance/claim-draft
   * Drafts a formal insurance claim letter using Gemini AI.
   */
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('claim-draft')
  async draftClaim(
    @CurrentUser() user: JwtPayload,
    @Body() dto: DraftClaimDto,
  ) {
    return this.aiInsuranceService.draftClaim(
      user.tenantId,
      user.sub,
      dto.policyId,
      dto.itemId,
      dto.incidentDescription,
    );
  }
}
