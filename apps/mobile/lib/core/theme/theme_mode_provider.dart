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
    return Theme.of(context).colorScheme.surfaceContainerHighest;
  }
  return AppColors.surfaceVariant;
}

/// Resolves background color for full-screen scaffolds.
Color scaffoldBackgroundColor(BuildContext context) {
  return Theme.of(context).scaffoldBackgroundColor;
}
