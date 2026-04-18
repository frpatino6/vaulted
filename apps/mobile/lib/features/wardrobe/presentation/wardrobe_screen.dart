import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../inventory/data/models/item_model.dart';
import '../data/wardrobe_stats_repository.dart';
import '../domain/wardrobe_notifier.dart';
import '../domain/wardrobe_stats_provider.dart';
import 'wardrobe_item_card.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  static const Map<String, String> _typeFilters = {
    'all': 'All',
    'clothing': 'Clothing',
    'footwear': 'Footwear',
    'accessories': 'Accessories',
    'jewelry_watches': 'Jewelry & Watches',
  };

  static const Map<String, String> _cleaningFilters = {
    'all': 'All',
    'clean': 'Clean',
    'needs_cleaning': 'Needs Cleaning',
    'at_dry_cleaner': 'At Dry Cleaner',
  };

  static const Map<String, String> _seasonFilters = {
    'all': 'All Seasons',
    'spring_summer': 'Spring / Summer',
    'fall_winter': 'Fall / Winter',
    'all_season': 'All Season',
  };

  String _selectedType = 'all';
  String _selectedCleaningStatus = 'all';
  String _selectedSeason = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wardrobeNotifierProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ItemModel>> state = ref.watch(
      wardrobeNotifierProvider,
    );
    final AsyncValue<WardrobeStatsModel> statsState = ref.watch(
      wardrobeStatsProvider,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.wardrobe),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Wardrobe',
          style: AppTypography.displaySerif.copyWith(
            color: AppColors.onBackground,
            fontSize: 22,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/wardrobe/outfits'),
                icon: const Icon(Icons.checkroom),
                label: const Text('Outfits'),
              ),
            ),
            _WardrobeStatsBar(state: statsState),
            _FiltersRow(
              values: _typeFilters,
              selected: _selectedType,
              onSelected:
                  (String value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            _FiltersRow(
              values: _cleaningFilters,
              selected: _selectedCleaningStatus,
              subtleSelected: true,
              onSelected:
                  (String value) =>
                      setState(() => _selectedCleaningStatus = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            _FiltersRow(
              values: _seasonFilters,
              selected: _selectedSeason,
              subtleSelected: true,
              onSelected:
                  (String value) => setState(() => _selectedSeason = value),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: state.when(
                data: (List<ItemModel> items) {
                  final List<ItemModel> filtered = _applyFilters(items);
                  if (filtered.isEmpty) return const _WardrobeEmptyState();
                  return RefreshIndicator(
                    onRefresh:
                        () =>
                            ref
                                .read(wardrobeNotifierProvider.notifier)
                                .refresh(),
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ItemModel item = filtered[index];
                        return WardrobeItemCard(
                          item: item,
                          onTap: () async {
                            await context.push('/items/${item.id}');
                            if (!mounted) return;
                            await ref
                                .read(wardrobeNotifierProvider.notifier)
                                .refresh();
                          },
                          onStatusTap: () => _showCleaningStatusPicker(item),
                        );
                      },
                    ),
                  );
                },
                loading: () => const AppScreenSkeleton(showHeader: false),
                error:
                    (Object error, StackTrace _) => Center(
                      child: Text(
                        'Unable to load wardrobe items',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<ItemModel> _applyFilters(List<ItemModel> items) {
    return items.where((ItemModel item) {
      if (item.category.trim().toLowerCase() != 'wardrobe') return false;
      final attrs = item.wardrobeAttributes;
      final bool matchesType =
          _selectedType == 'all' || attrs.type == _selectedType;
      final bool matchesCleaning =
          _selectedCleaningStatus == 'all' ||
          attrs.cleaningStatus == _selectedCleaningStatus;
      final bool matchesSeason =
          _selectedSeason == 'all' || attrs.season == _selectedSeason;
      return matchesType && matchesCleaning && matchesSeason;
    }).toList();
  }

  Future<void> _showCleaningStatusPicker(ItemModel item) async {
    const Map<String, String> labels = <String, String>{
      'clean': 'Clean',
      'needs_cleaning': 'Needs Cleaning',
      'at_dry_cleaner': 'At Dry Cleaner',
    };

    final String? selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (BuildContext ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    labels.entries.map((MapEntry<String, String> entry) {
                      final String? current =
                          item.wardrobeAttributes.cleaningStatus;
                      final bool isSelected = current == entry.key;
                      return ListTile(
                        leading: _StatusDot(status: entry.key),
                        title: Text(
                          entry.value,
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onBackground,
                          ),
                        ),
                        trailing:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  color: AppColors.accent,
                                )
                                : null,
                        onTap: () => Navigator.of(ctx).pop(entry.key),
                      );
                    }).toList(),
              ),
            ),
          ),
    );

    if (!mounted || selected == null) return;

    try {
      await ref
          .read(wardrobeNotifierProvider.notifier)
          .updateCleaningStatus(item: item, cleaningStatus: selected);
      ref.invalidate(wardrobeStatsProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update cleaning status'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _WardrobeStatsBar extends StatelessWidget {
  const _WardrobeStatsBar({required this.state});

  final AsyncValue<WardrobeStatsModel> state;

  @override
  Widget build(BuildContext context) {
    final WardrobeStatsModel? stats = state.valueOrNull;
    if (stats == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _StatChip(label: 'Total', value: '${stats.totalItems}'),
          _StatChip(
            label: 'Needs cleaning',
            value: '${stats.needsCleaning}',
            color: Colors.amber,
          ),
          _StatChip(
            label: 'At cleaner',
            value: '${stats.atDryCleaner}',
            color: Colors.blue,
          ),
          _StatChip(label: 'Outfits', value: '${stats.outfitsCount}'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: AppColors.surfaceVariant,
        border: Border.all(color: color ?? Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color ?? AppColors.onBackground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.values,
    required this.selected,
    required this.onSelected,
    this.subtleSelected = false,
  });

  final Map<String, String> values;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool subtleSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            values.entries.map((MapEntry<String, String> entry) {
              final bool isSelected = selected == entry.key;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: FilterChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 1,
                  ),
                  label:
                      subtleSelected
                          ? Container(
                            padding: const EdgeInsets.only(bottom: 2),
                            decoration: BoxDecoration(
                              border:
                                  isSelected
                                      ? const Border(
                                        bottom: BorderSide(
                                          color: AppColors.accent,
                                          width: 1,
                                        ),
                                      )
                                      : null,
                            ),
                            child: Text(entry.value),
                          )
                          : Text(entry.value),
                  selected: isSelected,
                  showCheckmark: false,
                  selectedColor:
                      subtleSelected
                          ? AppColors.surfaceVariant
                          : AppColors.accent.withValues(alpha: 0.15),
                  backgroundColor: AppColors.surfaceVariant,
                  side: BorderSide(
                    color:
                        subtleSelected
                            ? Colors.white10
                            : isSelected
                            ? AppColors.accent
                            : Colors.white10,
                    width: 0.5,
                  ),
                  labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        isSelected
                            ? subtleSelected
                                ? AppColors.onBackground
                                : AppColors.accent
                            : AppColors.onBackground.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                  onSelected: (_) => onSelected(entry.key),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _WardrobeEmptyState extends StatelessWidget {
  const _WardrobeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 48,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No wardrobe items yet',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

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
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }
}
