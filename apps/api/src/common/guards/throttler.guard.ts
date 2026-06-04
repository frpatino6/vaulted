import { Injectable, ExecutionContext } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerRequest, ThrottlerModuleOptions, ThrottlerStorageService } from '@nestjs/throttler';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

@Injectable()
export class AppThrottlerGuard extends ThrottlerGuard {
  constructor(
    options: ThrottlerModuleOptions,
    storageService: ThrottlerStorageService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {
    super(options, storageService);
  }

  protected async getTracker(req: ThrottlerRequest): Promise<string> {
    const request = req as unknown as Request;

    if (this.isPublicAuthRoute(request)) {
      return request.ip ?? request.socket.remoteAddress ?? 'unknown';
    }

    const userId = this.extractUserId(request);
    if (userId) return `user:${userId}`;

    return request.ip ?? request.socket.remoteAddress ?? 'unknown';
  }

  protected async shouldSkip(context: ExecutionContext): Promise<boolean> {
    return super.shouldSkip(context);
  }

  private extractUserId(request: Request): string | null {
    const authHeader = request.headers['authorization'] as string | undefined;
    if (authHeader?.startsWith('Bearer ')) {
      const sub = this.verifyAccessTokenSub(authHeader.slice(7));
      if (sub) return sub;
    }

    const mediaMatch = (request.path ?? '').match(/^\/api\/media\/([^/?]+)/);
    if (mediaMatch) {
      const userId = this.verifyMediaTokenUserId(mediaMatch[1]);
      if (userId) return userId;
    }

    return null;
  }

  private isPublicAuthRoute(request: Request): boolean {
    const path = request.path ?? request.url ?? '';
    return /^\/api\/auth\/(register|login|accept-invite|refresh)$/.test(path);
  }

  private verifyAccessTokenSub(token: string): string | null {
    try {
      const secret = this.configService.get<string>('JWT_SECRET');
      if (!secret) return null;
      const payload = this.jwtService.verify<{ sub?: string }>(token, { secret, ignoreExpiration: true });
      return payload?.sub ?? null;
    } catch {
      return null;
    }
  }

  private verifyMediaTokenUserId(token: string): string | null {
    try {
      const secret = this.configService.get<string>('MEDIA_JWT_SECRET');
      if (!secret) return null;
      const payload = this.jwtService.verify<{ userId?: string }>(token, { secret, ignoreExpiration: true });
      return payload?.userId ?? null;
    } catch {
      return null;
    }
  }
}
