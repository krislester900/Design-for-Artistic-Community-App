import 'package:flutter/material.dart';

class AppTheme {
  // Blanc majoritaire + Noir pour le contraste
  static const Color bgLight = Color(0xFFFFFFFF);     // Fond blanc pur
  static const Color bgDark = Color(0xFF000000);       // Noir pour accent
  static const Color cardLight = Color(0xFFF5F5F5);    // Cartes blanc cassé
  static const Color cardLightHover = Color(0xFFEEEEEE);
  static const Color cardDark = Color(0xFF1A1A1A);     // Cartes noires (rares)
  static const Color cardDarkLight = Color(0xFF2A2A2A);
  static const Color textPrimary = Color(0xFF000000);  // Texte principal noir
  static const Color textSecondary = Color(0xFF666666); // Texte secondaire gris
  static const Color textLight = Color(0xFF999999);     // Texte très clair
  static const Color border = Color(0xFFE0E0E0);       // Bordures gris clair
  static const Color borderLight = Color(0xFFD0D0D0);
  static const Color accent = Color(0xFF000000);       // Accent noir
  static const Color accentLight = Color(0xFF333333);  // Accent gris foncé
  static const Color overlay = Color(0x1A000000);      // Overlay noir léger

  // Anciens noms (compatibilité)
  static const Color primaryViolet = Color(0xFF000000);
  static const Color primaryTeal = Color(0xFF666666);
  static const Color primaryPink = Color(0xFFCCCCCC);
  static const Color primaryCyan = Color(0xFF999999);
  static const Color textMuted = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFF999999);
  static const Color greyLight = Color(0xFFCCCCCC);
  static const Color greyDark = Color(0xFF666666);

  // Thème Material complet
  static ThemeData get arteiaTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black,
    scaffoldBackgroundColor: bgLight,
    cardColor: cardLight,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF000000),
      secondary: Color(0xFF666666),
      surface: Color(0xFFF5F5F5),
      background: Color(0xFFFFFFFF),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF000000)),
      bodyMedium: TextStyle(color: Color(0xFF666666)),
      bodySmall: TextStyle(color: Color(0xFF999999)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      elevation: 0,
      foregroundColor: Color(0xFF000000),
    ),
  );
}