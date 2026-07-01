import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'interactivity_service.dart';

class LikeService {
  final SupabaseService _supabase = SupabaseService();
  final InteractivityService _haptic = InteractivityService();
  static final LikeService _instance = LikeService._();
  factory LikeService() => _instance;
  LikeService._();

  /// Toggle like sur un post
  Future<LikeResult> toggleLike(String postId) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Connecte-toi pour liker !');

    // Vérifier si déjà liké
    final existing = await _supabase.client
        .from('post_likes')
        .select('id')
        .eq('user_id', user.id)
        .eq('post_id', postId)
        .maybeSingle();

    if (existing != null) {
      // Unlike
      await _supabase.client
          .from('post_likes')
          .delete()
          .eq('id', existing['id']);

      // Décrémenter le compteur
      await _supabase.client.rpc('decrement_likes', params: {'post_id': postId});
      
      final count = await getLikeCount(postId);
      return LikeResult(liked: false, count: count);
    } else {
      // Like
      await _supabase.client.from('post_likes').insert({
        'user_id': user.id,
        'post_id': postId,
      });

      // Incrémenter le compteur
      await _supabase.client.rpc('increment_likes', params: {'post_id': postId});

      // Haptique
      _haptic.triggerHaptic(HapticFeedbackType.success);

      final count = await getLikeCount(postId);
      return LikeResult(liked: true, count: count);
    }
  }

  /// Vérifier si l'utilisateur a liké
  Future<bool> isLiked(String postId) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    final existing = await _supabase.client
        .from('post_likes')
        .select('id')
        .eq('user_id', user.id)
        .eq('post_id', postId)
        .maybeSingle();

    return existing != null;
  }

  /// Obtenir le nombre de likes
  Future<int> getLikeCount(String postId) async {
    try {
      final response = await _supabase.client
          .from('post_likes')
          .select()
          .eq('post_id', postId);
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }

  /// Obtenir les likes users pour un post
  Future<List<Map<String, dynamic>>> getPostLikes(String postId) async {
    final response = await _supabase.client
        .from('post_likes')
        .select('user_id, profiles!inner(username, avatar_url)')
        .eq('post_id', postId)
        .order('created_at', ascending: false)
        .limit(10);

    return (response as List).cast<Map<String, dynamic>>();
  }
}

class LikeResult {
  final bool liked;
  final int count;

  LikeResult({required this.liked, required this.count});
}

/// Widget LikeButton réutilisable
class LikeButton extends StatefulWidget {
  final String postId;
  final int initialCount;
  final bool initialLiked;
  final double size;
  final VoidCallback? onChanged;

  const LikeButton({
    super.key,
    required this.postId,
    this.initialCount = 0,
    this.initialLiked = false,
    this.size = 24,
    this.onChanged,
  });

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likeCount;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _bounceAnim;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialLiked;
    _likeCount = widget.initialCount;

    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _bounceAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLike() async {
    if (_isAnimating) return;
    _isAnimating = true;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    _animController.forward(from: 0.0);

    try {
      final service = LikeService();
      final result = await service.toggleLike(widget.postId);
      
      if (mounted) {
        setState(() {
          _isLiked = result.liked;
          _likeCount = result.count;
        });
        widget.onChanged?.call();
      }
    } catch (e) {
      // Rollback
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });
      }
    } finally {
      _isAnimating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleLike,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: _isLiked ? (1.0 + _bounceAnim.value * 0.3) : 1.0,
                child: AnimatedBuilder(
                  animation: _scaleAnim,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animController.isAnimating ? _scaleAnim.value : 1.0,
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.grey,
                        size: widget.size,
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 4),
          AnimatedBuilder(
            animation: _bounceAnim,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_bounceAnim.value * 8),
                child: Text(
                  _formatCount(_likeCount),
                  style: TextStyle(
                    color: _isLiked ? Colors.red : Colors.grey,
                    fontSize: widget.size * 0.6,
                    fontWeight: _isLiked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}