import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/inventory/data/models/item_model.dart';
import 'item_card.dart';
import 'status_badge.dart';
import 'valuation_text.dart';

/// Catalog-style asset card for room inventory: image, name, brand/category, price tag, refined status.
/// Height 100; supports slidable parent for Edit/Delete.
/// [roomNameToStrip] when set, removes " – $roomNameToStrip" from the displayed item name.
/// [nameMaxLines] allows more text before ellipsis (e.g. 2 for search results).
/// [valueFontWeight] controls price emphasis (e.g. FontWeight.bold for search).
class RoomInventoryAssetCard extends ConsumerWidget {
  const RoomInventoryAssetCard({
    super.key,
    required this.item,
    this.roomNameToStrip,
    this.canSeeValues = true,
    this.nameMaxLines = 1,
    this.valueFontWeight = FontWeight.w500,
    this.showLocation = false,
  });

  final ItemModel item;
  final String? roomNameToStrip;
  final bool canSeeValues;
  final int nameMaxLines;
  final FontWeight valueFontWeight;
  final bool showLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? AppColors.surfaceVariant.withValues(alpha: 0.6)
        : AppColors.surfaceVariant.withValues(alpha: 0.4);
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
          constraints: BoxConstraints(minHeight: nameMaxLines > 1 ? 120 : 100),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                            maxLines: nameMaxLines,
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
                          if (showLocation && _locationText.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              _locationText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.accentLight.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    letterSpacing: 0.3,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          StatusBadge(status: item.status, compact: true),
                        ],
                      ),
                    ),
                    if (canSeeValues) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 92,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: ValuationText(
                            value: item.valuation?.currentValue,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: valueColor,
                                  fontWeight: valueFontWeight,
                                ),
                          ),
                        ),
                      ),
                    ],
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

  String get _locationText {
    final parts = <String>[];
    if (item.roomName?.isNotEmpty == true) parts.add(item.roomName!);
    if (item.locationDetail?.isNotEmpty == true) parts.add(item.locationDetail!);
    return parts.join(' → ');
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
