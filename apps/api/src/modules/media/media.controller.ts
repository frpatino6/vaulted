import {
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Query,
  Req,
  Res,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import type { Response } from 'express';
import { Request } from 'express';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { UploadResponseDto } from './dto/upload-response.dto';
import { MediaService } from './media.service';
import { AuditService } from '../audit/audit.service';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiBearerAuth,
  ApiConsumes,
} from '@nestjs/swagger';

@ApiTags('Media')
@Controller('media')
export class MediaController {
  constructor(
    private readonly mediaService: MediaService,
    private readonly auditService: AuditService,
  ) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('upload')
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Upload media file' })
  @ApiBearerAuth()
  @ApiResponse({ status: 201, description: 'File uploaded' })
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  async upload(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File | undefined,
    @Req() req: Request,
  ): Promise<UploadResponseDto> {
    const result = await this.mediaService.upload(user.tenantId, user.sub, file);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'media.upload',
      entityType: 'media',
      entityId: result.filename,
      metadata: { mimeType: result.mimeType, size: result.size },
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete('file')
  @ApiOperation({ summary: 'Delete media file' })
  @ApiBearerAuth()
  @ApiResponse({ status: 200, description: 'File deleted' })
  async delete(
    @CurrentUser() user: JwtPayload,
    @Query('key') key: string | undefined,
    @Req() req: Request,
  ): Promise<{ deleted: true }> {
    const result = await this.mediaService.delete(user.tenantId, key);
    await this.auditService.log({
      tenantId: user.tenantId,
      userId: user.sub,
      action: 'media.delete',
      entityType: 'media',
      entityId: key ?? 'unknown',
      ipAddress: req.ip ?? 'unknown',
    });
    return result;
  }

  @Public()
  @Throttle({ default: { limit: 60, ttl: 60000 } })
  @Get(':token')
  serveFile(
    @Param('token') token: string,
    @Res() res: Response,
  ): Promise<void> {
    return this.mediaService.serveFile(token, res);
  }
}
