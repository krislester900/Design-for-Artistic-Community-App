import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class MusicUploadPage extends StatefulWidget {
  const MusicUploadPage({super.key});

  @override
  State<MusicUploadPage> createState() => _MusicUploadPageState();
}

class _MusicUploadPageState extends State<MusicUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _apiService = ApiService();
  final _supabase = SupabaseService();
  final _picker = ImagePicker();
  final AudioPlayer _audioPlayer = AudioPlayer();

  File? _coverImage;
  String? _coverImageUrl;
  File? _audioFile;
  String? _audioUrl;
  bool _isUploading = false;
  bool _isSubmitting = false;
  bool _isPlayingPreview = false;

  final List<Map<String, dynamic>> _genres = [
    {'slug': 'electronic', 'name': 'Électronique', 'icon': '🎛️'},
    {'slug': 'hip-hop', 'name': 'Hip-Hop', 'icon': '🎤'},
    {'slug': 'rock', 'name': 'Rock', 'icon': '🎸'},
    {'slug': 'jazz', 'name': 'Jazz', 'icon': '🎷'},
    {'slug': 'classical', 'name': 'Classique', 'icon': '🎻'},
    {'slug': 'pop', 'name': 'Pop', 'icon': '🎵'},
  ];

  String? _selectedGenre;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => _coverImage = File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'mp4', 'wav', 'aac', 'm4a'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() => _audioFile = File(result.files.single.path!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _uploadCover() async {
    if (_coverImage == null) return;
    setState(() => _isUploading = true);
    try {
      final fileName = 'music_covers/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await _supabase.client.storage
          .from('posts')
          .upload(fileName, _coverImage!);
      _coverImageUrl = _supabase.client.storage
          .from('posts')
          .getPublicUrl(fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload cover: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadAudio() async {
    if (_audioFile == null) return;
    setState(() => _isUploading = true);
    try {
      final fileName = 'music_tracks/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _supabase.client.storage
          .from('posts')
          .upload(fileName, _audioFile!);
      _audioUrl = _supabase.client.storage
          .from('posts')
          .getPublicUrl(fileName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload audio: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _previewAudio() async {
    if (_audioFile == null) return;
    try {
      if (_isPlayingPreview) {
        await _audioPlayer.pause();
        setState(() => _isPlayingPreview = false);
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioFile!.path));
        setState(() => _isPlayingPreview = true);
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlayingPreview = false);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lecture: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitTrack() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImageUrl == null && _coverImage != null) {
      await _uploadCover();
    }
    if (_audioUrl == null && _audioFile != null) {
      await _uploadAudio();
    }
    if (_selectedGenre == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir un genre'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = _supabase.currentUser;
      if (user == null) throw Exception('Non connecté');

      await _apiService.createPost({
        'user_id': user.id,
        'category_slug': 'musique',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': _coverImageUrl ?? '',
        'type': 'music',
        'likes_count': 0,
        'comments_count': 0,
        'views_count': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication réussie! 🎵'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Publier un titre', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitTrack,
            child: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Publier', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Cover image
            GestureDetector(
              onTap: _pickCoverImage,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppTheme.cardDarkLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: _coverImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(_coverImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.album, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text('Ajouter une pochette', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Audio file
            GestureDetector(
              onTap: _pickAudioFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDarkLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.audio_file, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _audioFile != null ? _audioFile!.path.split('/').last : 'Fichier audio',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _audioFile != null ? 'Prêt à uploader' : 'MP3, MP4, WAV, AAC',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (_audioFile != null)
                      IconButton(
                        icon: Icon(_isPlayingPreview ? Icons.pause : Icons.play_arrow, color: Colors.white),
                        onPressed: _previewAudio,
                      ),
                    Icon(Icons.upload_file, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text('Titre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ex: Nuit étoilée',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: AppTheme.cardDarkLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
            ),
            const SizedBox(height: 16),

            // Genre
            const Text('Genre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedGenre,
              dropdownColor: AppTheme.cardDark,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Choisir un genre',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: AppTheme.cardDarkLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: _genres.map((g) => DropdownMenuItem<String>(
                value: g['slug'] as String,
                child: Text('${g['icon']} ${g['name']}'),
              )).toList(),
              onChanged: (v) => setState(() => _selectedGenre = v),
              validator: (v) => v == null ? 'Requis' : null,
            ),
            const SizedBox(height: 16),

            // Description
            const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Parlez de votre titre...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: AppTheme.cardDarkLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}