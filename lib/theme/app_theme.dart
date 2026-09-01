import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors (Cyber Neon Fitness Palette)
  static const Color background = Color(0xFF0F1218);
  static const Color surface = Color(0xFF181D26);
  static const Color surfaceLight = Color(0xFF222936);
  static const Color surfaceBorder = Color(0xFF2E3849);

  // Accents
  static const Color primaryNeon = Color(0xFF00FFA3); // Energetic Electric Green
  static const Color primaryAccent = Color(0xFF00D1FF); // Cyan Blue
  static const Color secondaryOrange = Color(0xFFFF6B00); // Fire / PR Accent
  static const Color purpleXP = Color(0xFFA855F7); // Level / XP Purple
  static const Color goldRank = Color(0xFFFFD700); // Gold / Achievement

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primaryNeon,
      colorScheme: const ColorScheme.dark(
        primary: primaryNeon,
        secondary: primaryAccent,
        surface: surface,
        error: Color(0xFFEF4444),
      ),
      fontFamily: 'Segoe UI',
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
    );
  }
}
