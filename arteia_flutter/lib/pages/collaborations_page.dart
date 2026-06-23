import 'package:flutter/material.dart';
import '../services/collaboration_service.dart';
import '../theme/app_theme.dart';

class CollaborationsPage extends StatefulWidget {
  const CollaborationsPage({super.key});

  @override
  State<CollaborationsPage> createState() => _CollaborationsPageState();
}

class _CollaborationsPageState extends State<CollaborationsPage> {
  final CollaborationService _collabService = CollaborationService();

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'musique';
  final List<String> _roles = [];
  final _roleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Nouveau projet', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Titre',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: AppTheme.cardDarkLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: AppTheme.cardDarkLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: AppTheme.cardDark,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppTheme.cardDarkLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: ['musique', 'art-visuel', 'litterature', 'manga', 'films']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _roleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ajouter un rôle',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: AppTheme.cardDarkLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add, color: AppTheme.primaryViolet),
                    onPressed: () {
                      if (_roleController.text.isNotEmpty) {
                        setState(() => _roles.add(_roleController.text));
                        _roleController.clear();
                      }
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: _roles.map((r) => Chip(
                  label: Text(r, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  backgroundColor: AppTheme.primaryViolet.withOpacity(0.2),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => setState(() => _roles.remove(r)),
                )).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty && _roles.isNotEmpty) {
                _collabService.createProject(
                  title: _titleController.text,
                  description: _descController.text,
                  creatorId: 'user-123',
                  category: _selectedCategory,
                  roles: _roles,
                );
                _titleController.clear();
                _descController.clear();
                _roles.clear();
                Navigator.pop(context);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Collaborations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _showCreateDialog,
          ),
        ],
      ),
      body: _collabService.openProjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  Text('Aucun projet collaboratif', style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Lancer un projet'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryViolet),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _collabService.openProjects.length,
              itemBuilder: (context, index) {
                final project = _collabService.openProjects[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryViolet.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.groups, color: AppTheme.primaryViolet, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(project.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(project.description, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: project.roles.map((role) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDarkLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(role, style: const TextStyle(fontSize: 11, color: AppTheme.primaryTeal)),
                        )).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}