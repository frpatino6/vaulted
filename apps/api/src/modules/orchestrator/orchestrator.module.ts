import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { JwtModule } from '@nestjs/jwt';
import { MongooseModule } from '@nestjs/mongoose';
import { AuditModule } from '../audit/audit.module';
import { AiSharedModule } from '../ai/shared/ai-shared.module';
import { UsersModule } from '../users/users.module';
import { MediaModule } from '../media/media.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { Item, ItemSchema } from '../inventory/schemas/item.schema';
import { Property, PropertySchema } from '../properties/schemas/property.schema';
import {
  OrchestratorPlan,
  OrchestratorPlanSchema,
} from './schemas/orchestrator-plan.schema';
import { GuestExpirationGuard } from '../../common/guards/guest-expiration.guard';
import { OrchestratorController } from './orchestrator.controller';
import { OrchestratorService } from './orchestrator.service';
import { OrchestratorAiService } from './orchestrator-ai.service';
import { OrchestratorGateway } from './orchestrator.gateway';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: OrchestratorPlan.name, schema: OrchestratorPlanSchema },
      { name: Item.name, schema: ItemSchema },
      { name: Property.name, schema: PropertySchema },
    ]),
    ConfigModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.getOrThrow<string>('JWT_SECRET'),
        signOptions: { expiresIn: '15m' },
      }),
    }),
    UsersModule,
    AuditModule,
    AiSharedModule,
    MediaModule,
    NotificationsModule,
  ],
  controllers: [OrchestratorController],
  providers: [OrchestratorService, OrchestratorAiService, OrchestratorGateway, GuestExpirationGuard],
  exports: [OrchestratorService],
})
export class OrchestratorModule {}
