import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardItem(
      icon: Icons.palette_outlined,
      title: 'Créez sans limite',
      subtitle: 'Partagez vos œuvres, musiques et écrits dans une communauté dédiée aux artistes.',
    ),
    _OnboardItem(
      icon: Icons.people_outline,
      title: 'Connectez-vous',
      subtitle: 'Trouvez des contacts par email ou téléphone et échangez en privé.',
    ),
    _OnboardItem(
      icon: Icons.auto_awesome_rounded,
      title: 'Inspirez-vous',
      subtitle: 'Explorez l’univers, sauvegardez vos favoris et laissez l’IA muse vous accompagner.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final item = _pages[index];
                  return _OnboardCard(item: item);
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => _dot(i == _page)),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton(
                onPressed: widget.onComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryViolet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.primaryViolet.withValues(alpha: 0.4),
                ),
                child: Text(_page == _pages.length - 1 ? 'Commencer' : 'Suivant', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _dot(bool active) {
    return AnimatedContainer(duration: const Duration(milliseconds: 300), width: active ? 18 : 8, height: 8, margin: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: active ? AppTheme.primaryViolet : Colors.white24, borderRadius: BorderRadius.circular(8)));
  }
}

class _OnboardCard extends StatelessWidget {
  final _OnboardItem item;
  const _OnboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(28)),
            child: Icon(item.icon, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(item.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(item.subtitle, style: TextStyle(fontSize: 15, color: AppTheme.textMuted, height: 1.6), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _OnboardItem {
  final IconData icon;
  final String title;
  final String subtitle;
  const _OnboardItem({required this.icon, required this.title, required this.subtitle});
}
