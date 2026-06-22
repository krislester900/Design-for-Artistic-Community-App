import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UniversePage extends StatefulWidget {
  final String categorySlug;
  final String categoryName;

  const UniversePage({
    super.key,
    this.categorySlug = 'all',
    this.categoryName = 'Univers',
  });

  @override
  State<UniversePage> createState() => _UniversePageState();
}

class _UniversePageState extends State<UniversePage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _posts = [];
  List<Map<String, dynamic>> _categories = [];
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
        widget.categorySlug == 'all' ? _api.getPosts() : _api.getPostsByCategory(widget.categorySlug),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _posts.isEmpty
              ? const Center(child: Text('Aucune publication', style: TextStyle(color: Colors.black)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return _PostCard(post: post);
                  },
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