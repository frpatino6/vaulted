import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as crypto from 'crypto';

const ALGORITHM = 'aes-256-gcm';
const IV_LENGTH = 12;

// Old format: iv:authTag:ciphertext  (no version — legacy)
// New format: v{version}:iv:authTag:ciphertext
const OLD_CIPHERTEXT_RE = /^[0-9a-f]+:[0-9a-f]+:[0-9a-f]+$/i;
const NEW_CIPHERTEXT_RE = /^v\d+:[0-9a-f]+:[0-9a-f]+:[0-9a-f]+$/i;

interface KeyEntry {
  version: number;
  key: Buffer;
}

@Injectable()
export class CryptoService {
  private readonly logger = new Logger(CryptoService.name);
  private readonly keys: KeyEntry[];
  private readonly salt: string;

  constructor(config: ConfigService) {
    this.salt = config.getOrThrow<string>('ENCRYPTION_SALT');
    if (this.salt.length < 32) {
      throw new Error('ENCRYPTION_SALT must be at least 32 characters');
    }

    const currentSecret = config.getOrThrow<string>('ENCRYPTION_KEY');
    this.keys = [{ version: 1, key: this.deriveMasterKey(currentSecret) }];

    const prevRaw = config.get<string>('ENCRYPTION_KEY_PREVIOUS');
    if (prevRaw) {
      const prevSecrets = prevRaw.split(',').map(k => k.trim()).filter(Boolean);
      for (let i = 0; i < prevSecrets.length; i++) {
        this.keys.push({ version: -(i + 1), key: this.deriveMasterKey(prevSecrets[i]) });
      }
    }
  }

  private deriveMasterKey(secret: string): Buffer {
    return crypto.scryptSync(secret, this.salt, 32);
  }

  private getKeyForVersion(version: number): Buffer | null {
    if (version === 0) {
      // Legacy version 0 — uses current key (backwards compat)
      const current = this.keys.find(k => k.version === 1);
      return current ? current.key : null;
    }
    const entry = this.keys.find(k => k.version === version);
    return entry ? entry.key : null;
  }

  private getCurrentKey(): Buffer {
    return this.keys.find(k => k.version === 1)!.key;
  }

  private getCurrentVersion(): number {
    return 1;
  }

  // ── Tenant-scoped FLE helpers ─────────────────────────────────────────────

  /**
   * Derives a 256-bit AES key unique to one entity (tenant, user, etc.) via HKDF-SHA-256.
   * Pass tenantId for tenant-scoped fields (insurance policies, item valuations).
   * Pass userId for user-scoped fields (MFA secrets).
   */
  deriveKey(entityId: string): Buffer {
    return Buffer.from(
      crypto.hkdfSync(
        'sha256',
        this.getCurrentKey(),
        Buffer.alloc(0),
        Buffer.from(`vaulted-fle:${entityId}`, 'utf8'),
        32,
      ),
    );
  }

  private deriveKeyWithVersion(entityId: string, masterKey: Buffer): Buffer {
    return Buffer.from(
      crypto.hkdfSync(
        'sha256',
        masterKey,
        Buffer.alloc(0),
        Buffer.from(`vaulted-fle:${entityId}`, 'utf8'),
        32,
      ),
    );
  }

  /** Encrypts a field value using a per-entity derived key. Format: v{version}:iv:authTag:ciphertext */
  encryptField(value: string, entityId: string): string {
    const masterKey = this.getCurrentKey();
    const key = this.deriveKeyWithVersion(entityId, masterKey);
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, key, iv) as crypto.CipherGCM;
    const encrypted = Buffer.concat([cipher.update(value, 'utf8'), cipher.final()]);
    const authTag = cipher.getAuthTag();
    return `v${this.getCurrentVersion()}:${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
  }

  /** Decrypts a field value previously encrypted with encryptField. entityId must match the value used during encryption. */
  decryptField(ciphertext: string, entityId: string): string {
    // Try new format first (v{version}:iv:authTag:ciphertext)
    const newMatch = ciphertext.match(/^v(\d+):([0-9a-f]+):([0-9a-f]+):([0-9a-f]+)$/i);
    if (newMatch) {
      const version = parseInt(newMatch[1], 10);
      const masterKey = this.getKeyForVersion(version);
      if (!masterKey) {
        throw new Error(`No key available for version ${version}`);
      }
      const key = this.deriveKeyWithVersion(entityId, masterKey);
      const iv = Buffer.from(newMatch[2], 'hex');
      const authTag = Buffer.from(newMatch[3], 'hex');
      const encrypted = Buffer.from(newMatch[4], 'hex');
      const decipher = crypto.createDecipheriv(ALGORITHM, key, iv) as crypto.DecipherGCM;
      decipher.setAuthTag(authTag);
      return decipher.update(encrypted).toString('utf8') + decipher.final('utf8');
    }

    // Backward compat: old format (iv:authTag:ciphertext) — try all keys
    const parts = ciphertext.split(':');
    if (parts.length === 3) {
      const [ivHex, authTagHex, encryptedHex] = parts;
      const errors: string[] = [];
      for (const entry of this.keys) {
        try {
          const key = this.deriveKeyWithVersion(entityId, entry.key);
          const iv = Buffer.from(ivHex, 'hex');
          const authTag = Buffer.from(authTagHex, 'hex');
          const encrypted = Buffer.from(encryptedHex, 'hex');
          const decipher = crypto.createDecipheriv(ALGORITHM, key, iv) as crypto.DecipherGCM;
          decipher.setAuthTag(authTag);
          return decipher.update(encrypted).toString('utf8') + decipher.final('utf8');
        } catch {
          errors.push(`version ${entry.version} failed`);
        }
      }
      throw new Error(`Decryption failed with all keys: ${errors.join(', ')}`);
    }

    throw new Error('Invalid ciphertext format');
  }

  /** Returns true when a stored value is an FLE ciphertext (vs. legacy plaintext). */
  isEncryptedField(value: unknown): boolean {
    return typeof value === 'string' && (OLD_CIPHERTEXT_RE.test(value) || NEW_CIPHERTEXT_RE.test(value));
  }

  // ── Global (non-tenant) helpers — used for non-financial fields ───────────

  encrypt(plaintext: string): string {
    const key = this.getCurrentKey();
    const iv = crypto.randomBytes(IV_LENGTH);
    const cipher = crypto.createCipheriv(ALGORITHM, key, iv) as crypto.CipherGCM;
    const encrypted = Buffer.concat([cipher.update(plaintext, 'utf8'), cipher.final()]);
    const authTag = cipher.getAuthTag();
    return `v${this.getCurrentVersion()}:${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted.toString('hex')}`;
  }

  decrypt(ciphertext: string): string {
    // Try new format first
    const newMatch = ciphertext.match(/^v(\d+):([0-9a-f]+):([0-9a-f]+):([0-9a-f]+)$/i);
    if (newMatch) {
      const version = parseInt(newMatch[1], 10);
      const key = this.getKeyForVersion(version);
      if (!key) {
        throw new Error(`No key available for version ${version}`);
      }
      const iv = Buffer.from(newMatch[2], 'hex');
      const authTag = Buffer.from(newMatch[3], 'hex');
      const encrypted = Buffer.from(newMatch[4], 'hex');
      const decipher = crypto.createDecipheriv(ALGORITHM, key, iv) as crypto.DecipherGCM;
      decipher.setAuthTag(authTag);
      return decipher.update(encrypted).toString('utf8') + decipher.final('utf8');
    }

    // Backward compat: old format
    const parts = ciphertext.split(':');
    if (parts.length === 3) {
      const [ivHex, authTagHex, encryptedHex] = parts;
      const errors: string[] = [];
      for (const entry of this.keys) {
        try {
          const key = entry.key;
          const iv = Buffer.from(ivHex, 'hex');
          const authTag = Buffer.from(authTagHex, 'hex');
          const encrypted = Buffer.from(encryptedHex, 'hex');
          const decipher = crypto.createDecipheriv(ALGORITHM, key, iv) as crypto.DecipherGCM;
          decipher.setAuthTag(authTag);
          return decipher.update(encrypted).toString('utf8') + decipher.final('utf8');
        } catch {
          errors.push(`version ${entry.version} failed`);
        }
      }
      throw new Error(`Decryption failed with all keys: ${errors.join(', ')}`);
    }

    throw new Error('Invalid ciphertext format');
  }
}
