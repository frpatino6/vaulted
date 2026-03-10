import { SetMetadata } from '@nestjs/common';
import { SKIP_MFA_KEY } from '../guards/mfa-verified.guard';

// Use on endpoints that must be accessible before MFA is verified (mfa/setup, mfa/verify)
export const SkipMfa = () => SetMetadata(SKIP_MFA_KEY, true);
