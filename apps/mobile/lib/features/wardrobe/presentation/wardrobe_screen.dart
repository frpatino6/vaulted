import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../household_members/data/models/household_member_model.dart';
import '../../household_members/domain/household_members_notifier.dart';
import '../../inventory/data/models/item_model.dart';
import '../data/wardrobe_stats_repository.dart';
import '../domain/wardrobe_notifier.dart';
import '../domain/wardrobe_stats_provider.dart';
import 'at_laundry_screen.dart';
import 'wardrobe_filters_sheet.dart';
import 'wardrobe_item_card.dart';

class WardrobeScreen extends ConsumerStatefulWidget {
  const WardrobeScreen({super.key});

  @override
  ConsumerState<WardrobeScreen> createState() => _WardrobeScreenState();
}

class _WardrobeScreenState extends ConsumerState<WardrobeScreen> {
  String _selectedType = 'all';
  String _selectedCleaningStatus = 'all';
  String _selectedSeason = 'all';
  String? _selectedMemberId;

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
      bottomNavigationBar: AppBottomNav(currentTab: AppTab.wardrobe),
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
      body: RefreshIndicator(
        onRefresh: () => ref.read(wardrobeNotifierProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WardrobeStatsBar(state: statsState),
                    _PrimaryFiltersRow(
                      selectedType: _selectedType,
                      onTypeSelected: (String value) =>
                          setState(() => _selectedType = value),
                      onFiltersPressed: () => _showAdvancedFilters(context),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
            state.when(
              loading: () => const SliverFillRemaining(
                child: AppScreenSkeleton(showHeader: false),
              ),
              error: (Object error, StackTrace _) => SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Unable to load wardrobe items',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
              ),
              data: (List<ItemModel> items) {
                final List<ItemModel> filtered = _applyFilters(items);
                if (filtered.isEmpty) {
                  return const SliverFillRemaining(
                    child: _WardrobeEmptyState(),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    20,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext ctx, int index) {
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
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
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
      final bool matchesMember =
          _selectedMemberId == null || attrs.ownerMemberId == _selectedMemberId;
      return matchesType && matchesCleaning && matchesSeason && matchesMember;
    }).toList();
  }

  void _showAdvancedFilters(BuildContext context) {
    final List<HouseholdMemberModel> members = ref
            .read(householdMembersNotifierProvider)
            .valueOrNull
            ?.where((HouseholdMemberModel m) => m.isActive)
            .toList() ??
        [];

    showModalBottomSheet<WardrobeFiltersResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => WardrobeFiltersSheet(
        members: members,
        selectedMemberId: _selectedMemberId,
        selectedSeason: _selectedSeason,
        selectedCleaningStatus: _selectedCleaningStatus,
      ),
    ).then((WardrobeFiltersResult? result) {
      if (result == null || !mounted) return;
      setState(() {
        _selectedMemberId = result.memberId;
        _selectedSeason = result.season;
        _selectedCleaningStatus = result.cleaningStatus;
      });
    });
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _StatChip(label: 'Total', value: '${stats.totalItems}'),
            const SizedBox(width: AppSpacing.sm),
            _StatChip(
              label: 'Needs cleaning',
              value: '${stats.needsCleaning}',
              glowColor: stats.needsCleaning > 0 ? Colors.amber : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatChip(
              label: 'At cleaner',
              value: '${stats.atDryCleaner}',
              color: Colors.blue,
              showOverdueDot: stats.overdueItems > 0,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AtLaundryScreen(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StatChip(
              label: 'Outfits',
              value: '${stats.outfitsCount}',
              onTap: () => context.push('/wardrobe/outfits'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.color,
    this.glowColor,
    this.onTap,
    this.showOverdueDot = false,
  });

  final String label;
  final String value;
  final Color? color;
  final Color? glowColor;
  final VoidCallback? onTap;
  final bool showOverdueDot;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = glowColor ?? color ?? Colors.white10;
    final List<BoxShadow> shadows = glowColor != null
        ? [
            BoxShadow(
              color: glowColor!.withValues(alpha: 0.45),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ]
        : [];

    final Widget chip = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppColors.surfaceVariant,
          border: Border.all(color: borderColor, width: 0.8),
          boxShadow: shadows,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: glowColor ?? color ?? AppColors.onBackground,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );

    if (!showOverdueDot) return chip;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        chip,
        Positioned(
          top: -2,
          right: -2,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryFiltersRow extends StatelessWidget {
  const _PrimaryFiltersRow({
    required this.selectedType,
    required this.onTypeSelected,
    required this.onFiltersPressed,
  });

  static const Map<String, String> _types = {
    'all': 'All',
    'clothing': 'Clothing',
    'footwear': 'Footwear',
    'accessories': 'Accessories',
  };

  final String selectedType;
  final ValueChanged<String> onTypeSelected;
  final VoidCallback onFiltersPressed;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _TuneButton(onPressed: onFiltersPressed),
          const SizedBox(width: AppSpacing.sm),
          ..._types.entries.map((MapEntry<String, String> entry) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: _GlowFilterChip(
                label: entry.value,
                isSelected: selectedType == entry.key,
                onTap: () => onTypeSelected(entry.key),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TuneButton extends StatelessWidget {
  const _TuneButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.surfaceVariant,
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        child: const Icon(
          Icons.tune,
          size: 18,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _GlowFilterChip extends StatelessWidget {
  const _GlowFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: AppColors.surfaceVariant,
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.white10,
            width: isSelected ? 1.0 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Colors.white
                    : AppColors.onBackground.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 12,
              ),
        ),
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
