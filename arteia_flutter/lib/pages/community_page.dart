import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _api.getPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
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
        title: const Text('Communauté', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _posts.isEmpty
              ? const Center(child: Text('Aucune publication', style: TextStyle(color: Colors.black)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[300]!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text(post['profiles']?['avatar_url'] ?? '👤', style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['profiles']?['username'] ?? 'Anonyme', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black)),
                    Text(post['type'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(post['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 6),
          Text(post['description'] ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_border, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text('${post['likes_count'] ?? 0}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              const SizedBox(width: 16),
              Icon(Icons.comment_outlined, size: 20, color: Colors.grey[700]),
              const SizedBox(width: 4),
              Text('${post['comments_count'] ?? 0}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ],
          ),
        ],
      ),
    );
  }
}