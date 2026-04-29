import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/notifications_provider.dart';

class NotificationPreferencesPage extends ConsumerStatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  ConsumerState<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

class _NotificationPreferencesPageState
    extends ConsumerState<NotificationPreferencesPage> {
  bool _initialLoadCompleted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // The AsyncNotifier builds automatically when first watched.
      // We listen for the first resolved state to flip the skeleton flag.
      ref
          .read(notificationPreferencesProvider.future)
          .whenComplete(() {
        if (mounted) setState(() => _initialLoadCompleted = true);
      });
    });
  }

  Future<void> _toggle(String key, bool value) async {
    try {
      await ref
          .read(notificationPreferencesProvider.notifier)
          .updatePreferences({key: value});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save preference. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncPrefs = ref.watch(notificationPreferencesProvider);

    final showSkeleton = !_initialLoadCompleted &&
        (asyncPrefs is AsyncLoading || asyncPrefs is AsyncData);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.onBackground,
        title: Text(
          'Notification Preferences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.onBackground,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncPrefs.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppColors.onSurfaceVariant),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Could not load preferences.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onBackground,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(notificationPreferencesProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (prefs) => showSkeleton
            ? _buildSkeleton()
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _SectionLabel(label: 'Channels'),
                  const SizedBox(height: AppSpacing.sm),
                  _PrefsCard(
                    children: [
                      _PrefTile(
                        icon: Icons.notifications_outlined,
                        title: 'Push Notifications',
                        subtitle: 'Receive alerts on this device',
                        value: prefs.pushEnabled,
                        onChanged: (v) => _toggle('pushEnabled', v),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _PrefTile(
                        icon: Icons.email_outlined,
                        title: 'Email Notifications',
                        subtitle: 'Receive alerts by email',
                        value: prefs.emailEnabled,
                        onChanged: (v) => _toggle('emailEnabled', v),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SectionLabel(label: 'Alert types'),
                  const SizedBox(height: AppSpacing.sm),
                  _PrefsCard(
                    children: [
                      _PrefTile(
                        icon: Icons.local_laundry_service_outlined,
                        title: 'Dry Cleaning Overdue',
                        subtitle: 'Items past their expected return date',
                        value: prefs.dryCleaningOverdue,
                        onChanged: (v) => _toggle('dryCleaningOverdue', v),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _PrefTile(
                        icon: Icons.build_outlined,
                        title: 'Maintenance Due',
                        subtitle: 'Scheduled maintenance reminders',
                        value: prefs.maintenanceDue,
                        onChanged: (v) => _toggle('maintenanceDue', v),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      _PrefTile(
                        icon: Icons.add_circle_outline,
                        title: 'Item Added',
                        subtitle: 'When a new item is cataloged',
                        value: prefs.itemAdded,
                        onChanged: (v) => _toggle('itemAdded', v),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _skeletonLabel(),
        const SizedBox(height: AppSpacing.sm),
        _skeletonCard(rows: 2),
        const SizedBox(height: AppSpacing.lg),
        _skeletonLabel(),
        const SizedBox(height: AppSpacing.sm),
        _skeletonCard(rows: 3),
      ],
    );
  }

  Widget _skeletonLabel() {
    return Container(
      height: 14,
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _skeletonCard({required int rows}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (i) {
          return Column(
            children: [
              if (i > 0) const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 13,
                            width: 140,
                            decoration: BoxDecoration(
                              color: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 11,
                            width: 200,
                            decoration: BoxDecoration(
                              color: AppColors.onSurfaceVariant
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 24,
                      decoration: BoxDecoration(
                        color:
                            AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        }),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.accent,
            letterSpacing: 1,
          ),
    );
  }
}

class _PrefsCard extends StatelessWidget {
  const _PrefsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _PrefTile extends StatelessWidget {
  const _PrefTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      tileColor: Colors.transparent,
      secondary: Icon(icon, color: AppColors.accent, size: 24),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onBackground,
            ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accent,
    );
  }
}
