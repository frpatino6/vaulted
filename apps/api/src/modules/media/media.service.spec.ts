jest.mock('uuid', () => ({
  v4: jest.fn(() => 'test-uuid'),
}));

jest.mock('node:fs', () => {
  const actual = jest.requireActual<typeof import('node:fs')>('node:fs');
  const { Readable } = require('stream');
  return {
    ...actual,
    createReadStream: jest.fn(() => Readable.from([Buffer.from('x')])),
  };
});

jest.mock('node:fs/promises', () => {
  const actual =
    jest.requireActual<typeof import('node:fs/promises')>('node:fs/promises');
  return {
    ...actual,
    stat: jest.fn(),
    mkdir: jest.fn().mockResolvedValue(undefined),
    writeFile: jest.fn().mockResolvedValue(undefined),
    unlink: jest.fn().mockResolvedValue(undefined),
  };
});

jest.mock('node:stream/promises', () => ({
  pipeline: jest.fn(),
}));

jest.mock(
  'sharp',
  () =>
    jest.fn(() => ({
      rotate: jest.fn().mockReturnThis(),
      resize: jest.fn().mockReturnThis(),
      jpeg: jest.fn().mockReturnThis(),
      toBuffer: jest.fn().mockResolvedValue(Buffer.from([0xff, 0xd8, 0xff])),
    })),
  { virtual: true },
);

import {
  ForbiddenException,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as fsPromises from 'node:fs/promises';
import * as streamPromises from 'node:stream/promises';
import type { Response } from 'express';
import { MediaService } from './media.service';

describe('MediaService', () => {
  let service: MediaService;
  let jwtService: { sign: jest.Mock; verify: jest.Mock; decode: jest.Mock };

  const mockStat = fsPromises.stat as jest.MockedFunction<
    typeof fsPromises.stat
  >;
  const mockPipeline = streamPromises.pipeline as jest.MockedFunction<
    typeof streamPromises.pipeline
  >;

  const configService = {
    get: jest.fn((key: string) => {
      if (key === 'APP_URL') return 'http://localhost:3000/';
      if (key === 'MEDIA_JWT_PREVIOUS_SECRET') return undefined;
      return undefined;
    }),
    getOrThrow: jest.fn((key: string) => {
      if (key === 'MEDIA_JWT_SECRET') return 'media-secret';
      throw new Error(`Missing ${key}`);
    }),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockStat.mockResolvedValue({} as import('node:fs').Stats);
    mockPipeline.mockResolvedValue(undefined);

    jwtService = {
      sign: jest.fn().mockReturnValue('signed-token'),
      verify: jest.fn(),
      decode: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MediaService,
        { provide: ConfigService, useValue: configService },
        { provide: JwtService, useValue: jwtService },
      ],
    }).compile();

    service = module.get<MediaService>(MediaService);
  });

  it('generateFileToken() signs normalized object key with tenant and user', () => {
    const token = service.generateFileToken(
      'http://localhost:3000/uploads/tenant-1/file.jpg',
      'tenant-1',
      'user-9',
    );

    expect(token).toBe('signed-token');
    expect(jwtService.sign).toHaveBeenCalledWith(
      {
        typ: 'media',
        fileKey: 'tenant-1/file.jpg',
        tenantId: 'tenant-1',
        userId: 'user-9',
        iat: expect.any(Number),
        exp: expect.any(Number),
      },
      { noTimestamp: true, secret: 'media-secret' },
    );
  });

  it('serveFile() throws UnauthorizedException when token verification fails', async () => {
    jwtService.verify.mockImplementation(() => {
      throw new Error('invalid');
    });
    const res = {
      setHeader: jest.fn(),
      redirect: jest.fn(),
    } as unknown as Response;

    await expect(service.serveFile('bad', res)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(mockStat).not.toHaveBeenCalled();
  });

  it('serveFile() throws ForbiddenException when file key is outside tenant prefix', async () => {
    jwtService.verify.mockReturnValue({
      typ: 'media',
      fileKey: 'other-tenant/file.jpg',
      tenantId: 'tenant-1',
      userId: 'user-1',
    });
    const res = {} as Response;

    await expect(service.serveFile('tok', res)).rejects.toBeInstanceOf(
      ForbiddenException,
    );
  });

  it('serveFile() rejects path traversal inside the tenant prefix', async () => {
    jwtService.verify.mockReturnValue({
      typ: 'media',
      fileKey: 'tenant-1/../../.env',
      tenantId: 'tenant-1',
      userId: 'user-1',
    });
    const res = {} as Response;

    await expect(service.serveFile('tok', res)).rejects.toThrow(
      'Invalid file key',
    );
  });

  it('serveFile() streams local file when storage bucket is not configured', async () => {
    jwtService.verify.mockReturnValue({
      typ: 'media',
      fileKey: 'tenant-1/photo.png',
      tenantId: 'tenant-1',
      userId: 'user-1',
    });
    const res = {
      setHeader: jest.fn(),
    } as unknown as Response;

    await service.serveFile('tok', res);

    expect(res.setHeader).toHaveBeenCalledWith('Content-Type', 'image/png');
    expect(mockStat).toHaveBeenCalled();
    expect(mockPipeline).toHaveBeenCalled();
  });

  it('serveFile() throws NotFoundException when local file is missing', async () => {
    mockStat.mockRejectedValueOnce(new Error('ENOENT'));
    jwtService.verify.mockReturnValue({
      typ: 'media',
      fileKey: 'tenant-1/missing.jpg',
      tenantId: 'tenant-1',
      userId: 'user-1',
    });
    const res = { setHeader: jest.fn() } as unknown as Response;

    await expect(service.serveFile('tok', res)).rejects.toBeInstanceOf(
      NotFoundException,
    );
  });

  it('upload() throws BadRequestException when file is missing', async () => {
    await expect(
      service.upload('tenant-1', 'user-1', undefined),
    ).rejects.toThrow();
  });

  it('upload() throws BadRequestException when file exceeds 10MB', async () => {
    const largeFile = {
      size: 15 * 1024 * 1024,
      buffer: Buffer.alloc(15 * 1024 * 1024),
    } as Express.Multer.File;

    await expect(
      service.upload('tenant-1', 'user-1', largeFile),
    ).rejects.toThrow('exceeds 10MB');
  });

  it('upload() throws BadRequestException for unsupported file type', async () => {
    const invalidFile = {
      size: 1024,
      buffer: Buffer.from([0x00, 0x01, 0x02]),
    } as Express.Multer.File;

    await expect(
      service.upload('tenant-1', 'user-1', invalidFile),
    ).rejects.toThrow('Unsupported file type');
  });

  it('upload() saves file locally and returns URL', async () => {
    const validFile = {
      size: 1024,
      buffer: Buffer.from([0x25, 0x50, 0x44, 0x46]), // PDF magic bytes
    } as Express.Multer.File;

    const result = await service.upload('tenant-1', 'user-1', validFile);

    expect(result.filename).toContain('tenant-1/');
    expect(result.url).toContain(
      'http://localhost:3000/api/media/signed-token',
    );
    expect(result.mimeType).toBe('application/pdf');
  });

  it('delete() throws BadRequestException when key is missing', async () => {
    await expect(service.delete('tenant-1', undefined)).rejects.toThrow(
      'key query parameter',
    );
  });

  it('delete() throws BadRequestException when key does not belong to tenant', async () => {
    await expect(
      service.delete('tenant-1', 'other-tenant/file.jpg'),
    ).rejects.toThrow('Invalid file key');
  });

  it('serveFile() rejects non-media JWT claims', async () => {
    jwtService.verify.mockReturnValue({
      typ: 'access',
      sub: 'user-1',
      tenantId: 'tenant-1',
      role: 'owner',
      mfaVerified: true,
    });
    const res = {} as Response;

    await expect(service.serveFile('tok', res)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('serveFile() accepts tokens signed with previous media secret during rotation', async () => {
    configService.get.mockImplementation((key: string) => {
      if (key === 'APP_URL') return 'http://localhost:3000/';
      if (key === 'MEDIA_JWT_PREVIOUS_SECRET') return 'old-media-secret';
      return undefined;
    });
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MediaService,
        { provide: ConfigService, useValue: configService },
        { provide: JwtService, useValue: jwtService },
      ],
    }).compile();
    const serviceWithPrevious = module.get<MediaService>(MediaService);

    jwtService.verify
      .mockImplementationOnce(() => {
        throw new Error('new secret failed');
      })
      .mockReturnValueOnce({
        typ: 'media',
        fileKey: 'tenant-1/photo.png',
        tenantId: 'tenant-1',
        userId: 'user-1',
      });
    const res = {
      setHeader: jest.fn(),
    } as unknown as Response;

    await serviceWithPrevious.serveFile('old-token', res);

    expect(jwtService.verify).toHaveBeenNthCalledWith(1, 'old-token', {
      secret: 'media-secret',
    });
    expect(jwtService.verify).toHaveBeenNthCalledWith(2, 'old-token', {
      secret: 'old-media-secret',
    });
  });
});
