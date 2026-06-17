---
name: design-system
description: Vaulted's centralized design tokens, theme colors, typography, and spacing scales
metadata:
  type: reference
---

# Vaulted Design System

**Location:** `apps/mobile/lib/core/theme/app_theme.dart`

## Spacing Scale (AppSpacing)
- **xs**: 4px
- **sm**: 8px (base unit)
- **md**: 16px
- **lg**: 24px
- **xl**: 32px
- **xxl**: 48px

Grid: 8px. Always use these constants, never magic numbers.

## Dark Colors (AppColors) — Premium Dark Palette
- **background**: `0xFF0A0A0F` (pure black-dark, primary bg)
- **backgroundElevated**: `0xFF121212` (elevated sections, rare)
- **surface**: `0xFF13131A` (card/elevated surfaces)
- **surfaceVariant**: `0xFF1C1C26` (subtle surfaces, input fills)
- **onBackground**: `0xFFE8E8ED` (primary text on dark)
- **onSurface**: `0xFFB8B8C4` (secondary text)
- **onSurfaceVariant**: `0xFF8E8E9E` (tertiary text, hints)
- **accent**: `0xFFC9A84C` (gold, primary action)
- **accentBright**: `0xFFD4AF37` (brighter gold, icons on dark backgrounds)
- **accentLight**: `0xFFE5D4A1` (light gold)
- **catalogGold**: `0xFFC5A059` (special: valuations, room summary)
- **warning**: `0xFFFF9800` (amber, alerts, unlocated items)
- **error**: `0xFFCF6679` (pink-red)
- **statusActive**: `0xFF4CAF50` (green)
- **statusLoaned**: `0xFFFFC107` (yellow)
- **statusRepair**: `0xFFFF9800` (orange)
- **statusStorage**: `0xFF2196F3` (blue)
- **statusDisposed**: `0xFF9E9E9E` (gray)

## Light Colors (AppColors.light*) — Luxury Light Palette
- **lightBackground**: `0xFFFAF9F6` (ivory, never pure white)
- **lightSurface**: `0xFFFFFFFF` (pure white for cards)
- **lightSurfaceVariant**: `0xFFF0EDE6` (warm cream)
- **lightOnBackground**: `0xFF2B2B2B` (carbon text)
- **lightOnSurface**: `0xFF3D3D3D` (charcoal)
- **lightOnSurfaceVariant**: `0xFF757575` (taupe)
- **lightAccent**: `0xFFB8961E` (deep gold)
- **lightOutline**: `0xFFDDD8CE` (parchment border)

## Typography (AppTypography)
All use `google_fonts`. Never hardcode font families.
- **displayLarge**: DMSans 32px w600, -0.5 letter-spacing
- **headlineMedium**: DMSans 24px w600
- **titleLarge**: DMSans 20px w600
- **titleMedium**: DMSans 16px w500
- **bodyLarge**: DMSans 16px w400, 1.5 line-height
- **bodyMedium**: DMSans 14px w400, 1.5 line-height
- **bodySmall**: DMSans 12px w400, 1.4 line-height
- **labelLarge**: DMSans 14px w500
- **labelSmall**: DMSans 11px w500
- **displaySerif**: PlayfairDisplay 26px w500, -0.3 letter-spacing (luxury headings)
- **titleSerif**: PlayfairDisplay 18px w500 (app bar titles)

**Usage rule:** Always use `AppTypography.*` and then `.copyWith()` for color/weight overrides. Never set font-family directly.

## Theme System
- **Dark theme**: `AppTheme.dark()` — Material 3 with gold accent
- **Light theme**: `AppTheme.light()` — ivory background, warm gold accent
- Both themes apply consistent spacing, radii, and component styling

## Rules for Premium Polish
1. **Never hardcode colors.** Use `AppColors.*` constants. Exception: transparent/alpha values can use `Colors.transparent` or `.withValues(alpha: X)` with theme tokens.
2. **Elevation & shadow:** Cards/surfaces use subtle `boxShadow` (4-6px blur, ~12% black opacity).
3. **Border radius:** Follow scale: 8px (chips), 12px (inputs), 16px (cards), 20px (modals), circular (FAB).
4. **Spacing:** Always use `AppSpacing.*` constants. Never magic-number padding/margin.
5. **Typography:** Reference `AppTypography.*` first, then copyWith() for overrides only.

