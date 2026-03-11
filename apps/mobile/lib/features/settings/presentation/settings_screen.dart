import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_mode_provider.dart';

/// Settings: theme mode (Light / Dark / System) and future options.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            onSelected: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
          ),
          _ThemeModeTile(
            value: ThemeMode.dark,
            label: 'Dark',
            icon: Icons.dark_mode_outlined,
            current: themeMode,
            onSelected: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
          ),
          _ThemeModeTile(
            value: ThemeMode.system,
            label: 'System',
            icon: Icons.brightness_auto_outlined,
            current: themeMode,
            onSelected: () => ref.read(themeModeProvider.notifier).state = ThemeMode.system,
          ),
        ],
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
