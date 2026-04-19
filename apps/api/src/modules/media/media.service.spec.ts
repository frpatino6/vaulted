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
  const actual = jest.requireActual<typeof import('node:fs/promises')>('node:fs/promises');
  return {
    ...actual,
    stat: jest.fn(),
  };
});

jest.mock('node:stream/promises', () => ({
  pipeline: jest.fn(),
}));

import { ForbiddenException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as fsPromises from 'node:fs/promises';
import * as streamPromises from 'node:stream/promises';
import type { Response } from 'express';
import { MediaService } from './media.service';

describe('MediaService', () => {
  let service: MediaService;
  let jwtService: { sign: jest.Mock; verify: jest.Mock };

  const mockStat = fsPromises.stat as jest.MockedFunction<typeof fsPromises.stat>;
  const mockPipeline = streamPromises.pipeline as jest.MockedFunction<typeof streamPromises.pipeline>;

  const configService = {
    get: jest.fn((key: string) => {
      if (key === 'APP_URL') return 'http://localhost:3000/';
      return undefined;
    }),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    mockStat.mockResolvedValue({} as import('node:fs').Stats);
    mockPipeline.mockResolvedValue(undefined);

    jwtService = {
      sign: jest.fn().mockReturnValue('signed-token'),
      verify: jest.fn(),
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
      { fileKey: 'tenant-1/file.jpg', tenantId: 'tenant-1', userId: 'user-9' },
      { expiresIn: '15m' },
    );
  });

  it('serveFile() throws UnauthorizedException when token verification fails', async () => {
    jwtService.verify.mockImplementation(() => {
      throw new Error('invalid');
    });
    const res = { setHeader: jest.fn(), redirect: jest.fn() } as unknown as Response;

    await expect(service.serveFile('bad', res)).rejects.toBeInstanceOf(UnauthorizedException);
    expect(mockStat).not.toHaveBeenCalled();
  });

  it('serveFile() throws ForbiddenException when file key is outside tenant prefix', async () => {
    jwtService.verify.mockReturnValue({
      fileKey: 'other-tenant/file.jpg',
      tenantId: 'tenant-1',
      userId: 'user-1',
    });
    const res = {} as Response;

    await expect(service.serveFile('tok', res)).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('serveFile() streams local file when storage bucket is not configured', async () => {
    jwtService.verify.mockReturnValue({
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
      fileKey: 'tenant-1/missing.jpg',
      tenantId: 'tenant-1',
      userId: 'user-1',
    });
    const res = { setHeader: jest.fn() } as unknown as Response;

    await expect(service.serveFile('tok', res)).rejects.toBeInstanceOf(NotFoundException);
  });
});
