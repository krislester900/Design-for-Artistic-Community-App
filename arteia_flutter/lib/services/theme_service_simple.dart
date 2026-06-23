import 'package:flutter/material.dart';

class AppPalette {
  final String name;
  final String emoji;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color gold;

  const AppPalette({
    required this.name,
    required this.emoji,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.gold,
  });

  static const palettes = [
    AppPalette(name: 'Violet mystique', emoji: '🔮', primary: Color(0xFF7C5CFC), secondary: Color(0xFF00D4AA), accent: Color(0xFFFF6B9D), gold: Color(0xFFFFD700)),
    AppPalette(name: 'Océan', emoji: '🌊', primary: Color(0xFF2196F3), secondary: Color(0xFF00BCD4), accent: Color(0xFFE91E63), gold: Color(0xFFFFC107)),
    AppPalette(name: 'Forêt', emoji: '🌿', primary: Color(0xFF4CAF50), secondary: Color(0xFF009688), accent: Color(0xFFFF7043), gold: Color(0xFFFFD54F)),
    AppPalette(name: 'Crépuscule', emoji: '🌅', primary: Color(0xFFE040FB), secondary: Color(0xFFFF4081), accent: Color(0xFFFF6F00), gold: Color(0xFFFFAB00)),
    AppPalette(name: 'Nuit étoilée', emoji: '🌌', primary: Color(0xFF673AB7), secondary: Color(0xFF448AFF), accent: Color(0xFFCE93D8), gold: Color(0xFFFFE082)),
    AppPalette(name: 'Feu & Glace', emoji: '🔥', primary: Color(0xFFFF5722), secondary: Color(0xFF03A9F4), accent: Color(0xFFE91E63), gold: Color(0xFFFFD700)),
    AppPalette(name: 'Pastel', emoji: '🌸', primary: Color(0xFF9C89B8), secondary: Color(0xFFA3D9C8), accent: Color(0xFFF0A6CA), gold: Color(0xFFF5D6A8)),
    AppPalette(name: 'Cyberpunk', emoji: '🤖', primary: Color(0xFF00FF88), secondary: Color(0xFF00E5FF), accent: Color(0xFFFF0055), gold: Color(0xFFFFB300)),
  ];
}

class ThemeServiceSimple extends ChangeNotifier {
  int _selectedPaletteIndex = 0;
  bool _isDarkMode = true;

  AppPalette get palette => AppPalette.palettes[_selectedPaletteIndex];
  int get selectedIndex => _selectedPaletteIndex;
  bool get isDarkMode => _isDarkMode;

  Color get primary => palette.primary;
  Color get secondary => palette.secondary;
  Color get accent => palette.accent;
  Color get gold => palette.gold;

  void selectPalette(int index) {
    _selectedPaletteIndex = index;
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  ThemeData get theme {
    return ThemeData(
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      colorScheme: ColorScheme(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primary: primary,
        onPrimary: Colors.white,
        secondary: secondary,
        onSecondary: Colors.white,
        tertiary: accent,
        onTertiary: Colors.white,
        surface: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        onSurface: _isDarkMode ? Colors.white : Colors.black,
        error: Colors.red,
        onError: Colors.white,
      ),
    );
  }
}

final ThemeServiceSimple themeService = ThemeServiceSimple();