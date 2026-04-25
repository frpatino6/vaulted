import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../data/at_laundry_model.dart';
import '../data/dry_cleaning_repository.dart';
import '../data/dry_cleaning_repository_provider.dart';
import '../domain/at_laundry_notifier.dart';
import '../domain/wardrobe_stats_provider.dart';

class AtLaundryScreen extends ConsumerStatefulWidget {
  const AtLaundryScreen({super.key});

  @override
  ConsumerState<AtLaundryScreen> createState() => _AtLaundryScreenState();
}

class _AtLaundryScreenState extends ConsumerState<AtLaundryScreen> {
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(atLaundryNotifierProvider.notifier)
          .refresh()
          .whenComplete(() {
            if (mounted) setState(() => _initialLoadCompleted = true);
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<AtLaundryData?> state =
        ref.watch(atLaundryNotifierProvider);

    final bool showInitialSkeleton =
        !_initialLoadCompleted && state is! AsyncError;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.onBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'At the Laundry',
          style: AppTypography.titleSerif.copyWith(
            color: AppColors.onBackground,
          ),
        ),
      ),
      body: state.when(
        data: (AtLaundryData? data) {
          if (showInitialSkeleton || data == null) {
            return _buildSkeleton();
          }
          return _buildContent(data);
        },
        loading: () => _buildSkeleton(),
        error: (Object error, StackTrace _) => Center(
          child: Text(
            'Unable to load laundry items',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return const AppScreenSkeleton(
      showHeader: true,
      cardCount: 3,
    );
  }

  Widget _buildContent(AtLaundryData data) {
    final bool hasItems = data.totalItems > 0;

    if (!hasItems) {
      return const _EmptyState();
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(atLaundryNotifierProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          if (data.overdueItems > 0)
            SliverToBoxAdapter(
              child: _OverdueBanner(
                overdueCount: data.overdueItems,
                thresholdDays: data.overdueThresholdDays,
              ),
            ),
          SliverToBoxAdapter(
            child: _SummaryHeader(
              totalItems: data.totalItems,
              propertyCount: data.byProperty.length,
            ),
          ),
          for (final AtLaundryProperty property in data.byProperty) ...[
            SliverToBoxAdapter(
              child: _PropertySectionHeader(name: property.propertyName),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  return _LaundryItemTile(
                    item: property.items[index],
                    onReturned: () => _markReturned(property.items[index]),
                  );
                },
                childCount: property.items.length,
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }

  Future<void> _markReturned(AtLaundryItem item) async {
    try {
      final DryCleaningRepository repo =
          ref.read(dryCleaningRepositoryProvider);
      await repo.markReturned(item.recordId);
      await ref.read(atLaundryNotifierProvider.notifier).refresh();
      ref.invalidate(wardrobeStatsProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to mark item as returned'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({
    required this.overdueCount,
    required this.thresholdDays,
  });

  final int overdueCount;
  final int thresholdDays;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: AppColors.error, width: 3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_outlined,
            color: AppColors.error,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '$overdueCount ${overdueCount == 1 ? 'item has' : 'items have'} been at the laundry for over $thresholdDays days',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalItems,
    required this.propertyCount,
  });

  final int totalItems;
  final int propertyCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        '$totalItems ${totalItems == 1 ? 'item' : 'items'} · $propertyCount ${propertyCount == 1 ? 'property' : 'properties'}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _PropertySectionHeader extends StatelessWidget {
  const _PropertySectionHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Text(
        name.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.accent,
              letterSpacing: 0.8,
            ),
      ),
    );
  }
}

class _LaundryItemTile extends StatelessWidget {
  const _LaundryItemTile({
    required this.item,
    required this.onReturned,
  });

  final AtLaundryItem item;
  final VoidCallback onReturned;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: item.photoUrl != null
              ? CachedNetworkImage(
                  imageUrl: item.photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _ItemPhotoPlaceholder(),
                  errorWidget: (_, _, _) => const _ItemPhotoPlaceholder(),
                )
              : const _ItemPhotoPlaceholder(),
        ),
      ),
      title: Text(
        item.itemName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: Text(
        item.cleanerName ?? 'Unknown cleaner',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _DaysBadge(days: item.daysAtCleaner, isOverdue: item.isOverdue),
          const SizedBox(height: AppSpacing.xs),
          FilledButton.tonal(
            onPressed: onReturned,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: Theme.of(context).textTheme.labelSmall,
              minimumSize: Size.zero,
            ),
            child: const Text('Returned'),
          ),
        ],
      ),
    );
  }
}

class _DaysBadge extends StatelessWidget {
  const _DaysBadge({required this.days, required this.isOverdue});

  final int days;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (days <= 3) {
      color = Colors.blueGrey.shade300;
    } else if (days <= 7) {
      color = Colors.amber.shade400;
    } else {
      color = AppColors.error;
    }

    final String label = days > 7 ? '$days days ⚠' : '$days days';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _ItemPhotoPlaceholder extends StatelessWidget {
  const _ItemPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF232323),
      child: Icon(
        Icons.checkroom_outlined,
        color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
        size: 24,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_laundry_service_outlined,
            size: 64,
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nothing at the laundry',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
