import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../services/localization_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ThemeService _themeService = ThemeService();
  final LocalizationService _localizationService = LocalizationService();

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
        listenable: Listenable.merge([_themeService, _localizationService]),
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SECTION 1: Apparence
                _buildSectionTitle('Apparence'),
                const SizedBox(height: 12),
                _buildThemeCard(),
                const SizedBox(height: 24),

                // SECTION 2: Personnalisation (palettes)
                _buildSectionTitle('Personnalisation'),
                const SizedBox(height: 12),
                Text(
                  'Choisissez une palette de couleurs pour personnaliser l\'application',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                _buildPalettesGrid(),
                const SizedBox(height: 24),

                // SECTION 3: Langue & Région
                _buildSectionTitle('Langue & Région'),
                const SizedBox(height: 12),
                _buildLanguageCard(),
                const SizedBox(height: 24),

                // SECTION 4: Notifications
                _buildSectionTitle('Notifications'),
                const SizedBox(height: 12),
                _buildNotificationsCard(),
                const SizedBox(height: 24),

                // SECTION 5: Cache & Stockage
                _buildSectionTitle('Cache & Stockage'),
                const SizedBox(height: 12),
                _buildCacheCard(),
                const SizedBox(height: 24),

                // SECTION 6: Confidentialité
                _buildSectionTitle('Confidentialité'),
                const SizedBox(height: 12),
                _buildPrivacyCard(),
                const SizedBox(height: 24),

                // SECTION 7: À propos
                _buildSectionTitle('À propos'),
                const SizedBox(height: 12),
                _buildAboutCard(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============= WIDGETS SECTIONS =============

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
    );
  }

  Widget _buildThemeCard() {
    final isDark = _themeService.isDarkMode;
    return _settingsCard(
      child: Row(
        children: [
          _iconContainer(isDark ? Icons.dark_mode : Icons.light_mode),
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

  Widget _buildLanguageCard() {
    return _settingsCard(
      child: Column(
        children: [
          _settingRow(
            icon: Icons.language,
            title: 'Langue',
            subtitle: _localizationService.languageName(_localizationService.currentLang),
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onTap: () => _showLanguagePicker(),
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.public,
            title: 'Région',
            subtitle: 'France',
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onTap: () {},
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.access_time,
            title: 'Fuseau horaire',
            subtitle: 'UTC+1 (Paris)',
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showLanguagePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir la langue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _localizationService.supportedLanguages.map((lang) {
            final isSelected = _localizationService.currentLang == lang;
            return ListTile(
              leading: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? Colors.black : Colors.grey,
              ),
              title: Text(
                _localizationService.languageName(lang),
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.black : Colors.black87,
                ),
              ),
              subtitle: Text(lang == 'fr' ? 'Français' : 'English'),
              onTap: () {
                _localizationService.setLang(lang);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return _settingsCard(
      child: Column(
        children: [
          _settingRow(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications push',
            subtitle: 'Recevoir des alertes',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: Colors.black,
              activeTrackColor: Colors.black.withOpacity(0.3),
            ),
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.favorite_outline,
            title: 'Likes et commentaires',
            subtitle: 'Quand on aime vos publications',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: Colors.black,
              activeTrackColor: Colors.black.withOpacity(0.3),
            ),
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.people_outline,
            title: 'Nouveaux abonnés',
            subtitle: 'Quand quelqu\'un vous suit',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: Colors.black,
              activeTrackColor: Colors.black.withOpacity(0.3),
            ),
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.message_outlined,
            title: 'Messages',
            subtitle: 'Nouveaux messages privés',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: Colors.black,
              activeTrackColor: Colors.black.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheCard() {
    return _settingsCard(
      child: Column(
        children: [
          _settingRow(
            icon: Icons.storage,
            title: 'Cache images',
            subtitle: '24 images en cache (320 Ko)',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Vider', style: TextStyle(color: Colors.red, fontSize: 13)),
            ),
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.offline_bolt,
            title: 'Téléchargements',
            subtitle: '12 œuvres sauvegardées',
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Gérer', style: TextStyle(color: Colors.black, fontSize: 13)),
            ),
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.wifi,
            title: 'Téléchargement auto',
            subtitle: 'Wi-Fi uniquement',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: Colors.black,
              activeTrackColor: Colors.black.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return _settingsCard(
      child: Column(
        children: [
          _settingRow(
            icon: Icons.visibility_outlined,
            title: 'Profil public',
            subtitle: 'Visible par tous',
            trailing: Switch(
              value: true,
              onChanged: (_) {},
              activeColor: Colors.black,
              activeTrackColor: Colors.black.withOpacity(0.3),
            ),
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.near_me_disabled,
            title: 'Activité en ligne',
            subtitle: 'Masquer mon statut',
            trailing: Switch(
              value: false,
              onChanged: (_) {},
              activeColor: Colors.black,
              activeTrackColor: Colors.black.withOpacity(0.3),
            ),
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.block,
            title: 'Comptes bloqués',
            subtitle: 'Aucun compte bloqué',
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return _settingsCard(
      child: Column(
        children: [
          _infoRow(Icons.palette, 'Palette active', '${_themeService.currentPalette.emoji} ${_themeService.currentPalette.name}'),
          const Divider(height: 1),
          _infoRow(Icons.brightness_6, 'Thème', _themeService.isDarkMode ? 'Sombre' : 'Clair'),
          const Divider(height: 1),
          _infoRow(Icons.language, 'Langue', _localizationService.languageName(_localizationService.currentLang)),
          const Divider(height: 1),
          _infoRow(Icons.info_outline, 'Version', '1.0.0'),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.code,
            title: 'Développeurs',
            subtitle: 'Artéïa Team',
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onTap: () {},
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.description,
            title: 'Conditions d\'utilisation',
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onTap: () {},
          ),
          const Divider(height: 1),
          _settingRow(
            icon: Icons.shield,
            title: 'Politique de confidentialité',
            trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ============= PALETTES GRID =============

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

  // ============= HELPERS =============

  Widget _settingsCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: child,
    );
  }

  Widget _iconContainer(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.black, size: 22),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.black)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black)),
        ],
      ),
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
}