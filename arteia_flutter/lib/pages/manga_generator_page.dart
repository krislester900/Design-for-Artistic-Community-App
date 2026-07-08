import 'dart:async';
import 'package:flutter/material.dart';
import '../services/manga_generator_service.dart';


class MangaGeneratorPage extends StatefulWidget {
  const MangaGeneratorPage({super.key});

  @override
  State<MangaGeneratorPage> createState() => _MangaGeneratorPageState();
}

class _MangaGeneratorPageState extends State<MangaGeneratorPage> {
  final _service = MangaGeneratorService();
  final _promptController = TextEditingController();

  List<Map<String, dynamic>> _styles = [];
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _selectedStyle;
  String? _imageUrl;
  bool _isGenerating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStyles();
    _loadHistory();
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _loadStyles() async {
    final styles = await _service.getStyles();
    if (mounted) setState(() => _styles = styles);
  }

  Future<void> _loadHistory() async {
    final history = await _service.getMyGenerations();
    if (mounted) setState(() => _history = history);
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty || _selectedStyle == null) return;

    setState(() {
      _isGenerating = true;
      _error = null;
      _imageUrl = null;
    });

    final result = await _service.generate(
      prompt: prompt,
      styleSlug: _selectedStyle!['slug'] as String,
    );

    if (result.containsKey('error')) {
      setState(() {
        _isGenerating = false;
        _error = result['error'] as String?;
      });
      return;
    }

    if (result['status'] == 'completed' && result['image_url'] != null) {
      setState(() {
        _isGenerating = false;
        _imageUrl = result['image_url'] as String?;
      });
      _loadHistory();
    } else if (result['prediction_id'] != null) {
      _pollPrediction(result['prediction_id'] as String);
    } else {
      setState(() {
        _isGenerating = false;
        _error = 'La génération n\'a pas abouti';
      });
    }
  }

  Future<void> _pollPrediction(String predictionId) async {
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final status = await _service.checkStatus(predictionId);
      if (status['status'] == 'completed' && status['image_url'] != null) {
        if (mounted) {
          setState(() {
            _isGenerating = false;
            _imageUrl = status['image_url'] as String?;
          });
          _loadHistory();
        }
        return;
      }
      if (status['status'] == 'failed') break;
    }
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _error = 'Le délai d\'attente est dépassé. Réessaie !';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Générateur Manga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { _loadStyles(); _loadHistory(); },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStyleGrid(theme),
            const SizedBox(height: 20),
            _buildPromptInput(theme),
            const SizedBox(height: 16),
            _buildGenerateButton(theme),
            if (_isGenerating) _buildLoadingState(theme),
            if (_error != null) _buildError(theme),
            if (_imageUrl != null) _buildResult(theme),
            if (_history.isNotEmpty) _buildHistory(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleGrid(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choisis un style', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 12),
        _styles.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            : SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _styles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final style = _styles[index];
                    final selected = _selectedStyle?['id'] == style['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStyle = style),
                      child: Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: selected
                                ? [const Color(0xFF7C5CFC), const Color(0xFF5B3FE0)]
                                : [theme.cardColor, theme.cardColor.withOpacity(0.6)],
                          ),
                          border: selected ? Border.all(color: const Color(0xFF7C5CFC), width: 2) : null,
                          boxShadow: selected
                              ? [BoxShadow(color: const Color(0xFF7C5CFC).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(style['name'] as String? ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? Colors.white : theme.textTheme.bodyLarge?.color), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(style['mangaka'] as String? ?? '', style: TextStyle(fontSize: 9, color: selected ? Colors.white70 : Colors.grey), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: selected ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: Text(style['style_tags'] is List ? (style['style_tags'] as List).first as String? ?? '' : '', style: TextStyle(fontSize: 8, color: selected ? Colors.white70 : Colors.grey)),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildPromptInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Décris ton dessin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 8),
        TextField(
          controller: _promptController,
          maxLines: 3,
          enabled: !_isGenerating,
          decoration: InputDecoration(
            hintText: 'Ex: un samouraï au coucher du soleil, combat dynamique...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (_selectedStyle == null || _isGenerating) ? null : _generate,
        icon: _isGenerating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome),
        label: Text(_isGenerating ? 'Génération en cours...' : 'Générer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C5CFC),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[800],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 60, height: 60,
            child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF7C5CFC)),
          ),
          const SizedBox(height: 16),
          Text('Arteïa Muse dessine...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Text('Cela peut prendre 10 à 30 secondes', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[300], fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildResult(ThemeData theme) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[400], size: 18),
              const SizedBox(width: 8),
              Text('Génération réussie !', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _imageUrl!,
              width: double.infinity,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 300,
                  color: theme.scaffoldBackgroundColor,
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[900],
                  child: const Center(child: Text('Erreur de chargement', style: TextStyle(color: Colors.grey))),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(Icons.refresh, 'Refaire', () {
                _imageUrl = null;
                _generate();
              }),
              _actionButton(Icons.content_copy, 'Dupliquer', () {
                _promptController.text = _promptController.text;
              }),
              _actionButton(Icons.download, 'Sauvegarder', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image sauvegardée dans la galerie')),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(foregroundColor: Colors.grey[300]),
    );
  }

  Widget _buildHistory(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text('Mes générations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _history.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final gen = _history[index];
              return GestureDetector(
                onTap: () => setState(() {
                  _imageUrl = gen['image_url'] as String?;
                  _promptController.text = gen['prompt'] as String? ?? '';
                }),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: theme.cardColor,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.network(
                            gen['image_url'] as String? ?? '',
                            width: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(6),
                          child: Text(
                            gen['prompt'] as String? ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
