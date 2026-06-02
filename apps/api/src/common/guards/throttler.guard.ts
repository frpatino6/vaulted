import { Injectable, ExecutionContext } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerRequest } from '@nestjs/throttler';
import { Request } from 'express';

@Injectable()
export class AppThrottlerGuard extends ThrottlerGuard {
  protected async getTracker(req: ThrottlerRequest): Promise<string> {
    const request = req as unknown as Request;

    if (this.isPublicAuthRoute(request)) {
      return this.getIpTracker(request);
    }

    // Decode JWT payload (no signature check — bucketing only) to throttle
    // per user and avoid Cloudflare IP collisions across users.
    const userId = this.extractUserId(request);
    if (userId) return `user:${userId}`;

    return this.getIpTracker(request);
  }

  private getIpTracker(request: Request): string {
    const ip =
      (request.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ??
      request.ip ??
      request.socket.remoteAddress ??
      'unknown';
    return ip;
  }

  protected async shouldSkip(context: ExecutionContext): Promise<boolean> {
    return super.shouldSkip(context);
  }

  private extractUserId(request: Request): string | null {
    // 1. Authorization: Bearer <access-token> — standard authenticated routes
    const authHeader = request.headers['authorization'] as string | undefined;
    if (authHeader?.startsWith('Bearer ')) {
      const sub = this.decodeJwtSub(authHeader.slice(7));
      if (sub) return sub;
    }

    // 2. /api/media/:token — CachedNetworkImage loads images without Auth header.
    //    The media JWT in the URL path contains userId for bucketing.
    const mediaMatch = (request.path ?? '').match(/^\/api\/media\/([^/?]+)/);
    if (mediaMatch) {
      const userId = this.decodeJwtUserId(mediaMatch[1]);
      if (userId) return userId;
    }

    return null;
  }

  private isPublicAuthRoute(request: Request): boolean {
    const path = request.path ?? request.url ?? '';
    return /^\/api\/auth\/(register|login|accept-invite|refresh)$/.test(path);
  }

  private decodeJwtSub(token: string): string | null {
    try {
      const raw = Buffer.from(token.split('.')[1], 'base64url').toString();
      const payload = JSON.parse(raw) as { sub?: string };
      return payload?.sub ?? null;
    } catch {
      return null;
    }
  }

  private decodeJwtUserId(token: string): string | null {
    try {
      const raw = Buffer.from(token.split('.')[1], 'base64url').toString();
      const payload = JSON.parse(raw) as { userId?: string };
      return payload?.userId ?? null;
    } catch {
      return null;
    }
  }
}
