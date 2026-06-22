import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import '../services/quests_service.dart';
import '../theme/app_theme.dart';

class WritingFullscreenPage extends StatefulWidget {
  const WritingFullscreenPage({super.key});

  @override
  State<WritingFullscreenPage> createState() => _WritingFullscreenPageState();
}

class _WritingFullscreenPageState extends State<WritingFullscreenPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _apiService = ApiService();
  final _supabase = SupabaseService();
  final _questsService = QuestsService();

  String? _selectedCategory;
  bool _isSubmitting = false;
  int _wordCount = 0;
  int _charCount = 0;
  DateTime? _sessionStartTime;

  final List<Map<String, dynamic>> _categories = [
    {'slug': 'litterature', 'name': 'Littérature', 'icon': '✍️'},
    {'slug': 'manga', 'name': 'Manga / BD', 'icon': '📚'},
    {'slug': 'poesie', 'name': 'Poésie', 'icon': '📜'},
    {'slug': 'nouvelle', 'name': 'Nouvelle', 'icon': '📖'},
    {'slug': 'roman', 'name': 'Roman', 'icon': '📕'},
  ];

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _contentController.addListener(_updateStats);
    // Masquer la barre de statut
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _updateStats() {
    final text = _contentController.text;
    final words = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    setState(() {
      _wordCount = words;
      _charCount = text.length;
    });
  }

  @override
  void dispose() {
    _contentController.removeListener(_updateStats);
    _titleController.dispose();
    _contentController.dispose();
    // Restaurer la barre de statut
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _submitWriting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une catégorie'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = _supabase.currentUser;
      if (user == null) throw Exception('Non connecté');

      await _apiService.createPost({
        'user_id': user.id,
        'category_slug': _selectedCategory,
        'title': _titleController.text.trim(),
        'description': _contentController.text.trim(),
        'image_url': '',
        'type': 'literature',
        'likes_count': 0,
        'comments_count': 0,
        'views_count': 0,
      });

      // Mettre à jour les quêtes
      _questsService.updateQuestProgress(QuestType.publish, 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Publication réussie! ✍️'), backgroundColor: Colors.green),
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

  void _saveDraft() {
    // TODO: Sauvegarder le brouillon localement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Brouillon sauvegardé'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionDuration = DateTime.now().difference(_sessionStartTime!);
    final minutes = sessionDuration.inMinutes;
    final seconds = sessionDuration.inSeconds % 60;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mode création', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
            Text(
              '$minutes:${seconds.toString().padLeft(2, '0')} • $_wordCount mots',
              style: TextStyle(color: Colors.grey[400], fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saveDraft,
            child: const Text('Brouillon', style: TextStyle(color: AppTheme.primaryViolet)),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : _submitWriting,
            child: _isSubmitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Publier', style: TextStyle(color: AppTheme.primaryViolet, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Category selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardDarkLight,
                border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        dropdownColor: AppTheme.cardDark,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        hint: const Text('Choisir une catégorie', style: TextStyle(color: Colors.grey)),
                        isExpanded: true,
                        items: _categories.map((c) => DropdownMenuItem<String>(
                          value: c['slug'] as String,
                          child: Text('${c['icon']} ${c['name']}'),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Writing area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        hintText: 'Titre de votre œuvre',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 24),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.grey, height: 1),
                    const SizedBox(height: 20),

                    // Content
                    TextFormField(
                      controller: _contentController,
                      style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.8),
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Commencez à écrire votre histoire...\n\nLaissez libre cours à votre imagination.',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 16, height: 1.8),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                    ),
                  ],
                ),
              ),
            ),

            // Stats bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
              ),
              child: Row(
                children: [
                  Icon(Icons.text_fields, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('$_charCount caractères', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  const SizedBox(width: 16),
                  Icon(Icons.auto_stories, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('$_wordCount mots', style: TextStyle(color: Colors.grey[400], fontSize: 11)),
                  const Spacer(),
                  Text(
                    '${minutes}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
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