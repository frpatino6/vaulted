import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
} from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { CreateUserDirectDto } from './dto/create-user-direct.dto';
import { InviteUserDto } from './dto/invite-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

@ApiTags('Users')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Roles(Role.OWNER)
  @Post()
  createDirect(@CurrentUser() user: JwtPayload, @Body() dto: CreateUserDirectDto) {
    return this.usersService.createDirect(user.tenantId, dto);
  }

  @Roles(Role.OWNER)
  @Post('invite')
  @ApiOperation({ summary: 'Invite a new user' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'User invited' })
  invite(@CurrentUser() user: JwtPayload, @Body() dto: InviteUserDto) {
    return this.usersService.invite(user.tenantId, user.sub, user.role, dto);
  }

  @Roles(Role.OWNER)
  @Get()
  @ApiOperation({ summary: 'Get all users' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Users retrieved' })
  findAll(@CurrentUser() user: JwtPayload) {
    return this.usersService.findAllByTenant(user.tenantId);
  }

  @Roles(Role.OWNER)
  @Get(':id')
  @ApiOperation({ summary: 'Get user by ID' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'User retrieved' })
  findById(@CurrentUser() user: JwtPayload, @Param('id') userId: string) {
    return this.usersService.findSanitizedById(user.tenantId, userId);
  }

  @Roles(Role.OWNER)
  @Put(':id')
  @ApiOperation({ summary: 'Update user' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'User updated' })
  update(
    @CurrentUser() user: JwtPayload,
    @Param('id') userId: string,
    @Body() dto: UpdateUserDto,
  ) {
    return this.usersService.updateUser(user.tenantId, user.sub, user.role, userId, dto);
  }

  @Roles(Role.OWNER)
  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Deactivate user' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'User deactivated' })
  delete(@CurrentUser() user: JwtPayload, @Param('id') userId: string) {
    return this.usersService.deactivateUser(user.tenantId, user.sub, userId);
  }
}
