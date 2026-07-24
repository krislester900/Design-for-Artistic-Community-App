import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class MusicPlayerPage extends StatefulWidget {
  final Map<String, dynamic> song;

  const MusicPlayerPage({
    super.key,
    required this.song,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _position = 0.0;
  Duration _duration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _setupPlayer();
  }

  Future<void> _setupPlayer() async {
    try {
      final audioUrl = widget.song['audio_url'] ?? widget.song['audioUrl'] ?? '';
      if (audioUrl.isNotEmpty) {
        await _audioPlayer.setUrl(audioUrl);
      }

      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
            _isLoading = false;
          });
        }
      });

      _audioPlayer.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _position = _duration.inMilliseconds > 0
                ? position.inMilliseconds / _duration.inMilliseconds
                : 0.0;
          });
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted) setState(() => _isPlaying = state.playing);
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePlay() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (_) {}
    setState(() {});
  }

  Future<void> _seekTo(double value) async {
    final position = Duration(milliseconds: (value * _duration.inMilliseconds).round());
    await _audioPlayer.seek(position);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.song['title'] ?? 'Sans titre';
    final artist = widget.song['artist'] ?? 'Artiste Arteïa';
    final cover = widget.song['cover'] ?? widget.song['coverUrl'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(26, 18, 26, 32),
                child: Column(
                  children: [
                    // Cover
                    Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.1),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: cover.isNotEmpty
                            ? Image.network(
                                cover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1A1A1A),
                                  child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 64),
                                ),
                              )
                            : Container(
                                color: const Color(0xFF1A1A1A),
                                child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 64),
                              ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Title + artist
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Progress
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: Colors.white,
                                  inactiveTrackColor: Colors.white.withOpacity(0.14),
                                  thumbColor: Colors.white,
                                  overlayColor: Colors.white.withOpacity(0.16),
                                  trackHeight: 4,
                                ),
                                child: Slider(
                                  min: 0,
                                  max: 1,
                                  value: _position,
                                  onChanged: _seekTo,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_currentPosition),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                    Text(
                                      _formatDuration(_duration),
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                    const SizedBox(height: 34),

                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _controlButton(icon: Icons.skip_previous_rounded, size: 56, onTap: () {}),
                        const SizedBox(width: 32),
                        _controlButton(
                          icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 80,
                          isMain: true,
                          onTap: _togglePlay,
                        ),
                        const SizedBox(width: 32),
                        _controlButton(icon: Icons.skip_next_rounded, size: 56, onTap: () {}),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required double size,
    bool isMain = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: isMain ? Colors.white : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: isMain
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          color: isMain ? Colors.black : Colors.white,
          size: isMain ? 36 : 24,
        ),
      ),
    );
  }
}
