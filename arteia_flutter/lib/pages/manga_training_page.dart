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
  Map<String, dynamic>? _globalStats;
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
    final results = await Future.wait([
      _service.getStyles(),
      _service.getGlobalStats(),
    ]);
    if (mounted) {
      setState(() {
        _styles = results[0] as List<Map<String, dynamic>>;
        _globalStats = results[1] as Map<String, dynamic>?;
        _isLoading = false;
      });
    }
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
                SizedBox(width: 220, child: _buildStyleList(theme)),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _selectedStyle != null
                      ? _buildTrainingPanel(theme)
                      : _buildDashboard(theme),
                ),
              ],
            ),
    );
  }

  Widget _buildDashboard(ThemeData theme) {
    final stats = _globalStats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pipeline Entraînement', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          Text('Suivi des images collectées et entraînées', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 24),

          if (stats != null) ...[
            _statCard('Images collectées', '${stats['total_images_collected'] ?? 0}', Icons.collections, Colors.blue, theme),
            const SizedBox(height: 12),
            _statCard('Images entraînées', '${stats['total_images_trained'] ?? 0}', Icons.model_training, Colors.green, theme),
            const SizedBox(height: 12),
            _statCard('Générations', '${stats['total_generations'] ?? 0}', Icons.auto_awesome, Colors.orange, theme),
            const SizedBox(height: 12),
            _statCard('Entraînements complétés', '${stats['total_trainings_completed'] ?? 0}', Icons.check_circle, Colors.purple, theme),
          ],

          const SizedBox(height: 24),
          Text('Styles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 12),

          ..._styles.map((s) => _stylePipelineCard(s, theme)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stylePipelineCard(Map<String, dynamic> style, ThemeData theme) {
    final name = style['name'] as String? ?? '';
    final scraped = style['scraped_count'] as int? ?? 0;
    final trained = style['trained_count'] as int? ?? 0;
    final total = style['total_refs'] as int? ?? 0;
    final status = style['training_status'] as String? ?? 'untrained';
    final downloaded = style['downloaded_count'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              _statusBadge(status, total),
            ],
          ),
          const SizedBox(height: 10),
          // Barre de progression collecte → entrainement
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  Flexible(
                    flex: total,
                    child: Container(color: Colors.blue.withOpacity(0.5)),
                  ),
                  if (total == 0) Expanded(child: Container(color: Colors.grey[800])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _dot(Colors.blue, 'Collecté: $total'),
              const SizedBox(width: 12),
              _dot(Colors.green, 'Entraîné: $trained'),
              const SizedBox(width: 12),
              _dot(Colors.orange, 'Téléchargé: $downloaded'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[400])),
      ],
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
    final trainedCount = style['trained_count'] as int? ?? 0;
    final totalRefs = style['total_refs'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(style['name'] as String? ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text('par ${style['mangaka']}', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          const SizedBox(height: 8),
          Text(style['description'] as String? ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 16),

          // Tracking card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tracking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _trackStat('Collectées', '$totalRefs', Colors.blue),
                    _trackStat('Entraînées', '$trainedCount', Colors.green),
                    _trackStat('Générées', '${style['generation_count'] ?? 0}', Colors.orange),
                  ],
                ),
                if (totalRefs > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 6,
                      child: LinearProgressIndicator(
                        value: totalRefs > 0 ? trainedCount / totalRefs : 0,
                        backgroundColor: Colors.grey[800],
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('${totalRefs > 0 ? (trainedCount * 100 / totalRefs).toInt() : 0}% utilisé en entraînement',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                      final isTrained = ref['used_in_training'] == true;
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              ref['image_url'] as String? ?? '',
                              width: 100, height: 140, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 100, height: 140, color: Colors.grey[800]),
                            ),
                          ),
                          if (isTrained)
                            Positioned(
                              top: 4, right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                                child: const Icon(Icons.check, size: 12, color: Colors.white),
                              ),
                            ),
                        ],
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

  Widget _trackStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildJobStatus(ThemeData theme) {
    final job = _trainingJob!;
    final jobStatus = job['status'] as String? ?? 'unknown';
    final progress = (job['progress'] as num?)?.toDouble() ?? 0;
    final refCount = job['reference_count'] as int? ?? 0;

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
          if (refCount > 0) ...[
            const SizedBox(height: 8),
            Text('$refCount images utilisées', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
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
}
