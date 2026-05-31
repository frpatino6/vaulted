import { Module } from '@nestjs/common';
import { MongooseModule } from '@nestjs/mongoose';
import { HouseholdMembersController } from './household-members.controller';
import { HouseholdMembersService } from './household-members.service';
import {
  HouseholdMember,
  HouseholdMemberSchema,
} from './schemas/household-member.schema';
import { AuditModule } from '../audit/audit.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    MongooseModule.forFeature([
      { name: HouseholdMember.name, schema: HouseholdMemberSchema },
    ]),
    AuditModule,
    UsersModule,
  ],
  controllers: [HouseholdMembersController],
  providers: [HouseholdMembersService],
  exports: [HouseholdMembersService],
})
export class HouseholdMembersModule {}
