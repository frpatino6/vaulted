import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';

import '../../../core/storage/auth_token_store.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../users/domain/current_user_jwt.dart';
import '../../maintenance/data/models/maintenance_model.dart';
import '../../maintenance/domain/maintenance_notifier.dart';
import '../../properties/data/models/property_model.dart';
import '../../properties/domain/properties_notifier.dart';
import '../../properties/presentation/add_property_sheet.dart';
import '../data/models/dashboard_model.dart';
import '../domain/dashboard_notifier.dart';
import '../../movements/data/models/movement_model.dart';
import '../../movements/domain/movement_list_notifier.dart';
import '../../../features/presence/presentation/widgets/online_users_count.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/app_bottom_nav.dart';

/// Dashboard: clean welcome header, Quick Actions grid, recent property cards.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = currentUserRole() ?? 'guest';
    final canManageProperties = role == 'owner' || role == 'manager';
    final canSeeValues = role == 'owner' || role == 'auditor';
    final propertiesState = ref.watch(propertiesNotifierProvider);
    final dashboardState = ref.watch(dashboardNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundElevated,
      bottomNavigationBar: const AppBottomNav(currentTab: AppTab.home),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.read(propertiesNotifierProvider.notifier).load();
          ref.read(dashboardNotifierProvider.notifier).load();
          ref.read(maintenanceListNotifierProvider.notifier).load();
          ref.read(movementListNotifierProvider.notifier).load();
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _DashboardHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OnlineUsersCount(),
                  ],
                ),
              ),
            ),
            // Stats section — loading skeleton or real data
            if (dashboardState.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (dashboardState.hasValue && dashboardState.value != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    0,
                  ),
                  child: _StatsSection(
                    data: dashboardState.value!,
                    canSeeValues: canSeeValues,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: _MaintenanceAlertCard()),
            const SliverToBoxAdapter(child: _ActiveOperationsCard()),
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
                  if (!canManageProperties) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.lg,
                        ),
                        child: Center(
                          child: Text(
                            'No properties assigned to your account',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    );
                  }
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
                              'YOUR PROPERTIES',
                              style: Theme.of(
                                context,
                              ).textTheme.titleSmall?.copyWith(
                                color: AppColors.onSurfaceVariant.withValues(
                                  alpha: 0.6,
                                ),
                                fontSize: 12.0,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (canManageProperties)
                              TextButton.icon(
                                onPressed:
                                    () => _showAddPropertySheet(context, ref),
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
                        ...list.map(
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
              loading:
                  () => const SliverToBoxAdapter(
                    child: AppScreenSkeleton(
                      showHeader: false,
                      scrollable: false,
                      cardCount: 2,
                    ),
                  ),
              error:
                  (_, _) => SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Could not load properties',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            TextButton(
                              onPressed:
                                  () =>
                                      ref
                                          .read(
                                            propertiesNotifierProvider.notifier,
                                          )
                                          .load(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: _FooterText()),
              ),
            ),
          ],
        ),
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
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.home_work_outlined,
                  size: 40,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
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

/// Clean welcome: small greeting + avatar that opens user menu.
class _DashboardHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final email = _emailFromJwt() ?? 'Guest';
    final role = currentUserRole() ?? 'guest';
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12
            ? 'Good morning,'
            : hour < 18
            ? 'Good afternoon,'
            : 'Good evening,';

    // D4: try name claim from JWT first, fall back to capitalized email prefix
    final firstName =
        _firstNameFromJwt() ??
        () {
          final prefix = email.split('@').first;
          if (prefix.isEmpty) return 'Guest';
          return prefix[0].toUpperCase() + prefix.substring(1);
        }();

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
                  greeting,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  firstName,
                  style: AppTypography.displaySerif.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
              ],
            ),
          ),
          // D2: 48dp touch target wrapping the 40dp avatar container
          SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: GestureDetector(
                onTap: () => _showUserMenu(context, ref, email, role),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white10,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      email.isNotEmpty ? email[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppColors.accentBright,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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

  String? _emailFromJwt() {
    final token = AuthTokenStore.instance.getToken();
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      return jsonDecode(payload)['email'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// D4: extract the name claim from the JWT payload.
  String? _firstNameFromJwt() {
    final token = AuthTokenStore.instance.getToken();
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final name = decoded['name'] as String?;
      if (name == null || name.trim().isEmpty) return null;
      final first = name.trim().split(' ').first;
      if (first.isEmpty) return null;
      return first[0].toUpperCase() + first.substring(1);
    } catch (_) {
      return null;
    }
  }

  void _showUserMenu(
    BuildContext context,
    WidgetRef ref,
    String email,
    String role,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceVariant,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            email.isNotEmpty ? email[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              email,
                              style: Theme.of(
                                ctx,
                              ).textTheme.bodyMedium?.copyWith(
                                color: AppColors.onBackground,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              role[0].toUpperCase() + role.substring(1),
                              style: Theme.of(ctx).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: Icon(
                      Icons.build_circle_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    title: Text(
                      'Maintenance',
                      style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/maintenance');
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings_outlined,
                      color: AppColors.onSurfaceVariant,
                    ),
                    title: Text(
                      'Settings',
                      style: Theme.of(ctx).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onBackground,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      context.push('/settings');
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.logout, color: AppColors.error),
                    title: Text(
                      'Sign out',
                      style: Theme.of(
                        ctx,
                      ).textTheme.bodyLarge?.copyWith(color: AppColors.error),
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await ref.read(authNotifierProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

/// Quick Actions: 2-column grid, luxury look, equal square cards.
class DashboardQuickActions extends ConsumerWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'QUICK ACTIONS',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 12.0,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16.0),
        // D1: removed wrapping Padding(all:16) — GridView sits flush with parent padding
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 1.0,
          padding: EdgeInsets.zero,
          children: [
            _QuickActionTile(
              icon: Icons.qr_code_scanner_outlined,
              label: 'Scan QR',
              onTap: () => context.push('/scanner'),
            ),
            _QuickActionTile(
              icon: Icons.auto_awesome_outlined,
              label: 'AI Assistant',
              onTap: () => context.push('/chat'),
            ),
            _QuickActionTile(
              icon: Icons.swap_horiz_rounded,
              label: 'Operations',
              onTap: () => context.push('/movements'),
            ),
            _QuickActionTile(
              icon: Icons.build_circle_outlined,
              label: 'Maintenance',
              onTap: () => context.push('/maintenance'),
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
        highlightColor: Colors.white12,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            // D3: replaced const Color(0xFF1E1E1E) → AppColors.surface
            color: AppColors.surface,
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
                    // D3: replaced Colors.white.withValues(alpha:0.9) → AppColors.onBackground
                    color: AppColors.onBackground,
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
/// name + location at bottom, elegant type badge with fine border.
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

  // D8: badge border color per type
  Color get _typeBadgeBorderColor => switch (property.type) {
    'primary' => AppColors.accent,
    'vacation' => const Color(0xFF2196F3),
    _ => AppColors.onSurfaceVariant,
  };

  String get _location => '${property.address.city}, ${property.address.state}';

  @override
  Widget build(BuildContext context) {
    final hasImage = property.photos.isNotEmpty;
    final imageUrl = hasImage ? property.photos.first : null;

    // D8: show badge for primary, vacation, and rental
    final showBadge =
        property.type == 'primary' ||
        property.type == 'vacation' ||
        property.type == 'rental';

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/properties/${property.id}'),
          splashColor: Colors.white10,
          highlightColor: Colors.white10.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
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
                    errorBuilder: (_, _, _) => _buildPlaceholderGradient(),
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
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                      stops: const [0.35, 0.65, 1.0],
                    ),
                  ),
                ),
                // D8: type badge shown for primary, vacation, and rental
                if (showBadge)
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
                          color: _typeBadgeBorderColor.withValues(alpha: 0.8),
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
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
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
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
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
                            style: Theme.of(
                              context,
                            ).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
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
          colors: [Color(0xFF2C2C2C), Color(0xFF121212)],
        ),
      ),
    );
  }
}

/// Portfolio overview: total valuation + total items + status breakdown.
class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.data, required this.canSeeValues});

  final DashboardModel data;
  final bool canSeeValues;

  static final _currency = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PORTFOLIO OVERVIEW',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 10,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            if (canSeeValues) ...[
              Expanded(
                child: _StatCard(
                  label: 'Total Value',
                  value: _currency.format(data.totalValuation),
                  icon: Icons.account_balance_outlined,
                  highlight: true,
                  onTap: () => context.push('/assets'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: _StatCard(
                label: 'Total Items',
                value: '${data.totalItems}',
                icon: Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
        if (data.itemsByStatus.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _StatusRow(itemsByStatus: data.itemsByStatus),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              highlight
                  ? AppColors.accent.withValues(alpha: 0.3)
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: highlight ? AppColors.accent : AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: highlight ? AppColors.accent : AppColors.onBackground,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.accent.withValues(alpha: 0.7),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 8,
                  color: AppColors.accent.withValues(alpha: 0.7),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.itemsByStatus});

  final Map<String, int> itemsByStatus;

  static const _statusColors = {
    'active': Color(0xFF4CAF50),
    'loaned': Color(0xFFFFC107),
    'repair': Color(0xFFFF9800),
    'storage': Color(0xFF2196F3),
    'disposed': Color(0xFF9E9E9E),
  };

  @override
  Widget build(BuildContext context) {
    final entries = itemsByStatus.entries.where((e) => e.value > 0).toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children:
            entries.map((e) {
              final color = _statusColors[e.key] ?? AppColors.onSurfaceVariant;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${e.value} ${e.key}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.onSurface,
                      fontSize: 11,
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Maintenance alert card — shown only when overdue or due-this-week items exist
// ---------------------------------------------------------------------------

class _MaintenanceAlertCard extends ConsumerStatefulWidget {
  const _MaintenanceAlertCard();

  @override
  ConsumerState<_MaintenanceAlertCard> createState() =>
      _MaintenanceAlertCardState();
}

class _MaintenanceAlertCardState extends ConsumerState<_MaintenanceAlertCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(maintenanceListNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceListNotifierProvider);

    return state.when(
      data: (records) {
        final overdue = records.where((r) => r.isOverdue).length;
        final dueSoon = records.where((r) => r.isDueSoon).length;

        if (overdue == 0 && dueSoon == 0) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            0,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFCF6679).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MAINTENANCE ALERTS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 10,
                        letterSpacing: 2.0,
                      ),
                    ),
                    // D6: TextButton replaces GestureDetector
                    TextButton(
                      onPressed: () => context.push('/maintenance'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      child: Text(
                        'See all →',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    if (overdue > 0) ...[
                      Expanded(
                        child: _AlertCountTile(
                          count: overdue,
                          label: 'Overdue',
                          color: const Color(0xFFCF6679),
                        ),
                      ),
                      if (dueSoon > 0) const SizedBox(width: AppSpacing.sm),
                    ],
                    if (dueSoon > 0)
                      Expanded(
                        child: _AlertCountTile(
                          count: dueSoon,
                          label: 'Due this week',
                          color: const Color(0xFFD4AF37),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppSkeletonBox(height: 78, radius: 18),
          ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

// ---------------------------------------------------------------------------
// Active Operations card — shown when there are draft or active movements
// ---------------------------------------------------------------------------

class _ActiveOperationsCard extends ConsumerStatefulWidget {
  const _ActiveOperationsCard();

  @override
  ConsumerState<_ActiveOperationsCard> createState() =>
      _ActiveOperationsCardState();
}

class _ActiveOperationsCardState extends ConsumerState<_ActiveOperationsCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(movementListNotifierProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(movementListNotifierProvider);

    return state.when(
      data: (movements) {
        final active = movements.where((m) => m.isDraft || m.isActive).toList();
        if (active.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            0,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2196F3).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ACTIVE OPERATIONS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 10,
                        letterSpacing: 2.0,
                      ),
                    ),
                    // D6: TextButton replaces GestureDetector
                    TextButton(
                      onPressed: () => context.push('/movements'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      child: Text(
                        'See all →',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                ...active.take(2).map((m) => _OperationRow(movement: m)),
                if (active.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      '+${active.length - 2} more',
                      style: TextStyle(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      loading:
          () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: AppSkeletonBox(height: 96, radius: 18),
          ),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _OperationRow extends StatelessWidget {
  const _OperationRow({required this.movement});

  final MovementModel movement;

  @override
  Widget build(BuildContext context) {
    final typeIcon = _typeIcon(movement.operationType);
    final typeColor = _typeColor(movement.operationType);
    final isDraft = movement.isDraft;

    return GestureDetector(
      onTap:
          () => context.push(
            isDraft
                ? '/movements/${movement.id}/scan'
                : '/movements/${movement.id}',
          ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, color: typeColor, size: 16),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    movement.title,
                    style: TextStyle(
                      color: AppColors.onBackground,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${movement.items.length} item${movement.items.length == 1 ? '' : 's'} · ${isDraft ? 'Draft' : '${movement.returnedCount}/${movement.items.length} returned'}',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isDraft
                        ? const Color(0xFF9E9E9E)
                        : const Color(0xFF2196F3))
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isDraft ? 'DRAFT' : 'ACTIVE',
                style: TextStyle(
                  color:
                      isDraft
                          ? const Color(0xFF9E9E9E)
                          : const Color(0xFF2196F3),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String t) => switch (t) {
    'loan' => Icons.person_outline_rounded,
    'repair' => Icons.build_outlined,
    'disposal' => Icons.delete_outline_rounded,
    _ => Icons.swap_horiz_rounded,
  };

  Color _typeColor(String t) => switch (t) {
    'loan' => const Color(0xFF9C27B0),
    'repair' => const Color(0xFFFF9800),
    'disposal' => const Color(0xFFCF6679),
    _ => const Color(0xFF2196F3),
  };
}

// ---------------------------------------------------------------------------

class _AlertCountTile extends StatelessWidget {
  const _AlertCountTile({
    required this.count,
    required this.label,
    required this.color,
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

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
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Text(
          'Vaulted — Private',
          style: TextStyle(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
