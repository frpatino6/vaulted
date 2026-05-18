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
import { UpdatePolicyDto } from './dto/update-policy.dto';
import { InsuranceService } from './insurance.service';
import { PolicyStatus } from './entities/insurance-policy.entity';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';

/** Mutating routes intentionally exclude {@link Role.AUDITOR} — auditors are read-only (GET). */
@ApiTags('Insurance')
@Controller('insurance')
export class InsuranceController {
  constructor(private readonly insuranceService: InsuranceService) {}

  // ─── Policies ────────────────────────────────────────────────────────────────

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('policies')
  @ApiOperation({ summary: 'Create insurance policy' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Policy created' })
  createPolicy(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreatePolicyDto,
  ) {
    return this.insuranceService.createPolicy(user.tenantId, user.sub, dto);
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.AUDITOR)
  @Get('policies')
  @ApiOperation({ summary: 'Get all policies' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Policies retrieved' })
  findAllPolicies(
    @CurrentUser() user: JwtPayload,
    @Query('status') status?: PolicyStatus,
  ) {
    return this.insuranceService.findAllPolicies(user.tenantId, { status });
  }

  @Roles(Role.OWNER, Role.MANAGER, Role.AUDITOR)
  @Get('policies/:id')
  @ApiOperation({ summary: 'Get policy by ID' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Policy retrieved' })
  findPolicyById(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
  ) {
    return this.insuranceService.findPolicyById(user.tenantId, policyId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put('policies/:id')
  @ApiOperation({ summary: 'Update policy' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Policy updated' })
  updatePolicy(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
    @Body() dto: UpdatePolicyDto,
  ) {
    return this.insuranceService.updatePolicy(user.tenantId, policyId, user.sub, dto);
  }

  @Roles(Role.OWNER)
  @Delete('policies/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete policy' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Policy deleted' })
  deletePolicy(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
  ) {
    return this.insuranceService.deletePolicy(user.tenantId, policyId, user.sub);
  }

  // ─── Item attachment ──────────────────────────────────────────────────────────

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('policies/:id/items')
  @ApiOperation({ summary: 'Attach item to policy' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Item attached' })
  attachItem(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
    @Body() dto: AttachItemDto,
  ) {
    return this.insuranceService.attachItem(user.tenantId, policyId, user.sub, dto);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete('policies/:id/items/:itemId')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Detach item from policy' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Item detached' })
  detachItem(
    @CurrentUser() user: JwtPayload,
    @Param('id') policyId: string,
    @Param('itemId') itemId: string,
  ) {
    return this.insuranceService.detachItem(user.tenantId, policyId, itemId, user.sub);
  }

  // ─── Coverage analysis ────────────────────────────────────────────────────────

  @Roles(Role.OWNER, Role.MANAGER, Role.AUDITOR)
  @Get('coverage-gaps')
  @ApiOperation({ summary: 'Get coverage gaps analysis' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Coverage gaps retrieved' })
  getCoverageGaps(@CurrentUser() user: JwtPayload) {
    return this.insuranceService.getCoverageGaps(user.tenantId, user.sub, user.role);
  }
}
