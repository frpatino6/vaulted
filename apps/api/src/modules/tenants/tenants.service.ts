import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tenant } from './entities/tenant.entity';

@Injectable()
export class TenantsService {
  constructor(
    @InjectRepository(Tenant)
    private readonly tenantRepository: Repository<Tenant>,
  ) {}

  async create(name: string): Promise<Tenant> {
    const existing = await this.tenantRepository.findOne({ where: { name } });
    if (existing) {
      throw new ConflictException('Tenant name already exists');
    }

    const tenant = this.tenantRepository.create({ name });
    return this.tenantRepository.save(tenant);
  }

  async findById(id: string): Promise<Tenant | null> {
    return this.tenantRepository.findOne({ where: { id } });
  }
}
