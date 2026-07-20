import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String albumCover;
  final String youtubeId;
  final String? albumName;
  final int? year;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumCover,
    required this.youtubeId,
    this.albumName,
    this.year,
  });
}

const List<Song> _defaultSongs = [
  Song(
    id: 'song-0',
    title: 'Generous',
    artist: 'Doja Cat',
    albumName: 'Planet Her',
    year: 2021,
    youtubeId: 'o2m8UHK_tUU',
    albumCover: 'assets/images/covers/generous_doja_cat.jpg',
  ),
  Song(
    id: 'song-1',
    title: 'Midnight Dreams',
    artist: 'Luna Nova',
    albumName: 'Neon Dreams',
    year: 2023,
    youtubeId: 'dQw4w9WgXcQ',
    albumCover: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop',
  ),
  Song(
    id: 'song-2',
    title: 'Neon Nights',
    artist: 'DJ Prism',
    albumName: 'Electric Soul',
    year: 2022,
    youtubeId: 'kJQP7kiw5Fk',
    albumCover: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&h=400&fit=crop',
  ),
  Song(
    id: 'song-3',
    title: 'Summer Vibes',
    artist: 'Solaris',
    albumName: 'Sunset Sessions',
    year: 2023,
    youtubeId: '3JZ_D3ELwOQ',
    albumCover: 'https://images.unsplash.com/photo-1518770660439-4636190af475?w=400&h=400&fit=crop',
  ),
  Song(
    id: 'song-4',
    title: 'Digital Love',
    artist: 'Neon Wave',
    albumName: 'Cyber Pop',
    year: 2022,
    youtubeId: 'fJ9rUzIMcZQ',
    albumCover: 'https://images.unsplash.com/photo-1526401294524-0d9ce2a661d6?w=400&h=400&fit=crop',
  ),
  Song(
    id: 'song-5',
    title: 'Purple Haze',
    artist: 'Electric Sky',
    albumName: 'Synthwave Dreams',
    year: 2023,
    youtubeId: 'hT_nvWreIhg',
    albumCover: 'https://images.unsplash.com/photo-1511512578047-639691d6ac95?w=400&h=400&fit=crop',
  ),
];

class VynoraMusicPage extends StatefulWidget {
  const VynoraMusicPage({super.key});

  @override
  State<VynoraMusicPage> createState() => _VynoraMusicPageState();
}

class _VynoraMusicPageState extends State<VynoraMusicPage> {
  int _currentIndex = 0;
  bool _isPlaying = false;
  late final YoutubePlayerController _audioPlayerController;
  late final YoutubePlayerController _backgroundPlayerController;

  static const Color _bgPrimary = Color(0xFF000000);
  static const Color _bgSecondary = Color(0xFF111111);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFF9CA3AF);
  static const Color _textTertiary = Color(0xFF6B7280);
  static const Color _greenBattery = Color(0xFF4ADE80);
  static const Color _whiteGlow = Color(0x30FFFFFF);

  @override
  void initState() {
    super.initState();
    _initializePlayers();
  }

  void _initializePlayers() {
    final initialSong = _songs[_currentIndex];
    _audioPlayerController = YoutubePlayerController.fromVideoId(
      videoId: initialSong.youtubeId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
      ),
    );

    _backgroundPlayerController = YoutubePlayerController.fromVideoId(
      videoId: initialSong.youtubeId,
      autoPlay: false,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
      ),
    );

    _audioPlayerController.listen((playerState) {
      final isPlaying = playerState.toString() == 'YoutubePlayerState.playing';
      setState(() => _isPlaying = isPlaying);
      
      // Sync background player with audio player
      if (isPlaying) {
        _backgroundPlayerController.playVideo();
      } else {
        _backgroundPlayerController.pauseVideo();
      }
    });

    // Initialize background player to be ready
    _backgroundPlayerController.loadVideoById(
      videoId: initialSong.youtubeId,
      startSeconds: 0,
    );
  }

  @override
  void dispose() {
    _audioPlayerController.close();
    _backgroundPlayerController.close();
    super.dispose();
  }

  List<Song> get _songs => _defaultSongs;

  Song get _currentSong => _songs[_currentIndex];

  void _playVideo(String youtubeId) {
    _audioPlayerController.loadVideoById(
      videoId: youtubeId,
      startSeconds: 0,
    );
    
    _backgroundPlayerController.loadVideoById(
      videoId: youtubeId,
      startSeconds: 0,
    );
    
    // Start playing the newly loaded video
    _audioPlayerController.playVideo();
    _backgroundPlayerController.playVideo();
  }

  void _selectSong(int index) {
    if (index < 0 || index >= _songs.length) return;
    
    setState(() {
      _currentIndex = index;
      _isPlaying = true;
    });
    
    _playVideo(_songs[index].youtubeId);
  }

  void _nextSong() {
    if (_currentIndex < _songs.length - 1) {
      _selectSong(_currentIndex + 1);
    }
  }

  void _prevSong() {
    if (_currentIndex > 0) {
      _selectSong(_currentIndex - 1);
    }
  }

  void _togglePlay() {
    setState(() => _isPlaying = !_isPlaying);
    
    if (_isPlaying) {
      _audioPlayerController.playVideo();
      _backgroundPlayerController.playVideo();
    } else {
      _audioPlayerController.pauseVideo();
      _backgroundPlayerController.pauseVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPrimary,
      body: Stack(
        children: [
          // Background video for visualizer effect (behind everything)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: YoutubePlayer(
                controller: _backgroundPlayerController,
              ),
            ),
          ),
          
          // YouTube Player for the music (in background, hidden)
          IgnorePointer(
            ignoring: true,
            child: YoutubePlayer(
              controller: _audioPlayerController,
            ),
          ),

          // Reflective floor
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_bgSecondary, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // iPod-style header
                _buildHeader(),

                // Album cover display (simplified version of CoverFlow)
                Expanded(
                  child: Center(
                    child: _buildAlbumDisplay(),
                  ),
                ),

                // Track info + Player
                _buildPlayerSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgPrimary.withOpacity(0.2),
        border: Border(bottom: BorderSide(color: _textPrimary.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _textPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'iPod',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 16,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: _textPrimary.withOpacity(0.4), width: 1),
            ),
            child: Row(
              children: List.generate(4, (i) {
                final level = i < 3;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: i == 0 ? 1 : 0,
                      right: i == 3 ? 1 : 0,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      color: level ? _greenBattery : _textPrimary.withOpacity(0.2),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumDisplay() {
    final song = _currentSong;
    
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _textPrimary.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        image: song.albumCover.startsWith('http')
            ? DecorationImage(
                image: NetworkImage(song.albumCover),
                fit: BoxFit.cover,
              )
            : DecorationImage(
                image: AssetImage(song.albumCover),
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Widget _buildPlayerSection() {
    final song = _currentSong;
    
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: _bgPrimary.withOpacity(0.85),
        border: Border(top: BorderSide(color: _textPrimary.withOpacity(0.08))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Track info
          Text(
            song.title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            song.artist,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              _controlButton(
                icon: Icons.skip_previous_rounded,
                iconSize: 28,
                size: 56,
                onTap: _prevSong,
                label: 'Previous',
              ),
              const SizedBox(width: 32),
              
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlay,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _textPrimary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _textPrimary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: _isPlaying
                        ? Icon(
                            Icons.pause_rounded,
                            color: _bgPrimary,
                            size: 36,
                            key: const ValueKey('pause'),
                          )
                        : Icon(
                            Icons.play_arrow_rounded,
                            color: _bgPrimary,
                            size: 36,
                            key: const ValueKey('play'),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              
              // Next button
              _controlButton(
                icon: Icons.skip_next_rounded,
                iconSize: 28,
                size: 56,
                onTap: _nextSong,
                label: 'Next',
              ),
            ],
          ),
          
          // Status text
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _isPlaying ? 'Now Playing' : 'Tap to play',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required double iconSize,
    required double size,
    required VoidCallback onTap,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
children: [
         GestureDetector(
           onTap: onTap,
           child: Container(
             width: size,
             height: size,
             decoration: BoxDecoration(
               color: _textPrimary.withOpacity(0.1),
               shape: BoxShape.circle,
               border: Border.all(
                 color: _textPrimary.withOpacity(0.2),
               ),
             ),
             child: Icon(
               icon,
               color: _textPrimary,
               size: iconSize,
             ),
           ),
         ),
         const SizedBox(height: 4),
         Text(
           label,
           style: TextStyle(
             color: _textSecondary,
             fontSize: 10,
           ),
         ),
       ],
    );
  }
}