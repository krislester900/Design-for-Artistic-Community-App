import 'package:flutter/material.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

class ThemeCustomizerPage extends StatelessWidget {
  const ThemeCustomizerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = ThemeService();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Personnalisation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        actions: [
          // Toggle nuit/jour
          IconButton(
            icon: Icon(
              themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: AppTheme.primaryViolet,
            ),
            onPressed: () {
              themeService.toggleDarkMode();
              // Forcer le rebuild
              (context as Element).reassemble();
            },
            tooltip: themeService.isDarkMode ? 'Mode clair' : 'Mode sombre',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode nuit/jour
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      themeService.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      color: AppTheme.primaryViolet,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          themeService.isDarkMode ? 'Mode sombre' : 'Mode clair',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Changez entre les thèmes sombre et clair',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: themeService.isDarkMode,
                    onChanged: (_) {
                      themeService.toggleDarkMode();
                    },
                    activeColor: AppTheme.primaryViolet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Titre palettes
            const Text('Palettes de couleurs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Choisissez une palette qui correspond à votre style',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),

            // Grille des palettes
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: AppPalette.palettes.length,
              itemBuilder: (context, index) {
                final palette = AppPalette.palettes[index];
                final isSelected = themeService.selectedIndex == index;

                return GestureDetector(
                  onTap: () {
                    themeService.selectPalette(index);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? palette.primaryViolet : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: palette.primaryViolet.withOpacity(0.3), blurRadius: 12)]
                          : [],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview des couleurs
                        Row(
                          children: [
                            _ColorPreview(color: palette.primaryViolet),
                            const SizedBox(width: 4),
                            _ColorPreview(color: palette.primaryTeal),
                            const SizedBox(width: 4),
                            _ColorPreview(color: palette.primaryPink),
                            const SizedBox(width: 4),
                            _ColorPreview(color: palette.accentGold),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Text(palette.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                palette.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? palette.primaryViolet : Colors.white,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: palette.primaryViolet,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, color: Colors.white, size: 14),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Aperçu en direct
            const Text('Aperçu en direct', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              themeService.currentPalette.primaryViolet,
                              themeService.currentPalette.primaryTeal,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.palette, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bouton principal',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textColor),
                            ),
                            Text(
                              'Couleur: ${themeService.currentPalette.name}',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeService.currentPalette.primaryViolet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Bouton violet'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeService.currentPalette.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Bouton teal'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: Color(0xFFFF6B9D), size: 20),
                      const SizedBox(width: 6),
                      Text('${themeService.currentPalette.primaryPink.value.toRadixString(16).padLeft(8, '0')}'),
                      const SizedBox(width: 16),
                      const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                      const SizedBox(width: 6),
                      Text('${themeService.currentPalette.accentGold.value.toRadixString(16).padLeft(8, '0')}'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorPreview extends StatelessWidget {
  final Color color;

  const _ColorPreview({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
    );
  }
}