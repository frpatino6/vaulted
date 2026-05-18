import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  Inject,
} from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../decorators/inject-redis.decorator';
import { AuditService } from '../../modules/audit/audit.service';
import { JwtPayload } from '../../modules/auth/strategies/jwt.strategy';

@Injectable()
export class AnomalyGuard implements CanActivate {
  constructor(
    @Inject(REDIS_CLIENT) private readonly redis: Redis,
    private readonly auditService: AuditService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<{
      user?: JwtPayload;
      method: string;
      path: string;
    }>();
    const user = req.user;
    if (!user?.sub || !user.tenantId) {
      return true;
    }

    const userId = user.sub;
    const tenantId = user.tenantId;
    const endpoint = `${req.method}:${req.path.replace(/\/[a-f0-9]{24}/gi, '/:id')}`;
    const key = `anomaly:financial:${userId}:${endpoint}`;
    const count = await this.redis.incr(key);
    if (count === 1) {
      await this.redis.expire(key, 3600);
    }
    if (count > 500) {
      await this.auditService.log({
        tenantId,
        userId,
        action: 'security.anomaly.rate_limit_exceeded',
        entityType: 'user',
        entityId: userId,
        metadata: { count, endpoint, windowSeconds: 3600 },
      });
      throw new ForbiddenException('Anomalous access pattern detected');
    }
    return true;
  }
}
