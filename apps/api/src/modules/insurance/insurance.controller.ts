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
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { AttachItemDto } from './dto/attach-item.dto';
import { CreatePolicyDto } from './dto/create-policy.dto';
import { DetachItemParamDto } from './dto/detach-item-param.dto';
import { UpdatePolicyDto } from './dto/update-policy.dto';
import { InsuranceService } from './insurance.service';
import { PolicyStatus } from './entities/insurance-policy.entity';

@Controller('insurance')
export class InsuranceController {
  constructor(private readonly insuranceService: InsuranceService) {}

  // ─── Policies ────────────────────────────────────────────────────────────────

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('policies')
  createPolicy(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreatePolicyDto,
  ) {
    return this.insuranceService.createPolicy(user.tenantId, user.sub, dto);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.AUDITOR)
  @Get('policies')
  findAllPolicies(
    @CurrentUser() user: JwtPayload,
    @Query('status') status?: PolicyStatus,
  ) {
    return this.insuranceService.findAllPolicies(user.tenantId, { status });
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.AUDITOR)
  @Get('policies/:id')
  findPolicyById(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
  ) {
    return this.insuranceService.findPolicyById(user.tenantId, policyId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put('policies/:id')
  updatePolicy(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
    @Body() dto: UpdatePolicyDto,
  ) {
    return this.insuranceService.updatePolicy(user.tenantId, policyId, user.sub, dto);
  }

  @Roles(Role.OWNER)
  @Delete('policies/:id')
  @HttpCode(HttpStatus.OK)
  deletePolicy(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
  ) {
    return this.insuranceService.deletePolicy(user.tenantId, policyId, user.sub);
  }

  // ─── Item attachment ──────────────────────────────────────────────────────────

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('policies/:id/items')
  attachItem(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
    @Body() dto: AttachItemDto,
  ) {
    return this.insuranceService.attachItem(user.tenantId, policyId, user.sub, dto);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete('policies/:id/items/:itemId')
  @HttpCode(HttpStatus.OK)
  detachItem(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
    @Param() params: DetachItemParamDto,
  ) {
    return this.insuranceService.detachItem(user.tenantId, policyId, params.itemId, user.sub);
  }

  // ─── Coverage analysis ────────────────────────────────────────────────────────

  @Roles(Role.OWNER, Role.MANAGER, Role.AUDITOR)
  @Get('coverage-gaps')
  getCoverageGaps(@CurrentUser() user: JwtPayload) {
    return this.insuranceService.getCoverageGaps(user.tenantId);
  }
}
