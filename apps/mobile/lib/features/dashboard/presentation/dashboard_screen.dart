import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/domain/properties_notifier.dart';
import '../../properties/presentation/add_property_sheet.dart';

/// Dashboard: clean welcome header, Quick Actions grid, recent property cards.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesState = ref.watch(propertiesNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundElevated,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _DashboardHeader()),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: DashboardQuickActions(),
            ),
          ),
          propertiesState.when(
            data: (list) {
              if (list.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyPropertiesCta(
                    onAddProperty: () => _showAddPropertySheet(context, ref),
                  ),
                );
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'RECENT PROPERTIES',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant.withOpacity(
                                    0.6,
                                  ),
                                  fontSize: 12.0,
                                  letterSpacing: 1.5,
                                ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _showAddPropertySheet(context, ref),
                            icon: Icon(
                              Icons.add,
                              size: 18,
                              color: AppColors.accent,
                            ),
                            label: Text(
                              'Add',
                              style: TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...list
                          .take(3)
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: DashboardPropertyCard(
                                property: p,
                                itemCount: null,
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: _FooterText()),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPropertySheet(BuildContext context, WidgetRef ref) {
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

/// Empty state: CTA to add first property from dashboard.
class _EmptyPropertiesCta extends StatelessWidget {
  const _EmptyPropertiesCta({required this.onAddProperty});

  final VoidCallback onAddProperty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onAddProperty,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.lg,
              horizontal: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.onSurfaceVariant.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 40,
                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add your first property',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppColors.onBackground),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create a property to organize floors, rooms and items.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add_circle_outline,
                  color: AppColors.accent,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Clean welcome: small greeting + user name in Playfair Display + avatar.
class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: replace with ref.watch(userProvider)?.displayName when user API exists
    const String displayName = 'Guest';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg + 8,
        AppSpacing.md,
        0,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning,',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant.withOpacity(0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: AppTypography.displaySerif.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white10,
              border: Border.all(
                color: AppColors.accent.withOpacity(0.6),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.person_outline,
              size: 20,
              color: AppColors.accentBright,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick Actions: 2x2 grid, luxury look, equal square cards.
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
            fontSize: 12.0,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            childAspectRatio: 1.0,
            padding: EdgeInsets.zero,
            children: [
              _QuickActionTile(
                icon: Icons.home_work_outlined,
                label: 'Properties',
                onTap: () => context.go('/dashboard'),
              ),
              _QuickActionTile(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory',
                onTap: () {},
              ),
              _QuickActionTile(
                icon: Icons.picture_as_pdf_outlined,
                label: 'Reports',
                onTap: () {},
              ),
              _QuickActionTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white10,
        highlightColor: Colors.white12,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            color: const Color(0xFF1E1E1E),
            border: Border.all(color: Colors.white10, width: 0.5),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.accentBright, size: 28.0),
                const SizedBox(height: 12.0),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
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

/// Property card: background image + dark gradient overlay, ClipRRect 20,
/// name + location at bottom, elegant "Primary" badge with fine gold border.
class DashboardPropertyCard extends StatelessWidget {
  const DashboardPropertyCard({
    super.key,
    required this.property,
    this.itemCount,
  });

  final PropertyModel property;

  /// Total items inventoried in this property. When null, shows "— items".
  final int? itemCount;

  String get _typeLabel => switch (property.type) {
    'primary' => 'Primary',
    'vacation' => 'Vacation',
    _ => 'Rental',
  };

  String get _location => '${property.address.city}, ${property.address.state}';

  @override
  Widget build(BuildContext context) {
    final hasImage = property.photos.isNotEmpty;
    final imageUrl = hasImage ? property.photos.first : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/properties/${property.id}'),
          splashColor: Colors.white10,
          highlightColor: Colors.white10.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image or gradient
                if (imageUrl != null && imageUrl.isNotEmpty)
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildPlaceholderGradient(),
                  )
                else
                  _buildPlaceholderGradient(),
                // Dark gradient overlay for legibility (slightly lighter at bottom so text pops)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0.35, 0.65, 1.0],
                    ),
                  ),
                ),
                // Primary badge (top-right)
                if (property.type == 'primary')
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _typeLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.accentLight,
                        ),
                      ),
                    ),
                  ),
                // Name + location + items count at bottom
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              property.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onBackground,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _location,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (itemCount != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '$itemCount items',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderGradient() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2C), Color(0xFF121212)],
        ),
      ),
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline,
          size: 12,
          color: AppColors.onSurfaceVariant.withOpacity(0.6),
        ),
        const SizedBox(width: 8),
        Text(
          'Vaulted — Private',
          style: TextStyle(
            color: AppColors.onSurfaceVariant.withOpacity(0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
