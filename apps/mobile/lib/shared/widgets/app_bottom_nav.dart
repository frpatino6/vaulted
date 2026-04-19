import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

enum AppTab { home, insurance, wardrobe }

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key, required this.currentTab});

  final AppTab currentTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NavigationBar(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.accent.withValues(alpha: 0.15),
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      selectedIndex: currentTab.index,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) {
        final tab = AppTab.values[index];
        if (tab == currentTab) return;
        switch (tab) {
          case AppTab.home:
            context.go('/dashboard');
          case AppTab.insurance:
            context.go('/insurance');
          case AppTab.wardrobe:
            context.go('/wardrobe');
        }
      },
      destinations: [
        NavigationDestination(
          icon: Icon(
            Icons.home_outlined,
            color: currentTab == AppTab.home
                ? AppColors.accent
                : AppColors.onSurfaceVariant,
          ),
          selectedIcon: Icon(Icons.home_rounded, color: AppColors.accent),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.shield_outlined,
            color: currentTab == AppTab.insurance
                ? AppColors.accent
                : AppColors.onSurfaceVariant,
          ),
          selectedIcon: Icon(Icons.shield_rounded, color: AppColors.accent),
          label: 'Insurance',
        ),
        NavigationDestination(
          icon: Icon(
            Icons.checkroom_outlined,
            color: currentTab == AppTab.wardrobe
                ? AppColors.accent
                : AppColors.onSurfaceVariant,
          ),
          selectedIcon: Icon(Icons.checkroom_rounded, color: AppColors.accent),
          label: 'Wardrobe',
        ),
      ],
    );
  }
}
