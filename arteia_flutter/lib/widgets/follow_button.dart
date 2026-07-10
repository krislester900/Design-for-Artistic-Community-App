import 'package:flutter/material.dart';
import '../services/follow_service.dart';
import '../services/supabase_service.dart';
import '../services/quests_service.dart';
import '../services/toast_service.dart';
import '../theme/app_theme.dart';

class FollowButton extends StatefulWidget {
  final String userId;
  final double? height;
  final VoidCallback? onChanged;

  const FollowButton({
    super.key,
    required this.userId,
    this.height,
    this.onChanged,
  });

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  final FollowService _followService = FollowService();
  final SupabaseService _supabase = SupabaseService();
  final QuestsService _questsService = QuestsService();
  
  bool _isFollowing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFollowing();
  }

  Future<void> _checkFollowing() async {
    final following = await _followService.isFollowing(widget.userId);
    if (mounted) setState(() {
      _isFollowing = following;
      _isLoading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final user = _supabase.currentUser;
    if (user == null) {
      ToastService.instance.show(message: 'Connectez-vous pour suivre', type: ToastType.warning);
      return;
    }

    if (user.id == widget.userId) {
      ToastService.instance.show(message: 'Vous ne pouvez pas vous suivre vous-même', type: ToastType.warning);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _followService.toggleFollow(widget.userId);
      if (success && mounted) {
        setState(() {
          _isFollowing = !_isFollowing;
          _isLoading = false;
        });
        widget.onChanged?.call();
        
        if (_isFollowing) {
          _questsService.updateQuestProgress(QuestType.follow, 1);
        }
        
        ToastService.instance.show(
          message: _isFollowing ? 'Abonné avec succès!' : 'Désabonné',
          type: ToastType.success,
          duration: const Duration(seconds: 1),
        );
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastService.instance.show(message: 'Erreur: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        width: 90,
        height: widget.height ?? 36,
        child: const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    return GestureDetector(
      onTap: _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: widget.height ?? 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: _isFollowing ? Colors.transparent : AppTheme.primaryViolet,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isFollowing ? Colors.grey.withOpacity(0.5) : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            _isFollowing ? 'Suivi(e)' : 'Suivre',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _isFollowing ? Colors.grey[400] : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// A compact follow button for use in lists
class CompactFollowButton extends StatelessWidget {
  final String userId;
  final VoidCallback? onChanged;

  const CompactFollowButton({
    super.key,
    required this.userId,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 30,
      child: FollowButton(
        userId: userId,
        height: 30,
        onChanged: onChanged,
      ),
    );
  }
}