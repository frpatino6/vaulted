import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../users/domain/current_user_jwt.dart';
import '../data/item_repository_provider.dart';
import '../data/models/item_model.dart';
import '../domain/item_list_notifier.dart';
import '../../../shared/widgets/room_inventory_asset_card.dart';
import 'add_item_sheet.dart';
import 'section_qr_sheet.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.propertyId,
    required this.roomId,
    required this.roomName,
  });

  final String propertyId;
  final String roomId;
  final String roomName;

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _searchQuery = _searchController.text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemListNotifierProvider.notifier).load(widget.propertyId, widget.roomId);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ItemModel> _filterItems(List<ItemModel> items) {
    if (_searchQuery.trim().isEmpty) return items;
    final q = _searchQuery.trim().toLowerCase();
    return items.where((i) {
      return i.name.toLowerCase().contains(q) ||
          i.category.toLowerCase().contains(q) ||
          i.subcategory.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final role = currentUserRole() ?? 'guest';
    final canAddItem = role == 'owner' || role == 'manager' || role == 'staff';
    final canEditItem = role == 'owner' || role == 'manager' || role == 'staff';
    final canDeleteItem = role == 'owner' || role == 'manager';
    final canSeeValues = role == 'owner' || role == 'auditor';
    final state = ref.watch(itemListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onBackground,
            elevation: 0,
            scrolledUnderElevation: 2,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(
              widget.roomName,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              if (state.valueOrNull?.any((i) => i.locationDetail?.isNotEmpty == true) == true)
                IconButton(
                  onPressed: () {
                    final items = state.valueOrNull ?? [];
                    final sections = items
                        .map((i) => i.locationDetail)
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .toSet()
                        .toList()
                      ..sort();
                    showSectionQrSheet(
                      context,
                      widget.roomId,
                      widget.roomName,
                      sections,
                    );
                  },
                  icon: const Icon(Icons.qr_code_2, color: AppColors.accentLight),
                  tooltip: 'Section QR codes',
                  splashRadius: 24,
                ),
              if (canAddItem)
                IconButton(
                  onPressed: () => _showAddItem(context),
                  icon: const Icon(Icons.add, color: AppColors.accent),
                  tooltip: 'Add item',
                  splashRadius: 24,
                ),
            ],
          ),
          state.when(
            data: (items) {
              final totalValue = items.fold<int>(
                0,
                (sum, i) => sum + (i.valuation?.currentValue ?? 0),
              );
              final currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.sm),
                      _buildSummarySection(context, items.length, totalValue, currencyFormat, canSeeValues),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'INVENTORY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 2.0,
                              fontSize: 10,
                            ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSearchBar(context),
                        const SizedBox(height: AppSpacing.md),
                      ] else
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              );
            },
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Loading inventory...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            error: (_, _) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          state.when(
            data: (items) {
              if (items.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'No items in this room yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Tap Add item to register your first item',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final filtered = _filterItems(items);
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      final slidableActions = <Widget>[
                        if (canEditItem)
                          SlidableAction(
                            onPressed: (_) => context.push('/items/${item.id}'),
                            backgroundColor: AppColors.surfaceVariant,
                            foregroundColor: AppColors.onBackground,
                            icon: Icons.edit_outlined,
                            label: 'Edit',
                          ),
                        if (canDeleteItem)
                          SlidableAction(
                            onPressed: (_) => _confirmDelete(context, item),
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            icon: Icons.delete_outline,
                            label: 'Delete',
                          ),
                      ];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: slidableActions.isEmpty
                            ? RoomInventoryAssetCard(
                                item: item,
                                roomNameToStrip: widget.roomName,
                                canSeeValues: canSeeValues,
                              )
                            : Slidable(
                                key: ValueKey(item.id),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.32,
                                  children: slidableActions,
                                ),
                                child: RoomInventoryAssetCard(
                                  item: item,
                                  roomNameToStrip: widget.roomName,
                                  canSeeValues: canSeeValues,
                                ),
                              ),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
            loading: () => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
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
                      'Loading items...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppColors.onSurfaceVariant),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      ItemListNotifier.message(err),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onBackground,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.tonal(
                      onPressed: () => ref
                          .read(itemListNotifierProvider.notifier)
                          .load(widget.propertyId, widget.roomId),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
      bottomNavigationBar: _buildAddItemFooter(context, canAddItem),
    );
  }

  Widget _buildAddItemFooter(BuildContext context, bool canAddItem) {
    if (!canAddItem) return const SizedBox.shrink();
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
            onPressed: () => _showAddItem(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
            child: Text(
              '+ Add New Item',
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

  Widget _buildSummarySection(
    BuildContext context,
    int itemCount,
    int totalValue,
    NumberFormat currencyFormat,
    bool canSeeValues,
  ) {
    final hasValue = totalValue > 0;
    final valueColor = hasValue
        ? AppColors.catalogGold
        : AppColors.onBackground.withValues(alpha: 0.4);
    final labelColor = hasValue
        ? AppColors.catalogGold.withValues(alpha: 0.5)
        : AppColors.onBackground.withValues(alpha: 0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.2,
                fontSize: 10,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$itemCount item(s)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            if (canSeeValues)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currencyFormat.format(totalValue),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: valueColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Total Value',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: labelColor,
                          fontSize: 10,
                        ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.onBackground),
      decoration: InputDecoration(
        hintText: 'Search inventory...',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.38)),
        prefixIcon: Icon(
          Icons.search,
          size: 20,
          color: Colors.white24,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white10, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC5A059), width: 0.8),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, ItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: Text('Delete item?', style: TextStyle(color: AppColors.onBackground)),
        content: Text(
          '“${item.name}” will be permanently removed.',
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    final didConfirm = confirmed == true;
    if (!didConfirm || !context.mounted) return;
    try {
      await ref.read(itemRepositoryProvider).deleteItem(item.id);
      if (!context.mounted) return;
      ref.read(itemListNotifierProvider.notifier).load(widget.propertyId, widget.roomId);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not delete item')),
        );
      }
    }
  }

  void _showAddItem(BuildContext context) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddItemSheet(
        propertyId: widget.propertyId,
        roomId: widget.roomId,
        onAdded: () {
          ref.read(itemListNotifierProvider.notifier).load(widget.propertyId, widget.roomId);
        },
      ),
    );
  }
}
