import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/room_inventory_asset_card.dart';
import '../../properties/domain/properties_notifier.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/item_model.dart';
import '../domain/asset_browser_notifier.dart';

const List<String> _categoryFilters = <String>[
  'All',
  'Furniture',
  'Art',
  'Technology',
  'Wardrobe',
  'Vehicles',
  'Wine',
  'Sports',
];

const List<String> _statusFilters = <String>[
  'Active',
  'Loaned',
  'Repair',
  'Storage',
];

class AssetBrowserScreen extends ConsumerStatefulWidget {
  const AssetBrowserScreen({super.key});

  @override
  ConsumerState<AssetBrowserScreen> createState() => _AssetBrowserScreenState();
}

class _AssetBrowserScreenState extends ConsumerState<AssetBrowserScreen> {
  late final TextEditingController _controller;
  String _query = '';
  String? _selectedCategory;
  String? _selectedStatus;
  String? _selectedPropertyId;
  bool _unlocated = false;
  AssetSortBy _sortBy = AssetSortBy.recent;
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_onQueryChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(assetBrowserNotifierProvider.notifier)
          .loadInitial()
          .whenComplete(() {
        if (mounted) setState(() => _initialLoadCompleted = true);
      });
    });
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final next = _controller.text;
    if (_query == next) return;
    setState(() => _query = next);
    _applyFilters();
  }

  void _applyFilters() {
    ref.read(assetBrowserNotifierProvider.notifier).applyFilters(
      query: _query,
      category: _selectedCategory?.toLowerCase(),
      status: _selectedStatus?.toLowerCase(),
      propertyId: _selectedPropertyId,
      unlocated: _unlocated,
      sortBy: _sortBy,
    );
  }

  void _toggleCategory(String category) {
    setState(() => _selectedCategory = category == 'All' ? null : category);
    _applyFilters();
  }

  void _toggleStatus(String status) {
    setState(() => _selectedStatus = _selectedStatus == status ? null : status);
    _applyFilters();
  }

  void _toggleProperty(String propertyId) {
    setState(
      () => _selectedPropertyId =
          _selectedPropertyId == propertyId ? null : propertyId,
    );
    _applyFilters();
  }

  void _toggleUnlocated() {
    setState(() => _unlocated = !_unlocated);
    _applyFilters();
  }

  void _setSortBy(AssetSortBy sortBy) {
    if (_sortBy == sortBy) return;
    setState(() => _sortBy = sortBy);
    _applyFilters();
  }

  void _clearFilters() {
    _controller.clear();
    setState(() {
      _query = '';
      _selectedCategory = null;
      _selectedStatus = null;
      _selectedPropertyId = null;
      _unlocated = false;
      _sortBy = AssetSortBy.recent;
    });
    ref.read(assetBrowserNotifierProvider.notifier).loadInitial();
  }

  bool _isCategorySelected(String category) =>
      category == 'All' ? _selectedCategory == null : _selectedCategory == category;

  // Sort change also counts as active filter so Clear appears
  bool get _hasActiveFilters =>
      _query.isNotEmpty ||
      _selectedCategory != null ||
      _selectedStatus != null ||
      _selectedPropertyId != null ||
      _unlocated ||
      _sortBy != AssetSortBy.recent;

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole() ?? 'guest';
    final canSeeValues = role == 'owner' || role == 'auditor';
    final browserState = ref.watch(assetBrowserNotifierProvider);
    final propertiesState = ref.watch(propertiesNotifierProvider);
    final properties = propertiesState.valueOrNull ?? [];
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    final showInitialSkeleton =
        !_initialLoadCompleted || browserState is AsyncLoading<AssetBrowserState>;

    return Scaffold(
      backgroundColor: AppColors.backgroundElevated,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundElevated,
        foregroundColor: AppColors.onBackground,
        toolbarHeight: 64,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        titleSpacing: 0,
        title: Text(
          'Asset Directory',
          style: AppTypography.titleSerif.copyWith(color: AppColors.onBackground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_hasActiveFilters)
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Clear',
                style: AppTypography.labelLarge.copyWith(color: AppColors.accent),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: TextField(
              controller: _controller,
              style:
                  AppTypography.bodyLarge.copyWith(color: AppColors.onBackground),
              cursorColor: AppColors.accent,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search by name, tag, serial…',
                hintStyle:
                    AppTypography.bodyLarge.copyWith(color: Colors.white38),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        tooltip: 'Clear search',
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.onSurfaceVariant,
                          size: 18,
                        ),
                        onPressed: () => _controller.clear(),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
          // Row 1: Category + Status
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._categoryFilters.map((cat) {
                    final selected = _isCategorySelected(cat);
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _FilterChip(
                        label: cat,
                        selected: selected,
                        onTap: () => _toggleCategory(cat),
                      ),
                    );
                  }),
                  const _FilterDivider(),
                  ..._statusFilters.map((s) {
                    final selected = _selectedStatus == s;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _FilterChip(
                        label: s,
                        selected: selected,
                        onTap: () => _toggleStatus(s),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          // Row 2: Property + Unlocated + Sort
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (properties.isNotEmpty) ...[
                    ...properties.map((p) {
                      final selected = _selectedPropertyId == p.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _FilterChip(
                          label: p.name,
                          selected: selected,
                          onTap: () => _toggleProperty(p.id),
                          icon: Icons.home_work_outlined,
                        ),
                      );
                    }),
                    const _FilterDivider(),
                  ],
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _FilterChip(
                      label: 'Unlocated',
                      selected: _unlocated,
                      onTap: _toggleUnlocated,
                      icon: Icons.location_off_outlined,
                    ),
                  ),
                  const _FilterDivider(),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: _FilterChip(
                      label: 'Recent',
                      selected: _sortBy == AssetSortBy.recent,
                      onTap: () => _setSortBy(AssetSortBy.recent),
                      icon: Icons.schedule_outlined,
                    ),
                  ),
                  if (canSeeValues)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: _FilterChip(
                        label: 'Value ↓',
                        selected: _sortBy == AssetSortBy.valueDesc,
                        onTap: () => _setSortBy(AssetSortBy.valueDesc),
                        icon: Icons.attach_money_rounded,
                      ),
                    ),
                  _FilterChip(
                    label: 'Name A–Z',
                    selected: _sortBy == AssetSortBy.nameAsc,
                    onTap: () => _setSortBy(AssetSortBy.nameAsc),
                    icon: Icons.sort_by_alpha_rounded,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: showInitialSkeleton
                ? const AppScreenSkeleton(showHeader: false)
                : browserState.when(
                    data: (data) => _BrowserBody(
                      data: data,
                      canSeeValues: canSeeValues,
                      sortBy: _sortBy,
                      bottomPadding: bottomPadding,
                    ),
                    loading: () => const AppScreenSkeleton(showHeader: false),
                    error: (e, _) => _ErrorState(
                      message: AssetBrowserNotifier.message(e),
                      onRetry: _applyFilters,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterDivider extends StatelessWidget {
  const _FilterDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
      color: Colors.white.withValues(alpha: 0.1),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              // Fixed width — only color animates to avoid layout shift
              color: selected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: selected
                      ? AppColors.accent
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: selected
                      ? AppColors.accent
                      : AppColors.onBackground.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowserBody extends StatelessWidget {
  const _BrowserBody({
    required this.data,
    required this.canSeeValues,
    required this.sortBy,
    required this.bottomPadding,
  });

  final AssetBrowserState data;
  final bool canSeeValues;
  final AssetSortBy sortBy;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    if (data.items.isEmpty) {
      return _EmptyState(hasActiveFilters: data.isFiltered);
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(data: data, sortBy: sortBy),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md + bottomPadding,
          ),
          sliver: SliverList.separated(
            itemCount: data.items.length,
            separatorBuilder: (context, i) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = data.items[index];
              return _BrowserItemCard(item: item, canSeeValues: canSeeValues);
            },
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.data, required this.sortBy});

  final AssetBrowserState data;
  final AssetSortBy sortBy;

  String get _label {
    if (data.isFiltered) return '${data.items.length} results';
    return switch (sortBy) {
      AssetSortBy.recent => 'Recently Added',
      AssetSortBy.valueDesc => 'All Items · Value ↓',
      AssetSortBy.nameAsc => 'All Items · A–Z',
    };
  }

  bool get _isRecent => !data.isFiltered && sortBy == AssetSortBy.recent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (_isRecent)
          Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Text(
          _label.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: _isRecent ? AppColors.accentLight : AppColors.onSurfaceVariant,
            letterSpacing: 1.4,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _BrowserItemCard extends StatelessWidget {
  const _BrowserItemCard({required this.item, required this.canSeeValues});

  final ItemModel item;
  final bool canSeeValues;

  @override
  Widget build(BuildContext context) {
    final locationText = [item.propertyName, item.roomName]
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .join(' › ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoomInventoryAssetCard(
          item: item,
          canSeeValues: canSeeValues,
          nameMaxLines: 2,
          valueFontWeight: FontWeight.bold,
        ),
        if (locationText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 10,
                  color: AppColors.catalogGold,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    locationText,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasActiveFilters});

  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasActiveFilters
                  ? Icons.filter_list_off_rounded
                  : Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasActiveFilters ? 'No items match your filters' : 'No items yet',
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Try adjusting or clearing the active filters.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.onBackground,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Try again',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
