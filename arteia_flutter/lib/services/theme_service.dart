import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppPalette {
  final String name;
  final String emoji;
  final Color primaryViolet;
  final Color primaryTeal;
  final Color primaryPink;
  final Color accentGold;
  final Color bgDark;
  final Color bgLight;
  final Color cardDark;
  final Color cardLight;

  const AppPalette({
    required this.name,
    required this.emoji,
    required this.primaryViolet,
    required this.primaryTeal,
    required this.primaryPink,
    required this.accentGold,
    required this.bgDark,
    required this.bgLight,
    required this.cardDark,
    required this.cardLight,
  });

  static const palettes = [
    AppPalette(
      name: 'Violet mystique',
      emoji: '🔮',
      primaryViolet: Color(0xFF7C5CFC),
      primaryTeal: Color(0xFF00D4AA),
      primaryPink: Color(0xFFFF6B9D),
      accentGold: Color(0xFFFFD700),
      bgDark: Color(0xFF0a0a0a),
      bgLight: Color(0xFFF8F9FA),
      cardDark: Color(0xFF1E1E1E),
      cardLight: Color(0xFFFFFFFF),
    ),
    AppPalette(
      name: 'Océan profond',
      emoji: '🌊',
      primaryViolet: Color(0xFF2196F3),
      primaryTeal: Color(0xFF00BCD4),
      primaryPink: Color(0xFFE91E63),
      accentGold: Color(0xFFFFC107),
      bgDark: Color(0xFF0D1117),
      bgLight: Color(0xFFF0F4F8),
      cardDark: Color(0xFF161B22),
      cardLight: Color(0xFFFFFFFF),
    ),
    AppPalette(
      name: 'Forêt enchantée',
      emoji: '🌿',
      primaryViolet: Color(0xFF4CAF50),
      primaryTeal: Color(0xFF009688),
      primaryPink: Color(0xFFFF7043),
      accentGold: Color(0xFFFFD54F),
      bgDark: Color(0xFF0A1F0E),
      bgLight: Color(0xFFF1F8E9),
      cardDark: Color(0xFF1B3A1F),
      cardLight: Color(0xFFFFFFFF),
    ),
    AppPalette(
      name: 'Crépuscule rose',
      emoji: '🌅',
      primaryViolet: Color(0xFFE040FB),
      primaryTeal: Color(0xFFFF4081),
      primaryPink: Color(0xFFFF6F00),
      accentGold: Color(0xFFFFAB00),
      bgDark: Color(0xFF1A0A1E),
      bgLight: Color(0xFFFCE4EC),
      cardDark: Color(0xFF2D1B2E),
      cardLight: Color(0xFFFFFFFF),
    ),
    AppPalette(
      name: 'Nuit étoilée',
      emoji: '🌌',
      primaryViolet: Color(0xFF673AB7),
      primaryTeal: Color(0xFF448AFF),
      primaryPink: Color(0xFFCE93D8),
      accentGold: Color(0xFFFFE082),
      bgDark: Color(0xFF050510),
      bgLight: Color(0xFFEDE7F6),
      cardDark: Color(0xFF12122A),
      cardLight: Color(0xFFFFFFFF),
    ),
    AppPalette(
      name: 'Feu & Glace',
      emoji: '🔥',
      primaryViolet: Color(0xFFFF5722),
      primaryTeal: Color(0xFF03A9F4),
      primaryPink: Color(0xFFE91E63),
      accentGold: Color(0xFFFFD700),
      bgDark: Color(0xFF1A0A0A),
      bgLight: Color(0xFFFFF3E0),
      cardDark: Color(0xFF2A1414),
      cardLight: Color(0xFFFFFFFF),
    ),
    AppPalette(
      name: 'Pastel doux',
      emoji: '🌸',
      primaryViolet: Color(0xFF9C89B8),
      primaryTeal: Color(0xFFA3D9C8),
      primaryPink: Color(0xFFF0A6CA),
      accentGold: Color(0xFFF5D6A8),
      bgDark: Color(0xFF1A1A2E),
      bgLight: Color(0xFFF8F0F5),
      cardDark: Color(0xFF25253D),
      cardLight: Color(0xFFFFFFFF),
    ),
    AppPalette(
      name: 'Cyberpunk',
      emoji: '🤖',
      primaryViolet: Color(0xFF00FF88),
      primaryTeal: Color(0xFF00E5FF),
      primaryPink: Color(0xFFFF0055),
      accentGold: Color(0xFFFFB300),
      bgDark: Color(0xFF0A0A1A),
      bgLight: Color(0xFFF0FFF0),
      cardDark: Color(0xFF1A1A2E),
      cardLight: Color(0xFFFFFFFF),
    ),
  ];
}

class ThemeService extends ChangeNotifier {
  static const _paletteKey = 'selected_palette';
  static const _isDarkKey = 'is_dark_mode';
  
  int _selectedPaletteIndex = 0;
  bool _isDarkMode = true;
  late Box _cache;

  ThemeService() {
    _init();
  }

  Future<void> _init() async {
    _cache = await Hive.openBox('arteia_cache');
    _selectedPaletteIndex = _cache.get(_paletteKey, defaultValue: 0);
    _isDarkMode = _cache.get(_isDarkKey, defaultValue: true);
    notifyListeners();
  }

  AppPalette get currentPalette => AppPalette.palettes[_selectedPaletteIndex];
  int get selectedIndex => _selectedPaletteIndex;
  bool get isDarkMode => _isDarkMode;

  Color get backgroundColor => _isDarkMode ? currentPalette.bgDark : currentPalette.bgLight;
  Color get cardColor => _isDarkMode ? currentPalette.cardDark : currentPalette.cardLight;
  Color get textColor => _isDarkMode ? Colors.white : Colors.black;
  Color get textSecondary => _isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

  void selectPalette(int index) {
    _selectedPaletteIndex = index;
    _cache.put(_paletteKey, index);
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _cache.put(_isDarkKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get theme {
    final palette = currentPalette;
    return ThemeData(
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
      cardColor: cardColor,
      primaryColor: palette.primaryViolet,
      colorScheme: ColorScheme(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primary: palette.primaryViolet,
        onPrimary: Colors.white,
        secondary: palette.primaryTeal,
        onSecondary: Colors.white,
        tertiary: palette.primaryPink,
        onTertiary: Colors.white,
        surface: cardColor,
        onSurface: textColor,
        error: Colors.red,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cardColor,
        selectedItemColor: palette.primaryViolet,
        unselectedItemColor: textSecondary,
      ),
      dividerColor: textSecondary.withOpacity(0.2),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor),
        bodyMedium: TextStyle(color: textColor),
        bodySmall: TextStyle(color: textSecondary),
      ),
    );
  }
}