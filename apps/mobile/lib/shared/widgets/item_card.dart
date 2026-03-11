import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../features/inventory/data/models/item_model.dart';
import 'status_badge.dart';

/// Category icon mapping for inventory items.
class ItemCategoryIcons {
  ItemCategoryIcons._();

  static IconData forCategory(String category) {
    switch (category.toLowerCase()) {
      case 'furniture':
        return Icons.chair_outlined;
      case 'art':
        return Icons.palette_outlined;
      case 'technology':
        return Icons.devices_outlined;
      case 'wardrobe':
        return Icons.checkroom_outlined;
      case 'vehicles':
        return Icons.directions_car_outlined;
      case 'wine':
        return Icons.wine_bar_outlined;
      case 'sports':
        return Icons.sports_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}

/// Premium item card: dark surface, category icon, name, subcategory, status badge, value.
class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item});

  final ItemModel item;

  static final _currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceVariant.withValues(alpha: 0.6)
        : AppColors.surfaceVariant.withValues(alpha: 0.4);

    final valueText = item.valuation != null && item.valuation!.currentValue > 0
        ? _currencyFormat.format(item.valuation!.currentValue)
        : '—';

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/items/${item.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1E1E28).withValues(alpha: 0.8),
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Icon(
                ItemCategoryIcons.forCategory(item.category),
                size: 28,
                color: AppColors.accentBright,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.onBackground,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.subcategory.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.subcategory,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    StatusBadge(status: item.status),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                valueText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
