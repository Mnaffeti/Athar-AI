import 'package:flutter/material.dart';

/// Dark, minimal palette: near-black surfaces, off-white accent, logo red for alerts.
class AppColors {
  static const background = Color(0xFF0A0A0B);
  static const surface = Color(0xFF151517);
  static const surfaceHigh = Color(0xFF1E1E21);
  static const border = Color(0xFF2A2A2E);

  // Brand colours taken from the Athar logo.
  static const brandNavy = Color(0xFF00004D);
  static const brandRed = Color(0xFFE30B21);
  static const brandLight = Color(0xFFF5F5F5);

  static const accent = Color(0xFFF5F5F5); // off-white
  static const onAccent = brandNavy; // text/icons on accent surfaces
  static const accentDim = Color(0xFF1C1C3A); // navy-tinted selected surface

  /// Over-limit / bad-direction indicator.
  static const alert = Color(0xFFFF3B4E);

  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFF9A9AA2);
  static const textMuted = Color(0xFF5E5E66);

  // Per-metric tints, used sparingly for icons and chart bars.
  static const scroll = Color(0xFFFF8A5B);
  static const screen = Color(0xFFFF3B4E);
  static const social = Color(0xFFB98BFF);
  static const gym = Color(0xFF5BC8FF);
  static const phoneFree = accent;
}

/// Font families bundled in assets/fonts.
class AppFonts {
  /// Clean sans used for all UI text and numbers.
  static const body = 'Manrope';

  /// Elegant serif for headlines, echoing the ATHAR wordmark.
  static const display = 'PlayfairDisplay';
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        outline: AppColors.border,
      ),
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          disabledBackgroundColor: AppColors.surfaceHigh,
          disabledForegroundColor: AppColors.textMuted,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.accentDim,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? AppColors.textPrimary
                : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.accent
                : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
