import {
  Controller,
  Delete,
  Post,
  Query,
  UploadedFile,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { Roles } from '../../common/decorators/roles.decorator';
import { Role } from '../../common/enums/role.enum';
import { JwtPayload } from '../auth/strategies/jwt.strategy';
import { UploadResponseDto } from './dto/upload-response.dto';
import { MediaService } from './media.service';

@Controller('media')
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Roles(Role.OWNER, Role.MANAGER)
  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: 10 * 1024 * 1024 },
    }),
  )
  upload(
    @CurrentUser() user: JwtPayload,
    @UploadedFile() file: Express.Multer.File | undefined,
  ): Promise<UploadResponseDto> {
    return this.mediaService.upload(user.tenantId, file);
  }

  @Roles(Role.OWNER, Role.MANAGER)
  @Delete('file')
  delete(
    @CurrentUser() user: JwtPayload,
    @Query('key') key: string | undefined,
  ): Promise<{ deleted: true }> {
    return this.mediaService.delete(user.tenantId, key);
  }
}
