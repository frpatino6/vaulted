import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { InjectRedis } from '../../../common/decorators/inject-redis.decorator';
import { Redis } from 'ioredis';
import { Role } from '../../../common/enums/role.enum';

export interface JwtPayload {
  sub: string;       // userId
  tenantId: string;
  email: string;
  role: Role;
  mfaVerified: boolean;
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
      passReqToCallback: true,
    });
  }

  async validate(req: Request & { headers: { authorization?: string } }, payload: JwtPayload): Promise<JwtPayload> {
    const token = req.headers.authorization?.replace('Bearer ', '');

    if (token) {
      const isBlacklisted = await this.redis.get(`blacklist:${token}`);
      if (isBlacklisted) {
        throw new UnauthorizedException('Token has been revoked');
      }
    }

    return payload;
  }
}
