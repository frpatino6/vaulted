import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Request } from 'express';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { JwtPayload } from '../../modules/auth/strategies/jwt.strategy';
import { MFA_REQUIRED_ROLES } from '../enums/role.enum';

export const SKIP_MFA_KEY = 'skipMfa';

// Blocks access for Owner/Manager if MFA has not been verified in this session
@Injectable()
export class MfaVerifiedGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const skipMfa = this.reflector.getAllAndOverride<boolean>(SKIP_MFA_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (skipMfa) return true;

    const request = context
      .switchToHttp()
      .getRequest<Request & { user?: JwtPayload }>();

    const user = request.user;
    if (!user) return true; // JwtAuthGuard handles missing user

    if (MFA_REQUIRED_ROLES.includes(user.role) && !user.mfaVerified) {
      throw new ForbiddenException(
        'MFA verification required. Complete MFA at POST /auth/mfa/verify',
      );
    }

    return true;
  }
}
