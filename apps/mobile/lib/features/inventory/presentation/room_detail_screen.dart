import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../inventory/domain/item_list_notifier.dart';
import '../../../shared/widgets/item_card.dart';
import 'add_item_sheet.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(itemListNotifierProvider.notifier).load(widget.propertyId, widget.roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(itemListNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.background,
            foregroundColor: AppColors.onBackground,
            title: Text(
              widget.roomName,
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.onBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${items.length} item(s)',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                          Text(
                            'Total ${currencyFormat.format(totalValue)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'INVENTORY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 2.0,
                              fontSize: 10,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (err, stackTrace) => const SliverToBoxAdapter(child: SizedBox.shrink()),
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
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ItemCard(item: items[index]),
                    ),
                    childCount: items.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
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
      floatingActionButton: state.hasValue
          ? OutlinedButton.icon(
              onPressed: () => _showAddItem(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add item'),
            )
          : null,
    );
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
