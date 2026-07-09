import 'dart:async';
import 'package:flutter/material.dart';
import '../services/planche_generator_service.dart';

class PlancheGeneratorPage extends StatefulWidget {
  const PlancheGeneratorPage({super.key});

  @override
  State<PlancheGeneratorPage> createState() => _PlancheGeneratorPageState();
}

class _PlancheGeneratorPageState extends State<PlancheGeneratorPage> {
  final _service = PlancheGeneratorService();
  final _sceneController = TextEditingController();
  final _titleController = TextEditingController();

  List<Map<String, dynamic>> _styles = [];
  List<Map<String, dynamic>> _layouts = [];
  Map<String, dynamic>? _selectedStyle;
  Map<String, dynamic>? _selectedLayout;
  bool _isGenerating = false;
  String? _error;

  Map<String, dynamic>? _currentPlanche;
  List<Map<String, dynamic>> _currentPanels = [];
  bool _isPolling = false;

  final List<Map<String, String>> _characters = [];
  final _charNameController = TextEditingController();
  final _charAppearanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _sceneController.dispose();
    _titleController.dispose();
    _charNameController.dispose();
    _charAppearanceController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final styles = await _service.getStyles();
    final layouts = await _service.getLayouts();
    if (mounted) {
      setState(() {
        _styles = styles;
        _layouts = layouts;
        if (_selectedLayout == null && layouts.isNotEmpty) {
          _selectedLayout = layouts[0];
        }
      });
    }
  }

  void _addCharacter() {
    final name = _charNameController.text.trim();
    final appearance = _charAppearanceController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _characters.add({'name': name, 'appearance': appearance});
      _charNameController.clear();
      _charAppearanceController.clear();
    });
  }

  void _removeCharacter(int index) {
    setState(() => _characters.removeAt(index));
  }

  Future<void> _generate() async {
    final scene = _sceneController.text.trim();
    if (scene.isEmpty || _selectedStyle == null) return;

    setState(() {
      _isGenerating = true;
      _error = null;
      _currentPlanche = null;
      _currentPanels = [];
    });

    final result = await _service.generatePlanche(
      scene: scene,
      styleSlug: _selectedStyle!['slug'] as String,
      layoutType: _selectedLayout?['slug'] as String?,
      characters: _characters.isNotEmpty ? _characters : null,
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
    );

    if (result.containsKey('error')) {
      setState(() {
        _isGenerating = false;
        _error = result['error'] as String?;
      });
      return;
    }

    final plancheId = result['planche_id'] as int?;
    if (plancheId != null) {
      _pollPlanche(plancheId);
    } else {
      setState(() {
        _isGenerating = false;
        _error = 'La génération n\'a pas abouti';
      });
    }
  }

  Future<void> _pollPlanche(int plancheId) async {
    setState(() => _isPolling = true);

    for (int i = 0; i < 60; i++) {
      await Future.delayed(const Duration(seconds: 2));
      final status = await _service.getPlancheStatus(plancheId);

      if (!mounted) return;

      setState(() {
        _currentPlanche = status['planche'] as Map<String, dynamic>?;
        _currentPanels = List<Map<String, dynamic>>.from(status['panels'] as List? ?? []);
      });

      final completed = status['completed_panels'] as int? ?? 0;
      final total = status['total_panels'] as int? ?? 0;

      if (completed == total && total > 0) {
        setState(() {
          _isGenerating = false;
          _isPolling = false;
        });
        return;
      }

      if (_currentPlanche?['status'] == 'failed') break;
    }

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _isPolling = false;
        if (_currentPlanche?['status'] != 'completed') {
          _error = 'Le délai d\'attente est dépassé';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Générateur de Planche'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStyleGrid(theme),
            const SizedBox(height: 16),
            _buildLayoutGrid(theme),
            const SizedBox(height: 16),
            _buildCharacterSection(theme),
            const SizedBox(height: 16),
            _buildSceneInput(theme),
            const SizedBox(height: 12),
            _buildTitleInput(theme),
            const SizedBox(height: 16),
            _buildGenerateButton(theme),
            if (_error != null) _buildError(theme),
            if (_isGenerating || _isPolling) _buildLoadingState(theme),
            if (_currentPlanche != null && _currentPanels.isNotEmpty) _buildPlanchePreview(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleGrid(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Style manga', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 8),
        _styles.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            : SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _styles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final style = _styles[index];
                    final selected = _selectedStyle?['id'] == style['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStyle = style),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 90,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: selected
                              ? const LinearGradient(colors: [Color(0xFF7C5CFC), Color(0xFF5B3FE0)])
                              : LinearGradient(colors: [theme.cardColor, theme.cardColor.withOpacity(0.6)]),
                          border: selected ? Border.all(color: const Color(0xFF7C5CFC), width: 2) : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(style['name'] as String? ?? '', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: selected ? Colors.white : theme.textTheme.bodyLarge?.color), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(style['mangaka'] as String? ?? '', style: TextStyle(fontSize: 8, color: selected ? Colors.white70 : Colors.grey), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
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

  Widget _buildLayoutGrid(ThemeData theme) {
    String layoutName(Map<String, dynamic> l) => l['name'] as String? ?? '';
    int panelCount(Map<String, dynamic> l) => l['panel_count'] as int? ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Disposition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 8),
        _layouts.isEmpty
            ? Text('Aucune disposition disponible', style: TextStyle(color: Colors.grey[500], fontSize: 12))
            : SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _layouts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final layout = _layouts[index];
                    final selected = _selectedLayout?['id'] == layout['id'];
                    final count = panelCount(layout);

                    return GestureDetector(
                      onTap: () => setState(() => _selectedLayout = layout),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: selected ? const Color(0xFF7C5CFC).withOpacity(0.15) : theme.cardColor,
                          border: Border.all(color: selected ? const Color(0xFF7C5CFC) : Colors.grey.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLayoutMini(count),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(count > 0 ? '$count cases' : '?', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? const Color(0xFF7C5CFC) : theme.textTheme.bodyLarge?.color)),
                                Text(layoutName(layout), style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                              ],
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

  Widget _buildLayoutMini(int count) {
    if (count == 1) {
      return Container(width: 24, height: 32, decoration: BoxDecoration(color: const Color(0xFF7C5CFC).withOpacity(0.3), borderRadius: BorderRadius.circular(3)));
    }
    if (count == 4) {
      return SizedBox(
        width: 24, height: 32,
        child: Column(children: [
          Expanded(child: Row(children: [Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 0.5)))), const SizedBox(width: 1), Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 0.5))))])),
          const SizedBox(height: 1),
          Expanded(child: Row(children: [Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 0.5)))), const SizedBox(width: 1), Expanded(child: Container(decoration: BoxDecoration(border: Border.all(color: Colors.grey, width: 0.5))))])),
        ]),
      );
    }
    return Icon(Icons.grid_view, size: 20, color: Colors.grey[400]);
  }

  Widget _buildCharacterSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personnages (optionnel)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 8),
        if (_characters.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: List.generate(_characters.length, (i) {
              final c = _characters[i];
              return Chip(
                label: Text('${c['name']}${c['appearance']!.isNotEmpty ? ': ${c['appearance']}' : ''}', style: const TextStyle(fontSize: 11)),
                deleteIcon: const Icon(Icons.close, size: 14),
                onDeleted: () => _removeCharacter(i),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _charNameController,
                decoration: InputDecoration(
                  hintText: 'Nom',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _charAppearanceController,
                decoration: InputDecoration(
                  hintText: 'Apparence',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF7C5CFC)),
              onPressed: _addCharacter,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSceneInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Scène', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
        const SizedBox(height: 8),
        TextField(
          controller: _sceneController,
          maxLines: 3,
          enabled: !_isGenerating,
          decoration: InputDecoration(
            hintText: 'Décris la scène de cette planche... ex: un combat de samouraïs sous la pluie, avec duel au sommet d\'un temple',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleInput(ThemeData theme) {
    return TextField(
      controller: _titleController,
      enabled: !_isGenerating,
      decoration: InputDecoration(
        hintText: 'Titre de la planche (optionnel)',
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildGenerateButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (_isGenerating || _selectedStyle == null || _sceneController.text.trim().isEmpty) ? null : _generate,
        icon: _isGenerating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_stories),
        label: Text(_isGenerating ? 'Génération en cours...' : 'Générer la planche'),
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
    final planche = _currentPlanche;
    final panels = _currentPanels;
    final completed = panels.where((p) => p['status'] == 'completed').length;
    final total = panels.length;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(width: 60, height: 60, child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF7C5CFC))),
          const SizedBox(height: 16),
          Text('Arteïa Muse construit ta planche...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 8),
          if (total > 0)
            Text('$completed / $total cases générées', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          if (planche != null && panels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildPlancheGrid(theme, planche, panels),
            ),
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

  Widget _buildPlanchePreview(ThemeData theme) {
    final planche = _currentPlanche!;
    final panels = _currentPanels;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
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
              Text('Planche terminée !', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color)),
            ],
          ),
          if (planche['title']?.toString().isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(planche['title'] as String? ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[400])),
            ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildPlancheGrid(theme, planche, panels),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _actionButton(Icons.refresh, 'Nouvelle', () {
                setState(() {
                  _currentPlanche = null;
                  _currentPanels = [];
                  _error = null;
                });
              }),
              _actionButton(Icons.download, 'Exporter', () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir : export PNG/PDF')),
                );
              }),
              _actionButton(Icons.info_outline, 'Détails', () => _showPanelDetails(context, planche, panels)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlancheGrid(ThemeData theme, Map<String, dynamic> planche, List<Map<String, dynamic>> panels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 1.414;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: panels.map<Widget>((panel) {
              final x = (panel['x_pct'] as num?)?.toDouble() ?? 0;
              final y = (panel['y_pct'] as num?)?.toDouble() ?? 0;
              final w = (panel['width_pct'] as num?)?.toDouble() ?? 25;
              final h = (panel['height_pct'] as num?)?.toDouble() ?? 25;
              final status = panel['status'] as String? ?? 'pending';
              final imageUrl = panel['image_url'] as String?;

              return Positioned(
                left: width * x / 100,
                top: height * y / 100,
                width: width * w / 100,
                height: height * h / 100,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 0.5),
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: _buildPanelContent(status, imageUrl, panel, theme),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildPanelContent(String status, String? imageUrl, Map<String, dynamic> panel, ThemeData theme) {
    switch (status) {
      case 'completed':
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            },
            errorBuilder: (context, error, stackTrace) {
              return _panelPlaceholder(panel, theme, Icons.broken_image, 'Erreur');
            },
          );
        }
        return _panelPlaceholder(panel, theme, Icons.image, 'Complété');
      case 'generating':
        return _panelPlaceholder(panel, theme, Icons.hourglass_top, 'Génération...');
      case 'failed':
        return _panelPlaceholder(panel, theme, Icons.error_outline, 'Échec');
      default:
        return _panelPlaceholder(panel, theme, Icons.hourglass_empty, 'En attente');
    }
  }

  Widget _panelPlaceholder(Map<String, dynamic> panel, ThemeData theme, IconData icon, String label) {
    return Container(
      color: theme.brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.grey[500]),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  void _showPanelDetails(BuildContext context, Map<String, dynamic> planche, List<Map<String, dynamic>> panels) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Text('Détails des cases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color)),
                  const SizedBox(height: 16),
                  ...panels.asMap().entries.map((entry) {
                    final i = entry.key;
                    final p = entry.value;
                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C5CFC).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('Case ${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C5CFC))),
                                ),
                                const SizedBox(width: 8),
                                Text('${p['width_pct']}% × ${p['height_pct']}%', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                              ],
                            ),
                            if (p['scene_description']?.toString().isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(p['scene_description'] as String? ?? '', style: const TextStyle(fontSize: 13)),
                              ),
                            if (p['dialogue']?.toString().isNotEmpty == true)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('✏️ ${p['dialogue'] as String? ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic)),
                              ),
                            if (p['image_url'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    p['image_url'] as String? ?? '',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
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
}
