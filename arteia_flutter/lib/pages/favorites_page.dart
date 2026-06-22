import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/favorites_service.dart';
import '../theme/app_theme.dart';
import 'post_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with SingleTickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  final SupabaseService _supabase = SupabaseService();
  
  late TabController _tabController;
  List<Map<String, dynamic>> _favoriteArtworks = [];
  List<Map<String, dynamic>> _bookmarkedArtworks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _favoritesService.getFavoriteArtworks(),
        _favoritesService.getBookmarkedArtworks(),
      ]);

      if (mounted) {
        setState(() {
          _favoriteArtworks = results[0];
          _bookmarkedArtworks = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(String artworkId) async {
    final wasFavorited = _favoriteArtworks.any((a) => a['id'] == artworkId);
    
    setState(() {
      if (wasFavorited) {
        _favoriteArtworks.removeWhere((a) => a['id'] == artworkId);
      }
    });

    await _favoritesService.toggleFavoriteArtwork(artworkId);
  }

  Future<void> _toggleBookmark(String artworkId) async {
    final wasBookmarked = _bookmarkedArtworks.any((a) => a['id'] == artworkId);
    
    setState(() {
      if (wasBookmarked) {
        _bookmarkedArtworks.removeWhere((a) => a['id'] == artworkId);
      }
    });

    await _favoritesService.toggleBookmarkArtwork(artworkId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Favoris', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryViolet,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Favoris (${_favoriteArtworks.length})'),
            Tab(text: 'Enregistrés (${_bookmarkedArtworks.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
          : _error != null
              ? _buildErrorView()
              : _supabase.currentUser == null
                  ? _buildLoginPrompt()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildArtworkList(_favoriteArtworks, isFavorite: true),
                        _buildArtworkList(_bookmarkedArtworks, isFavorite: false),
                      ],
                    ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text('Erreur de chargement', style: TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text('Connectez-vous', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Pour voir vos favoris et œuvres enregistrées',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkList(List<Map<String, dynamic>> artworks, {required bool isFavorite}) {
    if (artworks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isFavorite ? Icons.favorite_border : Icons.bookmark_border, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              Text(
                isFavorite ? 'Aucun favori' : 'Aucun enregistrement',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                isFavorite ? 'Likez des œuvres pour les retrouver ici' : 'Enregistrez des œuvres pour plus tard',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryViolet,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: artworks.length,
        itemBuilder: (context, index) {
          final artwork = artworks[index];
          return _ArtworkCard(
            artwork: artwork,
            isFavorite: isFavorite,
            onToggleFavorite: () => _toggleFavorite(artwork['id']),
            onToggleBookmark: () => _toggleBookmark(artwork['id']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailPage(post: artwork),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  final Map<String, dynamic> artwork;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onToggleBookmark;
  final VoidCallback onTap;

  const _ArtworkCard({
    required this.artwork,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onToggleBookmark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = artwork['image_url'];
    final title = artwork['title'] ?? 'Sans titre';
    final artistName = artwork['artist_name'] ?? 'Artiste';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              child: imageUrl != null && (imageUrl as String).isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppTheme.cardDarkLight,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.cardDarkLight,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        );
                      },
                    )
                  : Container(
                      color: AppTheme.cardDarkLight,
                      child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                    ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artistName,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isFavorite ? AppTheme.primaryPink : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onToggleBookmark,
                        child: Icon(
                          Icons.bookmark,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
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