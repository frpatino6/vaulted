import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../media/data/media_repository_provider.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/address_model.dart';
import '../data/models/floor_model.dart';
import '../data/models/property_model.dart';
import '../domain/properties_notifier.dart';
import '../domain/property_detail_notifier.dart';
import 'add_floor_sheet.dart';
import 'add_room_sheet.dart';

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

class _PropertyDetailBody extends StatelessWidget {
  const _PropertyDetailBody({
    required this.property,
    required this.canManageProperties,
    required this.onRefresh,
    this.onAddFloor,
    this.onChangePhoto,
  });

  final PropertyModel property;
  final bool canManageProperties;
  final VoidCallback onRefresh;
  final VoidCallback? onAddFloor;
  final VoidCallback? onChangePhoto;

  static const double _appBarExpandedHeight = 280;

  /// Placeholder: modern luxury mansion when property has no photos.
  static const String _placeholderMansionUrl =
      'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800';

  @override
  Widget build(BuildContext context) {
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
                const SizedBox(height: AppSpacing.xxl),
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

class _FloorTile extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceOverlay,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: Icon(
          Icons.villa_outlined,
          size: 18,
          color: const Color(0xFFFFD700),
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
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        children: [
          if (floor.rooms.isEmpty && canManageProperties)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: TextButton.icon(
                onPressed: onAddRoom,
                icon: const Icon(Icons.add, size: 18, color: AppColors.accent),
                label: const Text('Add room'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            ),
          if (floor.rooms.isNotEmpty)
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
                    context.push(
                      '/properties/$propertyId/rooms/${room.roomId}?name=${Uri.encodeComponent(room.name)}',
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
    required this.onAiScan,
  });

  final bool isOpen;
  final VoidCallback onToggle;
  final VoidCallback onAddFloor;
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
            label: 'Agregar planta',
            icon: Icons.villa_outlined,
            onTap: onAddFloor,
            isAi: false,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DialItem(
            label: 'Agregar ítem con IA',
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
