import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../features/inventory/data/models/item_model.dart';
import 'item_card.dart';
import 'status_badge.dart';

/// Catalog-style asset card for room inventory: image, name, brand/category, price tag, refined status.
/// Height 100; supports slidable parent for Edit/Delete.
/// [roomNameToStrip] when set, removes " – $roomNameToStrip" from the displayed item name.
class RoomInventoryAssetCard extends StatelessWidget {
  const RoomInventoryAssetCard({
    super.key,
    required this.item,
    this.roomNameToStrip,
  });

  final ItemModel item;
  final String? roomNameToStrip;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_US',
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceVariant.withValues(alpha: 0.6)
        : AppColors.surfaceVariant.withValues(alpha: 0.4);
    final valueText = item.valuation != null && item.valuation!.currentValue > 0
        ? _currencyFormat.format(item.valuation!.currentValue)
        : '—';
    final hasValue = item.valuation != null && item.valuation!.currentValue > 0;
    final valueColor = hasValue
        ? AppColors.catalogGold
        : AppColors.onBackground.withValues(alpha: 0.4);

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push('/items/${item.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF1E1E28).withValues(alpha: 0.8),
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: _buildThumbnail(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _displayName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onBackground,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _subtitleText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.onBackground.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  letterSpacing: 0.8,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          StatusBadge(status: item.status, compact: true),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: Text(
                        valueText,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: valueColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _displayName {
    if (roomNameToStrip != null && roomNameToStrip!.isNotEmpty) {
      return item.name.replaceAll(' – $roomNameToStrip', '').trim();
    }
    return item.name;
  }

  String get _subtitleText {
    final parts = <String>[];
    if (item.subcategory.isNotEmpty) parts.add(item.subcategory);
    parts.add(item.category);
    return parts.join(' · ');
  }

  Widget _buildThumbnail() {
    if (item.photos.isNotEmpty) {
      return Image.network(
        item.photos.first,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholderIcon(),
      );
    }
    return _placeholderIcon();
  }

  Widget _placeholderIcon() {
    return Container(
      color: Colors.black26,
      child: Icon(
        ItemCategoryIcons.forCategory(item.category),
        size: 32,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
