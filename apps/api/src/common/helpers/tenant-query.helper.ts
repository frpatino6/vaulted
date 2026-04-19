import { InternalServerErrorException } from '@nestjs/common';

/**
 * Merges `tenantId` into a MongoDB filter object.
 * Throws InternalServerErrorException at runtime if `tenantId` is missing or empty.
 *
 * This is the ONLY approved way to build MongoDB queries in services.
 * It makes it impossible to accidentally query without tenant isolation.
 *
 * ─── BEFORE (unsafe) ────────────────────────────────────────────────────────
 *   // Developer forgets tenantId — returns data for ALL tenants:
 *   const items = await this.itemModel.find({ status: 'active' }).exec();
 *
 * ─── AFTER (safe) ────────────────────────────────────────────────────────────
 *   const items = await this.itemModel
 *     .find(withTenant(tenantId, { status: 'active' }))
 *     .exec();
 *   // → always executes: { tenantId: 'abc123', status: 'active' }
 *
 * ─── USAGE RULES ─────────────────────────────────────────────────────────────
 *   1. Services MUST receive tenantId as a parameter — never read JWT directly.
 *   2. Every MongoDB query MUST use withTenant() as the base filter.
 *   3. Controllers MUST source tenantId from @TenantId() decorator only.
 */
export function withTenant(
  tenantId: string,
  query: Record<string, unknown> = {},
): Record<string, unknown> {
  if (!tenantId) {
    throw new InternalServerErrorException(
      '[Security] tenantId is required for all database queries. ' +
        'Use @TenantId() in the controller and pass it to the service.',
    );
  }
  return { tenantId, ...query };
}
