/**
 * Returns an approximate value range string for a monetary amount.
 * Used in audit logs to avoid recording exact financial figures.
 */
export function toValueRange(amount: number): string {
  if (amount <= 0)          return '$0';
  if (amount < 1_000)       return 'under $1K';
  if (amount < 10_000)      return '$1K-$10K';
  if (amount < 50_000)      return '$10K-$50K';
  if (amount < 100_000)     return '$50K-$100K';
  if (amount < 250_000)     return '$100K-$250K';
  if (amount < 500_000)     return '$250K-$500K';
  if (amount < 1_000_000)   return '$500K-$1M';
  return 'over $1M';
}
