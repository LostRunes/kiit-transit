import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Material theme for the "Campus Pulse" design: Plus Jakarta Sans headlines,
/// Inter body text, pill buttons, soft filled inputs and borderless pods.
class AppTheme {
  AppTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.sage,
      brightness: brightness,
      primary: isDark ? AppColors.primaryLight : AppColors.primary,
      onPrimary: isDark ? AppColors.onSage : Colors.white,
      primaryContainer: isDark ? AppColors.primaryDark : AppColors.sage,
      onPrimaryContainer: isDark ? AppColors.primaryLight : AppColors.onSage,
      secondary: isDark ? const Color(0xFF95D2CC) : AppColors.secondary,
      secondaryContainer: isDark ? const Color(0xFF07504B) : AppColors.teal,
      onSecondaryContainer: isDark ? AppColors.teal : AppColors.onTeal,
      tertiary: isDark ? AppColors.peach : AppColors.tertiary,
      tertiaryContainer: isDark ? const Color(0xFF673C28) : AppColors.peachSoft,
      surface: isDark ? AppColors.darkCard : AppColors.card,
      onSurface: isDark ? const Color(0xFFE1E3E0) : AppColors.ink,
      error: AppColors.cancelled,
    );
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;
    final field = isDark ? AppColors.darkField : AppColors.field;
    final fg = scheme.onSurface;
    final mutedFg = isDark ? const Color(0xFF9DABA5) : AppColors.inkMuted;
    final base = ThemeData(brightness: brightness, useMaterial3: true, colorScheme: scheme);

    final body = GoogleFonts.interTextTheme(base.textTheme);
    final heading = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);
    final text = body
        .copyWith(
          displayLarge: heading.displayLarge,
          displayMedium: heading.displayMedium,
          displaySmall: heading.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.8),
          headlineLarge: heading.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.4),
          headlineMedium: heading.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
          headlineSmall: heading.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          titleLarge: heading.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: heading.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: heading.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(bodyColor: fg, displayColor: fg);

    final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(999));
    final buttonText = GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 16);

    return base.copyWith(
      scaffoldBackgroundColor: surface,
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: isDark ? fg : AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? fg : AppColors.primary,
        ),
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: isDark ? BorderSide(color: border) : BorderSide.none,
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: field,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(color: AppColors.inkMuted.withValues(alpha: 0.7)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.cancelled, width: 1.2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56), shape: pill, textStyle: buttonText),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          foregroundColor: scheme.primary,
          side: BorderSide(color: isDark ? border : AppColors.sage.withValues(alpha: 0.6), width: 2),
          shape: pill,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide.none,
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: fg),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: isDark ? AppColors.primaryDark : AppColors.sage,
        indicatorShape: pill,
        elevation: 0,
        height: 74,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            color: s.contains(WidgetState.selected) ? (isDark ? AppColors.primaryLight : AppColors.onSage) : mutedFg,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => GoogleFonts.inter(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? (isDark ? AppColors.primaryLight : AppColors.onSage) : mutedFg,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.darkField : AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
    );
  }
}
