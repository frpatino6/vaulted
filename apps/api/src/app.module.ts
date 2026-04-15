import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule } from '@nestjs/mongoose';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ThrottlerModule } from '@nestjs/throttler';
import { ScheduleModule } from '@nestjs/schedule';
import { AppThrottlerGuard } from './common/guards/throttler.guard';
import { APP_GUARD } from '@nestjs/core';
import { HealthModule } from './health/health.module';
import { RedisModule } from './redis/redis.module';
import { CommonModule } from './common/common.module';
import { AuditModule } from './modules/audit/audit.module';
import { TenantsModule } from './modules/tenants/tenants.module';
import { UsersModule } from './modules/users/users.module';
import { AuthModule } from './modules/auth/auth.module';
import { PropertiesModule } from './modules/properties/properties.module';
import { InventoryModule } from './modules/inventory/inventory.module';
import { MediaModule } from './modules/media/media.module';
import { DashboardModule } from './modules/dashboard/dashboard.module';
import { AiModule } from './modules/ai/ai.module';
import { MaintenanceModule } from './modules/maintenance/maintenance.module';
import { MovementsModule } from './modules/movements/movements.module';
import { WardrobeModule } from './modules/wardrobe/wardrobe.module';
import { InsuranceModule } from './modules/insurance/insurance.module';
import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { MfaVerifiedGuard } from './common/guards/mfa-verified.guard';
import { Tenant } from './modules/tenants/entities/tenant.entity';
import { User } from './modules/users/entities/user.entity';
import { AuditLog } from './modules/audit/entities/audit-log.entity';
import { InsurancePolicy } from './modules/insurance/entities/insurance-policy.entity';
import { InsuredItem } from './modules/insurance/entities/insured-item.entity';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    ThrottlerModule.forRoot([
      {
        name: 'default',
        ttl: 60000,
        limit: 100,
      },
    ]),

    ScheduleModule.forRoot(),

    MongooseModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri: config.getOrThrow<string>('MONGODB_URI'),
      }),
    }),

    TypeOrmModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const databaseUrl = config.get<string>('DATABASE_URL');
        const isProd = config.get<string>('NODE_ENV') === 'production';
        const base = {
          type: 'postgres' as const,
          entities: [Tenant, User, AuditLog, InsurancePolicy, InsuredItem],
          synchronize: config.get<string>('TYPEORM_SYNC') === 'true' || !isProd,
          logging: !isProd,
        };
        if (databaseUrl) {
          return {
            ...base,
            url: databaseUrl,
            ssl: { rejectUnauthorized: false },
          };
        }
        return {
          ...base,
          host: config.getOrThrow<string>('POSTGRES_HOST'),
          port: config.getOrThrow<number>('POSTGRES_PORT'),
          database: config.getOrThrow<string>('POSTGRES_DB'),
          username: config.getOrThrow<string>('POSTGRES_USER'),
          password: config.getOrThrow<string>('POSTGRES_PASSWORD'),
        };
      },
    }),

    RedisModule,
    CommonModule,
    AuditModule,
    HealthModule,
    TenantsModule,
    UsersModule,
    AuthModule,
    PropertiesModule,
    AiModule,
    InventoryModule,
    MediaModule,
    DashboardModule,
    MaintenanceModule,
    MovementsModule,
    WardrobeModule,
    InsuranceModule,
  ],
  providers: [
    // Order matters: Throttler → JWT → MFA → Roles
    { provide: APP_GUARD, useClass: AppThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: MfaVerifiedGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule {}
