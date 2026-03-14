import { Module, Global } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import { REDIS_CLIENT } from '../common/decorators/inject-redis.decorator';

@Global()
@Module({
  providers: [
    {
      provide: REDIS_CLIENT,
      inject: [ConfigService],
      useFactory: (config: ConfigService): Redis => {
        const redisUrl = config.get<string>('REDIS_URL');
        const client = redisUrl
          ? new Redis(redisUrl, { retryStrategy: (times: number) => Math.min(times * 100, 3000) })
          : new Redis({
              host: config.getOrThrow<string>('REDIS_HOST'),
              port: config.getOrThrow<number>('REDIS_PORT'),
              password: config.get<string>('REDIS_PASSWORD'),
              retryStrategy: (times: number) => Math.min(times * 100, 3000),
            });

        client.on('error', (err: Error) => {
          console.error('Redis connection error:', err.message);
        });

        return client;
      },
    },
  ],
  exports: [REDIS_CLIENT],
})
export class RedisModule {}
