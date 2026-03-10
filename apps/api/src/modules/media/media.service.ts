import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Storage } from '@google-cloud/storage';
import { v4 as uuidv4 } from 'uuid';
import { UploadResponseDto } from './dto/upload-response.dto';

const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;

// Magic byte signatures for each allowed MIME type.
// Validated against actual file buffer — not the client-supplied Content-Type header.
const MAGIC_SIGNATURES: Array<{ mimeType: string; bytes: number[]; offset?: number }> = [
  { mimeType: 'image/jpeg', bytes: [0xff, 0xd8, 0xff] },
  { mimeType: 'image/png', bytes: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a] },
  { mimeType: 'application/pdf', bytes: [0x25, 0x50, 0x44, 0x46] }, // %PDF
  // WebP: "RIFF" at offset 0, "WEBP" at offset 8
  { mimeType: 'image/webp', bytes: [0x52, 0x49, 0x46, 0x46], offset: 0 },
];


function detectMimeType(buffer: Buffer): string | null {
  for (const sig of MAGIC_SIGNATURES) {
    const offset = sig.offset ?? 0;
    const slice = buffer.slice(offset, offset + sig.bytes.length);
    if (slice.length === sig.bytes.length && sig.bytes.every((b, i) => slice[i] === b)) {
      // Extra check for WebP: bytes 8-11 must be "WEBP"
      if (sig.mimeType === 'image/webp') {
        const webpMarker = buffer.slice(8, 12);
        if (webpMarker.toString('ascii') !== 'WEBP') continue;
      }
      return sig.mimeType;
    }
  }
  return null;
}

@Injectable()
export class MediaService {
  private readonly storage: Storage;
  private readonly bucketName: string;
  private readonly usePublicUrls: boolean;

  constructor(private readonly configService: ConfigService) {
    this.bucketName =
      this.configService.getOrThrow<string>('GCP_STORAGE_BUCKET');
    this.usePublicUrls =
      this.configService.get<string>('GCP_STORAGE_PUBLIC') === 'true';

    const keyFilename =
      this.configService.get<string>('GCP_KEY_FILE') ||
      process.env['GOOGLE_APPLICATION_CREDENTIALS'];

    this.storage = new Storage({
      projectId: this.configService.get<string>('GCP_PROJECT_ID'),
      ...(keyFilename ? { keyFilename } : {}),
    });
  }

  async upload(
    tenantId: string,
    file: Express.Multer.File | undefined,
  ): Promise<UploadResponseDto> {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    const detectedMime = this.validateFile(file);

    const filename = this.buildFilename(tenantId, detectedMime);
    const bucket = this.storage.bucket(this.bucketName);
    const storageFile = bucket.file(filename);

    try {
      await storageFile.save(file.buffer, {
        resumable: false,
        metadata: {
          contentType: detectedMime,
        },
      });

      const url = this.usePublicUrls
        ? await this.getPublicUrl(bucket, storageFile)
        : await this.getSignedUrl(storageFile);

      // TODO: audit log on upload
      return {
        url,
        filename,
        size: file.size,
        mimeType: detectedMime,
      };
    } catch {
      throw new InternalServerErrorException('Failed to upload file');
    }
  }

  async delete(tenantId: string, key: string | undefined): Promise<{ deleted: true }> {
    if (!key) {
      throw new BadRequestException('key query parameter is required');
    }

    if (!key.startsWith(`${tenantId}/`)) {
      throw new BadRequestException('Invalid file key');
    }

    const storageFile = this.storage.bucket(this.bucketName).file(key);

    try {
      await storageFile.delete({ ignoreNotFound: false });
      // TODO: audit log on delete operations
      return { deleted: true };
    } catch {
      throw new InternalServerErrorException('Failed to delete file');
    }
  }

  private validateFile(file: Express.Multer.File): string {
    if (file.size > MAX_FILE_SIZE_BYTES) {
      throw new BadRequestException('File exceeds 10MB limit');
    }

    // Detect MIME type from actual file content (magic bytes), not client header
    const detectedMime = detectMimeType(file.buffer);
    if (!detectedMime) {
      throw new BadRequestException('Unsupported file type');
    }

    return detectedMime;
  }

  private buildFilename(tenantId: string, detectedMime: string): string {
    const extension = this.extensionFromMime(detectedMime);
    return `${tenantId}/${uuidv4()}.${extension}`;
  }

  private extensionFromMime(mimeType: string): string {
    const map: Record<string, string> = {
      'image/jpeg': 'jpg',
      'image/png': 'png',
      'image/webp': 'webp',
      'application/pdf': 'pdf',
    };
    return map[mimeType] ?? 'bin';
  }

  private async getPublicUrl(
    bucket: ReturnType<Storage['bucket']>,
    storageFile: ReturnType<ReturnType<Storage['bucket']>['file']>,
  ): Promise<string> {
    await storageFile.makePublic();
    return `https://storage.googleapis.com/${bucket.name}/${storageFile.name}`;
  }

  private async getSignedUrl(
    storageFile: ReturnType<ReturnType<Storage['bucket']>['file']>,
  ): Promise<string> {
    const [signedUrl] = await storageFile.getSignedUrl({
      action: 'read',
      expires: Date.now() + 60 * 60 * 1000,
      version: 'v4',
    });

    return signedUrl;
  }
}
