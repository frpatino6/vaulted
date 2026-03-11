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
  static const Color error = Color(0xFFCF6679);
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
      );

  static TextStyle get bodyMedium => GoogleFonts.dmSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodySmall => GoogleFonts.dmSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
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
      colorScheme: ColorScheme.light(
        primary: AppColors.accent,
        onPrimary: AppColors.background,
        secondary: AppColors.accentLight,
        onSecondary: AppColors.background,
        surface: const Color(0xFFF5F5F7),
        onSurface: const Color(0xFF1C1C26),
        error: AppColors.error,
        onError: Colors.white,
        outline: const Color(0xFF8E8E9E),
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFC),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.background),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.background),
        titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.background),
        titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.surface),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.surface),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.surface),
        labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.background),
        bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.surface),
        labelSmall: AppTypography.labelSmall.copyWith(color: const Color(0xFF6E6E7E)),
        headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.background),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F0F4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D0D8), width: 1),
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
}
