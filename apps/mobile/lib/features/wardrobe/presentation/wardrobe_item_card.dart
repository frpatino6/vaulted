import 'dart:ui';

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
      color: const Color(0xFF151515),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.photos.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.photos.first,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const _WardrobePlaceholder(),
                            errorWidget: (_, _, _) =>
                                const _WardrobePlaceholder(),
                          )
                        : const _WardrobePlaceholder(),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onStatusTap,
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                            child: Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              color: Colors.black.withValues(alpha: 0.50),
                              child: Icon(
                                statusIcon,
                                size: 15,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 0.3,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      (brand != null && brand.isNotEmpty) ? brand : ' ',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFFC5A059),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
        return Colors.white.withValues(alpha: 0.90);
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
    return const ColoredBox(
      color: Color(0xFF1E1E1E),
      child: Center(
        child: Icon(
          Icons.checkroom_outlined,
          color: Color(0xFF4A4A4A),
          size: 36,
        ),
      ),
    );
  }
}
