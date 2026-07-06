import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/cloudinary_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/category_themes.dart';

class MusicStudioPage extends StatefulWidget {
  const MusicStudioPage({super.key});

  @override
  State<MusicStudioPage> createState() => _MusicStudioPageState();
}

class _MusicStudioPageState extends State<MusicStudioPage> with TickerProviderStateMixin {
  final SupabaseService _supabase = SupabaseService();
  final CloudinaryService _cloudinary = CloudinaryService();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final Uuid _uuid = const Uuid();

  bool _isRecording = false;
  bool _isPlaying = false;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;

  final List<Map<String, dynamic>> _myTracks = [];
  int? _currentlyPlayingIndex;

  late final AnimationController _recordPulseController;
  late final Animation<double> _recordPulseAnimation;

  @override
  void initState() {
    super.initState();
    _cloudinary.initialize();
    _loadMyTracks();

    _recordPulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _recordPulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _recordPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    _recordPulseController.dispose();
    super.dispose();
  }

  Future<void> _loadMyTracks() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      final tracks = await _supabase.client
          .from('music_tracks')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _myTracks.clear();
          _myTracks.addAll(List<Map<String, dynamic>>.from(tracks));
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading tracks: $e');
    }
  }

  Future<bool> _requestPermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Permission error: $e');
      return false;
    }
  }

  Future<void> _startRecording() async {
    if (!await _requestPermission()) {
      _showSnackBar('Permission microphone refusée');
      return;
    }

    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'recording_${_uuid.v4()}.m4a';
      _currentRecordingPath = '${dir.path}/$fileName';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _currentRecordingPath!,
      );

      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
        _recordingStartTime = DateTime.now();
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_recordingStartTime != null) {
          setState(() {
            _recordingDuration = DateTime.now().difference(_recordingStartTime!);
          });
        }
      });

      debugPrint('🎙️ Recording started: $_currentRecordingPath');
    } catch (e) {
      debugPrint('❌ Error starting recording: $e');
      _showSnackBar('Erreur lors de l\'enregistrement');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      _recordingTimer?.cancel();

      setState(() {
        _isRecording = false;
        _currentRecordingPath = path;
      });

      debugPrint('⏹️ Recording stopped: $path');
    } catch (e) {
      debugPrint('❌ Error stopping recording: $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _saveRecording() async {
    if (_currentRecordingPath == null) return;

    final user = _supabase.currentUser;
    if (user == null) {
      _showSnackBar('Connecte-toi pour sauvegarder');
      return;
    }

    try {
      final file = File(_currentRecordingPath!);
      if (!await file.exists()) {
        _showSnackBar('Fichier introuvable');
        return;
      }

      _showSnackBar('Sauvegarde en cours...');

      final cloudinaryUrl = await _cloudinary.uploadImage(file, folder: 'music_tracks');
      if (cloudinaryUrl == null) {
        _showSnackBar('Erreur lors de l\'upload');
        return;
      }

      await _supabase.client.from('music_tracks').insert({
        'user_id': user.id,
        'title': 'Ma piste ${_myTracks.length + 1}',
        'audio_url': cloudinaryUrl,
        'duration': _recordingDuration.inSeconds,
        'created_at': DateTime.now().toIso8601String(),
      });

      _showSnackBar('✅ Piste sauvegardée !');
      await _loadMyTracks();

      setState(() {
        _currentRecordingPath = null;
        _recordingDuration = Duration.zero;
      });
    } catch (e) {
      debugPrint('❌ Error saving recording: $e');
      _showSnackBar('Erreur lors de la sauvegarde');
    }
  }

  Future<void> _playTrack(int index) async {
    if (_currentlyPlayingIndex == index && _isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
      return;
    }

    if (_currentlyPlayingIndex == index && !_isPlaying) {
      await _player.play();
      setState(() => _isPlaying = true);
      return;
    }

    try {
      final track = _myTracks[index];
      final audioUrl = track['audio_url'] as String;

      await _player.setUrl(audioUrl);
      await _player.play();

      setState(() {
        _currentlyPlayingIndex = index;
        _isPlaying = true;
      });

      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() => _playbackPosition = position);
        }
      });

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _isPlaying = false);
          _player.seek(Duration.zero);
        }
      });
    } catch (e) {
      debugPrint('❌ Error playing track: $e');
      _showSnackBar('Erreur lors de la lecture');
    }
  }

  Future<void> _deleteTrack(int index) async {
    final track = _myTracks[index];
    final audioUrl = track['audio_url'] as String;

    try {
      await _cloudinary.deleteImage(audioUrl);
      await _supabase.client
          .from('music_tracks')
          .delete()
          .eq('id', track['id']);

      setState(() => _myTracks.removeAt(index));
      _showSnackBar('Piste supprimée');
    } catch (e) {
      debugPrint('❌ Error deleting track: $e');
      _showSnackBar('Erreur lors de la suppression');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryViolet,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CategoryThemes.music;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0C0C),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecordingSection(theme),
                    const SizedBox(height: 32),
                    _buildMyTracksSection(theme),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CategoryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor.withOpacity(0.3), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.primaryColor, theme.secondaryColor]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.music_note_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Studio de Musique',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Créez votre musique',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingSection(CategoryTheme theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor.withOpacity(0.2), theme.secondaryColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          if (_isRecording)
            Column(
              children: [
                AnimatedBuilder(
                  animation: _recordPulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _recordPulseAnimation.value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.2),
                          border: Border.all(color: Colors.red, width: 3),
                        ),
                        child: const Icon(
                          Icons.mic_rounded,
                          color: Colors.red,
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  _formatDuration(_recordingDuration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enregistrement en cours...',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      icon: Icons.stop_rounded,
                      color: Colors.red,
                      onPressed: _stopRecording,
                    ),
                    const SizedBox(width: 20),
                    _buildControlButton(
                      icon: Icons.save_rounded,
                      color: Colors.green,
                      onPressed: _saveRecording,
                    ),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                Icon(
                  Icons.mic_none_rounded,
                  size: 60,
                  color: theme.primaryColor.withOpacity(0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'Prêt à enregistrer ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez votre propre musique',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
                const SizedBox(height: 24),
                _buildControlButton(
                  icon: Icons.mic_rounded,
                  color: theme.primaryColor,
                  onPressed: _startRecording,
                  label: 'Commencer l\'enregistrement',
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    String? label,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            if (label != null) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMyTracksSection(CategoryTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mes pistes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (_myTracks.isNotEmpty)
              Text(
                '${_myTracks.length} piste${_myTracks.length > 1 ? 's' : ''}',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_myTracks.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.music_off_rounded,
                  size: 50,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune piste enregistrée',
                  style: TextStyle(color: Colors.grey[400], fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Commencez par enregistrer votre premier morceau',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myTracks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final track = _myTracks[index];
              final isPlaying = _currentlyPlayingIndex == index && _isPlaying;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isPlaying ? theme.primaryColor.withOpacity(0.5) : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _playTrack(index),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [theme.primaryColor, theme.secondaryColor]),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track['title'] ?? 'Sans titre',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDuration(Duration(seconds: track['duration'] ?? 0)),
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteTrack(index),
                      icon: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 22),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}