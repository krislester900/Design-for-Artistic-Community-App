import 'package:flutter/material.dart';

class AppTheme {
  // Couleurs artistiques (violet/teal/rose)
  static const Color bgLight = Color(0xFFF8F9FC);       // Fond blanc doux
  static const Color bgDark = Color(0xFF0D0D1A);         // Fond sombre profond
  static const Color cardLight = Color(0xFFFFFFFF);       // Cartes blanches
  static const Color cardLightHover = Color(0xFFF0F0F5);
  static const Color cardDark = Color(0xFF1A1A2E);        // Cartes sombres
  static const Color cardDarkLight = Color(0xFF252540);
  static const Color textPrimary = Color(0xFF1A1A2E);     // Texte principal
  static const Color textSecondary = Color(0xFF6B7280);   // Texte secondaire
  static const Color textLight = Color(0xFF9CA3AF);        // Texte très clair
  static const Color border = Color(0xFFE5E7EB);          // Bordures
  static const Color borderLight = Color(0xFFD1D5DB);
  static const Color overlay = Color(0x1A000000);

  // Couleurs artistiques dynamiques
  static const Color primaryViolet = Color(0xFF7C5CFC);   // Violet principal
  static const Color primaryTeal = Color(0xFF00D4AA);     // Teal/secondaire
  static const Color primaryPink = Color(0xFFFF6B9D);     // Rose accent
  static const Color primaryCyan = Color(0xFF00D4FF);     // Cyan

  // Dégradés
  static const Gradient gradientViolet = LinearGradient(
    colors: [primaryViolet, Color(0xFF6C4FE0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient gradientTeal = LinearGradient(
    colors: [primaryTeal, Color(0xFF00B894)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient gradientPink = LinearGradient(
    colors: [primaryPink, Color(0xFFFF4D7A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const Gradient gradientVioletTeal = LinearGradient(
    colors: [primaryViolet, primaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Ombres
  static List<BoxShadow> shadowViolet = [
    BoxShadow(color: primaryViolet.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> shadowTeal = [
    BoxShadow(color: primaryTeal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> shadowCard = [
    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
  ];

  // Anciens noms (compatibilité)
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF9CA3AF);
  static const Color greyLight = Color(0xFFE5E7EB);
  static const Color greyDark = Color(0xFF6B7280);

  // Thème clair
  static ThemeData get arteiaTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryViolet,
    scaffoldBackgroundColor: bgLight,
    cardColor: cardLight,
    colorScheme: const ColorScheme.light(
      primary: primaryViolet,
      secondary: primaryTeal,
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF8F9FC),
      error: Color(0xFFDC2626),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textPrimary),
      bodyMedium: TextStyle(color: textSecondary),
      bodySmall: TextStyle(color: textLight),
      labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w500),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      foregroundColor: textPrimary,
      centerTitle: false,
      titleTextStyle: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryViolet,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        elevation: 0,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryViolet, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primaryViolet,
      unselectedItemColor: Color(0xFF9CA3AF),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(
      color: const Color(0xFFE5E7EB).withOpacity(0.5),
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryViolet.withOpacity(0.1),
      labelStyle: const TextStyle(color: primaryViolet, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),
  );
}