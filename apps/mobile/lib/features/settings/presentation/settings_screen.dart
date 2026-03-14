import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../users/domain/current_user_jwt.dart';

/// Settings: theme mode (Light / Dark / System) and Team link.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = currentUserRole() ?? 'guest';
    final canManageTeam = role == 'owner' || role == 'manager';
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
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
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.accent,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ThemeModeTile(
            value: ThemeMode.light,
            label: 'Light',
            icon: Icons.light_mode_outlined,
            current: themeMode,
            onSelected: () =>
                ref.read(themeModeProvider.notifier).state = ThemeMode.light,
          ),
          _ThemeModeTile(
            value: ThemeMode.dark,
            label: 'Dark',
            icon: Icons.dark_mode_outlined,
            current: themeMode,
            onSelected: () =>
                ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
          ),
          _ThemeModeTile(
            value: ThemeMode.system,
            label: 'System',
            icon: Icons.brightness_auto_outlined,
            current: themeMode,
            onSelected: () =>
                ref.read(themeModeProvider.notifier).state = ThemeMode.system,
          ),
          if (canManageTeam) ...[
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Team',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accent,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Icon(
                Icons.people_outline,
                color: AppColors.accent,
                size: 24,
              ),
              title: Text(
                'Team members',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.onBackground),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppColors.onSurfaceVariant,
              ),
              onTap: () => context.push('/settings/users'),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Features',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.accent,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: Icon(Icons.checkroom_outlined, color: AppColors.accent),
            title: Text(
              'Wardrobe',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.onBackground),
            ),
            trailing: const Icon(
              Icons.chevron_right,
              color: AppColors.onSurfaceVariant,
            ),
            onTap: () => context.push('/wardrobe'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Account',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.accent,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.error, size: 24),
            title: Text(
              'Sign out',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.error),
            ),
            onTap: () => _confirmLogout(context, ref),
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
