import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import '../services/quests_service.dart';
import '../services/local_image_cache_service.dart';
import '../theme/app_theme.dart';
import 'universe_page.dart';
import 'reading_mode_page.dart';

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> post;
  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final ApiService _api = ApiService();
  final SupabaseService _supabase = SupabaseService();
  final QuestsService _questsService = QuestsService();
  LocalImageCacheService? _imageCache;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLiked = false;
  int _likesCount = 0;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  bool _isSendingComment = false;

  @override
  void initState() {
    super.initState();
    _initServices();
    _likesCount = widget.post['likes_count'] ?? widget.post['likes'] ?? 0;
    _loadInitialData();
  }

  Future<void> _initServices() async {
    _imageCache = await LocalImageCacheService.getInstance();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _checkIfLiked(),
      _loadComments(),
    ]);
  }

  Future<void> _checkIfLiked() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    final postId = widget.post['id'];
    if (postId == null) return;

    final liked = await _api.isPostLiked(postId, user.id);
    if (mounted) setState(() => _isLiked = liked);
  }

  Future<void> _loadComments() async {
    final postId = widget.post['id'];
    if (postId == null) return;

    try {
      final response = await _supabase.client
          .from('comments')
          .select('*, profiles!user_id(username, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response);
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      print('🔴 Load comments error: $e');
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _toggleLike() async {
    final user = _supabase.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour liker')),
      );
      return;
    }

    final postId = widget.post['id'];
    if (postId == null) return;

    final wasLiked = _isLiked;
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    try {
      if (_isLiked) {
        await _api.likePost(postId, user.id);
        // Update quest progress
        _questsService.updateQuestProgress(QuestType.like, 1);
      } else {
        await _api.unlikePost(postId, user.id);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _isLiked = wasLiked;
        _likesCount += wasLiked ? 1 : -1;
      });
    }
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = _supabase.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour commenter')),
      );
      return;
    }

    final postId = widget.post['id'];
    if (postId == null) return;

    setState(() => _isSendingComment = true);

    try {
      await _supabase.client.from('comments').insert({
        'post_id': postId,
        'user_id': user.id,
        'content': text,
      });

      _commentController.clear();
      await _loadComments();

      // Update comments count in post
      await _supabase.client
          .from('posts')
          .update({'comments_count': _comments.length})
          .eq('id', postId);

      // Update quest progress
      _questsService.updateQuestProgress(QuestType.comment, 1);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire ajouté!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingComment = false);
    }
  }

  void _openUniverse() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UniversePage()),
    );
  }

  void _openReadingMode() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingModePage(
          title: widget.post['title'] ?? 'Sans titre',
          author: widget.post['profiles']?['username'] ?? 'Artiste',
          category: widget.post['category_slug'] ?? 'Art',
          content: widget.post['description'] ?? 'Contenu non disponible.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Publication', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories, color: Colors.white),
            onPressed: _openReadingMode,
            tooltip: 'Mode lecture',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post content
                  _buildPostContent(),
                  const SizedBox(height: 20),
                  // Actions
                  _buildActions(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Comments section
                  _buildCommentsSection(),
                ],
              ),
            ),
          ),
          // Comment input at bottom
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildPostContent() {
    final imageUrl = widget.post['image_url'];
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    widget.post['profiles']?['avatar_url'] ?? '👤',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post['profiles']?['username'] ?? 'Anonyme',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      widget.post['category_slug'] ?? 'Art',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.post['title'] ?? 'Sans titre',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          if (widget.post['description'] != null && (widget.post['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.post['description'],
              style: TextStyle(fontSize: 14, color: Colors.grey[300], height: 1.6),
            ),
          ],
          if (imageUrl != null && (imageUrl as String).isNotEmpty && _imageCache != null) ...[
            const SizedBox(height: 16),
            FutureBuilder<Uint8List?>(
              future: _imageCache!.getImage(imageUrl),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  // Display cached image
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      snapshot.data!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  );
                }
                // Fallback to network image
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: AppTheme.cardDarkLight,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: AppTheme.cardDarkLight,
                        child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        _ActionButton(
          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
          label: '$_likesCount',
          isActive: _isLiked,
          onTap: _toggleLike,
          activeColor: AppTheme.primaryPink,
        ),
        const SizedBox(width: 12),
        _ActionButton(
          icon: Icons.comment,
          label: '${_comments.length}',
          onTap: () {},
          activeColor: AppTheme.primaryViolet,
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _openReadingMode,
          icon: const Icon(Icons.auto_stories, size: 16),
          label: const Text('Lire'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryViolet),
        ),
        TextButton.icon(
          onPressed: _openUniverse,
          icon: const Icon(Icons.link, size: 16),
          label: const Text('Univers'),
          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryTeal),
        ),
      ],
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Commentaires (${_comments.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        if (_isLoadingComments)
          const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
        else if (_comments.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text('Aucun commentaire', style: TextStyle(color: Colors.grey[600])),
                  Text('Soyez le premier à commenter!', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                ],
              ),
            ),
          )
        else
          ..._comments.map((comment) => _CommentTile(comment: comment)),
      ],
    );
  }

  Widget _buildCommentInput() {
    final user = _supabase.currentUser;
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: user != null ? 'Ajouter un commentaire...' : 'Connectez-vous pour commenter',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
                filled: true,
                fillColor: AppTheme.cardDarkLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _addComment(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isSendingComment ? null : _addComment,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isSendingComment
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color activeColor;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : AppTheme.cardDarkLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isActive ? activeColor : Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isActive ? activeColor : Colors.grey[400],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  const _CommentTile({required this.comment});

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return 'Il y a ${diff.inDays ~/ 7}sem';
    } catch (e) {
      return createdAt;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = comment['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] ?? 'Anonyme';
    final avatarUrl = profile?['avatar_url'];
    final content = comment['content'] ?? '';
    final time = _getTimeAgo(comment['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDarkLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(avatarUrl, fit: BoxFit.cover),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(fontSize: 13, color: Colors.grey[300], height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}