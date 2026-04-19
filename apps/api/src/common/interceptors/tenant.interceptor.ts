import {
  CallHandler,
  ExecutionContext,
  Injectable,
  NestInterceptor,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { Request } from 'express';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { JwtPayload } from '../../modules/auth/strategies/jwt.strategy';

export interface TenantRequest extends Request {
  user: JwtPayload;
  tenantId: string;
}

/**
 * Global interceptor — runs after JwtAuthGuard (request.user already set).
 * Extracts tenantId from the verified JWT payload and stamps it onto request.tenantId.
 * Throws 401 if tenantId is absent on any protected route.
 *
 * Skips @Public() routes (no JWT = no tenant context needed).
 */
@Injectable()
export class TenantInterceptor implements NestInterceptor {
  constructor(private readonly reflector: Reflector) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) return next.handle();

    const request = context.switchToHttp().getRequest<TenantRequest>();
    const tenantId = request.user?.tenantId;

    if (!tenantId) {
      throw new UnauthorizedException('Tenant context missing');
    }

    request.tenantId = tenantId;
    return next.handle();
  }
}
