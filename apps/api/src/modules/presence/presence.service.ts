import { Injectable } from '@nestjs/common';
import { Redis } from 'ioredis';

import { InjectRedis } from '../../common/decorators/inject-redis.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { UsersService } from '../users/users.service';
import { PresenceOnlineAuditorDto, PresenceUserDto } from './dto/presence-user.dto';

const PRESENCE_TTL_SEC = 90;

/** Stored in Redis JSON (per user key). */
interface PresenceEntry {
  userId: string;
  tenantId: string;
  email: string;
  role: Role;
  connectedAt: string;
  lastSeen: string;
  connectionCount: number;
}

const presenceKey = (tenantId: string, userId: string): string =>
  `presence:${tenantId}:${userId}`;

@Injectable()
export class PresenceService {
  constructor(
    @InjectRedis() private readonly redis: Redis,
    private readonly usersService: UsersService,
  ) {}

  /** Register a WebSocket connection; emits `presence:user_online` only when first connection for this user. */
  async registerConnection(
    tenantId: string,
    payload: JwtPayload,
  ): Promise<{ isNewSession: boolean }> {
    const key = presenceKey(tenantId, payload.sub);
    const raw = await this.redis.get(key);
    const now = new Date().toISOString();

    let isNewSession = false;
    let entry: PresenceEntry;

    if (raw) {
      entry = JSON.parse(raw) as PresenceEntry;
      entry.connectionCount = (entry.connectionCount ?? 1) + 1;
      entry.lastSeen = now;
      isNewSession = false;
    } else {
      isNewSession = true;
      entry = {
        userId: payload.sub,
        tenantId,
        email: payload.email,
        role: payload.role,
        connectedAt: now,
        lastSeen: now,
        connectionCount: 1,
      };
    }

    await this.redis.setex(key, PRESENCE_TTL_SEC, JSON.stringify(entry));

    return {
      isNewSession,
      broadcastPayload: {
        userId: entry.userId,
        email: entry.email,
        role: entry.role,
        connectedAt: entry.connectedAt,
        lastSeen: entry.lastSeen,
      },
    };
  }

  /** Removes one connection; emits offline only when count reaches zero. */
  async unregisterConnection(
    tenantId: string,
    userId: string,
  ): Promise<{ fullyOffline: boolean }> {
    const key = presenceKey(tenantId, userId);
    const raw = await this.redis.get(key);
    if (!raw) {
      return { fullyOffline: false };
    }
    const entry = JSON.parse(raw) as PresenceEntry;
    const count = (entry.connectionCount ?? 1) - 1;
    if (count <= 0) {
      await this.redis.del(key);
      return { fullyOffline: true };
    }
    entry.connectionCount = count;
    await this.redis.setex(key, PRESENCE_TTL_SEC, JSON.stringify(entry));
    return { fullyOffline: false };
  }

  async refreshTTL(tenantId: string, userId: string): Promise<void> {
    const key = presenceKey(tenantId, userId);
    const raw = await this.redis.get(key);
    if (!raw) {
      return;
    }
    const entry = JSON.parse(raw) as PresenceEntry;
    entry.lastSeen = new Date().toISOString();
    await this.redis.setex(key, PRESENCE_TTL_SEC, JSON.stringify(entry));
  }

  async listRawEntries(tenantId: string): Promise<PresenceEntry[]> {
    const pattern = `presence:${tenantId}:*`;
    const keys = await this.redis.keys(pattern);
    if (keys.length === 0) {
      return [];
    }
    const values = await this.redis.mget(...keys);
    const out: PresenceEntry[] = [];
    for (const v of values) {
      if (!v) continue;
      try {
        out.push(JSON.parse(v) as PresenceEntry);
      } catch {
        continue;
      }
    }
    return out;
  }

  async getOnlineUsersForRequester(
    user: JwtPayload,
  ): Promise<PresenceUserDto[] | PresenceOnlineAuditorDto> {
    const entries = await this.listRawEntries(user.tenantId);

    if (user.role === Role.AUDITOR) {
      return { onlineCount: entries.length };
    }

    const dtos: PresenceUserDto[] = entries.map((e) => ({
      userId: e.userId,
      email: e.email,
      role: e.role,
      connectedAt: e.connectedAt,
      lastSeen: e.lastSeen,
    }));

    if (user.role === Role.OWNER || user.role === Role.MANAGER) {
      return dtos;
    }

    if (user.role !== Role.STAFF) {
      return dtos;
    }

    const actor = await this.usersService.findSanitizedById(user.tenantId, user.sub);
    const actorProps = actor.propertyIds ?? [];
    const targetIds = [...new Set(entries.map((e) => e.userId))];
    const userMap = await this.usersService.findSanitizedByIds(user.tenantId, targetIds);

    return dtos.filter((row) =>
      this.staffCanSeePresence(actor.id, actorProps, userMap, row.userId),
    );
  }

  private staffCanSeePresence(
    actorUserId: string,
    actorPropertyIds: string[],
    targetMap: Map<string, SanitizedUser>,
    targetUserId: string,
  ): boolean {
    if (targetUserId === actorUserId) {
      return true;
    }
    const target = targetMap.get(targetUserId);
    if (!target) {
      return false;
    }
    if (target.role === Role.OWNER || target.role === Role.MANAGER) {
      return true;
    }
    const t = target.propertyIds ?? [];
    const a = actorPropertyIds;
    if (a.length === 0 || t.length === 0) {
      return false;
    }
    return a.some((id) => t.includes(id));
  }
}
