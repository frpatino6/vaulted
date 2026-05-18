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
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { AuditService } from '../audit/audit.service';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { AddOutfitItemDto } from './dto/add-outfit-item.dto';
import { AtLaundryQueryDto } from './dto/at-laundry-query.dto';
import { CreateDryCleaningDto } from './dto/create-dry-cleaning.dto';
import { CreateOutfitDto } from './dto/create-outfit.dto';
import { UpdateOutfitDto } from './dto/update-outfit.dto';
import { WardrobeService } from './wardrobe.service';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';

@ApiTags('Wardrobe')
@Controller('wardrobe')
export class WardrobeController {
  constructor(
    private readonly wardrobeService: WardrobeService,
    private readonly auditService: AuditService,
  ) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('outfits')
  @ApiOperation({ summary: 'Create outfit' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Outfit created' })
  async createOutfit(
    @CurrentUser() user: JwtPayload,
    @Body() dto: CreateOutfitDto,
    @Req() req: Request,
  ) {
    const outfit = await this.wardrobeService.createOutfit(
      user.tenantId,
      user.sub,
      dto,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'wardrobe.outfit.create',
      entityType: 'outfit',
      entityId: String((outfit as { _id?: unknown })._id),
      ipAddress: req.ip,
    });

    return outfit;
  }

  @Get('outfits')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'List outfits' })
  @ApiBearerAuth()
  @ApiQuery({ name: 'ownerMemberId', required: false })
  @ApiResponse({ status: 200, description: 'Outfits retrieved' })
  listOutfits(
    @CurrentUser() user: JwtPayload,
    @Query('ownerMemberId') ownerMemberId?: string,
  ) {
    return this.wardrobeService.listOutfits(user.tenantId, ownerMemberId);
  }

  @Get('outfits/:id')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'Get outfit by ID' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Outfit retrieved' })
  getOutfit(@CurrentUser() user: JwtPayload, @Param('id') outfitId: string) {
    return this.wardrobeService.getOutfitWithItems(user.tenantId, outfitId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put('outfits/:id')
  @ApiOperation({ summary: 'Update outfit' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Outfit updated' })
  async updateOutfit(
    @CurrentUser() user: JwtPayload,
    @Param('id') outfitId: string,
    @Body() dto: UpdateOutfitDto,
    @Req() req: Request,
  ) {
    const outfit = await this.wardrobeService.updateOutfit(
      user.tenantId,
      outfitId,
      dto,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'wardrobe.outfit.update',
      entityType: 'outfit',
      entityId: outfitId,
      ipAddress: req.ip,
    });

    return outfit;
  }

  @Roles(Role.OWNER)
  @Delete('outfits/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete outfit' })
  @ApiBearerAuth()
  @ApiResponse({ status: 204, description: 'Outfit deleted' })
  async deleteOutfit(
    @CurrentUser() user: JwtPayload,
    @Param('id') outfitId: string,
    @Req() req: Request,
  ) {
    const result = await this.wardrobeService.deleteOutfit(
      user.tenantId,
      outfitId,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'wardrobe.outfit.delete',
      entityType: 'outfit',
      entityId: outfitId,
      ipAddress: req.ip,
    });

    return result;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('outfits/:id/items')
  @ApiOperation({ summary: 'Add item to outfit' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Item added to outfit' })
  async addItemToOutfit(
    @CurrentUser() user: JwtPayload,
    @Param('id') outfitId: string,
    @Body() dto: AddOutfitItemDto,
    @Req() req: Request,
  ) {
    const outfit = await this.wardrobeService.addItemToOutfit(
      user.tenantId,
      outfitId,
      dto.itemId,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'wardrobe.outfit.add_item',
      entityType: 'outfit',
      entityId: outfitId,
      metadata: { itemId: dto.itemId },
      ipAddress: req.ip,
    });

    return outfit;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete('outfits/:id/items/:itemId')
  @ApiOperation({ summary: 'Remove item from outfit' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Item removed from outfit' })
  async removeItemFromOutfit(
    @CurrentUser() user: JwtPayload,
    @Param('id') outfitId: string,
    @Param('itemId') itemId: string,
    @Req() req: Request,
  ) {
    const outfit = await this.wardrobeService.removeItemFromOutfit(
      user.tenantId,
      outfitId,
      itemId,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'wardrobe.outfit.remove_item',
      entityType: 'outfit',
      entityId: outfitId,
      metadata: { itemId },
      ipAddress: req.ip,
    });

    return outfit;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('dry-cleaning/:itemId')
  @ApiOperation({ summary: 'Create dry cleaning record' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'Dry cleaning record created' })
  async createDryCleaningRecord(
    @CurrentUser() user: JwtPayload,
    @Param('itemId') itemId: string,
    @Body() dto: CreateDryCleaningDto,
    @Req() req: Request,
  ) {
    const record = await this.wardrobeService.createDryCleaningRecord(
      user.tenantId,
      user.sub,
      itemId,
      dto,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'wardrobe.dry_cleaning.create',
      entityType: 'dry_cleaning_record',
      entityId: String((record as { _id?: unknown })._id),
      metadata: { itemId },
      ipAddress: req.ip,
    });

    return record;
  }

  @Get('dry-cleaning/:itemId')
  @Roles(Role.OWNER, Role.MANAGER)
  @ApiOperation({ summary: 'List dry cleaning history' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'History retrieved' })
  listDryCleaningHistory(
    @CurrentUser() user: JwtPayload,
    @Param('itemId') itemId: string,
  ) {
    return this.wardrobeService.listDryCleaningHistory(user.tenantId, itemId);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put('dry-cleaning/:recordId/return')
  @ApiOperation({ summary: 'Mark dry cleaning as returned' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Marked as returned' })
  async markDryCleaningReturned(
    @CurrentUser() user: JwtPayload,
    @Param('recordId') recordId: string,
    @Req() req: Request,
  ) {
    const record = await this.wardrobeService.markDryCleaningReturned(
      user.tenantId,
      recordId,
    );

    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'wardrobe.dry_cleaning.returned',
      entityType: 'dry_cleaning_record',
      entityId: recordId,
      ipAddress: req.ip,
    });

    return record;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Put('dry-cleaning/:itemId/return-latest')
  @ApiOperation({ summary: 'Mark latest dry cleaning record as returned for item' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Latest record marked returned or not found' })
  async markDryCleaningReturnedByItem(
    @CurrentUser() user: JwtPayload,
    @Param('itemId') itemId: string,
    @Req() req: Request,
  ) {
    const record = await this.wardrobeService.markDryCleaningReturnedByItem(
      user.tenantId,
      itemId,
    );

    if (record) {
      await this.auditService.log({
        tenantId: user.tenantId,
        userId: user.sub,
        action: 'wardrobe.dry_cleaning.returned',
        entityType: 'dry_cleaning_record',
        entityId: String((record as { _id?: unknown })._id),
        metadata: { itemId },
        ipAddress: req.ip,
      });
    }

    return record ?? { returned: false };
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Get('at-laundry')
  @ApiOperation({ summary: 'List wardrobe items currently at laundry' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'At-laundry items retrieved' })
  getAtLaundry(
    @CurrentUser() user: JwtPayload,
    @Query() query: AtLaundryQueryDto,
  ) {
    return this.wardrobeService.getAtLaundry(
      user.tenantId,
      query.thresholdDays ?? 7,
    );
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Get('stats')
  @ApiOperation({ summary: 'Get wardrobe statistics' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'Stats retrieved' })
  getStats(@CurrentUser() user: JwtPayload) {
    return this.wardrobeService.getStats(user.tenantId);
  }
}
