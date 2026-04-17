import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/room_inventory_asset_card.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/models/item_model.dart';
import '../domain/search_notifier.dart';

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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller;

  String _query = '';
  String? _selectedCategory;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController()..addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final nextQuery = _controller.text;
    if (_query == nextQuery) return;

    setState(() {
      _query = nextQuery;
    });

    _runSearch();
  }

  void _runSearch() {
    final notifier = ref.read(searchNotifierProvider.notifier);
    if (_query.trim().isEmpty) {
      notifier.clear();
      return;
    }

    notifier.search(
      _query,
      category: _selectedCategory?.toLowerCase(),
      status: _selectedStatus?.toLowerCase(),
    );
  }

  void _toggleCategory(String category) {
    setState(() {
      _selectedCategory = category == 'All' ? null : category;
    });
    _runSearch();
  }

  void _toggleStatus(String status) {
    setState(() {
      _selectedStatus = _selectedStatus == status ? null : status;
    });
    _runSearch();
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole() ?? 'guest';
    final canSeeValues = role == 'owner' || role == 'auditor';
    final searchState = ref.watch(searchNotifierProvider);
    final hasQuery = _query.trim().isNotEmpty;
    final titleText = hasQuery ? 'Search results' : 'Global Search';

    bool isCategorySelected(String category) =>
        category == 'All'
            ? _selectedCategory == null
            : _selectedCategory == category;

    return Scaffold(
      backgroundColor: AppColors.backgroundElevated,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundElevated,
        foregroundColor: AppColors.onBackground,
        toolbarHeight: 64,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        titleSpacing: 0,
        title: Text(
          titleText,
          style: AppTypography.titleSerif.copyWith(
            color: AppColors.onBackground,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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
              autofocus: true,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.onBackground,
              ),
              cursorColor: AppColors.accent,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search items...',
                hintStyle: AppTypography.bodyLarge.copyWith(
                  color: Colors.white38,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._categoryFilters.map((category) {
                    final selected = isCategorySelected(category);
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(category),
                        selected: selected,
                        onSelected: (_) => _toggleCategory(category),
                        showCheckmark: false,
                        selectedColor: Colors.white.withValues(alpha: 0.1),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color:
                              selected
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                        labelStyle: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(
                          color:
                              selected
                                  ? AppColors.accent
                                  : AppColors.onBackground.withValues(
                                    alpha: 0.8,
                                  ),
                        ),
                      ),
                    );
                  }),
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  ..._statusFilters.map((status) {
                    final selected = _selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: FilterChip(
                        label: Text(status),
                        selected: selected,
                        onSelected: (_) => _toggleStatus(status),
                        showCheckmark: false,
                        selectedColor: Colors.white.withValues(alpha: 0.1),
                        backgroundColor: Colors.transparent,
                        side: BorderSide(
                          color:
                              selected
                                  ? AppColors.accent
                                  : Colors.white.withValues(alpha: 0.1),
                          width: 0.5,
                        ),
                        labelStyle: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(
                          color:
                              selected
                                  ? AppColors.accent
                                  : AppColors.onBackground.withValues(
                                    alpha: 0.8,
                                  ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Expanded(
            child: searchState.when(
              data: (items) {
                if (_query.trim().isEmpty && items.isEmpty) {
                  return _EmptySearchState(query: _query);
                }

                if (items.isEmpty) {
                  return _NoResultsState(query: _query.trim());
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder:
                      (_, _) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _SearchResultCard(
                      item: item,
                      canSeeValues: canSeeValues,
                    );
                  },
                );
              },
              loading: () => const AppScreenSkeleton(showHeader: false),
              error:
                  (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        SearchNotifier.message(error),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onBackground,
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({required this.item, required this.canSeeValues});

  final ItemModel item;
  final bool canSeeValues;

  @override
  Widget build(BuildContext context) {
    final locationText = [
      item.propertyName,
      item.roomName,
    ].whereType<String>().join(' › ');
    final hasLocation = locationText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoomInventoryAssetCard(
          item: item,
          canSeeValues: canSeeValues,
          nameMaxLines: 2,
          valueFontWeight: FontWeight.bold,
        ),
        if (hasLocation)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 10,
                  color: const Color(0xFFC5A059),
                ),
                const SizedBox(width: 4),
                Text(
                  locationText,
                  style: TextStyle(
                    fontSize: 11.0,
                    color: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 48,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Search your inventory',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.onBackground),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(
          "No items found for '$query'",
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.onBackground),
        ),
      ),
    );
  }
}
