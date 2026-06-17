import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/supabase_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _channels = [];
  List<Map<String, dynamic>> _discussions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _supabase.getChatChannels(),
        _supabase.getForumDiscussions(limit: 20),
      ]);
      if (mounted) setState(() {
        _channels = results[0];
        _discussions = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        // Données de démonstration
        setState(() {
          _channels = [
            {'id': '1', 'name': 'Général', 'description': 'Discussions générales', 'unread_count': 3},
            {'id': '2', 'name': 'Musique', 'description': 'Partagez vos découvertes', 'unread_count': 0},
            {'id': '3', 'name': 'Art Visuel', 'description': 'Expositions et créations', 'unread_count': 5},
            {'id': '4', 'name': 'Manga', 'description': 'Nouveautés et avis', 'unread_count': 0},
          ];
          _discussions = [
            {'id': '1', 'title': 'Nouvelle exposition à Paris', 'author': 'Marie L.', 'replies': 12, 'likes': 45, 'created_at': '2024-01-15'},
            {'id': '2', 'title': 'Concert de jazz ce weekend', 'author': 'Jean D.', 'replies': 8, 'likes': 23, 'created_at': '2024-01-14'},
            {'id': '3', 'title': 'Nouveau manga à découvrir', 'author': 'Sophie M.', 'replies': 15, 'likes': 67, 'created_at': '2024-01-13'},
            {'id': '4', 'title': 'Conseils pour débuter en peinture', 'author': 'Lucas B.', 'replies': 20, 'likes': 89, 'created_at': '2024-01-12'},
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _createDiscussion() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Nouvelle discussion', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: titleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Titre de la discussion',
            hintStyle: TextStyle(color: Colors.grey),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  _discussions.insert(0, {
                    'id': DateTime.now().toString(),
                    'title': titleController.text,
                    'author': 'Vous',
                    'replies': 0,
                    'likes': 0,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Publier', style: TextStyle(color: AppTheme.primaryViolet)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
          : Column(
              children: [
                // Channels section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    border: Border(
                      bottom: BorderSide(color: AppTheme.textMuted.withOpacity(0.1)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Canaux', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.add, size: 18, color: AppTheme.primaryViolet),
                            label: const Text('Créer', style: TextStyle(color: AppTheme.primaryViolet, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _channels.length,
                          itemBuilder: (context, index) {
                            final channel = _channels[index];
                            return Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.primaryViolet.withOpacity(0.2), AppTheme.primaryTeal.withOpacity(0.1)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.primaryViolet.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Text(channel['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  if ((channel['unread_count'] ?? 0) > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryPink,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text('${channel['unread_count']}', style: const TextStyle(fontSize: 10, color: Colors.white)),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Discussions section
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discussions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                            IconButton(
                              onPressed: _createDiscussion,
                              icon: const Icon(Icons.add_circle, color: AppTheme.primaryViolet, size: 28),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _discussions.length,
                          itemBuilder: (context, index) {
                            final discussion = _discussions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.cardDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.textMuted.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    discussion['title'] ?? '',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text('Par ${discussion['author'] ?? 'Anonyme'}', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.chat_bubble_outline, size: 14, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text('${discussion['replies'] ?? 0}', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      const SizedBox(width: 12),
                                      Icon(Icons.favorite_border, size: 14, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text('${discussion['likes'] ?? 0}', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}