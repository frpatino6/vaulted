import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Spacing scale for consistent layout (8px base).
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Premium design system for Vaulted.
class AppColors {
  AppColors._();

  // Dark palette
  static const Color background = Color(0xFF0A0A0F);
  /// Slightly lighter background for depth (e.g. dashboard).
  static const Color backgroundElevated = Color(0xFF121212);
  static const Color surface = Color(0xFF13131A);
  static const Color accent = Color(0xFFC9A84C);
  static const Color accentLight = Color(0xFFE5D4A1);
  /// Brighter gold for icons and highlights on dark backgrounds.
  static const Color accentBright = Color(0xFFD4AF37);
  static const Color surfaceVariant = Color(0xFF1C1C26);
  static const Color onBackground = Color(0xFFE8E8ED);
  static const Color onSurface = Color(0xFFB8B8C4);
  static const Color onSurfaceVariant = Color(0xFF8E8E9E);
  /// Gold for catalog total value and premium highlights (e.g. room inventory summary).
  static const Color catalogGold = Color(0xFFC5A059);
  static const Color error = Color(0xFFCF6679);
  static const Color info = Color(0xFF2196F3);
  static const Color statusActive = Color(0xFF4CAF50);
  static const Color statusLoaned = Color(0xFFFFC107);
  static const Color statusRepair = Color(0xFFFF9800);
  static const Color statusStorage = Color(0xFF2196F3);
  static const Color statusDisposed = Color(0xFF9E9E9E);
  /// Warning / attention — amber orange for unlocated items, alerts.
  static const Color warning = Color(0xFFFF9800);
  /// Hero placeholder gradient (dark theme) — luxury charcoal.
  static const Color heroGradientStart = Color(0xFF1A1A24);
  static const Color heroGradientEnd = Color(0xFF0E0E14);

  // Light palette — "Luxury Light" (ivory, pearl, deep gold)
  /// Warm ivory pearl — never pure white; evokes Cartier packaging.
  static const Color lightBackground = Color(0xFFFAF9F6);
  /// Pure white for card surfaces — gives depth against ivory background.
  static const Color lightSurface = Color(0xFFFFFFFF);
  /// Warm cream — chip backgrounds, input fills, subtle containers.
  static const Color lightSurfaceVariant = Color(0xFFF0EDE6);
  /// Slightly elevated warm ivory for section containers.
  static const Color lightSurfaceElevated = Color(0xFFF5F2EC);
  /// Deep carbon — primary text on light backgrounds.
  static const Color lightOnBackground = Color(0xFF2B2B2B);
  /// Dark charcoal — body text, secondary headings.
  static const Color lightOnSurface = Color(0xFF3D3D3D);
  /// Warm taupe — secondary text, hints, placeholder, unselected nav items.
  static const Color lightOnSurfaceVariant = Color(0xFF757575);
  /// Warm parchment border — card outlines, dividers, input borders.
  static const Color lightOutline = Color(0xFFDDD8CE);
  /// Hairline ivory divider — ultra-subtle separation.
  static const Color lightOutlineVariant = Color(0xFFEAE7DF);
  /// Deeper gold — richer contrast on ivory/white for icons and selected states.
  static const Color lightAccent = Color(0xFFB8961E);
  /// Gold at 15 % opacity — chip selected fill, nav indicator tint.
  static const Color lightAccentSubtle = Color(0x26B8961E);
  /// Hero placeholder gradient (light theme) — warm pearl.
  static const Color lightHeroGradientStart = Color(0xFFF0EDE6);
  static const Color lightHeroGradientEnd = Color(0xFFFAF9F6);
}

/// Typography using clean, minimal fonts.
class AppTypography {
  AppTypography._();

  static TextStyle get displayLarge => GoogleFonts.dmSans(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get headlineSmall => GoogleFonts.dmSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleLarge => GoogleFonts.dmSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyLarge => GoogleFonts.dmSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      );

  static TextStyle get labelLarge => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get labelSmall => GoogleFonts.dmSans(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      );

  /// Serif display for luxury headings (e.g. user name on dashboard).
  static TextStyle get displaySerif => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.3,
      );

  /// Smaller serif for app bar titles (e.g. Global Search).
  static TextStyle get titleSerif => GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.2,
      );

  /// Serif hero title over imagery (e.g. property detail header).
  static TextStyle get heroTitle => GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w500,
      );

  /// Uppercase section label (e.g. "FLOORS & ROOMS").
  static TextStyle get sectionLabel => GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.0,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.background,
        secondary: AppColors.accentLight,
        onSecondary: AppColors.background,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        error: AppColors.error,
        onError: AppColors.background,
        outline: AppColors.onSurfaceVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.onBackground),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.onBackground),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.onBackground),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.onSurface),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.onSurface),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.onSurface),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.onBackground),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.onSurface),
        labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.onSurfaceVariant),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.onBackground),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.onSurfaceVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // ── Colour scheme ────────────────────────────────────────────────────
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightAccent,
        onPrimary: AppColors.lightOnBackground,
        primaryContainer: AppColors.lightAccentSubtle,
        onPrimaryContainer: AppColors.lightOnBackground,
        secondary: AppColors.lightOnSurfaceVariant,
        onSecondary: AppColors.lightSurface,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightOnBackground,
        surfaceContainerLowest: AppColors.lightSurface,
        surfaceContainerLow: AppColors.lightBackground,
        surfaceContainer: AppColors.lightSurfaceElevated,
        surfaceContainerHigh: AppColors.lightSurfaceVariant,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        error: AppColors.error,
        onError: AppColors.lightSurface,
        outline: AppColors.lightOutline,
        outlineVariant: AppColors.lightOutlineVariant,
      ),

      scaffoldBackgroundColor: AppColors.lightBackground,

      // ── App bar ──────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightOnBackground,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTypography.titleSerif.copyWith(
          color: AppColors.lightOnBackground,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.lightOnBackground,
          size: 24,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.lightOnSurfaceVariant,
          size: 24,
        ),
      ),

      // ── Bottom navigation bar (Material 2 widget) ────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightBackground,
        selectedItemColor: AppColors.lightAccent,
        unselectedItemColor: AppColors.lightOnSurfaceVariant,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),

      // ── Navigation bar (Material 3 widget) ──────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.lightBackground,
        indicatorColor: AppColors.lightAccentSubtle,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.lightAccent, size: 24);
          }
          return const IconThemeData(
              color: AppColors.lightOnSurfaceVariant, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.labelSmall.copyWith(
              color: AppColors.lightAccent,
              fontWeight: FontWeight.w600,
            );
          }
          return AppTypography.labelSmall
              .copyWith(color: AppColors.lightOnSurfaceVariant);
        }),
      ),

      // ── Cards ────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: const Color(0x142B2B2B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
              color: AppColors.lightOutlineVariant, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Chips ────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightSurfaceVariant,
        selectedColor: AppColors.lightAccentSubtle,
        disabledColor: AppColors.lightSurfaceVariant,
        labelStyle: AppTypography.labelLarge
            .copyWith(color: AppColors.lightOnBackground),
        secondaryLabelStyle: AppTypography.labelLarge
            .copyWith(color: AppColors.lightAccent),
        side: const BorderSide(color: AppColors.lightOutline, width: 0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: 0,
        pressElevation: 0,
      ),

      // ── Divider ──────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.lightOutlineVariant,
        thickness: 0.8,
        space: 0,
      ),

      // ── Icons ────────────────────────────────────────────────────────────
      iconTheme: const IconThemeData(
        color: AppColors.lightOnSurface,
        size: 24,
      ),

      // ── Typography ───────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge
            .copyWith(color: AppColors.lightOnBackground),
        headlineMedium: AppTypography.headlineMedium
            .copyWith(color: AppColors.lightOnBackground),
        headlineSmall: AppTypography.headlineSmall
            .copyWith(color: AppColors.lightOnBackground),
        titleLarge: AppTypography.titleLarge
            .copyWith(color: AppColors.lightOnBackground),
        titleMedium: AppTypography.titleMedium
            .copyWith(color: AppColors.lightOnSurface),
        bodyLarge: AppTypography.bodyLarge
            .copyWith(color: AppColors.lightOnSurface),
        bodyMedium: AppTypography.bodyMedium
            .copyWith(color: AppColors.lightOnSurface),
        bodySmall: AppTypography.bodySmall
            .copyWith(color: AppColors.lightOnSurfaceVariant),
        labelLarge: AppTypography.labelLarge
            .copyWith(color: AppColors.lightOnBackground),
        labelSmall: AppTypography.labelSmall
            .copyWith(color: AppColors.lightOnSurfaceVariant),
      ),

      // ── Input fields ─────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceElevated,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.lightOutline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.lightAccent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.bodyMedium
            .copyWith(color: AppColors.lightOnSurfaceVariant),
        hintStyle: AppTypography.bodyMedium
            .copyWith(color: AppColors.lightOnSurfaceVariant),
        floatingLabelStyle:
            AppTypography.bodySmall.copyWith(color: AppColors.lightAccent),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      // ── Buttons ──────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: AppColors.lightOnBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.labelLarge
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightAccent,
          side: const BorderSide(color: AppColors.lightAccent, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: AppTypography.labelLarge
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightAccent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTypography.labelLarge
              .copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // ── List tiles ───────────────────────────────────────────────────────
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColors.lightOnSurface,
        textColor: AppColors.lightOnBackground,
        subtitleTextStyle: TextStyle(color: AppColors.lightOnSurfaceVariant),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),

      // ── Dialogs ──────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(
              color: AppColors.lightOutlineVariant, width: 0.8),
        ),
        titleTextStyle: AppTypography.titleLarge
            .copyWith(color: AppColors.lightOnBackground),
        contentTextStyle: AppTypography.bodyMedium
            .copyWith(color: AppColors.lightOnSurface),
      ),

      // ── Switches & checkboxes ────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightSurface;
          }
          return AppColors.lightOnSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightAccent;
          }
          return AppColors.lightOutline;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.lightAccent;
          }
          return Colors.transparent;
        }),
        checkColor:
            WidgetStateProperty.all(AppColors.lightOnBackground),
        side: const BorderSide(color: AppColors.lightOutline, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),

      // ── Progress indicators ──────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.lightAccent,
        linearTrackColor: AppColors.lightOutlineVariant,
      ),

      // ── Floating action button ───────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightAccent,
        foregroundColor: AppColors.lightOnBackground,
        elevation: 2,
        shape: CircleBorder(),
      ),
    );
  }
}
