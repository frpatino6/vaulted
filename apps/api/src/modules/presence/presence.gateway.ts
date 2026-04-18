import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Redis } from 'ioredis';
import { Server, Socket } from 'socket.io';

import { InjectRedis } from '../../common/decorators/inject-redis.decorator';
import { Role } from '../../common/enums/role.enum';
import { MFA_REQUIRED_ROLES } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { PresenceService } from './presence.service';

@WebSocketGateway({
  namespace: '/presence',
  cors: { origin: true, credentials: true },
})
export class PresenceGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(PresenceGateway.name);

  constructor(
    @InjectRedis() private readonly redis: Redis,
    private readonly presenceService: PresenceService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async handleConnection(client: Socket): Promise<void> {
    try {
      const token = this.extractToken(client);
      if (!token) {
        client.disconnect(true);
        return;
      }

      const secret = this.configService.getOrThrow<string>('JWT_SECRET');
      const payload = await this.jwtService.verifyAsync<JwtPayload>(token, { secret });

      const isBlacklisted = await this.redis.get(`blacklist:${token}`);
      if (isBlacklisted) {
        client.disconnect(true);
        return;
      }

      if (MFA_REQUIRED_ROLES.includes(payload.role) && !payload.mfaVerified) {
        client.disconnect(true);
        return;
      }

      if (payload.role === Role.GUEST || payload.role === Role.AUDITOR) {
        client.disconnect(true);
        return;
      }

      client.data['user'] = payload;

      const room = `tenant:${payload.tenantId}`;
      await client.join(room);

      const { isNewSession } = await this.presenceService.registerConnection(payload.tenantId, payload);

      if (isNewSession) {
        client.to(room).emit('presence:user_online', { userId: payload.sub });
      }
    } catch (e) {
      const err = e as Error;
      this.logger.warn(`WS connection rejected: ${err.message}`);
      client.disconnect(true);
    }
  }

  async handleDisconnect(client: Socket): Promise<void> {
    const user = client.data['user'] as JwtPayload | undefined;
    if (!user) {
      return;
    }

    const { fullyOffline } = await this.presenceService.unregisterConnection(user.tenantId, user.sub);
    if (fullyOffline) {
      const room = `tenant:${user.tenantId}`;
      this.server.to(room).emit('presence:user_offline', { userId: user.sub });
    }
  }

  @SubscribeMessage('heartbeat')
  async onHeartbeat(@ConnectedSocket() client: Socket): Promise<void> {
    const user = client.data['user'] as JwtPayload | undefined;
    if (!user) {
      return;
    }
    await this.presenceService.refreshTTL(user.tenantId, user.sub);
  }

  private extractToken(client: Socket): string | undefined {
    const auth = client.handshake.auth;
    if (auth && typeof auth === 'object' && 'token' in auth) {
      const t = (auth as { token?: unknown }).token;
      if (typeof t === 'string' && t.length > 0) {
        return t;
      }
    }
    return undefined;
  }
}
