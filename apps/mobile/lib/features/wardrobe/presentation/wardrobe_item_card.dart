import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../inventory/data/models/item_model.dart';

class WardrobeItemCard extends StatelessWidget {
  const WardrobeItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onStatusTap,
  });

  final ItemModel item;
  final VoidCallback onTap;
  final VoidCallback onStatusTap;

  @override
  Widget build(BuildContext context) {
    final attrs = item.wardrobeAttributes;
    final brand = attrs.brand;
    final statusColor = _statusColor(attrs.cleaningStatus);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (item.photos.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: item.photos.first,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _WardrobePlaceholder(),
                  errorWidget: (_, _, _) => const _WardrobePlaceholder(),
                )
              else
                const _WardrobePlaceholder(),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.45, 1],
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onStatusTap,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: statusColor != null
                          ? Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.add,
                              size: 12,
                              color: AppColors.onBackground.withValues(
                                alpha: 0.75,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: AppSpacing.sm,
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (brand != null && brand.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        brand,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w500,
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

  Color? _statusColor(String? status) {
    switch (status) {
      case 'clean':
        return Colors.green;
      case 'needs_cleaning':
        return Colors.amber;
      case 'at_dry_cleaner':
        return Colors.blue;
      default:
        return null;
    }
  }
}

class _WardrobePlaceholder extends StatelessWidget {
  const _WardrobePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A2A38), Color(0xFF14141C)],
        ),
      ),
      child: Icon(
        Icons.checkroom_outlined,
        color: Colors.white.withValues(alpha: 0.25),
        size: 52,
      ),
    );
  }
}
