import 'package:flutter/material.dart';

class CategoryThemes {
  // Noir & Blanc - Même thème pour toutes les catégories
  static const music = CategoryTheme(
    primaryColor: Color(0xFFFFFFFF),
    secondaryColor: Color(0xFF666666),
    backgroundColor: Color(0xFF000000),
    cardColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFCCCCCC),
    emoji: '🎵',
    gradient: [Color(0xFF333333), Color(0xFF000000)],
  );

  static const film = CategoryTheme(
    primaryColor: Color(0xFFFFFFFF),
    secondaryColor: Color(0xFF666666),
    backgroundColor: Color(0xFF000000),
    cardColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFCCCCCC),
    emoji: '🎬',
    gradient: [Color(0xFF333333), Color(0xFF000000)],
  );

  static const visualArt = CategoryTheme(
    primaryColor: Color(0xFFFFFFFF),
    secondaryColor: Color(0xFF666666),
    backgroundColor: Color(0xFF000000),
    cardColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFCCCCCC),
    emoji: '🎨',
    gradient: [Color(0xFF333333), Color(0xFF000000)],
  );

  static const manga = CategoryTheme(
    primaryColor: Color(0xFFFFFFFF),
    secondaryColor: Color(0xFF666666),
    backgroundColor: Color(0xFF000000),
    cardColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFCCCCCC),
    emoji: '📚',
    gradient: [Color(0xFF333333), Color(0xFF000000)],
  );

  static const literature = CategoryTheme(
    primaryColor: Color(0xFFFFFFFF),
    secondaryColor: Color(0xFF666666),
    backgroundColor: Color(0xFF000000),
    cardColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFCCCCCC),
    emoji: '✍️',
    gradient: [Color(0xFF333333), Color(0xFF000000)],
  );

  static const animation = CategoryTheme(
    primaryColor: Color(0xFFFFFFFF),
    secondaryColor: Color(0xFF666666),
    backgroundColor: Color(0xFF000000),
    cardColor: Color(0xFF1A1A1A),
    accentColor: Color(0xFFCCCCCC),
    emoji: '🎞️',
    gradient: [Color(0xFF333333), Color(0xFF000000)],
  );
}

class CategoryTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color accentColor;
  final String emoji;
  final List<Color> gradient;

  const CategoryTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.accentColor,
    required this.emoji,
    required this.gradient,
  });

  ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardColor,
        background: backgroundColor,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        bodySmall: TextStyle(color: Colors.grey),
      ),
    );
  }
}