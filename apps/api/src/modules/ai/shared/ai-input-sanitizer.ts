import { Logger } from '@nestjs/common';

export interface SanitizedInput {
  safe: string;
  suspicious: boolean;
}

const INJECTION_PATTERNS: RegExp[] = [
  /\bignore\s+(all\s+)?(previous|prior|above|earlier)\s+(instructions?|rules?|prompts?|context)\b/i,
  /\bforget\s+(everything|all|the\s+(above|previous|system))\b/i,
  /\byou\s+are\s+now\b/i,
  /\bact\s+as\b/i,
  /\bsystem\s*:\s*/i,
  /\bDAN\b/i,
  /\bdo\s+anything\s+now\b/i,
  /\boutput\s+(the\s+)?system\s+(prompt|instructions?)\b/i,
  /\breveal\s+(your\s+)?(prompt|instructions?|system)\b/i,
  /\byour\s+system\s+(prompt|instructions?)\b/i,
  /\bnew\s+instructions?\b/i,
  /\boverride\b/i,
  /\bdisregard\b/i,
  /\bfrom\s+now\s+on\b/i,
  /\byou\s+must\b/i,
];

export function sanitizeInput(input: string): SanitizedInput {
  const suspicious = INJECTION_PATTERNS.some((p) => p.test(input));
  let safe = input;
  for (const pattern of INJECTION_PATTERNS) {
    safe = safe.replace(pattern, '[removed]');
  }
  safe = safe
    .replace(/<[^>]*>/g, '')
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '')
    .trim();
  return { safe, suspicious };
}

export function logSuspiciousInput(
  logger: Logger,
  userId: string,
  source: string,
  safeInput: string,
): void {
  logger.warn(`Suspicious ${source} from user ${userId}: ${safeInput.slice(0, 100)}`);
}
