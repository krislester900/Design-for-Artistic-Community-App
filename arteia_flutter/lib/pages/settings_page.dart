import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/theme_service_simple.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ThemeService _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
        foregroundColor: Colors.black,
      ),
      body: ListenableBuilder(
        listenable: _themeService,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Apparence
                _buildSectionTitle('Apparence'),
                const SizedBox(height: 12),
                _buildThemeCard(),
                const SizedBox(height: 24),

                // Section Personnalisation
                _buildSectionTitle('Personnalisation'),
                const SizedBox(height: 12),
                Text(
                  'Choisissez une palette de couleurs pour personnaliser l\'application',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                _buildPalettesGrid(),
                const SizedBox(height: 24),

                // Section Informations
                _buildSectionTitle('Informations'),
                const SizedBox(height: 12),
                _buildInfoCard(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
    );
  }

  Widget _buildThemeCard() {
    final isDark = _themeService.isDarkMode;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: Colors.black,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDark ? 'Mode sombre' : 'Mode clair',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark ? 'Fond noir, texte blanc' : 'Fond blanc, texte noir',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (_) => _themeService.toggleDarkMode(),
            activeColor: Colors.black,
            activeTrackColor: Colors.black.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPalettesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: AppPalette.palettes.length,
      itemBuilder: (context, index) {
        final palette = AppPalette.palettes[index];
        final isSelected = _themeService.selectedIndex == index;
        final isDark = _themeService.isDarkMode;

        return GestureDetector(
          onTap: () => _themeService.selectPalette(index),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? palette.cardDark : palette.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Color preview row
                Row(
                  children: [
                    _colorPreview(palette.primaryViolet),
                    const SizedBox(width: 4),
                    _colorPreview(palette.primaryTeal),
                    const SizedBox(width: 4),
                    _colorPreview(palette.primaryPink),
                    const SizedBox(width: 4),
                    _colorPreview(palette.accentGold),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(palette.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        palette.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? palette.primaryViolet : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: palette.primaryViolet,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 12),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _colorPreview(Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _infoRow(Icons.palette, 'Palette active', '${_themeService.currentPalette.emoji} ${_themeService.currentPalette.name}'),
          const Divider(height: 20),
          _infoRow(Icons.brightness_6, 'Thème', _themeService.isDarkMode ? 'Sombre' : 'Clair'),
          const Divider(height: 20),
          _infoRow(Icons.info_outline, 'Version', '1.0.0'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
      ],
    );
  }
}