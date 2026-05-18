import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';

import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { PresenceOnlineAuditorDto, PresenceUserDto } from './dto/presence-user.dto';
import { PresenceService } from './presence.service';

@ApiTags('Presence')
@Controller('presence')
export class PresenceController {
  constructor(private readonly presenceService: PresenceService) {}

  @Get('online')
  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @ApiOperation({ summary: 'Get online users for the tenant' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Online users retrieved' })
  getOnline(
    @CurrentUser() user: JwtPayload,
  ): Promise<PresenceUserDto[] | PresenceOnlineAuditorDto> {
    return this.presenceService.getOnlineUsersForRequester(user);
  }
}
