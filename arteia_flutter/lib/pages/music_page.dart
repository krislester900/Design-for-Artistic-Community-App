import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _artworks = [];
  List<Map<String, dynamic>> _trendTags = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _supabase.getArtworks(categorySlug: 'music', limit: 20),
        _supabase.getTrendTags(categorySlug: 'music'),
      ]);
      if (mounted) setState(() {
        _artworks = results[0];
        _trendTags = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        // Données de démonstration
        setState(() {
          _artworks = [
            {'title': 'Nuit Étoilée', 'artist_name': 'Luna', 'medium': 'Électro'},
            {'title': 'Urban Beat', 'artist_name': 'DJ Metro', 'medium': 'Hip-Hop'},
            {'title': 'Jazz Café', 'artist_name': 'Trio Blue', 'medium': 'Jazz'},
            {'title': 'Rock Anthem', 'artist_name': 'The Wild', 'medium': 'Rock'},
            {'title': 'Pop Dreams', 'artist_name': 'Star Light', 'medium': 'Pop'},
            {'title': 'Classical Mood', 'artist_name': 'Orchestra', 'medium': 'Classique'},
          ];
          _trendTags = [
            {'tag': 'Électro'},
            {'tag': 'Hip-Hop'},
            {'tag': 'Jazz'},
            {'tag': 'Rock'},
            {'tag': 'Pop'},
            {'tag': 'Classique'},
            {'tag': 'R&B'},
            {'tag': 'Reggae'},
          ];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerOpacity = (_scrollOffset / 80).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Dark header background that fades in
          if (_scrollOffset > 0)
            AnimatedOpacity(
              opacity: headerOpacity,
              duration: const Duration(milliseconds: 50),
              child: Container(
                height: MediaQuery.of(context).padding.top + 56,
                color: const Color(0xFF121212),
              ),
            ),
          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: AnimatedOpacity(
              opacity: headerOpacity < 0.5 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Musique', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.white.withOpacity(0.8), size: 24),
                      const SizedBox(width: 20),
                      Icon(Icons.settings, color: Colors.white.withOpacity(0.8), size: 24),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Content
          _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
            : CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 60)),
                  // Recently played
                  if (_artworks.isNotEmpty) ...[
                    _sectionHeader('Récent', null),
                    _albumHorizontalList(_artworks.take(6).toList()),
                  ],
                  // Heavy rotation
                  if (_artworks.length > 6) ...[
                    _sectionHeader('Tendances', 'Ce qui tourne en ce moment'),
                    _albumHorizontalList(_artworks.skip(6).take(6).toList()),
                  ],
                  // Jump back in
                  if (_artworks.length > 12) ...[
                    _sectionHeader('À découvrir', 'Suggestions pour toi'),
                    _albumHorizontalList(_artworks.skip(12).toList()),
                  ],
                  // Genres / Tags
                  if (_trendTags.isNotEmpty) ...[
                    _sectionHeader('Genres', null),
                    SliverPadding(
                      padding: const EdgeInsets.only(left: 16, bottom: 32),
                      sliver: SliverToBoxAdapter(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _trendTags.map((tag) => _genreChip(tag['tag'] ?? '')).toList(),
                        ),
                      ),
                    ),
                  ],
                  // Bottom padding
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String? subtitle) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _albumHorizontalList(List<Map<String, dynamic>> items) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: ListView.builder(
          padding: const EdgeInsets.only(left: 16),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _albumCard(
              title: item['title'] ?? 'Sans titre',
              artist: item['artist_name'] ?? '',
              subtitle: item['medium'] ?? '',
            );
          },
        ),
      ),
    );
  }

  Widget _albumCard({required String title, String artist = '', String subtitle = ''}) {
    return Container(
      width: 148,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album art placeholder
          Container(
            width: 148,
            height: 148,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryViolet, Color(0xFF2A1A5E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note, color: Colors.white, size: 40),
                if (artist.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(artist, style: const TextStyle(fontSize: 9, color: Colors.white70), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500]), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }

  Widget _genreChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}