import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _api.getPosts(),
        _api.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _posts = results[0];
          _categories = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPosts {
    if (_selectedCategory == 'all') return _posts;
    return _posts.where((post) => post['category_slug'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Explorer', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
      ),
      body: Column(
        children: [
          // Catégories
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                final isAll = index == 0;
                final cat = isAll ? null : _categories[index - 1];
                final isSelected = isAll ? _selectedCategory == 'all' : _selectedCategory == cat!['slug'];

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = isAll ? 'all' : cat!['slug'];
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        isAll ? 'Tout' : cat!['name'],
                        style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Grille
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _filteredPosts.isEmpty
                    ? const Center(child: Text('Aucune publication', style: TextStyle(color: Colors.black)))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
                        itemCount: _filteredPosts.length,
                        itemBuilder: (context, index) {
                          final post = _filteredPosts[index];
                          return _PostCard(post: post);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
                child: Center(child: Text(post['profiles']?['avatar_url'] ?? '📝', style: const TextStyle(fontSize: 48))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(post['profiles']?['username'] ?? 'Anonyme', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      const Spacer(),
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
      ),
    );
  }
}