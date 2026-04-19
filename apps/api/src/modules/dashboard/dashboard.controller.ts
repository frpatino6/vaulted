import { Controller, Get, UseGuards } from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { AnomalyGuard } from '../../common/guards/anomaly.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { DashboardService } from './dashboard.service';

@Controller('dashboard')
export class DashboardController {
  constructor(private readonly dashboardService: DashboardService) {}

  @UseGuards(AnomalyGuard)
  @Throttle({ 'dashboard': { ttl: 300_000, limit: 10 } })
  @Roles(Role.OWNER, Role.MANAGER)
  @Get()
  getDashboard(@CurrentUser() user: JwtPayload) {
    return this.dashboardService.getDashboard(user.tenantId, user.sub, user.role, user.propertyIds ?? []);
  }
}
