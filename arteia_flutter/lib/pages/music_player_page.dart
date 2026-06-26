import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/category_themes.dart';

class MusicPlayerPage extends StatefulWidget {
  final Map<String, dynamic> song;
  final CategoryTheme theme;

  const MusicPlayerPage({
    super.key,
    required this.song,
    required this.theme,
  });

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isFavorite = false;
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
        if (mounted) {
          setState(() => _isPlaying = state.playing);
        }
      });
    } catch (e) {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lecture: $e'), backgroundColor: Colors.red),
        );
      }
    }
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
    final duration = widget.song['duration'] ?? '3:24';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Lecture',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(26, 18, 26, 32),
          child: Column(
            children: [
              _cover(),
              const SizedBox(height: 28),
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
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isFavorite = !_isFavorite),
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color:
                          _isFavorite ? widget.theme.accentColor : Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator(color: Colors.white)
              else
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: widget.theme.accentColor,
                    inactiveTrackColor: Colors.white.withOpacity(0.14),
                    thumbColor: Colors.white,
                    overlayColor: widget.theme.accentColor.withOpacity(0.16),
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
              const SizedBox(height: 34),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _control(Icons.skip_previous_rounded, 54, () {}),
                  const SizedBox(width: 22),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFF42C83C),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(width: 22),
                  _control(Icons.skip_next_rounded, 54, () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cover() {
    final cover = (widget.song['cover'] ?? '').toString();

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [widget.theme.primaryColor, widget.theme.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.theme.primaryColor.withOpacity(0.35),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
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
                size: 96,
              ),
          ],
        ),
      ),
    );
  }

  Widget _control(IconData icon, double size, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }

}
