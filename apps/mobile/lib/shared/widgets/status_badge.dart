import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Refined display labels for catalog-style UI (e.g. "Verified" instead of "ACTIVE").
String statusRefinedLabel(String status) {
  switch (status.toLowerCase()) {
    case 'active':
      return 'Verified';
    case 'loaned':
      return 'On Loan';
    case 'repair':
      return 'In Repair';
    case 'storage':
      return 'In Storage';
    case 'disposed':
      return 'Disposed';
    default:
      return status.isNotEmpty ? status[0].toUpperCase() + status.substring(1).toLowerCase() : '—';
  }
}

/// Small pill badge for item status with color-coded tint.
/// Use [compact] for catalog/list cards with refined label.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  final String status;
  /// When true, uses smaller size and refined label (e.g. "Verified").
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (Color tint, Color bg) = _colorsForStatus(status);
    final label = compact ? statusRefinedLabel(status) : status.toUpperCase();
    final fontSize = compact ? 10.0 : 10.0;
    final fontWeight = compact ? FontWeight.bold : FontWeight.w600;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 8 : 12),
        border: Border.all(
          color: tint,
          width: compact ? 0.8 : 1,
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: fontWeight,
              letterSpacing: compact ? 0.2 : 0.5,
              fontSize: fontSize,
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
