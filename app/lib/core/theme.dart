import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppTheme {
  // Premium palette – deep teal / gold accent
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color accent = Color(0xFFD4A853);
  static const Color accentLight = Color(0xFFE8D5A3);
  static const Color surface = Color(0xFFF0F4F8);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF334155);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFDC2626);

  // Glass
  static const Color glassWhite = Color(0x18FFFFFF);
  static const Color glassBorder = Color(0x28FFFFFF);
  static const Color glassDark = Color(0x1A1E293B);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: accent,
          surface: surface,
          error: error,
          onPrimary: textOnPrimary,
          onSurface: textPrimary,
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme().copyWith(
          headlineLarge: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary),
          headlineMedium: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
          titleLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
          bodyLarge: GoogleFonts.outfit(fontSize: 16, color: textPrimary),
          bodyMedium: GoogleFonts.outfit(fontSize: 14, color: textSecondary),
        ),
        scaffoldBackgroundColor: surface,
        appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: textPrimary,
          titleTextStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      );
}
