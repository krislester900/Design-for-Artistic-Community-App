import 'package:flutter/material.dart';

class AppTheme {
  // Pure black & white minimalism (default theme)
  static const Color bgLight = Color(0xFFFFFFFF);        // Fond blanc pur
  static const Color bgDark = Color(0xFF000000);          // Fond noir pur
  static const Color cardLight = Color(0xFFFFFFFF);       // Cartes blanches
  static const Color cardLightHover = Color(0xFFF5F5F5);
  static const Color cardDark = Color(0xFF1A1A1A);        // Cartes sombres
  static const Color cardDarkLight = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFF000000);     // Texte principal NOIR
  static const Color textSecondary = Color(0xFF6B7280);   // Texte secondaire gris
  static const Color textLight = Color(0xFF9CA3AF);       // Texte très clair
  static const Color border = Color(0xFFE5E7EB);          // Bordures
  static const Color borderLight = Color(0xFFD1D5DB);
  static const Color overlay = Color(0x1A000000);

  // Rétrocompatibilité (tous pointent vers noir/blanc)
  static const Color primaryViolet = Color(0xFF000000);    // = noir
  static const Color primaryTeal = Color(0xFF000000);      // = noir
  static const Color primaryPink = Color(0xFF000000);      // = noir
  static const Color primaryCyan = Color(0xFF000000);      // = noir
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9CA3AF);
  static const Color greyLight = Color(0xFFE5E7EB);
  static const Color greyDark = Color(0xFF6B7280);

  // Ombres minimalistes
  static List<BoxShadow> shadowCard = [
    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  // Thème clair - Noir & Blanc pur
  static ThemeData get arteiaTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF000000),
      secondary: Color(0xFF000000),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFFFFFFF),
      error: Color(0xFFDC2626),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFF000000)),
      bodyMedium: TextStyle(color: Color(0xFF6B7280)),
      bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
      labelLarge: TextStyle(color: Color(0xFF000000), fontWeight: FontWeight.w500),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      foregroundColor: Color(0xFF000000),
      centerTitle: false,
      titleTextStyle: TextStyle(color: Color(0xFF000000), fontSize: 18, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF000000),
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: const Color(0xFFE5E7EB).withOpacity(0.5),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.black.withOpacity(0.05),
      labelStyle: const TextStyle(color: Color(0xFF000000), fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
  );

  // Thème sombre - Noir & Blanc
  static ThemeData get arteiaDarkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.white,
    scaffoldBackgroundColor: const Color(0xFF000000),
    cardColor: const Color(0xFF1A1A1A),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFFFFF),
      secondary: Color(0xFFFFFFFF),
      surface: Color(0xFF1A1A1A),
      background: Color(0xFF000000),
      error: Color(0xFFDC2626),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: Color(0xFFFFFFFF)),
      bodyMedium: TextStyle(color: Color(0xFF9CA3AF)),
      bodySmall: TextStyle(color: Color(0xFF6B7280)),
      labelLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.w500),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A),
      elevation: 0,
      foregroundColor: Color(0xFFFFFFFF),
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFFFFFFFF),
      unselectedItemColor: Color(0xFF6B7280),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}