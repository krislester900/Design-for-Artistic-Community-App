import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData arteiaTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0A0A0F),
    cardColor: const Color(0xFF12121A),
    dividerColor: Colors.white.withOpacity(0.08),
    primaryColor: const Color(0xFF7C5CFC),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7C5CFC),
      secondary: Color(0xFFFF6B9D),
      surface: Color(0xFF12121A),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF0EDE6)),
      bodyMedium: TextStyle(color: Color(0xFFF0EDE6)),
      titleLarge: TextStyle(color: Color(0xFFF0EDE6), fontWeight: FontWeight.bold),
    ),
  );
}