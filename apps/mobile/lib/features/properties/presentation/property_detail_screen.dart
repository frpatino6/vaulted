import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../inventory/data/item_repository_provider.dart';
import '../../inventory/domain/item_list_notifier.dart';
import '../../inventory/presentation/add_item_sheet.dart';
import '../../inventory/presentation/assign_location_sheet.dart';
import '../../media/data/media_repository_provider.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/address_model.dart';
import '../data/models/floor_model.dart';
import '../data/models/room_model.dart';
import '../data/models/property_model.dart';
import '../domain/properties_notifier.dart';
import '../domain/property_detail_notifier.dart';
import 'add_floor_sheet.dart';
import 'add_room_sheet.dart';
import 'edit_room_sheet.dart';

// Speed dial state
enum _SpeedDialState { closed, open }

class PropertyDetailScreen extends ConsumerStatefulWidget {
  const PropertyDetailScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  ConsumerState<PropertyDetailScreen> createState() =>
      _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends ConsumerState<PropertyDetailScreen> {
  _SpeedDialState _dialState = _SpeedDialState.closed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(propertyDetailNotifierProvider.notifier).load(widget.propertyId);
    });
  }

  void _toggleDial() =>
      setState(() => _dialState = _dialState == _SpeedDialState.closed
          ? _SpeedDialState.open
          : _SpeedDialState.closed);

  void _closeDial() =>
      setState(() => _dialState = _SpeedDialState.closed);

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole() ?? 'guest';
    final canManageProperties = role == 'owner' || role == 'manager';
    final state = ref.watch(propertyDetailNotifierProvider);
    final isDialOpen = _dialState == _SpeedDialState.open;

    return Scaffold(
      backgroundColor: AppColors.background,
      // Speed dial backdrop — tap to close
      floatingActionButton: state.whenOrNull(
        data: (property) {
          if (property == null || !canManageProperties) return null;
          return _SpeedDial(
            isOpen: isDialOpen,
            onToggle: _toggleDial,
            onAddFloor: () {
              _closeDial();
              _showAddFloor(context);
            },
            onAddItem: () {
              _closeDial();
              _showAddItem(context, property);
            },
            onAiScan: () {
              _closeDial();
              context.push(
                '/properties/${widget.propertyId}/ai-scan',
                extra: property.floors,
              );
            },
          );
        },
      ),
      body: Stack(
        children: [
          state.when(
        data: (property) {
          if (property == null) {
            return _NotFoundView();
          }
          return _PropertyDetailBody(
            property: property,
            canManageProperties: canManageProperties,
            onRefresh: () => ref
                .read(propertyDetailNotifierProvider.notifier)
                .load(widget.propertyId),
            onAddFloor: canManageProperties
                ? () => _showAddFloor(context)
                : null,
            onChangePhoto: canManageProperties
                ? () => _changePropertyPhoto(context, ref, property)
                : null,
            onAssignLocation: (itemId) => _showAssignLocation(
              context,
              itemId,
              property.floors,
            ),
          );
        },
        loading: () => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Loading property...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        error: (err, _) => _ErrorView(
          message: PropertyDetailNotifier.message(err),
          onRetry: () => ref
              .read(propertyDetailNotifierProvider.notifier)
              .load(widget.propertyId),
        ),
      ),
          // Backdrop when dial is open
          if (isDialOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeDial,
                child: Container(color: Colors.black54),
              ),
            ),
        ],
      ),
    );
  }

  void _showAssignLocation(
    BuildContext context,
    String itemId,
    List<FloorModel> floors,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignLocationSheet(
        floors: floors,
        itemId: itemId,
      ),
    ).then((_) {
      // Refresh unlocated count after assignment
      ref.invalidate(unlocatedItemsProvider(widget.propertyId));
    });
  }

  void _showAddItem(BuildContext context, PropertyModel property) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddItemSheet(
        propertyId: property.id,
        floors: property.floors,
        onAdded: () {
          ref.invalidate(unlocatedItemsProvider(property.id));
          ref.invalidate(itemListNotifierProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item saved')),
            );
          }
        },
      ),
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

  Future<void> _changePropertyPhoto(
    BuildContext context,
    WidgetRef ref,
    PropertyModel property,
  ) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !context.mounted) return;

    final file = await picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Uploading photo...'),
        duration: Duration(seconds: 10),
      ),
    );

    try {
      final url = await ref.read(mediaRepositoryProvider).uploadPhoto(file);
      await ref.read(propertiesNotifierProvider.notifier).updatePhotos(
        property.id,
        [url],
      );
      await ref.read(propertyDetailNotifierProvider.notifier).load(property.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cover photo updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }
}

class _PropertyDetailBody extends ConsumerWidget {
  const _PropertyDetailBody({
    required this.property,
    required this.canManageProperties,
    required this.onRefresh,
    this.onAddFloor,
    this.onChangePhoto,
    this.onAssignLocation,
  });

  final PropertyModel property;
  final bool canManageProperties;
  final VoidCallback onRefresh;
  final VoidCallback? onAddFloor;
  final VoidCallback? onChangePhoto;
  final void Function(String itemId)? onAssignLocation;

  static const double _appBarExpandedHeight = 280;

  /// Placeholder: modern luxury mansion when property has no photos.
  static const String _placeholderMansionUrl =
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasHeroImage = property.photos.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceOverlay = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.04);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: _appBarExpandedHeight,
          pinned: true,
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.onBackground,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 24.0, bottom: 16),
            title: Text(
              property.name,
              style: AppTypography.displaySerif.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w500,
                color: AppColors.onBackground,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: hasHeroImage
                      ? property.photos.first
                      : _placeholderMansionUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => _LuxuryGradientBackground(),
                  errorWidget: (_, _, _) => _LuxuryGradientBackground(),
                ),
                // Dark gradient at base so title reads perfectly
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.85),
                        AppColors.background,
                      ],
                      stops: const [0.3, 0.6, 0.85, 1.0],
                    ),
                  ),
                ),
                // Title overlay: strong gradient at bottom so title stands out on any photo
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 140,
                    padding: const EdgeInsets.only(left: 24.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ),
                if (canManageProperties && onChangePhoto != null)
                  Positioned(
                    bottom: AppSpacing.md,
                    right: AppSpacing.md,
                    child: GestureDetector(
                      onTap: onChangePhoto,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                Text(
                  _typeLabel(property.type),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        _formatAddress(property.address),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _UnlocatedItemsBanner(
                  propertyId: property.id,
                  floors: property.floors,
                  onAssignLocation: onAssignLocation,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'FLOORS & ROOMS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 2.0,
                        fontSize: 10,
                      ),
                    ),
                    if (onAddFloor != null)
                      OutlinedButton.icon(
                        onPressed: onAddFloor,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(
                            color: AppColors.accent,
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add floor'),
                      ),
                  ],
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
                      Icons.villa_outlined,
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
                    surfaceOverlay: surfaceOverlay,
                    canManageProperties: canManageProperties,
                    onAddRoom: () =>
                        _showAddRoom(context, property.floors[index]),
                    onRefresh: onRefresh,
                  ),
                ),
                childCount: property.floors.length,
              ),
            ),
          ),
        if (property.floors.length == 1) const _SingleFloorPlaceholder(),
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

// ── Unlocated items banner ─────────────────────────────────────────────────

class _UnlocatedItemsBanner extends ConsumerWidget {
  const _UnlocatedItemsBanner({
    required this.propertyId,
    required this.floors,
    this.onAssignLocation,
  });

  final String propertyId;
  final List<FloorModel> floors;
  final void Function(String itemId)? onAssignLocation;

  static const int _maxInline = 3;

  void _openSheet(BuildContext context, WidgetRef ref, List<dynamic> items) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnlocatedItemsSheet(
        propertyId: propertyId,
        floors: floors,
      ),
    ).then((_) {
      // ignore: unused_result
      ref.refresh(unlocatedItemsProvider(propertyId));
    });
  }

  Future<void> _deleteBannerItem(
    BuildContext context,
    WidgetRef ref,
    dynamic item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Delete "${item.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(itemRepositoryProvider).deleteItem(item.id);
        if (context.mounted) {
          // ignore: unused_result
          ref.refresh(unlocatedItemsProvider(propertyId));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(unlocatedItemsProvider(propertyId));

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final inlineItems = items.take(_maxInline).toList();
        final overflow = items.length - _maxInline;

        return Container(
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_off_outlined,
                      size: 18,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${items.length} item${items.length == 1 ? '' : 's'} pending location',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openSheet(context, ref, items),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Manage \u2192',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Inline item rows (max 3) ─────────────────────────────────
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                itemCount: inlineItems.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final item = inlineItems[index];
                  return Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onBackground.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (onAssignLocation != null)
                        TextButton(
                          onPressed: () => onAssignLocation!(item.id),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Assign'),
                        ),
                      IconButton(
                        onPressed: () =>
                            _deleteBannerItem(context, ref, item),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  );
                },
              ),
              // ── "+N more" chip ───────────────────────────────────────────
              if (overflow > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  child: GestureDetector(
                    onTap: () => _openSheet(context, ref, items),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        '+$overflow more',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: AppSpacing.xs),
            ],
          ),
        );
      },
    );
  }
}

// ── Unlocated items bottom sheet ───────────────────────────────────────────

class _UnlocatedItemsSheet extends ConsumerStatefulWidget {
  const _UnlocatedItemsSheet({
    required this.propertyId,
    required this.floors,
  });

  final String propertyId;
  final List<FloorModel> floors;

  @override
  ConsumerState<_UnlocatedItemsSheet> createState() =>
      _UnlocatedItemsSheetState();
}

class _UnlocatedItemsSheetState extends ConsumerState<_UnlocatedItemsSheet> {
  final Set<String> _selected = {};
  bool _assigning = false;

  void _toggleAll(List<dynamic> items) {
    setState(() {
      if (_selected.length == items.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(items.map<String>((i) => i.id as String));
      }
    });
  }

  void _toggleItem(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _deleteItem(BuildContext context, dynamic item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete item'),
        content: Text('Delete "${item.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ref.read(itemRepositoryProvider).deleteItem(item.id as String);
        if (mounted) {
          setState(() => _selected.remove(item.id));
          // ignore: unused_result
          ref.refresh(unlocatedItemsProvider(widget.propertyId));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _batchAssign(BuildContext context, List<dynamic> items) async {
    final selectedIds = List<String>.from(_selected);
    if (selectedIds.isEmpty) return;

    final room = await showModalBottomSheet<RoomModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AssignLocationSheet(floors: widget.floors),
    );

    if (room == null || !context.mounted) return;

    setState(() => _assigning = true);
    int assigned = 0;
    Object? assignError;

    for (final id in selectedIds) {
      try {
        await ref
            .read(itemRepositoryProvider)
            .assignLocation(id, roomId: room.roomId);
        if (mounted) setState(() => _selected.remove(id));
        assigned++;
      } catch (e) {
        assignError = e;
        break;
      }
    }

    if (mounted) {
      setState(() => _assigning = false);
      // ignore: unused_result
      ref.refresh(unlocatedItemsProvider(widget.propertyId));
    }

    if (!context.mounted) return;

    if (assignError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$assigned of ${selectedIds.length} items assigned. Some failed.',
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(unlocatedItemsProvider(widget.propertyId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(child: Text('Error: $e')),
            data: (items) {
              // Sort items by category for grouping
              final sorted = [...items]
                ..sort((a, b) => a.category.compareTo(b.category));

              final allSelected = _selected.length == items.length &&
                  items.isNotEmpty;

              return Column(
                children: [
                  // ── Drag handle ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.onSurfaceVariant
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  // ── Header ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '\u{1F4E6}',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${items.length} item${items.length == 1 ? '' : 's'} pending location',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppColors.onBackground,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Select items to assign them to a room',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  // ── Select all / Deselect all ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            allSelected
                                ? 'All selected'
                                : _selected.isEmpty
                                    ? 'None selected'
                                    : '${_selected.length} selected',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                        ),
                        TextButton(
                          onPressed: items.isEmpty
                              ? null
                              : () => _toggleAll(items),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            allSelected ? 'Deselect all' : 'Select all',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // ── Item list ────────────────────────────────────────────
                  Expanded(
                    child: items.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 48,
                                  color: AppColors.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'All items have been assigned',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xxl,
                            ),
                            itemCount: sorted.length,
                            itemBuilder: (context, index) {
                              final item = sorted[index];
                              final prevItem =
                                  index > 0 ? sorted[index - 1] : null;
                              final showCategoryHeader = prevItem == null ||
                                  prevItem.category != item.category;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (showCategoryHeader)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        AppSpacing.md,
                                        AppSpacing.md,
                                        AppSpacing.md,
                                        AppSpacing.xs,
                                      ),
                                      child: Text(
                                        item.category.toUpperCase(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: AppColors.onSurfaceVariant,
                                              letterSpacing: 1.5,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  CheckboxListTile(
                                    value: _selected.contains(item.id),
                                    onChanged: (_) => _toggleItem(item.id),
                                    activeColor: Colors.orange,
                                    checkColor: Colors.white,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    title: Text(
                                      item.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.onBackground,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: item.subcategory.isNotEmpty
                                        ? _CategoryChip(
                                            label: item.subcategory,
                                          )
                                        : null,
                                    secondary: IconButton(
                                      onPressed: () =>
                                          _deleteItem(context, item),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        size: 20,
                                        color: Colors.red,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  // ── Sticky action bar ────────────────────────────────────
                  if (_selected.isNotEmpty)
                    SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border(
                            top: BorderSide(
                              color: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.15),
                            ),
                          ),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed: _assigning
                                ? null
                                : () => _batchAssign(context, items),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  Colors.orange.withValues(alpha: 0.4),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _assigning
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Assign ${_selected.length} item${_selected.length == 1 ? '' : 's'} \u2192',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

// ── Luxury gradient background ─────────────────────────────────────────────

class _LuxuryGradientBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A24), Color(0xFF0E0E14)],
        ),
      ),
    );
  }
}

class _SingleFloorPlaceholder extends StatelessWidget {
  const _SingleFloorPlaceholder();

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.onSurfaceVariant.withValues(alpha: 0.25);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.md,
          bottom: AppSpacing.lg,
        ),
        child: DottedBorder(
          borderType: BorderType.RRect,
          radius: const Radius.circular(16),
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          dashPattern: const [6, 4],
          color: borderColor,
          strokeWidth: 1.2,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20, color: AppColors.accent),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'Add another floor to organize more rooms',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FloorTile extends ConsumerWidget {
  const _FloorTile({
    required this.floor,
    required this.propertyId,
    required this.surfaceOverlay,
    required this.canManageProperties,
    required this.onAddRoom,
    required this.onRefresh,
  });

  final FloorModel floor;
  final String propertyId;
  final Color surfaceOverlay;
  final bool canManageProperties;
  final VoidCallback onAddRoom;
  final VoidCallback onRefresh;

  void _showEditRoom(BuildContext context, RoomModel room) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditRoomSheet(
        floorId: floor.floorId,
        floorName: floor.name,
        room: room,
        onUpdated: onRefresh,
      ),
    );
  }

  Future<void> _confirmDeleteRoom(
    BuildContext context,
    WidgetRef ref,
    RoomModel room,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete room',
          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                color: AppColors.onBackground,
              ),
        ),
        content: Text(
          'Delete "${room.name}"? Items in this room will become unlocated.',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(propertyDetailNotifierProvider.notifier)
          .deleteRoom(floor.floorId, room.roomId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(PropertyDetailNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceOverlay,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: const Icon(
          Icons.villa_outlined,
          size: 18,
          color: Color(0xFFFFD700),
        ),
        title: Text(
          floor.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.onBackground,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            '${floor.rooms.length} room(s)',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        children: [
          ...floor.rooms.map(
            (room) => Padding(
              padding: const EdgeInsets.only(left: AppSpacing.lg),
              child: ListTile(
                contentPadding: const EdgeInsets.only(right: AppSpacing.sm),
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
                trailing: canManageProperties
                    ? PopupMenuButton<_RoomAction>(
                        icon: Icon(
                          Icons.more_vert,
                          size: 18,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                        color: AppColors.surfaceVariant,
                        onSelected: (action) {
                          if (action == _RoomAction.edit) {
                            _showEditRoom(context, room);
                          } else {
                            _confirmDeleteRoom(context, ref, room);
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _RoomAction.edit,
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 16, color: AppColors.accent),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Edit',
                                  style: TextStyle(color: AppColors.onBackground),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: _RoomAction.delete,
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 16, color: AppColors.error),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: AppColors.error),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : null,
                onTap: () {
                  context.push(
                    '/properties/$propertyId/rooms/${room.roomId}?name=${Uri.encodeComponent(room.name)}',
                  );
                },
              ),
            ),
          ),
          if (canManageProperties)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: TextButton.icon(
                onPressed: onAddRoom,
                icon: const Icon(Icons.add, size: 18, color: AppColors.accent),
                label: const Text('Add room'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }
}

enum _RoomAction { edit, delete }

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
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.onBackground),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Speed Dial FAB
// ─────────────────────────────────────────────────────────────────────────────

class _SpeedDial extends StatelessWidget {
  const _SpeedDial({
    required this.isOpen,
    required this.onToggle,
    required this.onAddFloor,
    required this.onAddItem,
    required this.onAiScan,
  });

  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onAddFloor;
  final VoidCallback onAddItem;
  final VoidCallback onAiScan;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── Options (visible when open) ──────────────────────
        if (isOpen) ...[
          _DialItem(
            label: 'Add floor',
            icon: Icons.villa_outlined,
            onTap: onAddFloor,
            isAi: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DialItem(
            label: 'Add item',
            icon: Icons.inventory_2_outlined,
            onTap: onAddItem,
            isAi: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DialItem(
            label: 'Add item with AI',
            icon: Icons.auto_awesome,
            onTap: onAiScan,
            isAi: true,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        // ── Main FAB ─────────────────────────────────────────
        FloatingActionButton(
          onPressed: onToggle,
          backgroundColor: isOpen ? AppColors.surface : AppColors.accent,
          foregroundColor: isOpen ? AppColors.accent : Colors.black,
          shape: const CircleBorder(),
          child: AnimatedRotation(
            turns: isOpen ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(isOpen ? Icons.close : Icons.add, size: 28),
          ),
        ),
      ],
    );
  }
}

class _DialItem extends StatelessWidget {
  const _DialItem({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isAi,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isAi;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label chip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isAi
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAi
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : Colors.white12,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isAi ? AppColors.accent : AppColors.onBackground,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Mini FAB
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAi ? AppColors.accent : AppColors.surfaceVariant,
            ),
            child: Icon(
              icon,
              size: 18,
              color: isAi ? Colors.black : AppColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.onBackground),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
