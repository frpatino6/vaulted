import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../features/properties/data/models/property_model.dart';

/// Premium property card: dark card, gold type badge, no elevation.
class PropertyCard extends StatelessWidget {
  const PropertyCard({super.key, required this.property});

  final PropertyModel property;

  int get _totalRooms =>
      property.floors.fold(0, (sum, f) => sum + f.rooms.length);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push('/properties/${property.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1E1E28)),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _typeLabel(property.type),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                property.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${property.address.city}, ${property.address.state}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.layers_outlined, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${property.floors.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.door_front_door_outlined, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '$_totalRooms',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'primary' => 'PRIMARY',
      'vacation' => 'VACATION',
      _ => 'RENTAL',
    };
  }
}
