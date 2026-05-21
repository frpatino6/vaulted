import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
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
import '../../../core/privacy/privacy_mode_provider.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../../features/notifications/presentation/providers/notifications_list_provider.dart';
import 'widgets/dashboard_header.dart';

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
      bottomNavigationBar: AppBottomNav(currentTab: AppTab.home),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () async {
          ref.read(propertiesNotifierProvider.notifier).load();
          ref.read(dashboardNotifierProvider.notifier).load();
          ref.read(maintenanceListNotifierProvider.notifier).load();
          ref.read(movementListNotifierProvider.notifier).load();
          ref.invalidate(notificationsListProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              automaticallyImplyLeading: false,
              toolbarHeight: 76,
              backgroundColor: AppColors.backgroundElevated,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              titleSpacing: 0,
              title: const DashboardHeader(),
            ),
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
              icon: Icons.help_outline_rounded,
              label: 'Vaulted Guide',
              onTap: () => context.push('/help-chat?screen=dashboard'),
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
            _QuickActionTile(
              icon: Icons.assignment_outlined,
              label: 'Orchestrator',
              onTap: () => context.push('/orchestrator'),
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
class _StatsSection extends ConsumerWidget {
  const _StatsSection({required this.data, required this.canSeeValues});

  final DashboardModel data;
  final bool canSeeValues;

  static final _currency = NumberFormat.currency(
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPrivate = ref.watch(privacyModeProvider).valueOrNull ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WARDROBE OVERVIEW',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 10,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.5,
          children: [
            if (canSeeValues)
              _OverviewCard(
                icon: Icons.diamond_outlined,
                value: isPrivate ? '●●●●●' : _currency.format(data.totalValuation),
                label: 'Total Value',
                valueColor: AppColors.accent,
                iconColor: AppColors.accent,
                borderColor: AppColors.accent.withValues(alpha: 0.3),
                onTap: () => context.push('/assets'),
              ),
            _OverviewCard(
              icon: Icons.inventory_2_outlined,
              value: '${data.totalItems}',
              label: 'Total Items',
              valueColor: AppColors.onBackground,
              iconColor: AppColors.onSurfaceVariant,
              borderColor: AppColors.onSurfaceVariant.withValues(alpha: 0.12),
              onTap: () => context.push('/assets'),
            ),
          ],
        ),
        if (data.itemsByStatus.isNotEmpty) ...[
          const SizedBox(height: 16.0),
          _StatusRow(itemsByStatus: data.itemsByStatus),
        ],
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.valueColor,
    required this.iconColor,
    required this.borderColor,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color valueColor;
  final Color iconColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: AppColors.accent.withValues(alpha: 0.08),
        highlightColor: AppColors.accent.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
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

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: entries.map((e) {
        final dotColor = _statusColors[e.key] ?? AppColors.onSurfaceVariant;
        final label = e.key[0].toUpperCase() + e.key.substring(1);
        return ActionChip(
          avatar: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          label: Text('${e.value} $label'),
          backgroundColor: AppColors.surface,
          side: BorderSide(
            color: AppColors.onSurfaceVariant.withValues(alpha: 0.2),
          ),
          labelStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          labelPadding: const EdgeInsets.only(left: 2, right: 4),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          onPressed: () => context.push('/assets?status=${e.key}'),
        );
      }).toList(),
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
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/maintenance'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MAINTENANCE ALERTS',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 10,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AlertCountTile(
                          count: overdue,
                          label: 'Overdue',
                          color: const Color(0xFFCF6679),
                          onTap: () => context.push('/maintenance'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _AlertCountTile(
                          count: dueSoon,
                          label: 'Due this week',
                          color: const Color(0xFFD4AF37),
                          onTap: () => context.push('/maintenance'),
                        ),
                      ),
                    ],
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
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => context.push('/movements'),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ACTIVE OPERATIONS (${active.length})',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                            fontSize: 10,
                            letterSpacing: 2.0,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  itemCount: active.length,
                  separatorBuilder: (_, __) => const Divider(
                    color: Colors.white10,
                    height: 1,
                    indent: AppSpacing.md,
                    endIndent: AppSpacing.md,
                  ),
                  itemBuilder: (_, i) => _OperationListItem(movement: active[i]),
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

class _OperationListItem extends StatelessWidget {
  const _OperationListItem({required this.movement});

  final MovementModel movement;

  @override
  Widget build(BuildContext context) {
    final typeIcon = _typeIcon(movement.operationType);
    final typeColor = _typeColor(movement.operationType);
    final isDraft = movement.isDraft;
    final itemCount = movement.items.length;
    final subtitle = isDraft
        ? '$itemCount item${itemCount == 1 ? '' : 's'}'
        : '$itemCount item${itemCount == 1 ? '' : 's'} · ${movement.returnedCount}/$itemCount returned';

    return InkWell(
      onTap: () => context.push(
        isDraft
            ? '/movements/${movement.id}/scan'
            : '/movements/${movement.id}',
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(typeIcon, color: typeColor, size: 18),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDraft
                    ? const Color(0xFF9E9E9E)
                    : const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isDraft ? 'DRAFT' : 'ACTIVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                movement.title,
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 16,
          color: AppColors.onSurfaceVariant,
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
    this.onTap,
  });

  final int count;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        splashColor: color.withValues(alpha: 0.15),
        highlightColor: color.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
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
        ),
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
