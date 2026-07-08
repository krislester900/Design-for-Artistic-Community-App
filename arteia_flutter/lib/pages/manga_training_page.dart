import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/manga_generator_service.dart';
import '../services/cloudinary_service.dart';

class MangaTrainingPage extends StatefulWidget {
  const MangaTrainingPage({super.key});

  @override
  State<MangaTrainingPage> createState() => _MangaTrainingPageState();
}

class _MangaTrainingPageState extends State<MangaTrainingPage> {
  final _service = MangaGeneratorService();
  final _imagePicker = ImagePicker();
  final _cloudinary = CloudinaryService();

  List<Map<String, dynamic>> _styles = [];
  Map<String, dynamic>? _selectedStyle;
  List<Map<String, dynamic>> _references = [];
  Map<String, dynamic>? _trainingJob;
  bool _isLoading = true;
  bool _isUploading = false;
  bool _isTraining = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final styles = await _service.getStyles();
    if (mounted) setState(() { _styles = styles; _isLoading = false; });
  }

  Future<void> _selectStyle(Map<String, dynamic> style) async {
    setState(() {
      _selectedStyle = style;
      _references = [];
      _trainingJob = null;
    });
    await _loadTrainingStatus(style['slug'] as String);
  }

  Future<void> _loadTrainingStatus(String slug) async {
    final status = await _service.getTrainingStatus(slug);
    if (!mounted) return;
    setState(() {
      _references = List<Map<String, dynamic>>.from(status['references'] ?? []);
      _trainingJob = status['job'] as Map<String, dynamic>?;
    });
  }

  Future<void> _uploadImage() async {
    final XFile? picked = await _imagePicker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (picked == null) return;
    setState(() => _isUploading = true);
    try {
      final file = File(picked.path);
      final url = await _cloudinary.uploadImage(file);
      if (url != null && _selectedStyle != null) {
        await _service.addReference(_selectedStyle!['slug'] as String, url);
        await _loadTrainingStatus(_selectedStyle!['slug'] as String);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur upload: $e')));
      }
    }
    if (mounted) setState(() => _isUploading = false);
  }

  Future<void> _startTraining() async {
    if (_selectedStyle == null) return;
    setState(() => _isTraining = true);
    try {
      final result = await _service.startTraining(_selectedStyle!['slug'] as String);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(result['message'] as String? ?? 'Entraînement lancé !'),
          backgroundColor: Colors.green,
        ));
        await _loadTrainingStatus(_selectedStyle!['slug'] as String);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
      }
    }
    if (mounted) setState(() => _isTraining = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Entraînement Manga')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                SizedBox(
                  width: 220,
                  child: _buildStyleList(theme),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _selectedStyle != null ? _buildTrainingPanel(theme) : _buildEmptyState(theme)),
              ],
            ),
    );
  }

  Widget _buildStyleList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _styles.length,
      itemBuilder: (context, index) {
        final style = _styles[index];
        final selected = _selectedStyle?['id'] == style['id'];
        final status = style['training_status'] as String? ?? 'untrained';
        final count = style['reference_count'] as int? ?? 0;

        return GestureDetector(
          onTap: () => _selectStyle(style),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: selected ? const Color(0xFF7C5CFC).withOpacity(0.2) : theme.cardColor,
              border: selected ? Border.all(color: const Color(0xFF7C5CFC), width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(style['name'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 4),
                Text(style['mangaka'] as String? ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                const SizedBox(height: 6),
                _statusBadge(status, count),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statusBadge(String status, int count) {
    final config = switch (status) {
      'ready' => (Colors.green, 'Prêt ($count img)'),
      'training' => (Colors.orange, 'Entraînement...'),
      'collecting' => (Colors.blue, '$count/20 images'),
      'failed' => (Colors.red, 'Échec'),
      _ => (Colors.grey, '0 image'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: config.$1.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
      child: Text(config.$2, style: TextStyle(fontSize: 9, color: config.$1)),
    );
  }

  Widget _buildTrainingPanel(ThemeData theme) {
    final style = _selectedStyle!;
    final status = style['training_status'] as String? ?? 'untrained';
    final hasLora = style['lora_url'] != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(style['name'] as String? ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text('par ${style['mangaka']}', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text(style['description'] as String? ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 20),

          if (hasLora)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green.withOpacity(0.3))),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Modèle LoRA entraîné ! Les générations utilisent désormais les traits réels.')),
                ],
              ),
            ),
          const SizedBox(height: 20),

          Text('Images de référence', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 4),
          Text('Ajoute des scans/planches manga de ${style['mangaka']} pour que l\'IA apprenne le trait exact.', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 12),

          SizedBox(
            height: 140,
            child: _references.isEmpty
                ? Center(
                    child: Text('Aucune image. Ajoute des planches !', style: TextStyle(color: Colors.grey[600])),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _references.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final ref = _references[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ref['image_url'] as String? ?? '',
                          width: 100, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 100, color: Colors.grey[800]),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadImage,
                icon: _isUploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add_photo_alternate, size: 18),
                label: Text(_isUploading ? 'Upload...' : 'Ajouter une planche'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C5CFC), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              if (status == 'collecting' || status == 'ready')
                ElevatedButton.icon(
                  onPressed: _isTraining ? null : _startTraining,
                  icon: _isTraining ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.model_training, size: 18),
                  label: Text(_isTraining ? 'Entraînement...' : 'Lancer l\'entraînement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),

          if (_trainingJob != null) ...[
            const SizedBox(height: 20),
            _buildJobStatus(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildJobStatus(ThemeData theme) {
    final job = _trainingJob!;
    final jobStatus = job['status'] as String? ?? 'unknown';
    final progress = (job['progress'] as num?)?.toDouble() ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dernier entraînement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                switch (jobStatus) {
                  'completed' => Icons.check_circle,
                  'training' || 'preparing' => Icons.sync,
                  'failed' => Icons.error,
                  _ => Icons.schedule,
                },
                color: switch (jobStatus) {
                  'completed' => Colors.green,
                  'training' || 'preparing' => Colors.orange,
                  'failed' => Colors.red,
                  _ => Colors.grey,
                },
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(switch (jobStatus) {
                'completed' => 'Terminé avec succès',
                'training' => 'En cours...',
                'preparing' => 'Préparation...',
                'failed' => 'Échec',
                _ => 'En attente',
              }, style: const TextStyle(fontSize: 13)),
            ],
          ),
          if (jobStatus == 'training' || jobStatus == 'preparing') ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress > 0 ? progress : null, backgroundColor: Colors.grey[800], color: const Color(0xFF7C5CFC)),
            const SizedBox(height: 8),
            Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
          if (job['error_message'] != null) ...[
            const SizedBox(height: 12),
            Text(job['error_message'] as String, style: TextStyle(fontSize: 12, color: Colors.red[300])),
          ],
          if (job['completed_at'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Terminé le ${job['completed_at']}', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.brush, size: 60, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text('Sélectionne un style à entraîner', style: TextStyle(fontSize: 16, color: Colors.grey[500])),
          const SizedBox(height: 8),
          Text('Ajoute des planches manga → entraîne le LoRA →\ngénère avec le trait réel du mangaka', style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
