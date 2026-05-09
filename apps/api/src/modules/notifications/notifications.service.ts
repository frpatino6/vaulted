import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { In, IsNull, Repository } from 'typeorm';
import * as admin from 'firebase-admin';
import { AuditService } from '../audit/audit.service';
import { UsersService } from '../users/users.service';
import { Role } from '../../common/enums/role.enum';
import { UserDeviceToken } from './entities/user-device-token.entity';
import { NotificationPreference } from './entities/notification-preference.entity';
import { NotificationLog, NotificationType } from './entities/notification-log.entity';
import { RegisterDeviceTokenDto } from './dto/register-device-token.dto';
import { UpdateNotificationPreferenceDto } from './dto/update-notification-preference.dto';

interface SendPushParams {
  tenantId: string;
  userIds: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface SendEmailParams {
  tenantId: string;
  to: string;
  subject: string;
  html: string;
}

interface NotifyTenantRolesParams {
  tenantId: string;
  roles: Role[];
  title: string;
  body: string;
  type?: NotificationType;
  emailSubject?: string;
  emailHtml?: string;
  data?: Record<string, string>;
}

interface ResendErrorBody {
  message?: string;
}

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly fcmEnabled: boolean;

  constructor(
    @InjectRepository(UserDeviceToken)
    private readonly deviceTokenRepository: Repository<UserDeviceToken>,
    @InjectRepository(NotificationPreference)
    private readonly preferenceRepository: Repository<NotificationPreference>,
    @InjectRepository(NotificationLog)
    private readonly notificationLogRepository: Repository<NotificationLog>,
    private readonly configService: ConfigService,
    private readonly auditService: AuditService,
    private readonly usersService: UsersService,
  ) {
    const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
    const privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY');
    const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');

    if (projectId && privateKey && clientEmail) {
      if (!admin.apps.length) {
        admin.initializeApp({
          credential: admin.credential.cert({
            projectId,
            privateKey: privateKey.replace(/\\n/g, '\n'),
            clientEmail,
          }),
        });
      }
      this.fcmEnabled = true;
    } else {
      this.logger.warn(
        'Firebase credentials not configured — push notifications disabled.',
      );
      this.fcmEnabled = false;
    }
  }

  async registerDeviceToken(
    userId: string,
    tenantId: string,
    dto: RegisterDeviceTokenDto,
  ): Promise<void> {
    const existing = await this.deviceTokenRepository.findOne({
      where: { token: dto.token },
    });

    if (existing) {
      // Re-associate the token with the current user/tenant in case it changed
      await this.deviceTokenRepository.update(existing.id, {
        userId,
        tenantId,
        platform: dto.platform,
      });
    } else {
      const entity = this.deviceTokenRepository.create({
        userId,
        tenantId,
        token: dto.token,
        platform: dto.platform,
      });
      await this.deviceTokenRepository.save(entity);
    }

    await this.auditService.log({
      tenantId,
      userId,
      action: 'notification.device_token.register',
      entityType: 'user_device_token',
      metadata: { platform: dto.platform },
    });
  }

  async unregisterDeviceToken(userId: string, token: string): Promise<void> {
    const existing = await this.deviceTokenRepository.findOne({
      where: { token, userId },
    });

    if (!existing) {
      throw new NotFoundException('Device token not found');
    }

    await this.deviceTokenRepository.delete(existing.id);

    await this.auditService.log({
      tenantId: existing.tenantId,
      userId,
      action: 'notification.device_token.unregister',
      entityType: 'user_device_token',
      entityId: existing.id,
    });
  }

  async sendPush(
    params: SendPushParams,
  ): Promise<{ successCount: number; failureCount: number }> {
    if (params.userIds.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    // Only send to users who have push enabled
    const enabledUserIds = await this.filterUsersByPushPreference(params.userIds);
    if (enabledUserIds.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    const deviceTokenRows = await this.deviceTokenRepository.find({
      where: { userId: In(enabledUserIds), tenantId: params.tenantId },
    });

    if (deviceTokenRows.length === 0) {
      return { successCount: 0, failureCount: 0 };
    }

    const tokens = deviceTokenRows.map((row) => row.token);

    if (!this.fcmEnabled) {
      this.logger.warn('FCM not configured — push skipped.');
      return { successCount: 0, failureCount: 0 };
    }

    try {
      const response = await admin.messaging().sendEachForMulticast({
        tokens,
        notification: { title: params.title, body: params.body },
        ...(params.data ? { data: params.data } : {}),
      });

      const invalidTokens: string[] = [];
      response.responses.forEach((res, idx) => {
        if (
          !res.success &&
          res.error?.code === 'messaging/registration-token-not-registered'
        ) {
          invalidTokens.push(tokens[idx]);
        }
      });

      if (invalidTokens.length > 0) {
        await this.deviceTokenRepository.delete({ token: In(invalidTokens) });
        this.logger.warn(
          `Removed ${invalidTokens.length} stale FCM token(s) for tenant ${params.tenantId}`,
        );
      }

      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`FCM multicast failed for tenant ${params.tenantId}: ${message}`);
      return { successCount: 0, failureCount: tokens.length };
    }
  }

  async sendEmail(params: SendEmailParams): Promise<boolean> {
    const apiKey = this.configService.get<string>('RESEND_API_KEY');
    if (!apiKey || apiKey.trim() === '') {
      this.logger.warn('RESEND_API_KEY not configured; email skipped');
      return false;
    }

    const from =
      this.configService.get<string>('EMAIL_FROM')?.trim() || 'onboarding@resend.dev';

    try {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from,
          to: [params.to],
          subject: params.subject,
          html: params.html,
        }),
      });

      if (!response.ok) {
        const raw: unknown = await response.json().catch(() => ({}));
        const body = raw as ResendErrorBody;
        this.logger.error(
          `Resend email failed [${response.status}]: ${body.message ?? 'unknown error'} — to: ${params.to}`,
        );
        return false;
      }

      return true;
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.error(`Resend email error: ${message} — to: ${params.to}`);
      return false;
    }
  }

  async notifyTenantRoles(params: NotifyTenantRolesParams): Promise<void> {
    const allUsers = await this.usersService.findAllByTenant(params.tenantId);
    const targetUsers = allUsers.filter(
      (u) => u.isActive && params.roles.includes(u.role),
    );

    if (targetUsers.length === 0) {
      return;
    }

    const userIds = targetUsers.map((u) => u.id);
    const prefsMap = await this.loadPreferencesMap(userIds);

    // Filter to users who have this notification type enabled
    const notificationType = params.type ?? 'general';
    const deliverableUsers = targetUsers.filter((u) =>
      this.isTypeEnabledForUser(notificationType, prefsMap.get(u.id)),
    );

    if (deliverableUsers.length === 0) {
      return;
    }

    void this.persistNotificationForUsers(
      params.tenantId,
      deliverableUsers.map((u) => u.id),
      notificationType,
      params.title,
      params.body,
      params.data,
    );

    let totalPushSuccess = 0;
    let totalPushFailure = 0;
    let totalEmailSuccess = 0;

    await Promise.allSettled(
      deliverableUsers.map(async (user) => {
        const prefs = prefsMap.get(user.id);
        const pushEnabled = prefs?.pushEnabled ?? true;
        const emailEnabled = prefs?.emailEnabled ?? true;

        if (pushEnabled) {
          try {
            const result = await this.sendPush({
              tenantId: params.tenantId,
              userIds: [user.id],
              title: params.title,
              body: params.body,
              data: params.data,
            });
            totalPushSuccess += result.successCount;
            totalPushFailure += result.failureCount;
          } catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            this.logger.error(
              `Push failed for user ${user.id} in tenant ${params.tenantId}: ${message}`,
            );
          }
        }

        if (emailEnabled && params.emailHtml && params.emailSubject) {
          try {
            const sent = await this.sendEmail({
              tenantId: params.tenantId,
              to: user.email,
              subject: params.emailSubject,
              html: params.emailHtml,
            });
            if (sent) totalEmailSuccess += 1;
          } catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            this.logger.error(
              `Email failed for user ${user.id} in tenant ${params.tenantId}: ${message}`,
            );
          }
        }
      }),
    );

    await this.auditService.log({
      tenantId: params.tenantId,
      action: 'notification.sent',
      entityType: 'notification',
      metadata: {
        roles: params.roles,
        title: params.title,
        recipientCount: targetUsers.length,
        pushSuccess: totalPushSuccess,
        pushFailure: totalPushFailure,
        emailSuccess: totalEmailSuccess,
      },
    });
  }

  async getPreferences(
    userId: string,
    tenantId: string,
  ): Promise<NotificationPreference> {
    const existing = await this.preferenceRepository.findOne({
      where: { userId, tenantId },
    });

    if (existing) {
      return existing;
    }

    // Create default preferences on first access
    const defaults = this.preferenceRepository.create({ userId, tenantId });
    return this.preferenceRepository.save(defaults);
  }

  async updatePreferences(
    userId: string,
    tenantId: string,
    dto: UpdateNotificationPreferenceDto,
  ): Promise<NotificationPreference> {
    let prefs = await this.preferenceRepository.findOne({
      where: { userId, tenantId },
    });

    if (!prefs) {
      prefs = this.preferenceRepository.create({ userId, tenantId });
      prefs = await this.preferenceRepository.save(prefs);
    }

    const updates: Partial<NotificationPreference> = {};
    if (dto.pushEnabled !== undefined) updates.pushEnabled = dto.pushEnabled;
    if (dto.emailEnabled !== undefined) updates.emailEnabled = dto.emailEnabled;
    if (dto.dryCleaningOverdue !== undefined) updates.dryCleaningOverdue = dto.dryCleaningOverdue;
    if (dto.maintenanceDue !== undefined) updates.maintenanceDue = dto.maintenanceDue;
    if (dto.itemAdded !== undefined) updates.itemAdded = dto.itemAdded;

    await this.preferenceRepository.update(prefs.id, updates);

    await this.auditService.log({
      tenantId,
      userId,
      action: 'notification.preferences.update',
      entityType: 'notification_preference',
      entityId: prefs.id,
      metadata: updates as Record<string, unknown>,
    });

    const updated = await this.preferenceRepository.findOne({
      where: { id: prefs.id },
    });

    if (!updated) {
      throw new NotFoundException('Notification preference not found after update');
    }

    return updated;
  }

  async getNotifications(
    userId: string,
    tenantId: string,
    page: number,
    limit: number,
  ): Promise<{ items: NotificationLog[]; total: number; unreadCount: number }> {
    const [items, total] = await this.notificationLogRepository.findAndCount({
      where: { userId, tenantId },
      order: { createdAt: 'DESC' },
      take: limit,
      skip: (page - 1) * limit,
    });

    const unreadCount = await this.notificationLogRepository.count({
      where: { userId, tenantId, readAt: IsNull() },
    });

    return { items, total, unreadCount };
  }

  async markRead(userId: string, notificationId: string): Promise<void> {
    const log = await this.notificationLogRepository.findOne({
      where: { id: notificationId, userId },
    });

    if (!log) {
      throw new NotFoundException('Notification not found');
    }

    await this.notificationLogRepository.update(log.id, { readAt: new Date() });
  }

  async markAllRead(
    userId: string,
    tenantId: string,
  ): Promise<{ updated: number }> {
    const result = await this.notificationLogRepository
      .createQueryBuilder()
      .update(NotificationLog)
      .set({ readAt: new Date() })
      .where('user_id = :userId AND tenant_id = :tenantId AND read_at IS NULL', {
        userId,
        tenantId,
      })
      .execute();

    return { updated: result.affected ?? 0 };
  }

  private async persistNotificationForUsers(
    tenantId: string,
    userIds: string[],
    type: NotificationType,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (userIds.length === 0) return;
    try {
      const logs = userIds.map((userId) =>
        this.notificationLogRepository.create({
          tenantId,
          userId,
          type,
          title,
          body,
          data: data ?? null,
        }),
      );
      await this.notificationLogRepository.save(logs);
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      this.logger.warn(`persistNotificationForUsers failed: ${message}`);
    }
  }

  private async filterUsersByPushPreference(userIds: string[]): Promise<string[]> {
    const prefs = await this.preferenceRepository.find({
      where: { userId: In(userIds) },
      select: ['userId', 'pushEnabled'],
    });

    const disabledSet = new Set(
      prefs.filter((p) => !p.pushEnabled).map((p) => p.userId),
    );

    // Users without a preference row default to push enabled
    return userIds.filter((id) => !disabledSet.has(id));
  }

  private async loadPreferencesMap(
    userIds: string[],
  ): Promise<Map<string, NotificationPreference>> {
    if (userIds.length === 0) {
      return new Map();
    }

    const prefs = await this.preferenceRepository.find({
      where: { userId: In(userIds) },
    });

    return new Map(prefs.map((p) => [p.userId, p]));
  }

  private isTypeEnabledForUser(
    type: NotificationType,
    prefs: NotificationPreference | undefined,
  ): boolean {
    if (!prefs) return true; // no row → all defaults on

    switch (type) {
      case 'dry_cleaning_overdue':
        return prefs.dryCleaningOverdue;
      case 'maintenance_due':
        return prefs.maintenanceDue;
      case 'item_added':
        return prefs.itemAdded;
      case 'general':
        return true;
    }
  }
}
