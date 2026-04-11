import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../modules/users/entities/user.entity';
import { Role } from '../enums/role.enum';

@Injectable()
export class AccessControlService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async getAllowedPropertyIds(
    userId: string,
    role: Role,
  ): Promise<string[] | null> {
    if (role === Role.OWNER || role === Role.MANAGER) return null;
    const user = await this.userRepository.findOne({
      where: { id: userId },
      select: ['propertyIds'],
    });
    return user?.propertyIds ?? [];
  }

  stripValuation<T>(item: T): Omit<T, 'valuation'> {
    const maybeDoc = item as T & { toObject?: () => T };
    const plain = typeof maybeDoc.toObject === 'function'
      ? maybeDoc.toObject()
      : { ...item };
    delete (plain as T & { valuation?: unknown }).valuation;
    return plain as Omit<T, 'valuation'>;
  }
}
