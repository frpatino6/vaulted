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
import { ApiBearerAuth, ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { CreateHouseholdMemberDto } from './dto/create-household-member.dto';
import { UpdateHouseholdMemberDto } from './dto/update-household-member.dto';
import { HouseholdMembersService } from './household-members.service';

@ApiTags('Household Members')
@Controller('household-members')
export class HouseholdMembersController {
  constructor(private readonly householdMembersService: HouseholdMembersService) {}

  // TODO: Claude Code will add @Roles() and guards
  @Post()
  @ApiOperation({ summary: 'Create a household member' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Household member created' })
  create(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateHouseholdMemberDto,
  ) {
    // TODO: audit log
    return this.householdMembersService.create(user.tenantId, user.sub, dto);
  }

  @Get()
  @ApiOperation({ summary: 'List household members' })
  @ApiBearerAuth()
  @ApiQuery({ name: 'includeInactive', required: false, type: Boolean })
  @ApiResponse({ status: 200, description: 'Household members retrieved' })
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
  @ApiOperation({ summary: 'Update a household member' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Household member updated' })
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
  @ApiOperation({ summary: 'Archive a household member' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Household member archived' })
  archive(@CurrentUser() user: JwtPayload, @Param('id') memberId: string) {
    // TODO: audit log
    return this.householdMembersService.archive(user.tenantId, memberId);
  }
}
