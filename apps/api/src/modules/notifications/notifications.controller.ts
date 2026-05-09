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
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferenceDto } from './dto/update-notification-preference.dto';
import { ListNotificationsDto } from './dto/list-notifications.dto';
import { NotificationsService } from './notifications.service';

@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Post('test-push')
  @HttpCode(HttpStatus.NO_CONTENT)
  async testPush(@CurrentUser() user: JwtPayload): Promise<void> {
    await this.notificationsService.sendPush({
      tenantId: user.tenantId,
      userIds: [user.sub],
      title: 'Vaulted test',
      body: 'Push notifications are working!',
    });
  }

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

  @Get()
  async getNotifications(
    @CurrentUser() user: JwtPayload,
    @Query() dto: ListNotificationsDto,
  ) {
    return this.notificationsService.getNotifications(
      user.sub,
      user.tenantId,
      dto.page ?? 1,
      dto.limit ?? 20,
    );
  }

  @Patch(':id/read')
  @HttpCode(HttpStatus.NO_CONTENT)
  async markRead(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ): Promise<void> {
    await this.notificationsService.markRead(user.sub, id);
  }

  @Post('mark-all-read')
  @HttpCode(HttpStatus.OK)
  async markAllRead(@CurrentUser() user: JwtPayload) {
    return this.notificationsService.markAllRead(user.sub, user.tenantId);
  }
}
