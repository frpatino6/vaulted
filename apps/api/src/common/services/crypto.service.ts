import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;

// Matches the "iv:authTag:ciphertext" format produced by encrypt/encryptField
const CIPHERTEXT_RE = /^[0-9a-f]+:[0-9a-f]+:[0-9a-f]+$/i;

@Injectable()
export class CryptoService {
  private readonly key: Buffer;

  constructor(config: ConfigService) {
    const secret = config.getOrThrow<string>('ENCRYPTION_KEY');
    this.key = crypto.scryptSync(secret, 'vaulted-salt', 32);
  }

  // ── Tenant-scoped FLE helpers ─────────────────────────────────────────────

  /**
   * Derives a 256-bit AES key unique to one tenant via HKDF-SHA-256.
   * Ensures a DB dump from tenant A cannot be decrypted with tenant B's key.
   */
  deriveKey(tenantId: string): Buffer {
    return Buffer.from(
      crypto.hkdfSync(
        'sha256',
        this.key,
        Buffer.alloc(0),
        Buffer.from(`vaulted-fle:${tenantId}`, 'utf8'),
        32,
      ),
    );
  }

  /** Encrypts a field value using a per-tenant derived key. Format: iv:authTag:ciphertext */
  encryptField(value: string, tenantId: string): string {
    const key = this.deriveKey(tenantId);
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, key, iv) as crypto.CipherGCM;
    const encrypted = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
    const authTag = cipher.getAuthTag();
    return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
  }

  /** Decrypts a field value previously encrypted with encryptField. */
  decryptField(ciphertext: string, tenantId: string): string {
    const [ivHex, authTagHex, encryptedHex] = ciphertext.split(':');
    if (!ivHex || !authTagHex || !encryptedHex) {
      throw new Error('Invalid ciphertext format');
    }
    const key = this.deriveKey(tenantId);
    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');
    const encrypted = Buffer.from(encryptedHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, key, iv) as crypto.DecipherGCM;
    decipher.setAuthTag(authTag);
    return decipher.update(encrypted).toString('utf8') + decipher.final('utf8');
  }

  /** Returns true when a stored value is an FLE ciphertext (vs. legacy plaintext). */
  isEncryptedField(value: unknown): boolean {
    return typeof value === 'string' && CIPHERTEXT_RE.test(value);
  }

  // ── Global (non-tenant) helpers — used for non-financial fields ───────────

  encrypt(plaintext: string): string {
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, this.key, iv) as crypto.CipherGCM;
    const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
    const authTag = cipher.getAuthTag();
    return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
  }

  decrypt(ciphertext: string): string {
    const [ivHex, authTagHex, encryptedHex] = ciphertext.split(':');
    if (!ivHex || !authTagHex || !encryptedHex) {
      throw new Error('Invalid ciphertext format');
    }
    const iv = Buffer.from(ivHex, 'hex');
    const authTag = Buffer.from(authTagHex, 'hex');
    const encrypted = Buffer.from(encryptedHex, 'hex');
    const decipher = crypto.createDecipheriv(ALGORITHM, this.key, iv) as crypto.DecipherGCM;
    decipher.setAuthTag(authTag);
    return decipher.update(encrypted).toString('utf8') + decipher.final('utf8');
  }
}
