import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Small pill badge for item status with color-coded tint.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (Color tint, Color bg) = _colorsForStatus(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
      ),
    );
  }

  static (Color tint, Color bg) _colorsForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return (const Color(0xFF4CAF50), const Color(0xFF4CAF50).withValues(alpha: 0.18));
      case 'loaned':
        return (const Color(0xFFFFB300), const Color(0xFFFFB300).withValues(alpha: 0.18));
      case 'repair':
        return (const Color(0xFFFF9800), const Color(0xFFFF9800).withValues(alpha: 0.18));
      case 'storage':
        return (const Color(0xFF2196F3), const Color(0xFF2196F3).withValues(alpha: 0.18));
      case 'disposed':
        return (const Color(0xFF9E9E9E), const Color(0xFF9E9E9E).withValues(alpha: 0.18));
      default:
        return (AppColors.onSurfaceVariant, AppColors.onSurfaceVariant.withValues(alpha: 0.15));
    }
  }
}
