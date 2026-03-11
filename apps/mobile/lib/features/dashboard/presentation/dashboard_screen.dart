import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/property_card.dart';
import '../../properties/domain/properties_notifier.dart';

/// Dashboard: greeting, gold divider, navigation cards (vertical list), footer.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesState = ref.watch(propertiesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onBackground,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Divider(height: 1, color: AppColors.accent, thickness: 1),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _NavCard(
                  icon: Icons.home_work_outlined,
                  title: 'Properties',
                  subtitle: 'Manage your properties and locations',
                  onTap: () => context.push('/properties'),
                ),
                const SizedBox(height: AppSpacing.sm),
                _NavCard(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory',
                  subtitle: 'Items and catalog',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                _NavCard(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Reports',
                  subtitle: 'Export and reports',
                  onTap: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                _NavCard(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Account and preferences',
                  onTap: () => context.push('/settings'),
                ),
              ]),
            ),
          ),
          propertiesState.when(
            data: (list) {
              if (list.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent properties',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.onSurfaceVariant,
                              letterSpacing: 1,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...list.take(3).map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: PropertyCard(property: p),
                          )),
                      if (list.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: TextButton(
                            onPressed: () => context.push('/properties'),
                            child: const Text('See all properties'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (e, st) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: _FooterText(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Vaulted — Private',
      style: TextStyle(
        color: AppColors.onSurfaceVariant,
        fontSize: 11,
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Icon(icon, color: AppColors.accent, size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.onBackground,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
