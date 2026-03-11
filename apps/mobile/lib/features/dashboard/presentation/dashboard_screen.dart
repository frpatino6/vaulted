import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/domain/properties_notifier.dart';

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
          SliverToBoxAdapter(
            child: _DashboardHeader(),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
              child: DashboardQuickActions(),
            ),
          ),
          propertiesState.when(
            data: (list) {
              if (list.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RECENT PROPERTIES',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppColors.onSurfaceVariant.withOpacity(0.6),
                              fontSize: 12.0,
                              letterSpacing: 1.5,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ...list.take(3).map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: DashboardPropertyCard(property: p, itemCount: null),
                          )),
                      if (list.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: TextButton(
                            onPressed: () => context.push('/properties'),
                            child: Text(
                              'See all properties',
                              style: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.6)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
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
}

/// Clean welcome: small greeting + user name in Playfair Display + avatar.
class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: replace with ref.watch(userProvider)?.displayName when user API exists
    const String displayName = 'Guest';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg + 8, AppSpacing.md, 0),
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
                  style: AppTypography.displaySerif.copyWith(color: AppColors.onBackground),
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

/// Quick Actions: 2x2 grid, outlined icons, light feel, no heavy backgrounds.
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
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.4,
          children: [
            _QuickActionTile(
              icon: Icons.home_work_outlined,
              label: 'Properties',
              onTap: () => context.push('/properties'),
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
        highlightColor: Colors.white10.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF252525),
                Color(0xFF1E1E1E),
              ],
            ),
            border: Border.all(color: Colors.white24, width: 0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.accentBright, size: 28),
              const SizedBox(height: AppSpacing.sm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurface.withOpacity(0.9),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Property card: background image + dark gradient overlay, ClipRRect 20,
/// name + location at bottom, elegant "Primary" badge with fine gold border.
class DashboardPropertyCard extends StatelessWidget {
  const DashboardPropertyCard({super.key, required this.property, this.itemCount});

  final PropertyModel property;
  /// Total items inventoried in this property. When null, shows "— items".
  final int? itemCount;

  String get _typeLabel => switch (property.type) {
        'primary' => 'Primary',
        'vacation' => 'Vacation',
        _ => 'Rental',
      };

  String get _location =>
      '${property.address.city}, ${property.address.state}';

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
                // Dark gradient overlay for legibility
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.3, 0.6, 1.0],
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
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accent.withOpacity(0.8),
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
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          itemCount != null ? '$itemCount items' : '— items',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                        ),
                      ),
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
          colors: [
            Color(0xFF2C2C2C),
            Color(0xFF121212),
          ],
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
