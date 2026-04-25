import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

enum AppTab { home, insurance, wardrobe }

/// Custom bottom navigation bar with a black background and a thin golden
/// line indicator below the active item's icon.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentTab});

  final AppTab currentTab;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E1E), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_filled,
                label: 'Home',
                isSelected: currentTab == AppTab.home,
                onTap: () => context.go('/dashboard'),
              ),
              _NavItem(
                icon: Icons.shield_outlined,
                label: 'Insurance',
                isSelected: currentTab == AppTab.insurance,
                onTap: () => context.go('/insurance'),
              ),
              _NavItem(
                icon: Icons.checkroom,
                label: 'Wardrobe',
                isSelected: currentTab == AppTab.wardrobe,
                onTap: () => context.go('/wardrobe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const _unselected = Color(0xFF56566A);

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.accent : _unselected;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: isSelected ? 20 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
