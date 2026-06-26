import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../theme/app_theme.dart';

class ThoughtBubbleAudio extends StatefulWidget {
  final String? audioUrl;
  final String? text;
  final String authorName;
  final String? authorAvatar;
  final Duration? duration;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onTap;

  const ThoughtBubbleAudio({
    super.key,
    this.audioUrl,
    this.text,
    required this.authorName,
    this.authorAvatar,
    this.duration,
    this.isPlaying = false,
    this.onPlayPause,
    this.onTap,
  });

  @override
  State<ThoughtBubbleAudio> createState() => _ThoughtBubbleAudioState();
}

class _ThoughtBubbleAudioState extends State<ThoughtBubbleAudio> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  double _currentPosition = 0.0;
  bool _isLoading = false;
  Duration? _totalDuration;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position.inSeconds.toDouble();
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isLoading = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _currentPosition = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    if (widget.audioUrl == null) return;

    try {
      if (widget.isPlaying) {
        await _audioPlayer.pause();
      } else {
        setState(() => _isLoading = true);
        await _audioPlayer.play(UrlSource(widget.audioUrl!));
        setState(() => _isLoading = false);
      }
      if (widget.onPlayPause != null) {
        widget.onPlayPause!();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lecture: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final displayDuration = widget.duration ?? _totalDuration ?? Duration.zero;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.isPlaying 
                ? Colors.white.withOpacity(0.5) 
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      widget.authorAvatar ?? widget.authorName[0].toUpperCase(),
                      style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.authorName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (widget.isPlaying)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'En lecture',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
            
            // Thought text (if provided)
            if (widget.text != null && widget.text!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.cardDarkLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.psychology, size: 16, color: Colors.white54),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.text!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[300],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Audio player controls (only if audio exists)
            if (widget.audioUrl != null) ...[
              Row(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: _isLoading ? null : _togglePlayPause,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Icon(
                              widget.isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.black,
                              size: 24,
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Progress bar and time
                  Expanded(
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: displayDuration.inSeconds > 0
                                ? _currentPosition / displayDuration.inSeconds
                                : 0.0,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.isPlaying ? Colors.white : Colors.grey,
                            ),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(Duration(seconds: _currentPosition.toInt())),
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                            Text(
                              _formatDuration(displayDuration),
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Audio wave icon
                  Icon(
                    Icons.graphic_eq,
                    size: 20,
                    color: widget.isPlaying ? Colors.white : Colors.grey[600],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ThoughtBubbleAudioPlayer extends StatefulWidget {
  final String audioUrl;
  final String? text;
  final String authorName;
  final String? authorAvatar;
  final Duration duration;

  const ThoughtBubbleAudioPlayer({
    super.key,
    required this.audioUrl,
    this.text,
    required this.authorName,
    this.authorAvatar,
    required this.duration,
  });

  @override
  State<ThoughtBubbleAudioPlayer> createState() => _ThoughtBubbleAudioPlayerState();
}

class _ThoughtBubbleAudioPlayerState extends State<ThoughtBubbleAudioPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  double _currentPosition = 0.0;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position.inSeconds.toDouble();
        });
      }
    });
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _currentPosition = 0.0;
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lecture: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ThoughtBubbleAudio(
      audioUrl: widget.audioUrl,
      text: widget.text,
      authorName: widget.authorName,
      authorAvatar: widget.authorAvatar,
      duration: widget.duration,
      isPlaying: _isPlaying,
      onPlayPause: _togglePlayPause,
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}