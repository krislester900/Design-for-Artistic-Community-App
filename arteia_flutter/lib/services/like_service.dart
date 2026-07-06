import 'package:flutter/foundation.dart';
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

  Future<LikeResult> toggleLike(String postId) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Connecte-toi pour liker !');

    try {
      final existing = await _supabase.client
          .from('post_likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('post_id', postId)
          .maybeSingle();

      if (existing != null) {
        await _supabase.client
            .from('post_likes')
            .delete()
            .eq('id', existing['id']);

        try {
          await _supabase.client.rpc('decrement_likes', params: {'post_id': postId});
        } catch (e) {
          debugPrint('⚠️ decrement_likes RPC failed: $e');
        }

        final count = await getLikeCount(postId);
        return LikeResult(liked: false, count: count);
      } else {
        await _supabase.client.from('post_likes').insert({
          'user_id': user.id,
          'post_id': postId,
        });

        try {
          await _supabase.client.rpc('increment_likes', params: {'post_id': postId});
        } catch (e) {
          debugPrint('⚠️ increment_likes RPC failed: $e');
        }

        try {
          _haptic.triggerHaptic(HapticFeedbackType.success);
        } catch (e) {
          debugPrint('⚠️ Haptic feedback failed: $e');
        }

        final count = await getLikeCount(postId);
        return LikeResult(liked: true, count: count);
      }
    } catch (e) {
      debugPrint('❌ toggleLike error: $e');
      rethrow;
    }
  }

  Future<bool> isLiked(String postId) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      final existing = await _supabase.client
          .from('post_likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('post_id', postId)
          .maybeSingle();
      return existing != null;
    } catch (e) {
      debugPrint('❌ isLiked error: $e');
      return false;
    }
  }

  Future<int> getLikeCount(String postId) async {
    try {
      final response = await _supabase.client
          .from('post_likes')
          .select()
          .eq('post_id', postId);
      if (response is List) return response.length;
      return 0;
    } catch (e) {
      debugPrint('❌ getLikeCount error: $e');
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getPostLikes(String postId) async {
    try {
      final response = await _supabase.client
          .from('post_likes')
          .select('user_id, profiles!inner(username, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: false)
          .limit(10);

      if (response is List) {
        return List<Map<String, dynamic>>.from(
          response.map((item) => Map<String, dynamic>.from(item as Map)),
        );
      }
      return [];
    } catch (e) {
      debugPrint('❌ getPostLikes error: $e');
      return [];
    }
  }
}

class LikeResult {
  final bool liked;
  final int count;
  LikeResult({required this.liked, required this.count});
}

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
  bool _isLoading = false;

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
    if (_isAnimating || _isLoading) return;
    _isAnimating = true;

    final previousLiked = _isLiked;
    final previousCount = _likeCount;

    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
      _isLoading = true;
    });

    _animController.forward(from: 0.0);

    try {
      final service = LikeService();
      final result = await service.toggleLike(widget.postId);

      if (mounted) {
        setState(() {
          _isLiked = result.liked;
          _likeCount = result.count;
          _isLoading = false;
        });
        widget.onChanged?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = previousLiked;
          _likeCount = previousCount;
          _isLoading = false;
        });
      }
    } finally {
      _isAnimating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading ? null : _handleLike,
      child: Opacity(
        opacity: _isLoading ? 0.6 : 1.0,
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
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}