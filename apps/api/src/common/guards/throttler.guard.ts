import { Injectable, ExecutionContext } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerRequest } from '@nestjs/throttler';
import { Request } from 'express';

@Injectable()
export class AppThrottlerGuard extends ThrottlerGuard {
  protected async getTracker(req: ThrottlerRequest): Promise<string> {
    const request = req as unknown as Request;

    // Throttler runs before JwtAuthGuard so request.user is not set yet.
    // Decode JWT payload (no signature check — bucketing only) to throttle
    // per user and avoid Cloudflare IP collisions across users.
    const authHeader = request.headers['authorization'] as string | undefined;
    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.slice(7);
      try {
        const raw = Buffer.from(token.split('.')[1], 'base64url').toString();
        const payload = JSON.parse(raw) as { sub?: string };
        if (payload?.sub) return `user:${payload.sub}`;
      } catch {
        // fall through to IP-based tracking
      }
    }

    // Public routes: fall back to real IP from proxy headers
    const ip =
      (request.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ??
      request.ip ??
      request.socket.remoteAddress ??
      'unknown';
    return ip;
  }

  protected async shouldSkip(context: ExecutionContext): Promise<boolean> {
    return false;
  }
}
