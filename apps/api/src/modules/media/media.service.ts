import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { Storage } from '@google-cloud/storage';
import { createReadStream } from 'node:fs';
import { mkdir, stat, unlink, writeFile } from 'node:fs/promises';
import { dirname, extname, join } from 'node:path';
import { pipeline } from 'node:stream/promises';
import type { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { UploadResponseDto } from './dto/upload-response.dto';

const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;

// Magic byte signatures for each allowed MIME type.
// Validated against actual file buffer — not the client-supplied Content-Type header.
const MAGIC_SIGNATURES: Array<{
  mimeType: string;
  bytes: number[];
  offset?: number;
}> = [
  { mimeType: 'image/jpeg', bytes: [0xff, 0xd8, 0xff] },
  {
    mimeType: 'image/png',
    bytes: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a],
  },
  { mimeType: 'application/pdf', bytes: [0x25, 0x50, 0x44, 0x46] }, // %PDF
  // WebP: "RIFF" at offset 0, "WEBP" at offset 8
  { mimeType: 'image/webp', bytes: [0x52, 0x49, 0x46, 0x46], offset: 0 },
];

function detectMimeType(buffer: Buffer): string | null {
  for (const sig of MAGIC_SIGNATURES) {
    const offset = sig.offset ?? 0;
    const slice = buffer.slice(offset, offset + sig.bytes.length);
    if (
      slice.length === sig.bytes.length &&
      sig.bytes.every((b, i) => slice[i] === b)
    ) {
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
  private readonly storage?: Storage;
  private readonly bucketName?: string;
  private readonly usePublicUrls: boolean;
  private readonly uploadsRoot: string;
  private readonly appUrl: string;
  private readonly useLocalStorage: boolean;

  constructor(
    private readonly configService: ConfigService,
    private readonly jwtService: JwtService,
  ) {
    this.bucketName = this.configService.get<string>('GCP_STORAGE_BUCKET');
    this.usePublicUrls =
      this.configService.get<string>('GCP_STORAGE_PUBLIC') === 'true';
    this.appUrl = (
      this.configService.get<string>('APP_URL') ?? 'http://localhost:3000'
    ).replace(/\/+$/, '');
    this.uploadsRoot = join(process.cwd(), 'uploads');

    const keyFilename =
      this.configService.get<string>('GCP_KEY_FILE') ||
      process.env['GOOGLE_APPLICATION_CREDENTIALS'];
    const projectId = this.configService.get<string>('GCP_PROJECT_ID');

    this.useLocalStorage = !projectId || !this.bucketName;

    if (!this.useLocalStorage) {
      this.storage = new Storage({
        projectId,
        ...(keyFilename ? { keyFilename } : {}),
      });
    }
  }

  generateFileToken(fileUrl: string, tenantId: string, userId: string): string {
    const normalizedKey = this.normalizeKey(fileUrl);
    return this.jwtService.sign(
      { fileKey: normalizedKey, tenantId, userId },
      { expiresIn: '15m' },
    );
  }

  async serveFile(token: string, res: Response): Promise<void> {
    let payload: { fileKey: string; tenantId: string; userId: string };
    try {
      payload = this.jwtService.verify<{ fileKey: string; tenantId: string; userId: string }>(
        token,
      );
    } catch {
      throw new UnauthorizedException('Invalid or expired media token');
    }

    if (!payload.fileKey.startsWith(`${payload.tenantId}/`)) {
      throw new ForbiddenException();
    }

    if (this.useLocalStorage) {
      const fullPath = join(this.uploadsRoot, payload.fileKey);
      const ext = extname(payload.fileKey).toLowerCase();
      let mimeType = 'application/octet-stream';
      if (ext === '.jpg' || ext === '.jpeg') {
        mimeType = 'image/jpeg';
      } else if (ext === '.png') {
        mimeType = 'image/png';
      } else if (ext === '.webp') {
        mimeType = 'image/webp';
      } else if (ext === '.pdf') {
        mimeType = 'application/pdf';
      }

      try {
        await stat(fullPath);
      } catch {
        throw new NotFoundException();
      }

      res.setHeader('Content-Type', mimeType);
      res.setHeader('Cache-Control', 'private, no-store');

      await pipeline(createReadStream(fullPath), res);
      return;
    }

    const storageFile = this.storage!.bucket(this.bucketName!).file(payload.fileKey);
    const [signedUrl] = await storageFile.getSignedUrl({
      action: 'read',
      expires: Date.now() + 5 * 60 * 1000,
      version: 'v4',
    });
    res.redirect(302, signedUrl);
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

    if (this.useLocalStorage) {
      return this.saveLocally(filename, file, detectedMime);
    }

    const bucket = this.storage!.bucket(this.bucketName!);
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

  async delete(
    tenantId: string,
    key: string | undefined,
  ): Promise<{ deleted: true }> {
    if (!key) {
      throw new BadRequestException('key query parameter is required');
    }

    const normalizedKey = this.normalizeKey(key);
    if (!normalizedKey.startsWith(`${tenantId}/`)) {
      throw new BadRequestException('Invalid file key');
    }

    if (this.useLocalStorage) {
      return this.deleteLocally(normalizedKey);
    }

    const storageFile = this.storage!.bucket(this.bucketName!).file(
      normalizedKey,
    );

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

  private async saveLocally(
    filename: string,
    file: Express.Multer.File,
    detectedMime: string,
  ): Promise<UploadResponseDto> {
    const fullPath = join(this.uploadsRoot, filename);
    await mkdir(dirname(fullPath), { recursive: true });

    try {
      await writeFile(fullPath, file.buffer);
      return {
        url: `${this.appUrl}/uploads/${filename}`,
        filename,
        size: file.size,
        mimeType: detectedMime,
      };
    } catch {
      throw new InternalServerErrorException('Failed to upload file');
    }
  }

  private async deleteLocally(key: string): Promise<{ deleted: true }> {
    try {
      await unlink(join(this.uploadsRoot, key));
      return { deleted: true };
    } catch {
      throw new InternalServerErrorException('Failed to delete file');
    }
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

  private normalizeKey(key: string): string {
    const uploadsPrefix = `${this.appUrl}/uploads/`;
    if (key.startsWith(uploadsPrefix)) {
      return key.slice(uploadsPrefix.length);
    }

    const gcsPublicPrefix = this.bucketName
      ? `https://storage.googleapis.com/${this.bucketName}/`
      : null;
    if (gcsPublicPrefix && key.startsWith(gcsPublicPrefix)) {
      return key.slice(gcsPublicPrefix.length);
    }

    return key;
  }
}
