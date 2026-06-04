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
import { Throttle } from '@nestjs/throttler';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferenceDto } from './dto/update-notification-preference.dto';
import { ListNotificationsDto } from './dto/list-notifications.dto';
import { NotificationsService } from './notifications.service';

@ApiTags('Notifications')
@Controller('notifications')
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('test-push')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Send a test push notification to current user' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Test push sent' })
  async testPush(@CurrentUser() user: JwtPayload): Promise<void> {
    await this.notificationsService.sendPush({
      tenantId: user.tenantId,
      userIds: [user.sub],
      title: 'Vaulted test',
      body: 'Push notifications are working!',
    });
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Post('device-token')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Register FCM device token' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Device token registered' })
  async registerDeviceToken(
    @CurrentUser() user: JwtPayload,
    @Body() dto: RegisterDeviceTokenDto,
  ): Promise<void> {
    await this.notificationsService.registerDeviceToken(user.sub, user.tenantId, dto);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Delete('device-token/:token')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Unregister FCM device token' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Device token unregistered' })
  async unregisterDeviceToken(
    @CurrentUser() user: JwtPayload,
    @Param('token') token: string,
  ): Promise<void> {
    await this.notificationsService.unregisterDeviceToken(user.sub, user.tenantId, token);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Get('preferences')
  @ApiOperation({ summary: 'Get notification preferences' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Preferences retrieved' })
  async getPreferences(@CurrentUser() user: JwtPayload) {
    return this.notificationsService.getPreferences(user.sub, user.tenantId);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Patch('preferences')
  @ApiOperation({ summary: 'Update notification preferences' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Preferences updated' })
  async updatePreferences(
    @CurrentUser() user: JwtPayload,
    @Body() dto: UpdateNotificationPreferenceDto,
  ) {
    return this.notificationsService.updatePreferences(user.sub, user.tenantId, dto);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Get()
  @ApiOperation({ summary: 'List notifications for current user' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Notifications retrieved' })
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

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Patch(':id/read')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Mark a notification as read' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Notification marked read' })
  async markRead(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ): Promise<void> {
    await this.notificationsService.markRead(user.sub, user.tenantId, id);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Post('mark-all-read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Mark all notifications as read' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'All notifications marked read' })
  async markAllRead(@CurrentUser() user: JwtPayload) {
    return this.notificationsService.markAllRead(user.sub, user.tenantId);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Delete('clear-read')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Delete all read notifications for current user' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Read notifications deleted', schema: { example: { deleted: 5 } } })
  async clearReadNotifications(@CurrentUser() user: JwtPayload) {
    return this.notificationsService.clearReadNotifications(user.sub, user.tenantId);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.STAFF, Role.AUDITOR)
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete a single notification' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Notification deleted' })
  @ApiResponse({ status: 404, description: 'Notification not found' })
  async deleteNotification(
    @CurrentUser() user: JwtPayload,
    @Param('id') id: string,
  ): Promise<void> {
    await this.notificationsService.deleteNotification(user.sub, user.tenantId, id);
  }
}
