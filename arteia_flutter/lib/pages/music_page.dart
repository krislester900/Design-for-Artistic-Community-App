import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_themes.dart';
import '../widgets/rive_loading.dart';
import '../widgets/spotify_playlist.dart';
import 'music_player_page.dart';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabase = SupabaseService();
  final ScrollController _scrollController = ScrollController();

  late final TabController _tabController;
  late CategoryTheme _theme;

  List<Map<String, dynamic>> _songs = [];
  List<Map<String, dynamic>> _trendTags = [];
  bool _isLoading = true;
  bool _showRiveSplash = true;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _theme = CategoryThemes.music;
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _supabase.getArtworks(categorySlug: 'music', limit: 24),
        _supabase.getTrendTags(categorySlug: 'music'),
      ]);

      if (!mounted) return;
      setState(() {
        _songs = _normalizeSongs(results[0]);
        _trendTags = results[1];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _songs = _fallbackSongs;
        _trendTags = _fallbackGenres;
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _normalizeSongs(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return _fallbackSongs;

    return items.map((item) {
      return {
        'title': item['title'] ?? 'Sans titre',
        'artist': item['artist_name'] ?? item['artist'] ?? 'Artiste Arteïa',
        'medium': item['medium'] ?? 'Single',
        'cover': item['image'] ?? '',
        'duration': item['duration'] ?? '3:24',
        'likes': item['likes'] ?? 0,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final headerOpacity = (_scrollOffset / 90).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0C),
      body: Stack(
        children: [
          AnimatedOpacity(
            opacity: headerOpacity,
            duration: const Duration(milliseconds: 120),
            child: Container(
              height: MediaQuery.of(context).padding.top + 58,
              color: const Color(0xFF121212),
            ),
          ),
          if (_showRiveSplash)
            RiveLoading(
              riveAsset: 'assets/animations/rock-girl.riv',
              onComplete: () {
                if (mounted) setState(() => _showRiveSplash = false);
              },
              durationInSeconds: 1.8,
            ),
          if (!_showRiveSplash)
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryViolet,
                    ),
                  )
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: MediaQuery.of(context).padding.top + 16,
                        ),
                      ),
                      SliverToBoxAdapter(child: _topBar(headerOpacity)),
                      SliverToBoxAdapter(child: _featuredAlbum()),
                      SliverToBoxAdapter(child: _tabs()),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 264,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _horizontalSongs(_songs.take(8).toList()),
                              _horizontalSongs(_songs.skip(4).take(8).toList()),
                              _horizontalSongs(_songs.skip(8).take(8).toList()),
                              _genrePanel(),
                              const MusicStudioPage(),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SpotifyPlaylist(
                          songs: _songs,
                          onSongTap: (index) => _openPlayer(_songs[index]),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 110)),
                    ],
                  ),
        ],
      ),
    );
  }

  Widget _topBar(double headerOpacity) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 120),
            style: TextStyle(
              fontSize: headerOpacity > 0.5 ? 20 : 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            child: const Text('Musique'),
          ),
          Row(
            children: [
              _roundIcon(Icons.search_rounded),
              const SizedBox(width: 12),
              _roundIcon(Icons.history_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _featuredAlbum() {
    final song = _songs.isNotEmpty ? _songs.first : _fallbackSongs.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      child: GestureDetector(
        onTap: () => _openPlayer(song),
        child: Container(
          height: 172,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: [_theme.primaryColor, const Color(0xFF111111)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _theme.primaryColor.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -16,
                top: -18,
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 150,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Nouveau son',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            song['title'] ?? 'Sans titre',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            song['artist'] ?? 'Artiste Arteïa',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFF42C83C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 36,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: Colors.white,
      unselectedLabelColor: Colors.grey[500],
      indicatorColor: const Color(0xFF42C83C),
      indicatorWeight: 3,
      tabAlignment: TabAlignment.start,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      tabs: [
        const Tab(text: 'Nouveautés'),
        const Tab(text: 'Vidéos'),
        const Tab(text: 'Artistes'),
        const Tab(text: 'Genres'),
        Tab(
          text: 'Créer ma musique',
          icon: const Icon(Icons.mic_rounded, size: 18),
        ),
      ],
    );
  }

  Widget _horizontalSongs(List<Map<String, dynamic>> songs) {
    final items = songs.isEmpty ? _songs.take(6).toList() : songs;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        final song = items[index];
        return GestureDetector(
          onTap: () => _openPlayer(song),
          child: SizedBox(
            width: 148,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _coverTile(song, size: 148),
                const SizedBox(height: 12),
                Text(
                  song['title'] ?? 'Sans titre',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  song['artist'] ?? 'Artiste',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _coverTile(Map<String, dynamic> song, {required double size}) {
    final cover = (song['cover'] ?? '').toString();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [_theme.primaryColor, _theme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (cover.isNotEmpty)
            cover.startsWith('http')
                ? Image.network(cover, fit: BoxFit.cover)
                : Image.asset(cover, fit: BoxFit.cover),
          if (cover.isEmpty)
            Icon(
              Icons.music_note_rounded,
              color: Colors.white.withOpacity(0.9),
              size: size * 0.38,
            ),
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              width: 38,
              height: 38,
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF42C83C),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.black,
                size: 26,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _genrePanel() {
    final tags = _trendTags.isEmpty ? _fallbackGenres : _trendTags;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 8),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              tag['tag'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _roundIcon(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  void _openPlayer(Map<String, dynamic> song) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MusicPlayerPage(song: song, theme: _theme),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

const List<Map<String, dynamic>> _fallbackSongs = [
  {
    'title': 'Nuit étoilée',
    'artist': 'Luna',
    'medium': 'Électro',
    'cover': 'assets/images/album1.png',
    'duration': '3:18',
    'likes': 234,
  },
  {
    'title': 'Urban Beat',
    'artist': 'DJ Metro',
    'medium': 'Hip-Hop',
    'cover': 'assets/images/album2.png',
    'duration': '2:56',
    'likes': 198,
  },
  {
    'title': 'Jazz Café',
    'artist': 'Trio Blue',
    'medium': 'Jazz',
    'cover': '',
    'duration': '4:02',
    'likes': 176,
  },
  {
    'title': 'Rock Anthem',
    'artist': 'The Wild',
    'medium': 'Rock',
    'cover': '',
    'duration': '3:44',
    'likes': 221,
  },
  {
    'title': 'Pop Dreams',
    'artist': 'Star Light',
    'medium': 'Pop',
    'cover': '',
    'duration': '3:31',
    'likes': 145,
  },
  {
    'title': 'Classical Mood',
    'artist': 'Orchestra',
    'medium': 'Classique',
    'cover': '',
    'duration': '5:10',
    'likes': 98,
  },
];

const List<Map<String, dynamic>> _fallbackGenres = [
  {'tag': 'Électro'},
  {'tag': 'Hip-Hop'},
  {'tag': 'Jazz'},
  {'tag': 'Rock'},
  {'tag': 'Pop'},
  {'tag': 'Classique'},
  {'tag': 'R&B'},
  {'tag': 'Reggae'},
];
