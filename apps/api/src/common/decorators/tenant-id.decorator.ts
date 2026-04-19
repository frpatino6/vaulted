import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { TenantRequest } from '../interceptors/tenant.interceptor';

/**
 * Extracts the tenantId stamped by TenantInterceptor.
 * Use this in controllers instead of reading user.tenantId directly.
 *
 * @example
 *   findAll(@TenantId() tenantId: string) { ... }
 */
export const TenantId = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): string => {
    const request = ctx.switchToHttp().getRequest<TenantRequest>();
    return request.tenantId;
  },
);
