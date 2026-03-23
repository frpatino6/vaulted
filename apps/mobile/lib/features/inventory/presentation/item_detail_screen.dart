import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../../users/domain/current_user_jwt.dart';
import '../../wardrobe/data/models/wardrobe_attributes.dart';
import '../../media/data/media_repository_provider.dart';
import '../../maintenance/domain/maintenance_notifier.dart';
import '../../maintenance/presentation/add_maintenance_sheet.dart';
import '../data/item_repository_provider.dart';
import '../data/models/item_model.dart';
import '../domain/item_detail_notifier.dart';
import 'edit_item_sheet.dart';
import '../../../shared/widgets/item_card.dart';
import '../../../shared/widgets/status_badge.dart';

/// Catalog gold for price and accents (Sotheby's/Christie's style).
const Color _kCatalogGold = Color(0xFFC5A059);

String _formatCreatedAt(String value) {
  try {
    final dt = DateTime.tryParse(value);
    if (dt != null) {
      return DateFormat.yMMMd().format(dt);
    }
  } catch (_) {}
  return value;
}

class ItemDetailScreen extends ConsumerStatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  ConsumerState<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends ConsumerState<ItemDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemDetailNotifierProvider.notifier).load(widget.itemId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole() ?? 'guest';
    final canEdit = role == 'owner' || role == 'manager' || role == 'staff';
    final canSeeValues = role == 'owner' || role == 'auditor';
    final state = ref.watch(itemDetailNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.when(
        data: (item) {
          if (item == null) {
            return const Center(child: Text('Item not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.onBackground,
                title: Text(
                  item.name,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                actions: [
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _showEditSheet(context, item),
                      tooltip: 'Edit',
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _ItemImageHeader(
                        item: item,
                        canEdit: canEdit,
                        onAddPhoto: () => _onAddOrChangePhoto(context, item),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (canSeeValues) _PriceHighlightSection(item: item),
                      if (canSeeValues) const SizedBox(height: AppSpacing.lg),
                      _SpecsGrid(item: item),
                      if (item.isWardrobe && item.hasWardrobeDetails) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _WardrobeDetailSection(attrs: item.wardrobeAttributes),
                      ],
                      if (item.subcategory.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('SUBCATEGORY'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.subcategory,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.onBackground),
                        ),
                      ],
                      if (canSeeValues &&
                          item.valuation != null &&
                          (item.valuation!.purchasePrice > 0 ||
                              item.valuation!.currentValue > 0 ||
                              item.valuation!.purchaseDate != null)) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('VALUATION DETAILS'),
                        const SizedBox(height: AppSpacing.sm),
                        _ValuationDetailsSection(item: item),
                      ],
                      if (item.createdAt != null &&
                          item.createdAt!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('ADDED'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _formatCreatedAt(item.createdAt!),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.onSurfaceVariant.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                        ),
                      ],
                      if (item.documents.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('DOCUMENTS'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${item.documents.length} document(s)',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.onSurfaceVariant.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                        ),
                      ],
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _SectionLabel('TAGS'),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: item.tags
                              .map(
                                (t) => Chip(
                                  label: Text(t),
                                  backgroundColor: AppColors.surfaceVariant
                                      .withValues(alpha: 0.6),
                                  side: BorderSide.none,
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (item.qrCode != null && item.qrCode!.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        _QrSection(qrCode: item.qrCode!),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      _MaintenanceSectionWidget(
                        itemId: item.id,
                        canSchedule: canEdit,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _HistorySectionLabel(),
                      const SizedBox(height: AppSpacing.sm),
                      _HistorySection(historyEntries: []),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
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
                ItemDetailNotifier.message(err),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.onBackground),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                onPressed: () => ref
                    .read(itemDetailNotifierProvider.notifier)
                    .load(widget.itemId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: state.valueOrNull != null && canEdit
          ? _buildEditFooter(context, state.valueOrNull!)
          : null,
    );
  }

  Widget _buildEditFooter(BuildContext context, ItemModel item) {
    return Container(
      color: const Color(0xFF0A0A0F),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showEditSheet(context, item),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: Text(
              'Edit Item',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onAddOrChangePhoto(BuildContext context, ItemModel item) async {
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Add photo',
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListTile(
                leading: Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.accent,
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: AppColors.onBackground),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.accent,
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: AppColors.onBackground),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !context.mounted) return;
    final picker = ImagePicker();
    final file = source == ImageSource.camera
        ? await picker.pickImage(source: ImageSource.camera)
        : await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !context.mounted) return;
    try {
      final mediaRepo = ref.read(mediaRepositoryProvider);
      final url = await mediaRepo.uploadPhoto(file);
      final repo = ref.read(itemRepositoryProvider);
      final updatedPhotos = [...item.photos, url];
      await repo.updateItem(item.id, photos: updatedPhotos);
      if (!context.mounted) return;
      await ref.read(itemDetailNotifierProvider.notifier).load(item.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Photo added')));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ItemDetailNotifier.message(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEditSheet(BuildContext context, ItemModel item) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditItemSheet(
        item: item,
        onUpdated: () =>
            ref.read(itemDetailNotifierProvider.notifier).load(item.id),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.accent,
        letterSpacing: 2.0,
        fontSize: 10,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Maintenance section embedded in item detail
// ---------------------------------------------------------------------------

class _MaintenanceSectionWidget extends ConsumerWidget {
  const _MaintenanceSectionWidget({
    required this.itemId,
    required this.canSchedule,
  });

  final String itemId;
  final bool canSchedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(itemMaintenanceNotifierProvider(itemId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MAINTENANCE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 2.0,
                    fontSize: 10,
                  ),
            ),
            if (canSchedule)
              TextButton.icon(
                onPressed: () async {
                  final record =
                      await showAddMaintenanceSheet(context, itemId);
                  if (record != null) {
                    ref
                        .read(itemMaintenanceNotifierProvider(itemId).notifier)
                        .reload();
                  }
                },
                icon: Icon(Icons.add, size: 16, color: AppColors.accent),
                label: Text(
                  'Schedule',
                  style: TextStyle(color: AppColors.accent, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        state.when(
          data: (records) {
            final active = records
                .where((r) => r.isPending || r.isOverdue)
                .take(3)
                .toList();
            if (active.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No maintenance scheduled.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant
                            .withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                ),
              );
            }
            return Column(
              children: active.map((r) {
                final isOverdue = r.isOverdue;
                final color = isOverdue
                    ? const Color(0xFFCF6679)
                    : r.isUrgent
                        ? const Color(0xFFE07B39)
                        : const Color(0xFFD4AF37);
                final date = DateTime.tryParse(r.scheduledDate);
                final dateStr = date != null
                    ? DateFormat.yMMMd().format(date)
                    : r.scheduledDate;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: color.withValues(alpha: 0.3), width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.build_outlined, size: 16, color: color),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.onBackground,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              isOverdue
                                  ? 'Overdue · Was $dateStr'
                                  : dateStr,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: color, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      if (r.isAiSuggested)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.auto_awesome,
                              size: 14, color: AppColors.accentLight),
                        ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: LinearProgressIndicator(),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _HistorySectionLabel extends StatelessWidget {
  const _HistorySectionLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      'HISTORY',
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: _kCatalogGold,
        letterSpacing: 2.0,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _QrSection extends StatelessWidget {
  const _QrSection({required this.qrCode});

  final String qrCode;

  @override
  Widget build(BuildContext context) {
    final base64Str = qrCode.split(',').last;
    final Uint8List bytes = base64Decode(base64Str);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('QR CODE'),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.memory(bytes, width: 180, height: 180),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              'Scan to identify this item',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share coming soon')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.onSurfaceVariant,
                side: BorderSide(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
                ),
              ),
              child: const Text('Share QR'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WardrobeDetailSection extends StatelessWidget {
  const _WardrobeDetailSection({required this.attrs});

  final WardrobeAttributes attrs;

  static const Map<String, String> _typeLabels = {
    'clothing': 'Clothing',
    'footwear': 'Footwear',
    'accessories': 'Accessories',
    'jewelry_watches': 'Jewelry & Watches',
  };

  static const Map<String, String> _seasonLabels = {
    'spring_summer': 'Spring/Summer',
    'fall_winter': 'Fall/Winter',
    'all_season': 'All Season',
  };

  static const Map<String, String> _cleaningLabels = {
    'clean': 'Clean ✓',
    'needs_cleaning': 'Needs Cleaning',
    'at_dry_cleaner': 'At Dry Cleaner',
  };

  @override
  Widget build(BuildContext context) {
    final hasAny =
        attrs.type != null ||
        attrs.brand != null ||
        attrs.size != null ||
        attrs.color != null ||
        attrs.material != null ||
        attrs.season != null ||
        attrs.cleaningStatus != null;
    if (!hasAny) return const SizedBox.shrink();

    final rows = <Widget>[
      if (attrs.type != null)
        _WardrobeRow(
          icon: Icons.checkroom_outlined,
          label: 'Type',
          value: _typeLabels[attrs.type] ?? attrs.type!,
        ),
      if (attrs.brand != null)
        _WardrobeRow(
          icon: Icons.label_outline,
          label: 'Brand',
          value: attrs.brand!,
        ),
      if (attrs.size != null)
        _WardrobeRow(
          icon: Icons.straighten_outlined,
          label: 'Size',
          value: attrs.size!,
        ),
      if (attrs.color != null)
        _WardrobeRow(
          icon: Icons.palette_outlined,
          label: 'Color',
          value: attrs.color!,
        ),
      if (attrs.material != null)
        _WardrobeRow(
          icon: Icons.texture_outlined,
          label: 'Material',
          value: attrs.material!,
        ),
      if (attrs.season != null)
        _WardrobeRow(
          icon: Icons.wb_sunny_outlined,
          label: 'Season',
          value: _seasonLabels[attrs.season] ?? attrs.season!,
        ),
      if (attrs.cleaningStatus != null)
        _WardrobeRow(
          icon: Icons.local_laundry_service_outlined,
          label: 'Cleaning',
          value: _cleaningLabels[attrs.cleaningStatus] ?? attrs.cleaningStatus!,
          trailing: _CleaningStatusChip(status: attrs.cleaningStatus!),
        ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel('WARDROBE DETAILS'),
          const SizedBox(height: AppSpacing.md),
          ...rows,
        ],
      ),
    );
  }
}

class _WardrobeRow extends StatelessWidget {
  const _WardrobeRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.onBackground),
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailing case final trailing?) trailing,
        ],
      ),
    );
  }
}

class _CleaningStatusChip extends StatelessWidget {
  const _CleaningStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case 'clean':
        color = Colors.green;
        break;
      case 'needs_cleaning':
        color = Colors.amber;
        break;
      case 'at_dry_cleaner':
        color = Colors.blue;
        break;
      default:
        color = AppColors.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 0.5),
      ),
      child: Text('●', style: TextStyle(color: color, fontSize: 10)),
    );
  }
}

class _ItemImageHeader extends StatefulWidget {
  const _ItemImageHeader({
    required this.item,
    required this.canEdit,
    required this.onAddPhoto,
  });

  final ItemModel item;
  final bool canEdit;
  final VoidCallback onAddPhoto;

  @override
  State<_ItemImageHeader> createState() => _ItemImageHeaderState();
}

class _ItemImageHeaderState extends State<_ItemImageHeader> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = _pageController.page?.round() ?? 0;
    if (page != _currentPage && mounted) {
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasPhoto = item.photos.isNotEmpty;
    final multiplePhotos = item.photos.length > 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: hasPhoto
                  ? multiplePhotos
                        ? SizedBox(
                            height: 220,
                            width: double.infinity,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: item.photos.length,
                              itemBuilder: (_, index) => CachedNetworkImage(
                                imageUrl: item.photos[index],
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholder: (_, _) =>
                                    _gradientPlaceholder(context, item),
                                errorWidget: (_, _, _) =>
                                    _gradientPlaceholder(context, item),
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                            imageUrl: item.photos.first,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (_, _) =>
                                _gradientPlaceholder(context, item),
                            errorWidget: (_, _, _) =>
                                _gradientPlaceholder(context, item),
                          )
                  : _gradientPlaceholder(context, item),
            ),
            if (widget.canEdit)
              Positioned(
                right: AppSpacing.sm,
                bottom: AppSpacing.sm,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: widget.onAddPhoto,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 22,
                        color: _kCatalogGold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (multiplePhotos) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              item.photos.length,
              (i) => GestureDetector(
                onTap: () => _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kCatalogGold.withValues(
                      alpha: i == _currentPage ? 1 : 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: item.photos.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => _pageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.xs),
                    child: CachedNetworkImage(
                      imageUrl: item.photos[i],
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => _thumbPlaceholder(),
                      errorWidget: (_, _, _) => _thumbPlaceholder(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.surfaceVariant,
      child: Icon(
        Icons.image_outlined,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
        size: 24,
      ),
    );
  }

  Widget _gradientPlaceholder(BuildContext context, ItemModel item) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2C2C), Color(0xFF121212)],
        ),
      ),
      child: Center(
        child: Icon(
          ItemCategoryIcons.forCategory(item.category),
          size: 120,
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
    );
  }
}

class _PriceHighlightSection extends StatelessWidget {
  const _PriceHighlightSection({required this.item});

  final ItemModel item;

  static final _currencyFormat = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final v = item.valuation;
    final currentValue = v?.currentValue ?? 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentValue > 0 ? _currencyFormat.format(currentValue) : '—',
              style: AppTypography.displaySerif.copyWith(
                color: _kCatalogGold,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Estimated Value',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onBackground.withValues(alpha: 0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValuationDetailsSection extends StatelessWidget {
  const _ValuationDetailsSection({required this.item});

  final ItemModel item;

  static final _currencyFormat = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final v = item.valuation!;
    final lines = <Widget>[];

    if (v.purchasePrice > 0) {
      lines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Purchase price',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${_currencyFormat.format(v.purchasePrice)} ${v.currency}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (v.currentValue > 0) {
      lines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current value',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
              Text(
                '${_currencyFormat.format(v.currentValue)} ${v.currency}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onBackground,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (v.purchaseDate != null) {
      lines.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Purchase date',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
              Text(
                DateFormat.yMMMd().format(v.purchaseDate!),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.onBackground),
              ),
            ],
          ),
        ),
      );
    }
    if (lines.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(children: lines),
    );
  }
}

class _SpecsGrid extends StatelessWidget {
  const _SpecsGrid({required this.item});

  final ItemModel item;

  static TextStyle _labelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall!.copyWith(
      color: Colors.white54,
      fontSize: 10,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w600,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 2.2,
        children: [
          _SpecCell(
            label: 'CATEGORY',
            value: item.category,
            labelStyle: _labelStyle(context),
          ),
          _SpecCell(
            label: 'STATUS',
            valueWidget: StatusBadge(status: item.status, compact: true),
            labelStyle: _labelStyle(context),
          ),
          _SpecCell(
            label: 'SERIAL NUMBER',
            value: item.serialNumber?.isNotEmpty == true
                ? item.serialNumber!
                : '—',
            labelStyle: _labelStyle(context),
          ),
        ],
      ),
    );
  }
}

class _SpecCell extends StatelessWidget {
  const _SpecCell({
    required this.label,
    this.value,
    this.valueWidget,
    required this.labelStyle,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: labelStyle),
        const SizedBox(height: 4),
        if (valueWidget != null)
          valueWidget!
        else
          Text(
            value ?? '—',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onBackground),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.historyEntries});

  final List<_HistoryEntry> historyEntries;

  @override
  Widget build(BuildContext context) {
    if (historyEntries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Text(
          'No movement recorded yet.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
            fontSize: 13,
          ),
        ),
      );
    }

    return _HistoryTimeline(entries: historyEntries);
  }
}

class _HistoryEntry {
  const _HistoryEntry({required this.date, required this.label});
  final String date;
  final String label;
}

class _HistoryTimeline extends StatelessWidget {
  const _HistoryTimeline({required this.entries});

  final List<_HistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _kCatalogGold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (i < entries.length - 1)
                        Container(
                          width: 1,
                          margin: const EdgeInsets.only(top: 2),
                          height: 32,
                          color: _kCatalogGold.withValues(alpha: 0.4),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].date,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: Colors.white54, fontSize: 10),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entries[i].label,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.onBackground),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
