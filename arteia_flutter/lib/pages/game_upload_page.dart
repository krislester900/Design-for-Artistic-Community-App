import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';

class GameUploadPage extends StatefulWidget {
  const GameUploadPage({super.key});

  @override
  State<GameUploadPage> createState() => _GameUploadPageState();
}

class _GameUploadPageState extends State<GameUploadPage> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  String _description = '';
  String _gameUrl = '';
  bool _isUploading = false;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    // Sécurité: vérifier si l'utilisateur est connecté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_supabase.auth.currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous devez être connecté pour publier un jeu.')),
        );
        Navigator.pop(context);
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _selectedImage != null) {
      _formKey.currentState!.save();
      final user = _supabase.auth.currentUser;
      
      if (user == null) return;

      setState(() {
        _isUploading = true;
      });

      try {
        // 1. Upload thumbnail
        final bytes = await _selectedImage!.readAsBytes();
        final fileExt = _selectedImage!.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${user.id}.$fileExt';
        final storagePath = 'thumbnails/$fileName';

        await _supabase.storage.from('game_thumbnails').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExt'),
        );

        final thumbnailUrl = _supabase.storage.from('game_thumbnails').getPublicUrl(storagePath);

        // 2. Insert into database
        await _supabase.from('community_games').insert({
          'author_id': user.id,
          'title': _title,
          'description': _description,
          'storage_url': _gameUrl, // We keep the column name storage_url for compatibility but it's an external URL
          'thumbnail_url': thumbnailUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jeu publié avec succès !')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la publication : $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    } else if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une image de couverture')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090D),
      appBar: AppBar(
        title: const Text('Publier un jeu'),
        backgroundColor: const Color(0xFF15151B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Aperçu de l'image
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFF15151B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: kIsWeb
                                ? NetworkImage(_selectedImage!.path)
                                : FileImage(File(_selectedImage!.path)) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 48, color: Colors.white54),
                            SizedBox(height: 8),
                            Text('Ajouter une miniature', style: TextStyle(color: Colors.white54)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Titre du jeu',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange)),
                ),
                validator: (value) => value!.isEmpty ? 'Requis' : null,
                onSaved: (value) => _title = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'URL du jeu (ex: lien itch.io, Github Pages...)',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange)),
                  hintText: 'https://...',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Requis';
                  if (!value.startsWith('http')) return 'Doit commencer par http ou https';
                  return null;
                },
                onSaved: (value) => _gameUrl = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Description (facultatif)',
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.deepOrange)),
                ),
                onSaved: (value) => _description = value ?? '',
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isUploading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Publier sur l\'Arcade', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
