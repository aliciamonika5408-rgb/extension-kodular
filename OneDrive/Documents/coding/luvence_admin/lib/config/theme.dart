import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';

class LuvTheme {
  LuvTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: LuvColors.background,
      primaryColor: LuvColors.accent,
      colorScheme: const ColorScheme.dark(
        primary: LuvColors.accent,
        secondary: LuvColors.accentLight,
        surface: LuvColors.surface,
        error: LuvColors.error,
        onPrimary: LuvColors.background,
        onSecondary: LuvColors.background,
        onSurface: LuvColors.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: LuvColors.textPrimary),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: LuvColors.textPrimary),
          displaySmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: LuvColors.textPrimary),
          headlineLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: LuvColors.textPrimary),
          headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: LuvColors.textPrimary),
          headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: LuvColors.textPrimary),
          titleLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: LuvColors.textPrimary),
          titleMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: LuvColors.textSecondary),
          titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: LuvColors.textSecondary),
          bodyLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: LuvColors.textPrimary),
          bodyMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: LuvColors.textSecondary),
          bodySmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: LuvColors.textTertiary),
          labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: LuvColors.accent),
          labelMedium: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: LuvColors.textTertiary),
          labelSmall: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.0, color: LuvColors.textMuted),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: LuvColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: LuvColors.textPrimary,
        ),
        iconTheme: const IconThemeData(color: LuvColors.accent),
      ),
      cardTheme: CardThemeData(
        color: LuvColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: LuvColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LuvColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LuvColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LuvColors.borderAccent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LuvColors.error),
        ),
        hintStyle: const TextStyle(color: LuvColors.textMuted, fontSize: 13),
        labelStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Color(0x66D4A574),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: LuvColors.accent,
          foregroundColor: LuvColors.background,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: LuvColors.textTertiary,
          side: const BorderSide(color: LuvColors.borderLight),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF080A10),
        selectedItemColor: LuvColors.accent,
        unselectedItemColor: LuvColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: LuvColors.surfaceLight,
        contentTextStyle: const TextStyle(color: LuvColors.textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: LuvColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: LuvColors.textPrimary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: LuvColors.borderLight,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return LuvColors.accent;
          return LuvColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return LuvColors.accentBg;
          return LuvColors.borderLight;
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: LuvColors.accent,
        foregroundColor: LuvColors.background,
        elevation: 8,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: LuvColors.glassLight,
        selectedColor: LuvColors.accentBg,
        side: const BorderSide(color: LuvColors.borderLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
    );
  }
}
