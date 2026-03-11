import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/models/item_model.dart';
import '../domain/item_detail_notifier.dart';
import '../../../shared/widgets/status_badge.dart';

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
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.md),
                      _PhotoPlaceholder(photos: item.photos),
                      const SizedBox(height: AppSpacing.lg),
                      _InfoSection(item: item),
                      if (item.tags.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'TAGS',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.accent,
                                letterSpacing: 2.0,
                                fontSize: 10,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: item.tags
                              .map(
                                (t) => Chip(
                                  label: Text(t),
                                  backgroundColor: AppColors.surfaceVariant.withValues(alpha: 0.6),
                                  side: BorderSide.none,
                                  labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.onSurfaceVariant,
                                      ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'HISTORY',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.accent,
                              letterSpacing: 2.0,
                              fontSize: 10,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              size: 20,
                              color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Coming soon',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
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
              Icon(Icons.error_outline, size: 48, color: AppColors.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
              Text(
                ItemDetailNotifier.message(err),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onBackground,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.tonal(
                onPressed: () => ref.read(itemDetailNotifierProvider.notifier).load(widget.itemId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.photos});

  final List<String> photos;

  @override
  Widget build(BuildContext context) {
    if (photos.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          photos.first,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholderBox(context),
        ),
      );
    }
    return _placeholderBox(context);
  }

  Widget _placeholderBox(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 64,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.item});

  final ItemModel item;

  static final _currencyFormat = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
  static final _dateFormat = DateFormat.yMMMd();

  @override
  Widget build(BuildContext context) {
    final v = item.valuation;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row(context, 'CATEGORY', item.category),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'STATUS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
              ),
              StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _row(
            context,
            'SERIAL NUMBER',
            item.serialNumber?.isNotEmpty == true ? item.serialNumber! : '—',
          ),
          const Divider(height: AppSpacing.lg),
          _row(
            context,
            'PURCHASE PRICE',
            v != null ? _currencyFormat.format(v.purchasePrice) : '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'CURRENT VALUE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
              ),
              Text(
                v != null ? _currencyFormat.format(v.currentValue) : '—',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
              ),
            ],
          ),
          if (v?.purchaseDate != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _row(context, 'PURCHASE DATE', _dateFormat.format(v!.purchaseDate!)),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onBackground,
                ),
          ),
        ),
      ],
    );
  }
}
