import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/music_player_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.getCategories(),
        _api.getPosts(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0];
          _posts = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.black,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // Hero card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bienvenue sur', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    const SizedBox(height: 4),
                    const Text('Artéïa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('La communauté artistique', style: TextStyle(fontSize: 13, color: Colors.grey[300])),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Catégories
              if (_categories.isNotEmpty) ...[
                const Text('Univers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final color = Color(int.parse(cat['color'].replaceFirst('#', '0xFF')));
                      return GestureDetector(
                        onTap: () {
                          // TODO: Navigate to universe page
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(cat['icon'], style: const TextStyle(fontSize: 24)),
                              const SizedBox(height: 4),
                              Text(cat['name'], style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Posts récents
              if (_posts.isNotEmpty) ...[
                const Text('Publications récentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 12),
                ..._posts.take(5).map((post) => _PostCard(post)),
              ],
              
              // Player musical (si un post musique est présent)
              if (_posts.any((post) => post['type'] == 'music')) ...[
                const SizedBox(height: 20),
                const Text('En écoute', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                const SizedBox(height: 12),
                MusicPlayerWidget(
                  audioUrl: '',
                  title: 'Titre exemple',
                  artist: 'Artiste',
                  coverUrl: null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _PostCard(Map<String, dynamic> post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                post['profiles']?['avatar_url'] ?? '📝',
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['title'],
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  post['profiles']?['username'] ?? 'Anonyme',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 3),
                    Text('${post['likes_count'] ?? 0}', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}