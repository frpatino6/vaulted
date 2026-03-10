import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';
import { InjectRedis } from '../../../common/decorators/inject-redis.decorator';
import { Redis } from 'ioredis';
import { JwtPayload } from './jwt.strategy';

export interface JwtRefreshPayload extends JwtPayload {
  refreshTokenId: string;
}

@Injectable()
export class JwtRefreshStrategy extends PassportStrategy(Strategy, 'jwt-refresh') {
  constructor(
    config: ConfigService,
    @InjectRedis() private readonly redis: Redis,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromExtractors([
        (req: Request) => req.cookies?.['refresh_token'] as string | null ?? null,
      ]),
      secretOrKey: config.getOrThrow<string>('JWT_REFRESH_SECRET'),
      passReqToCallback: true,
    });
  }

  async validate(req: Request, payload: JwtRefreshPayload): Promise<JwtRefreshPayload> {
    const token = req.cookies?.['refresh_token'] as string | undefined;

    if (!token) {
      throw new UnauthorizedException('Refresh token not found');
    }

    const isBlacklisted = await this.redis.get(`blacklist:refresh:${payload.refreshTokenId}`);
    if (isBlacklisted) {
      throw new UnauthorizedException('Refresh token has been revoked');
    }

    return payload;
  }
}
