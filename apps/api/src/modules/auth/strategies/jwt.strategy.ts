import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRedis } from '../../../common/decorators/inject-redis.decorator';
import { Redis } from 'ioredis';
import { createHash } from 'crypto';
import { Role } from '../../../common/enums/role.enum';

export interface JwtPayload {
  typ?: 'access' | 'refresh';
  sub: string;       // userId
  tenantId: string;
  email: string;
  role: Role;
  mfaVerified: boolean;
  propertyIds?: string[];
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(
    config: ConfigService,
    @InjectRedis() private readonly redis: Redis,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: config.getOrThrow<string>('JWT_SECRET'),
      algorithms: ['HS256'],
      passReqToCallback: true,
    });
  }

  async validate(req: Request & { headers: { authorization?: string } }, payload: JwtPayload): Promise<JwtPayload> {
    if (
      payload.typ !== 'access' ||
      !payload.sub ||
      !payload.tenantId ||
      !payload.email ||
      !payload.role ||
      typeof payload.mfaVerified !== 'boolean'
    ) {
      throw new UnauthorizedException('Invalid token claims');
    }

    const token = req.headers.authorization?.replace('Bearer ', '');

    if (token) {
      const tokenHash = createHash('sha256').update(token).digest('hex');
      const isBlacklisted = await this.redis.get(`blacklist:${tokenHash}`);
      if (isBlacklisted) {
        throw new UnauthorizedException('Token has been revoked');
      }
    }

    return payload;
  }
}
