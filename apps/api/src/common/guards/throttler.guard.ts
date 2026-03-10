import { Injectable, ExecutionContext } from '@nestjs/common';
import { ThrottlerGuard, ThrottlerRequest } from '@nestjs/throttler';
import { Request } from 'express';

@Injectable()
export class AppThrottlerGuard extends ThrottlerGuard {
  protected async getTracker(req: ThrottlerRequest): Promise<string> {
    const request = req as unknown as Request;
    // Use real IP from proxy headers, fallback to connection IP
    const ip =
      (request.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ??
      request.ip ??
      request.socket.remoteAddress ??
      'unknown';
    return ip;
  }

  protected async shouldSkip(context: ExecutionContext): Promise<boolean> {
    return false; // Never skip throttling
  }
}
