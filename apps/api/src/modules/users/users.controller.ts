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
import { InviteUserDto } from './dto/invite-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { UsersService } from './users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('invite')
  invite(@CurrentUser() user: JwtPayload, @Body() dto: InviteUserDto) {
    return this.usersService.invite(user.tenantId, user.sub, dto);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Get()
  findAll(@CurrentUser() user: JwtPayload) {
    return this.usersService.findAllByTenant(user.tenantId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Get(':id')
  findById(@CurrentUser() user: JwtPayload, @Param('id') userId: string) {
    return this.usersService.findSanitizedById(user.tenantId, userId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put(':id')
  update(
    @CurrentUser() user: JwtPayload,
    @Param('id') userId: string,
    @Body() dto: UpdateUserDto,
  ) {
    return this.usersService.updateUser(user.tenantId, user.sub, userId, dto);
  }

  @Roles(Role.OWNER)
  @Delete(':id')
  @HttpCode(HttpStatus.OK)
  delete(@CurrentUser() user: JwtPayload, @Param('id') userId: string) {
    return this.usersService.deactivateUser(user.tenantId, user.sub, userId);
  }
}
