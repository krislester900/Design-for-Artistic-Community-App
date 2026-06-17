import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'universe_page.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  void _openUniverse(String slug, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UniversePage(slug: slug)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _supabase.getCategories();
      if (mounted) setState(() { _categories = categories; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        // Données de démonstration
        setState(() {
          _categories = [
            {'slug': 'music', 'title': 'Musique', 'description': 'Artistes et albums', 'color': '#7C5CFC'},
            {'slug': 'visual-art', 'title': 'Art Visuel', 'description': 'Peinture, sculpture, photo', 'color': '#00D4AA'},
            {'slug': 'manga', 'title': 'Manga', 'description': 'BD japonaise et illustrations', 'color': '#FF6B9D'},
            {'slug': 'film', 'title': 'Films', 'description': 'Cinéma et séries', 'color': '#FFA500'},
            {'slug': 'literature', 'title': 'Littérature', 'description': 'Romans et poésie', 'color': '#4ECDC4'},
            {'slug': 'animation', 'title': 'Animation', 'description': 'Court-métrages et GIFs', 'color': '#FF6B6B'},
          ];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet));
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      color: AppTheme.primaryViolet,
      child: _categories.isEmpty
          ? Center(child: Text('Aucun univers disponible', style: TextStyle(color: AppTheme.textMuted)))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final color = Color(int.parse((cat['color'] ?? '#7C5CFC').replaceFirst('#', '0xFF')));
                return GestureDetector(
                  onTap: () => _openUniverse(cat['slug'] ?? '', cat['title'] ?? ''),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [color, color.withOpacity(0.3)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 16)],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getIconForCategory(cat['slug']), color: Colors.white, size: 36),
                        const SizedBox(height: 12),
                        Text(cat['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(cat['description'] ?? '', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getIconForCategory(String? slug) {
    switch (slug) {
      case 'music': return Icons.music_note;
      case 'visual-art': return Icons.palette;
      case 'manga': return Icons.menu_book;
      case 'film': return Icons.movie;
      case 'literature': return Icons.edit_note;
      case 'animation': return Icons.animation;
      default: return Icons.category;
    }
  }
}