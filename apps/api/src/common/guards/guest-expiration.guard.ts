import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Request } from 'express';
import { User } from '../../modules/users/entities/user.entity';
import { Role } from '../enums/role.enum';
import { JwtPayload } from '../../modules/auth/strategies/jwt.strategy';

@Injectable()
export class GuestExpirationGuard implements CanActivate {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<Request & { user: JwtPayload }>();
    const user = request.user;

    if (!user || user.role !== Role.GUEST) return true;

    const expired = await this.isGuestExpired(user.sub, user.tenantId);
    if (expired) {
      throw new ForbiddenException('Guest access has expired');
    }
    return true;
  }

  async isGuestExpired(userId: string, tenantId: string): Promise<boolean> {
    const entity = await this.userRepository.findOne({
      where: { id: userId, tenantId },
      select: ['expiresAt', 'isActive'],
    });

    if (!entity || !entity.isActive) return true;
    if (entity.expiresAt && entity.expiresAt < new Date()) return true;

    return false;
  }
}
