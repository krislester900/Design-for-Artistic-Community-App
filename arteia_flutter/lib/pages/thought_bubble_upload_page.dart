import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../services/supabase_service.dart';
import '../services/image_upload_service.dart';
import '../services/quests_service.dart';
import '../theme/app_theme.dart';

class ThoughtBubbleUploadPage extends StatefulWidget {
  const ThoughtBubbleUploadPage({super.key});

  @override
  State<ThoughtBubbleUploadPage> createState() => _ThoughtBubbleUploadPageState();
}

class _ThoughtBubbleUploadPageState extends State<ThoughtBubbleUploadPage> {
  final SupabaseService _supabase = SupabaseService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final QuestsService _questsService = QuestsService();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  final TextEditingController _textController = TextEditingController();
  File? _selectedImage;
  String? _imageUrl;
  String? _audioPath;
  bool _isRecording = false;
  bool _isUploading = false;
  bool _isSubmitting = false;
  Duration _recordingDuration = Duration.zero;
  bool get _isWeb => kIsWeb;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (_isWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistrement audio non disponible sur web'), backgroundColor: Colors.orange),
        );
      }
      return;
    }
    
    try {
      setState(() {
        _isRecording = true;
        _recordingDuration = Duration.zero;
      });
      _startDurationTimer();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistrement simulé - Fonctionnalité native requise'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    setState(() => _isRecording = false);
  }

  void _startDurationTimer() {
    const oneSecond = Duration(seconds: 1);
    Future.doWhile(() async {
      await Future.delayed(oneSecond);
      if (mounted && _isRecording) {
        setState(() {
          _recordingDuration += oneSecond;
        });
        return true;
      }
      return false;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitThoughtBubble() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez du texte ou une image'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _supabase.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connectez-vous pour publier'), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        final result = await _imageUploadService.uploadArtworkImage(_selectedImage!);
        imageUrl = result['image_url'];
      }

      // Upload audio if recorded (mobile only)
      String? audioUrl;
      if (_audioPath != null && !_isWeb) {
        try {
          final audioFile = File(_audioPath!);
          final audioFileName = 'thoughts/${_uuid.v4()}.m4a';
          
          await _supabase.client.storage
              .from('posts')
              .upload(audioFileName, audioFile);
          
          audioUrl = _supabase.client.storage
              .from('posts')
              .getPublicUrl(audioFileName);
        } catch (e) {
          // Silently fail audio upload
        }
      }

      // Create post
      await _supabase.client.from('posts').insert({
        'user_id': user.id,
        'category_slug': 'thought-bubble',
        'title': text.isEmpty ? 'Bulle de pensée' : text.substring(0, min(50, text.length)),
        'description': text,
        'image_url': imageUrl,
        'audio_url': audioUrl,
        'type': 'thought',
        'likes_count': 0,
        'comments_count': 0,
        'views_count': 0,
        'audio_duration': _recordingDuration.inSeconds,
      });

      // Update quest progress
      _questsService.updateQuestProgress(QuestType.publish, 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bulle de pensée publiée! 💭'), backgroundColor: Colors.green),
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

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Nouvelle bulle de pensée', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitThoughtBubble,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Publier', style: TextStyle(color: AppTheme.primaryViolet, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Text input
            const Text('Votre pensée', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Exprimez-vous librement...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: AppTheme.cardDarkLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // Image picker
            const Text('Image (optionnel)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  color: AppTheme.cardDarkLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: _selectedImage != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 40, color: Colors.grey[600]),
                          const SizedBox(height: 8),
                          Text('Ajouter une image', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Audio recorder
            if (!_isWeb) ...[
              const Text('Message audio (optionnel)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardDarkLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    if (_isRecording) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(_recordingDuration),
                              style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _stopRecording,
                        icon: const Icon(Icons.stop, size: 18),
                        label: const Text('Arrêter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ] else ...[
                      if (_audioPath != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('Audio enregistré', style: TextStyle(color: Colors.green, fontSize: 13)),
                              ),
                              Text(
                                _formatDuration(_recordingDuration),
                                style: TextStyle(color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      ElevatedButton.icon(
                        onPressed: _startRecording,
                        icon: Icon(_isRecording ? Icons.mic : Icons.mic_none, size: 18),
                        label: Text(_audioPath != null ? 'Réenregistrer' : 'Commencer l\'enregistrement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryViolet,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryTeal.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isWeb 
                          ? 'Les bulles de pensée sont des publications textuelles. L\'audio sera disponible sur mobile.'
                          : 'Les bulles de pensée sont des publications audio/textuelles éphémères.',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
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