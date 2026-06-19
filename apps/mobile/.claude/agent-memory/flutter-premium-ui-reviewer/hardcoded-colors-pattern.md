---
name: hardcoded-colors-pattern
description: Recurring anti-pattern in Vaulted screens — hardcoded colors instead of AppColors tokens
metadata:
  type: feedback
---

# Hardcoded Color Anti-Pattern

**Rule:** All colors must come from `AppColors` in `app_theme.dart`. No `Color(0x...)`, `Colors.white`, or `Colors.black` scattered in widgets.

**Why:** 
1. Breaks light/dark theme support — hardcoded colors don't switch with theme
2. Violates design system — makes it impossible to enforce brand consistency
3. Maintenance nightmare — updating palette requires grep+edit across 20+ files instead of one theme file

## Recurring Offenders in Property Detail Screen
- `Color(0xFF1A1A24)` and `Color(0xFF0E0E14)` in luxury gradient background (hardcoded dark colors)
- `Colors.white.withValues(alpha: 0.10)` scattered for overlays
- `Colors.white30`, `Colors.white12` for borders
- `Colors.black54` for backdrops
- Hardcoded black (`Colors.black`) in icon colors instead of `AppColors.onBackground`

## Fix Pattern
```dart
// ❌ WRONG
Container(
  color: Colors.white.withValues(alpha: 0.1),
  child: Icon(Icons.camera, color: Colors.black),
)

// ✅ RIGHT
Container(
  color: AppColors.onBackground.withValues(alpha: 0.1), // or compute based on isDark
  child: Icon(Icons.camera, color: AppColors.onBackground),
)
```

## How to Apply
1. Search file for `Color(0x`, `Colors.white`, `Colors.black`, `Colors.red` (except in error tokens)
2. Replace with nearest `AppColors.*` equivalent
3. For transparency overlays, use the token with `.withValues(alpha: X)` where X = desired opacity (0.0-1.0)
4. If color doesn't exist in `AppColors`, add it to the design system first

