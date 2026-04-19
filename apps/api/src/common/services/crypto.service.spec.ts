import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { CryptoService } from './crypto.service';

describe('CryptoService', () => {
  let service: CryptoService;
  let configService: { getOrThrow: jest.Mock };

  beforeEach(async () => {
    configService = {
      getOrThrow: jest.fn().mockReturnValue('test-encryption-key-32-bytes-long!!'),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CryptoService,
        { provide: ConfigService, useValue: configService },
      ],
    }).compile();

    service = module.get<CryptoService>(CryptoService);
  });

  it('encryptField returns a non-empty string different from the input', () => {
    const ciphertext = service.encryptField('5000', 'tenant-1');

    expect(ciphertext).toBeDefined();
    expect(ciphertext.length).toBeGreaterThan(0);
    expect(ciphertext).not.toBe('5000');
  });

  it('decryptField(encryptField(value)) returns original value', () => {
    const original = '25000';
    const tenantId = 'tenant-1';

    const ciphertext = service.encryptField(original, tenantId);
    const decrypted = service.decryptField(ciphertext, tenantId);

    expect(decrypted).toBe(original);
  });

  it('Two calls to encryptField with the same value return different ciphertext', () => {
    const value = '10000';
    const tenantId = 'tenant-1';

    const ciphertext1 = service.encryptField(value, tenantId);
    const ciphertext2 = service.encryptField(value, tenantId);

    expect(ciphertext1).not.toBe(ciphertext2);
  });

  it('decryptField with invalid ciphertext throws', () => {
    const tenantId = 'tenant-1';

    expect(() => service.decryptField('invalid', tenantId)).toThrow();
  });

  it('encrypt then decrypt returns original value', () => {
    const original = '5000';
    const tenantId = 'tenant-1';

    const ciphertext = service.encryptField(original, tenantId);
    const decrypted = service.decryptField(ciphertext, tenantId);

    expect(decrypted).toBe(original);
  });
});