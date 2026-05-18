import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { CreateHouseholdMemberDto } from './dto/create-household-member.dto';
import { UpdateHouseholdMemberDto } from './dto/update-household-member.dto';
import { HouseholdMembersService } from './household-members.service';

@Controller('household-members')
export class HouseholdMembersController {
  constructor(private readonly householdMembersService: HouseholdMembersService) {}

  // TODO: Claude Code will add @Roles() and guards
  @Post()
  create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateHouseholdMemberDto,
  ) {
    // TODO: audit log
    return this.householdMembersService.create(user.tenantId, user.sub, dto);
  }

  @Get()
  findAll(
    @CurrentUser() user: JwtPayload,
    @Query('includeInactive') includeInactive?: string,
  ) {
    return this.householdMembersService.findAll(
      user.tenantId,
      includeInactive === 'true',
    );
  }

  // TODO: Claude Code will add @Roles() and guards
  @Patch(':id')
  update(
    @CurrentUser() user: JwtPayload,
    @Param('id') memberId: string,
    @Body() dto: UpdateHouseholdMemberDto,
  ) {
    // TODO: audit log
    return this.householdMembersService.update(user.tenantId, memberId, dto);
  }

  // TODO: Claude Code will add @Roles() and guards
  @Delete(':id')
  archive(@CurrentUser() user: JwtPayload, @Param('id') memberId: string) {
    // TODO: audit log
    return this.householdMembersService.archive(user.tenantId, memberId);
  }
}
