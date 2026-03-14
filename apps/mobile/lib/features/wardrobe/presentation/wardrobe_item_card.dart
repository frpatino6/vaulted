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
    final title = item.name.split(' – ').first.trim();
    final brand = attrs.brand;
    final statusIcon = _statusIcon(attrs.cleaningStatus);
    final statusColor = _statusColor(attrs.cleaningStatus);

    return Material(
      color: const Color(0xFF1A1A1A),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 100,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.photos.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: item.photos.first,
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    const _WardrobePlaceholder(),
                                errorWidget: (_, _, _) =>
                                    const _WardrobePlaceholder(),
                              )
                            : const _WardrobePlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  letterSpacing: 0.3,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            (brand != null && brand.isNotEmpty) ? brand : ' ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFFC5A059),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: InkWell(
                  onTap: onStatusTap,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(statusIcon, size: 28, color: statusColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'clean':
        return Icons.check_rounded;
      case 'needs_cleaning':
        return Icons.water_drop_outlined;
      case 'at_dry_cleaner':
        return Icons.local_laundry_service_outlined;
      default:
        return Icons.add;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'clean':
        return const Color(0xFFC5A059);
      case 'needs_cleaning':
        return Colors.white.withValues(alpha: 0.65);
      case 'at_dry_cleaner':
        return Colors.blueGrey.shade200;
      default:
        return AppColors.onBackground.withValues(alpha: 0.65);
    }
  }
}

class _WardrobePlaceholder extends StatelessWidget {
  const _WardrobePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF232323),
      child: Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: Colors.white.withValues(alpha: 0.2),
          size: 34,
        ),
      ),
    );
  }
}
