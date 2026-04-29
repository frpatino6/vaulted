import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferenceDto } from './dto/update-notification-preference.dto';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post('device-token')
  @HttpCode(HttpStatus.NO_CONTENT)
  async registerDeviceToken(
    @CurrentUser() user: JwtPayload,
    @Body() dto: RegisterDeviceTokenDto,
  ): Promise<void> {
    await this.notificationsService.registerDeviceToken(user.sub, user.tenantId, dto);
  }

  @Delete('device-token/:token')
  @HttpCode(HttpStatus.NO_CONTENT)
  async unregisterDeviceToken(
    @CurrentUser() user: JwtPayload,
    @Param('token') token: string,
  ): Promise<void> {
    await this.notificationsService.unregisterDeviceToken(user.sub, token);
  }

  @Get('preferences')
  async getPreferences(@CurrentUser() user: JwtPayload) {
    return this.notificationsService.getPreferences(user.sub, user.tenantId);
  }

  @Patch('preferences')
  async updatePreferences(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateNotificationPreferenceDto,
  ) {
    return this.notificationsService.updatePreferences(user.sub, user.tenantId, dto);
  }
}
