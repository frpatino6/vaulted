import { Injectable, Logger } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { InjectDataSource } from '@nestjs/typeorm';
import { Connection } from 'mongoose';
import { DataSource } from 'typeorm';
import { Redis } from 'ioredis';
import { InjectRedis } from '../common/decorators/inject-redis.decorator';

export interface ServiceStatus {
  status: 'ok' | 'error';
  message?: string;
}

export interface HealthStatus {
  status: 'ok' | 'degraded';
  timestamp: string;
  services: {
    mongodb: ServiceStatus;
    postgres: ServiceStatus;
    redis: ServiceStatus;
  };
}

@Injectable()
export class HealthService {
  private readonly logger = new Logger(HealthService.name);

  constructor(
    @InjectConnection() private readonly mongoConnection: Connection,
    @InjectDataSource() private readonly dataSource: DataSource,
    @InjectRedis() private readonly redis: Redis,
  ) {}

  async check(): Promise<HealthStatus> {
    const [mongodb, postgres, redis] = await Promise.all([
      this.checkMongo(),
      this.checkPostgres(),
      this.checkRedis(),
    ]);

    const allOk = mongodb.status === 'ok' && postgres.status === 'ok' && redis.status === 'ok';

    return {
      status: allOk ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      services: { mongodb, postgres, redis },
    };
  }

  private async checkMongo(): Promise<ServiceStatus> {
    try {
      if (this.mongoConnection.readyState !== 1) {
        return { status: 'error', message: 'Not connected' };
      }
      return { status: 'ok' };
    } catch (err) {
      this.logger.error('MongoDB health check failed', err);
      return { status: 'error', message: 'Ping failed' };
    }
  }

  private async checkPostgres(): Promise<ServiceStatus> {
    try {
      await this.dataSource.query('SELECT 1');
      return { status: 'ok' };
    } catch (err) {
      this.logger.error('PostgreSQL health check failed', err);
      return { status: 'error', message: 'Query failed' };
    }
  }

  private async checkRedis(): Promise<ServiceStatus> {
    try {
      await this.redis.ping();
      return { status: 'ok' };
    } catch (err) {
      this.logger.error('Redis health check failed', err);
      return { status: 'error', message: 'Ping failed' };
    }
  }
}
