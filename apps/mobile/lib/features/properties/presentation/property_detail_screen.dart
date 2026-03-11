import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/address_model.dart';
import '../data/models/floor_model.dart';
import '../data/models/property_model.dart';
import '../domain/property_detail_notifier.dart';
import 'add_floor_sheet.dart';
import 'add_room_sheet.dart';

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(propertyDetailNotifierProvider.notifier)
          .load(widget.propertyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(propertyDetailNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.when(
        data: (property) {
          if (property == null) {
            return _NotFoundView();
          }
          return _PropertyDetailBody(
            property: property,
            onRefresh: () => ref
                .read(propertyDetailNotifierProvider.notifier)
                .load(widget.propertyId),
            onAddFloor: () => _showAddFloor(context),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorView(
          message: PropertyDetailNotifier.message(err),
          onRetry: () => ref
              .read(propertyDetailNotifierProvider.notifier)
              .load(widget.propertyId),
        ),
      ),
      floatingActionButton: state.value != null
          ? FloatingActionButton.extended(
              onPressed: () => _showAddFloor(context),
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.background,
              icon: const Icon(Icons.add),
              label: const Text('Add Floor'),
            )
          : null,
    );
  }

  void _showAddFloor(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddFloorSheet(
        propertyId: widget.propertyId,
        onAdded: () => ref
            .read(propertyDetailNotifierProvider.notifier)
            .load(widget.propertyId),
      ),
    );
  }
}

class _PropertyDetailBody extends StatelessWidget {
  const _PropertyDetailBody({
    required this.property,
    required this.onRefresh,
    required this.onAddFloor,
  });

  final PropertyModel property;
  final VoidCallback onRefresh;
  final VoidCallback onAddFloor;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.background,
          title: Text(
            property.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.onBackground,
                ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _typeLabel(property.type),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _formatAddress(property.address),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'FLOORS & ROOMS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 2,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        if (property.floors.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 48,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No floors added yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _FloorTile(
                    floor: property.floors[index],
                    propertyId: property.id,
                    onAddRoom: () => _showAddRoom(context, property.floors[index]),
                    onRefresh: onRefresh,
                  ),
                ),
                childCount: property.floors.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
      ],
    );
  }

  String _typeLabel(String type) {
    return switch (type) {
      'primary' => 'PRIMARY',
      'vacation' => 'VACATION',
      _ => 'RENTAL',
    };
  }

  String _formatAddress(AddressModel a) {
    return '${a.street}, ${a.city}, ${a.state} ${a.zip}, ${a.country}';
  }

  void _showAddRoom(BuildContext context, FloorModel floor) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddRoomSheet(
        propertyId: property.id,
        floorId: floor.floorId,
        floorName: floor.name,
        onAdded: onRefresh,
      ),
    );
  }
}

class _FloorTile extends StatelessWidget {
  const _FloorTile({
    required this.floor,
    required this.propertyId,
    required this.onAddRoom,
    required this.onRefresh,
  });

  final FloorModel floor;
  final String propertyId;
  final VoidCallback onAddRoom;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppColors.accent, width: 3),
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.layers_outlined, size: 20, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Text(
              floor.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.onBackground,
                  ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            '${floor.rooms.length} room(s)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add),
          onPressed: onAddRoom,
          tooltip: 'Add room',
        ),
        children: [
          if (floor.rooms.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Text(
                'No rooms. Tap + to add one.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
            )
          else
            ...floor.rooms.map(
              (room) => Padding(
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.door_front_door_outlined,
                    size: 20,
                    color: AppColors.onSurfaceVariant,
                  ),
                  title: Text(
                    room.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.onBackground,
                        ),
                  ),
                  subtitle: Text(
                    room.type,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                  ),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${room.name} — detail in Phase 3')),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Property not found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.onBackground,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onBackground,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
