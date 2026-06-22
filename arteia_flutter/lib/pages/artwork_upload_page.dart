import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../services/image_upload_service.dart';
import '../services/api_service.dart';
import '../services/color_analysis_service.dart';
import '../services/quests_service.dart';
import '../theme/app_theme.dart';

class ArtworkUploadPage extends StatefulWidget {
  const ArtworkUploadPage({super.key});

  @override
  State<ArtworkUploadPage> createState() => _ArtworkUploadPageState();
}

class _ArtworkUploadPageState extends State<ArtworkUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUploadService = ImageUploadService();
  final _apiService = ApiService();
  final _supabase = SupabaseService();
  final _picker = ImagePicker();
  final _questsService = QuestsService();
  List<String> _suggestedTags = [];
  String? _suggestedMood;

  File? _selectedImage;
  String? _imageUrl;
  String? _categorySlug;
  bool _isUploading = false;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = [
    {'slug': 'musique', 'name': 'Musique', 'icon': '🎵'},
    {'slug': 'art-visuel', 'name': 'Arts Visuels', 'icon': '🎨'},
    {'slug': 'litterature', 'name': 'Littérature', 'icon': '✍️'},
    {'slug': 'manga', 'name': 'Manga', 'icon': '📚'},
    {'slug': 'films', 'name': 'Films', 'icon': '🎬'},
    {'slug': 'animation', 'name': 'Animation', 'icon': '🎞️'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
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
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Choisir une image', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryViolet.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppTheme.primaryViolet),
                ),
                title: const Text('Appareil photo', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppTheme.primaryTeal),
                ),
                title: const Text('Galerie', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final result = await _imageUploadService.uploadArtworkImage(_selectedImage!);
      setState(() {
        _imageUrl = result['image_url'];
        _isUploading = false;
      });

      // Auto-tagging: analyser les couleurs de l'image
      if (_imageUrl != null) {
        try {
          final colors = await ColorAnalysisService.extractDominantColors(
            NetworkImage(_imageUrl!),
          );
          final tags = ColorAnalysisService.generateColorTags(colors);
          final mood = ColorAnalysisService.getMoodFromColors(colors);
          
          setState(() {
            _suggestedTags = tags;
            _suggestedMood = mood;
          });

          if (mounted && tags.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tags suggérés: ${tags.join(", ")}'),
                backgroundColor: AppTheme.primaryViolet,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          // Silently fail auto-tagging
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploadée avec succès!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur upload: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrl == null && _selectedImage != null) {
      await _uploadImage();
    }
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner et uploader une image'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = _supabase.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez vous connecter pour publier'), backgroundColor: Colors.red),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await _apiService.createPost({
        'user_id': user.id,
        'category_slug': _categorySlug ?? 'art-visuel',
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': _imageUrl,
        'type': _categorySlug ?? 'art',
        'likes_count': 0,
        'comments_count': 0,
        'views_count': 0,
        'tags': _suggestedTags,
        'mood': _suggestedMood,
      });

      // Mettre à jour les quêtes
      _questsService.updateQuestProgress(QuestType.publish, 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication réussie! 🎉'), backgroundColor: Colors.green),
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
        title: const Text('Publier une œuvre', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitPost,
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Publier', style: TextStyle(color: AppTheme.primaryViolet, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker area
              GestureDetector(
                onTap: _showImagePickerOptions,
                child: Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    color: AppTheme.cardDarkLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.withOpacity(0.3), style: BorderStyle.solid),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              if (_isUploading)
                                Container(
                                  color: Colors.black54,
                                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                                ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryViolet.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.add_photo_alternate, size: 48, color: AppTheme.primaryViolet),
                            ),
                            const SizedBox(height: 12),
                            const Text('Ajouter une image', style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text('Appuyez pour choisir', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),
              if (_imageUrl != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 6),
                      Text('Image uploadée', style: TextStyle(color: Colors.green, fontSize: 12)),
                    ],
                  ),
                ),
              if (_selectedImage != null && _imageUrl == null && !_isUploading)
                TextButton.icon(
                  onPressed: _uploadImage,
                  icon: const Icon(Icons.cloud_upload, size: 18),
                  label: const Text('Uploader l\'image'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryViolet),
                ),
              const SizedBox(height: 20),

              // Title
              const Text('Titre', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Titre de votre œuvre',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: AppTheme.cardDarkLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                validator: (value) => value == null || value.trim().isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Category
              const Text('Catégorie', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _categorySlug,
                dropdownColor: AppTheme.cardDark,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Choisir une catégorie',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: AppTheme.cardDarkLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _categories.map<DropdownMenuItem<String>>((cat) => DropdownMenuItem<String>(
                  value: cat['slug'] as String,
                  child: Text('${cat['icon']} ${cat['name']}'),
                )).toList(),
                onChanged: (value) => setState(() => _categorySlug = value),
                validator: (value) => value == null ? 'Requis' : null,
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Décrivez votre œuvre...',
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
              // Suggested tags (auto-tagging)
              if (_suggestedTags.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Tags suggérés', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestedTags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryViolet.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
                    ),
                    child: Text(tag, style: const TextStyle(color: AppTheme.primaryViolet, fontSize: 12)),
                  )).toList(),
                ),
                if (_suggestedMood != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.psychology, size: 16, color: AppTheme.primaryTeal),
                        const SizedBox(width: 6),
                        Text('Mood: $_suggestedMood', style: const TextStyle(color: AppTheme.primaryTeal, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
