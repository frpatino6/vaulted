import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/property_card.dart';
import '../domain/properties_notifier.dart';
import 'add_property_sheet.dart';

class PropertiesScreen extends ConsumerWidget {
  const PropertiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(propertiesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.background,
            title: Text(
              'Properties',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    color: AppColors.onBackground,
                  ),
            ),
          ),
          asyncState.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(onAddProperty: () => _showAddSheet(context, ref)),
                );
              }
              return SliverFillRemaining(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(propertiesNotifierProvider.notifier).load(),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.md,
                          right: AppSpacing.md,
                          bottom: AppSpacing.xxl,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: PropertyCard(property: list[index]),
                            ),
                            childCount: list.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => SliverFillRemaining(
              child: _ErrorState(
                message: PropertiesNotifier.message(err),
                isMfaRequired: PropertiesNotifier.message(err).toLowerCase().contains('mfa'),
                onRetry: () => ref.read(propertiesNotifierProvider.notifier).load(),
                onMfa: () => context.go('/mfa'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.background,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AddPropertySheet(),
    ).then((created) {
      if (created == true) {
        ref.read(propertiesNotifierProvider.notifier).load();
      }
    });
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddProperty});

  final VoidCallback onAddProperty;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_work_outlined,
              size: 72,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No properties yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onBackground,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to add your first property',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onAddProperty,
              icon: const Icon(Icons.add),
              label: const Text('Add property'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.isMfaRequired,
    required this.onRetry,
    required this.onMfa,
  });

  final String message;
  final bool isMfaRequired;
  final VoidCallback onRetry;
  final VoidCallback onMfa;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
              isMfaRequired
                  ? 'MFA verification required to access properties.'
                  : message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onBackground,
                  ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (isMfaRequired)
              FilledButton(
                onPressed: onMfa,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.background,
                ),
                child: const Text('Complete MFA'),
              )
            else
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
