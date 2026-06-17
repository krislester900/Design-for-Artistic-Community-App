import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _artworks = [];
  List<Map<String, dynamic>> _artists = [];
  List<Map<String, dynamic>> _stats = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _supabase.getCategories(),
        _supabase.getArtworks(limit: 10),
        _supabase.getArtists(limit: 10),
        _supabase.getCommunityStats(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0];
          _artworks = results[1];
          _artists = results[2];
          _stats = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Données de démonstration si la base est vide
        setState(() {
          _categories = [
            {'slug': 'music', 'title': 'Musique', 'short_label': '🎵', 'color': '#7C5CFC'},
            {'slug': 'visual-art', 'title': 'Art Visuel', 'short_label': '🎨', 'color': '#00D4AA'},
            {'slug': 'manga', 'title': 'Manga', 'short_label': '📚', 'color': '#FF6B9D'},
            {'slug': 'film', 'title': 'Films', 'short_label': '🎬', 'color': '#FFA500'},
          ];
          _artworks = [
            {'title': 'Sans titre', 'artist_name': 'Artiste 1', 'likes': 42, 'views': 128, 'medium': 'Digital'},
            {'title': 'Nuit étoilée', 'artist_name': 'Marie L.', 'likes': 89, 'views': 345, 'medium': 'Peinture'},
            {'title': 'Urban Life', 'artist_name': 'Jean D.', 'likes': 156, 'views': 512, 'medium': 'Photo'},
          ];
          _artists = [
            {'name': 'Marie L.', 'role': 'Peintre', 'likes': 234},
            {'name': 'Jean D.', 'role': 'Photographe', 'likes': 189},
            {'name': 'Sophie M.', 'role': 'Illustratrice', 'likes': 312},
          ];
          _stats = [
            {'label': 'Artistes', 'number_label': '1.2K'},
            {'label': 'Œuvres', 'number_label': '3.5K'},
            {'label': 'Communauté', 'number_label': '5.8K'},
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
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.primaryPink, size: 48),
            const SizedBox(height: 16),
            Text('Erreur de connexion', style: TextStyle(color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() { _isLoading = true; _error = null; });
                _loadData();
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryViolet,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppTheme.primaryViolet.withOpacity(0.3), blurRadius: 24)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bienvenue sur', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
                  const SizedBox(height: 4),
                  const Text('Artéïa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('La communauté artistique', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.explore, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Découvrir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Stats
            if (_stats.isNotEmpty) ...[
              Text('Statistiques', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _stats.length,
                  itemBuilder: (context, index) {
                    final stat = _stats[index];
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(stat['number_label'] ?? '0', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryViolet)),
                          Text(stat['label'] ?? '', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Categories
            if (_categories.isNotEmpty) ...[
              Text('Univers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final color = Color(int.parse((cat['color'] ?? '#7C5CFC').replaceFirst('#', '0xFF')));
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [color, color.withOpacity(0.3)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(cat['short_label'] ?? '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(cat['title'] ?? '', style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)), textAlign: TextAlign.center),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
            // Recent artworks
            if (_artworks.isNotEmpty) ...[
              Text('Œuvres récentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 12),
              ..._artworks.map((artwork) => _artworkCard(artwork)),
            ],
            // Recent artists
            if (_artists.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('Artistes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color)),
              const SizedBox(height: 12),
              ..._artists.map((artist) => _artistCard(artist)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _artworkCard(Map<String, dynamic> artwork) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryViolet.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image, color: AppTheme.primaryViolet, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artwork['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(artwork['artist_name'] ?? '', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 12, color: AppTheme.primaryPink),
                    const SizedBox(width: 3),
                    Text('${artwork['likes'] ?? 0}', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    const SizedBox(width: 12),
                    const Icon(Icons.visibility, size: 12, color: AppTheme.primaryCyan),
                    const SizedBox(width: 3),
                    Text('${artwork['views'] ?? 0}', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _artistCard(Map<String, dynamic> artist) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artist['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text(artist['role'] ?? '', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 12, color: AppTheme.primaryPink),
                    const SizedBox(width: 3),
                    Text('${artist['likes'] ?? 0}', style: TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}