import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import {
  OnGatewayConnection,
  OnGatewayDisconnect,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { Redis } from 'ioredis';
import { Server, Socket } from 'socket.io';

import { InjectRedis } from '../../common/decorators/inject-redis.decorator';
import { ALLOWED_ORIGINS } from '../../common/config/cors.constants';
import { MFA_REQUIRED_ROLES } from '../../common/enums/role.enum';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';

interface StepCompletedPayload {
  planId: string;
  groupId: string;
  stepId: string;
  completedByUserId: string;
  percentComplete: number;
}

interface PlanCompletedPayload {
  planId: string;
  title: string;
}

@WebSocketGateway({
  namespace: '/orchestrator',
  cors: { origin: [...ALLOWED_ORIGINS], credentials: true },
})
export class OrchestratorGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(OrchestratorGateway.name);

  constructor(
    @InjectRedis() private readonly redis: Redis,
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
    } catch (e) {
      const err = e as Error;
      this.logger.warn(`WS orchestrator connection rejected: ${err.message}`);
      client.disconnect(true);
    }
  }

  async handleDisconnect(client: Socket): Promise<void> {
    const user = client.data['user'] as JwtPayload | undefined;
    if (!user) {
      return;
    }
    this.logger.debug(`Orchestrator WS disconnected: user ${user.sub}`);
  }

  emitStepCompleted(tenantId: string, payload: StepCompletedPayload): void {
    this.server.to(`tenant:${tenantId}`).emit('orchestrator:step_completed', payload);
  }

  emitPlanCompleted(tenantId: string, payload: PlanCompletedPayload): void {
    this.server.to(`tenant:${tenantId}`).emit('orchestrator:plan_completed', payload);
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
