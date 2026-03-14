import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../inventory/data/models/item_model.dart';
import '../domain/wardrobe_notifier.dart';
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

  String _selectedType = 'all';
  String _selectedCleaningStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(wardrobeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
            _FiltersRow(
              values: _typeFilters,
              selected: _selectedType,
              onSelected: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            _FiltersRow(
              values: _cleaningFilters,
              selected: _selectedCleaningStatus,
              onSelected: (value) =>
                  setState(() => _selectedCleaningStatus = value),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: state.when(
                data: (items) {
                  final filtered = _applyFilters(items);
                  if (filtered.isEmpty) return const _WardrobeEmptyState();
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(wardrobeNotifierProvider.notifier).refresh(),
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: AppSpacing.sm,
                            mainAxisSpacing: AppSpacing.sm,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return WardrobeItemCard(
                          item: item,
                          onTap: () => context.push('/items/${item.id}'),
                          onStatusTap: () => _showCleaningStatusPicker(item),
                        );
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
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
    return items.where((item) {
      if (item.category != 'wardrobe') return false;
      final attrs = item.wardrobeAttributes;
      final matchesType = _selectedType == 'all' || attrs.type == _selectedType;
      final matchesCleaning =
          _selectedCleaningStatus == 'all' ||
          attrs.cleaningStatus == _selectedCleaningStatus;
      return matchesType && matchesCleaning;
    }).toList();
  }

  Future<void> _showCleaningStatusPicker(ItemModel item) async {
    const labels = <String, String>{
      'clean': 'Clean',
      'needs_cleaning': 'Needs Cleaning',
      'at_dry_cleaner': 'At Dry Cleaner',
    };

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: labels.entries.map((entry) {
              final current = item.wardrobeAttributes.cleaningStatus;
              final isSelected = current == entry.key;
              return ListTile(
                leading: _StatusDot(status: entry.key),
                title: Text(
                  entry.value,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.accent)
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

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final Map<String, String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values.entries.map((entry) {
          final isSelected = selected == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              showCheckmark: false,
              selectedColor: AppColors.accent.withValues(alpha: 0.15),
              backgroundColor: AppColors.surfaceVariant,
              side: BorderSide(
                color: isSelected ? AppColors.accent : Colors.white10,
                width: 0.5,
              ),
              labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.onBackground.withValues(alpha: 0.85),
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
