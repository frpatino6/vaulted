import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';

/// Current theme mode: system (follow device), light, or dark.
/// Default dark to match premium dark UI spec.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Resolves surface-variant color from the current theme (light or dark).
/// Use instead of AppColors.surfaceVariant when supporting light mode.
Color surfaceVariantColor(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  if (brightness == Brightness.light) {
    return AppColors.lightSurfaceVariant;
  }
  return AppColors.surfaceVariant;
}

/// Resolves background color for full-screen scaffolds.
Color scaffoldBackgroundColor(BuildContext context) {
  return Theme.of(context).scaffoldBackgroundColor;
}

/// Resolves the accent/gold color for the current theme.
Color accentColor(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  if (brightness == Brightness.light) return AppColors.lightAccent;
  return AppColors.accent;
}

/// Resolves the primary text color for the current theme.
Color onBackgroundColor(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  if (brightness == Brightness.light) return AppColors.lightOnBackground;
  return AppColors.onBackground;
}

/// Resolves the secondary text color for the current theme.
Color onSurfaceVariantColor(BuildContext context) {
  final brightness = Theme.of(context).brightness;
  if (brightness == Brightness.light) return AppColors.lightOnSurfaceVariant;
  return AppColors.onSurfaceVariant;
}
