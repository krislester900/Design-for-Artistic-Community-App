import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color primaryViolet = Color(0xFF7C5CFC);
  static const Color primaryPink = Color(0xFFFF6B9D);
  static const Color primaryTeal = Color(0xFF00D4AA);
  static const Color primaryGold = Color(0xFFFFB347);
  static const Color primaryCyan = Color(0xFF06B6D4);
  static const Color primaryBlue = Color(0xFF3B82F6);
  static const Color bgDark = Color(0xFF0A0A0F);
  static const Color cardDark = Color(0xFF12121A);
  static const Color cardDarkLight = Color(0xFF1A1A24);
  static const Color textLight = Color(0xFFF0EDE6);
  static const Color textMuted = Color(0xFF8A8A9A);
  static const Color divider = Color(0xFF2A2A3A);

  static final ThemeData arteiaTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    cardColor: cardDark,
    dividerColor: divider,
    primaryColor: primaryViolet,
    colorScheme: const ColorScheme.dark(
      primary: primaryViolet,
      secondary: primaryPink,
      surface: cardDark,
      tertiary: primaryTeal,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textLight, fontFamily: 'Inter'),
      bodyMedium: TextStyle(color: textLight, fontFamily: 'Inter'),
      bodySmall: TextStyle(color: textMuted, fontFamily: 'Inter'),
      titleLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
      titleMedium: TextStyle(color: textLight, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
      headlineLarge: TextStyle(color: textLight, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: textLight),
      titleTextStyle: TextStyle(
        color: textLight,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Inter',
      ),
    ),
    cardTheme: CardTheme(
      color: cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: divider, width: 1),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: primaryViolet,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}