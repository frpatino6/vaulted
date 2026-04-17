import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../users/domain/current_user_jwt.dart';

/// Settings: Team management, Appearance (theme), and Account actions.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = currentUserRole() ?? 'guest';
    final canManageTeam = role == 'owner' || role == 'manager';
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      // S7: flat AppBar matching the rest of the app
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.onBackground,
        title: Text(
          'Settings',
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
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // S1: Team section first (most important for this audience)
          if (canManageTeam) ...[
            _SectionLabel(label: 'Team'),
            const SizedBox(height: AppSpacing.sm),
            // S3: section wrapped in card container
            _SectionCard(
              children: [
                ListTile(
                  tileColor: Colors.transparent,
                  leading: Icon(
                    Icons.people_outline,
                    color: AppColors.accent,
                    size: 24,
                  ),
                  title: Text(
                    'Team members',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onBackground,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceVariant,
                  ),
                  onTap: () => context.push('/settings/users'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // S1: Appearance section second
          _SectionLabel(label: 'Appearance'),
          const SizedBox(height: AppSpacing.sm),
          // S3: appearance tiles in card container
          _SectionCard(
            children: [
              _ThemeModeTile(
                value: ThemeMode.light,
                label: 'Light',
                icon: Icons.light_mode_outlined,
                current: themeMode,
                onSelected: () =>
                    ref.read(themeModeProvider.notifier).state = ThemeMode.light,
              ),
              const Divider(color: Colors.white10, height: 1),
              _ThemeModeTile(
                value: ThemeMode.dark,
                label: 'Dark',
                icon: Icons.dark_mode_outlined,
                current: themeMode,
                onSelected: () =>
                    ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
              ),
              const Divider(color: Colors.white10, height: 1),
              _ThemeModeTile(
                value: ThemeMode.system,
                label: 'System',
                icon: Icons.brightness_auto_outlined,
                current: themeMode,
                onSelected: () =>
                    ref.read(themeModeProvider.notifier).state =
                        ThemeMode.system,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // S1: Account section last
          _SectionLabel(label: 'Account'),
          // S4: subtle visual separation before the danger card
          const Divider(color: Colors.white10),
          const SizedBox(height: AppSpacing.sm),
          // S3 + S4: account card with red-tinted border
          _SectionCard(
            borderColor: AppColors.error.withValues(alpha: 0.2),
            children: [
              // S6: Notifications placeholder
              ListTile(
                tileColor: Colors.transparent,
                leading: Icon(
                  Icons.notifications_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
                title: Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                ),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              // S6: Support placeholder
              ListTile(
                tileColor: Colors.transparent,
                leading: Icon(
                  Icons.help_outline,
                  color: AppColors.onSurfaceVariant,
                ),
                title: Text(
                  'Support',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onBackground,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                ),
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                ),
              ),
              const Divider(color: Colors.white10, height: 1),
              // Sign out
              ListTile(
                tileColor: Colors.transparent,
                leading: Icon(Icons.logout, color: AppColors.error, size: 24),
                title: Text(
                  'Sign out',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.error,
                  ),
                ),
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),

          // S5: App version footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text(
                'Vaulted · v1.0.0',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.4),
                  fontSize: 11,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }
}

/// Section header label rendered outside the card.
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

/// S3: card container wrapping a section's ListTiles.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.children,
    this.borderColor,
  });

  final List<Widget> children;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor ??
              AppColors.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

class _ThemeModeTile extends StatelessWidget {
  const _ThemeModeTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.current,
    required this.onSelected,
  });

  final ThemeMode value;
  final String label;
  final IconData icon;
  final ThemeMode current;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;

    return ListTile(
      tileColor: Colors.transparent,
      leading: Icon(icon, color: AppColors.accent, size: 24),
      title: Text(
        label,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: AppColors.onBackground,
          fontWeight: isSelected ? FontWeight.w600 : null,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppColors.accent, size: 22)
          : null,
      onTap: onSelected,
    );
  }
}
