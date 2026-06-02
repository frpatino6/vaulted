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
import { dirname, extname, join, resolve, sep } from 'node:path';
import { pipeline } from 'node:stream/promises';
import type { Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import sharp from 'sharp';
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
  private readonly uploadsRoot: string;
  private readonly appUrl: string;
  private readonly useLocalStorage: boolean;

  constructor(
    private readonly configService: ConfigService,
    private readonly jwtService: JwtService,
  ) {
    this.bucketName = this.configService.get<string>('GCP_STORAGE_BUCKET');
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
    const normalizedKey = this.normalizeTenantKey(fileUrl, tenantId);
    // Deterministic per 1-hour window: same file+user within the same hour always
    // produces the same JWT, so cached_network_image can reuse cached responses.
    const windowStart = Math.floor(Date.now() / (60 * 60 * 1000)) * 60 * 60;
    const exp = windowStart + 2 * 60 * 60; // valid for up to 2 hours
    return this.jwtService.sign(
      { fileKey: normalizedKey, tenantId, userId, iat: windowStart, exp },
      { noTimestamp: true },
    );
  }

  async serveFile(token: string, res: Response): Promise<void> {
    let payload: { fileKey: string; tenantId: string; userId: string };
    try {
      payload = this.jwtService.verify<{
        fileKey: string;
        tenantId: string;
        userId: string;
      }>(token);
    } catch {
      throw new UnauthorizedException('Invalid or expired media token');
    }

    const safeKey = this.assertSafeTenantKey(payload.fileKey, payload.tenantId);

    if (this.useLocalStorage) {
      const fullPath = this.resolveLocalPath(safeKey, payload.tenantId);
      const ext = extname(safeKey).toLowerCase();
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
      res.setHeader('Cache-Control', 'private, max-age=7200, immutable');

      try {
        await pipeline(createReadStream(fullPath), res);
      } catch (err: unknown) {
        // Client closed the connection before the stream finished — not an error
        if (
          (err as NodeJS.ErrnoException).code === 'ERR_STREAM_PREMATURE_CLOSE'
        )
          return;
        throw err;
      }
      return;
    }

    const storageFile = this.storage!.bucket(this.bucketName!).file(safeKey);
    const [signedUrl] = await storageFile.getSignedUrl({
      action: 'read',
      expires: Date.now() + 5 * 60 * 1000,
      version: 'v4',
    });
    res.redirect(302, signedUrl);
  }

  async upload(
    tenantId: string,
    userId: string,
    file: Express.Multer.File | undefined,
  ): Promise<UploadResponseDto> {
    if (!file) {
      throw new BadRequestException('File is required');
    }

    const detectedMime = this.validateFile(file);
    const { buffer: processedBuffer, mimeType: processedMime } =
      await this.processImage(file.buffer, detectedMime);
    const filename = this.buildFilename(tenantId, processedMime);

    if (this.useLocalStorage) {
      const processedFile = {
        ...file,
        buffer: processedBuffer,
        size: processedBuffer.length,
      };
      return this.saveLocally(
        tenantId,
        filename,
        userId,
        processedFile,
        processedMime,
      );
    }

    const bucket = this.storage!.bucket(this.bucketName!);
    const storageFile = bucket.file(filename);

    try {
      await storageFile.save(processedBuffer, {
        resumable: false,
        metadata: {
          contentType: processedMime,
        },
      });

      // TODO: audit log on upload
      return {
        url: this.buildSignedMediaUrl(filename, tenantId, userId),
        filename,
        size: processedBuffer.length,
        mimeType: processedMime,
      };
    } catch {
      throw new InternalServerErrorException('Failed to upload file');
    }
  }

  private async processImage(
    buffer: Buffer,
    mimeType: string,
  ): Promise<{ buffer: Buffer; mimeType: string }> {
    if (mimeType === 'application/pdf') {
      return { buffer, mimeType };
    }
    try {
      const processed = await sharp(buffer)
        .rotate()
        .resize({
          width: 2048,
          height: 2048,
          fit: 'inside',
          withoutEnlargement: true,
        })
        .jpeg({ quality: 85, mozjpeg: true })
        .toBuffer();
      return { buffer: processed, mimeType: 'image/jpeg' };
    } catch {
      throw new BadRequestException('Invalid or corrupted image file');
    }
  }

  async delete(
    tenantId: string,
    key: string | undefined,
  ): Promise<{ deleted: true }> {
    if (!key) {
      throw new BadRequestException('key query parameter is required');
    }

    const normalizedKey = this.normalizeTenantKey(key, tenantId);

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
    tenantId: string,
    filename: string,
    userId: string,
    file: Express.Multer.File,
    detectedMime: string,
  ): Promise<UploadResponseDto> {
    const fullPath = this.resolveLocalPath(filename, tenantId);
    await mkdir(dirname(fullPath), { recursive: true });

    try {
      await writeFile(fullPath, file.buffer);
      return {
        url: this.buildSignedMediaUrl(filename, tenantId, userId),
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
      const tenantId = key.split('/')[0];
      if (!tenantId) throw new BadRequestException('Invalid file key');
      await unlink(this.resolveLocalPath(key, tenantId));
      return { deleted: true };
    } catch {
      throw new InternalServerErrorException('Failed to delete file');
    }
  }

  private buildSignedMediaUrl(
    filename: string,
    tenantId: string,
    userId: string,
  ): string {
    return `${this.appUrl}/api/media/${this.generateFileToken(filename, tenantId, userId)}`;
  }

  private resolveLocalPath(key: string, tenantId: string): string {
    const safeKey = this.assertSafeTenantKey(key, tenantId);
    const uploadsRoot = resolve(this.uploadsRoot);
    const fullPath = resolve(uploadsRoot, safeKey);

    if (
      fullPath !== uploadsRoot &&
      !fullPath.startsWith(`${uploadsRoot}${sep}`)
    ) {
      throw new ForbiddenException('Invalid file path');
    }

    return fullPath;
  }

  private assertSafeTenantKey(key: string, tenantId: string): string {
    let decodedKey: string;
    try {
      decodedKey = decodeURIComponent(key);
    } catch {
      throw new BadRequestException('Invalid file key');
    }

    if (
      decodedKey.includes('\\') ||
      decodedKey.includes('\0') ||
      decodedKey.startsWith('/') ||
      decodedKey
        .split('/')
        .some(
          (segment) => segment === '' || segment === '.' || segment === '..',
        )
    ) {
      throw new BadRequestException('Invalid file key');
    }

    // Bare filename without any path separator (legacy data stored without tenant prefix)
    if (!decodedKey.startsWith(`${tenantId}/`) && !decodedKey.includes('/')) {
      decodedKey = `${tenantId}/${decodedKey}`;
    }

    if (!decodedKey.startsWith(`${tenantId}/`)) {
      throw new ForbiddenException('Invalid file key');
    }

    return decodedKey;
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

  normalizeTenantKey(key: string, tenantId: string): string {
    return this.assertSafeTenantKey(this.normalizeKey(key), tenantId);
  }

  normalizeKey(key: string): string {
    const uploadsMatch = key.match(/^https?:\/\/[^/]+\/uploads\/(.+)$/);
    if (uploadsMatch?.[1]) {
      return uploadsMatch[1];
    }

    const gcsPublicPrefix = this.bucketName
      ? `https://storage.googleapis.com/${this.bucketName}/`
      : null;
    if (gcsPublicPrefix && key.startsWith(gcsPublicPrefix)) {
      return key.slice(gcsPublicPrefix.length);
    }

    const mediaTokenMatch = key.match(/^https?:\/\/[^/]+\/api\/media\/(.+)$/);
    if (mediaTokenMatch?.[1]) {
      const token = mediaTokenMatch[1];
      const payload = this.jwtService.decode<{ fileKey: string }>(token);
      if (payload?.fileKey) return payload.fileKey;
    }

    // Relative /uploads/ path stored without http prefix (legacy data)
    const relativeUploadsMatch = key.match(/^\/uploads\/(.+)$/);
    if (relativeUploadsMatch?.[1]) {
      return relativeUploadsMatch[1];
    }

    return key;
  }
}
