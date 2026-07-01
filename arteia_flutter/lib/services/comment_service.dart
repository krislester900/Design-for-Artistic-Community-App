import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'quests_service.dart';

class CommentService {
  final SupabaseService _supabase = SupabaseService();
  final QuestsService _quests = QuestsService();
  static final CommentService _instance = CommentService._();
  factory CommentService() => _instance;
  CommentService._();

  /// Récupérer les commentaires d'un post
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final postIdInt = int.tryParse(postId) ?? 0;

      // Essayer d'abord la nouvelle table post_comments
      final response = await _supabase.client
          .from('post_comments')
          .select('*, profiles!user_id(username, avatar_url)')
          .eq('post_id', postIdInt)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback à l'ancienne table comments
      try {
        final response = await _supabase.client
            .from('comments')
            .select('*, profiles!user_id(username, avatar_url)')
            .eq('post_id', postIdInt)
            .order('created_at', ascending: false);

        return List<Map<String, dynamic>>.from(response);
      } catch (e2) {
        debugPrint('🔴 getComments error: $e2');
        return [];
      }
    }
  }

  /// Ajouter un commentaire
  Future<Map<String, dynamic>?> addComment({
    required String postId,
    required String userId,
    required String content,
    String? parentId,
  }) async {
    try {
      final postIdInt = int.tryParse(postId) ?? 0;

      final response = await _supabase.client
          .from('post_comments')
          .insert({
            'post_id': postIdInt,
            'user_id': userId,
            'content': content,
            if (parentId != null) 'parent_id': parentId,
          })
          .select('*, profiles!user_id(username, avatar_url)')
          .single();

      // Mettre à jour le compteur
      await _supabase.client.rpc('increment_comments', params: {'post_id': postIdInt});

      // Quête
      _quests.updateQuestProgress(QuestType.comment, 1);

      return response as Map<String, dynamic>?;
    } catch (e) {
      // Fallback ancienne table
      try {
        final response = await _supabase.client
            .from('comments')
            .insert({
              'post_id': postIdInt,
              'user_id': userId,
              'content': content,
            })
            .select('*, profiles!user_id(username, avatar_url)')
            .single();

        return response as Map<String, dynamic>?;
      } catch (e2) {
        debugPrint('🔴 addComment error: $e2');
        return null;
      }
    }
  }

  /// Supprimer un commentaire
  Future<bool> deleteComment(String commentId) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      await _supabase.client
          .from('post_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', user.id);
      return true;
    } catch (e) {
      try {
        await _supabase.client
            .from('comments')
            .delete()
            .eq('id', commentId)
            .eq('user_id', user.id);
        return true;
      } catch (e2) {
        return false;
      }
    }
  }

  /// Obtenir le nombre de commentaires
  Future<int> getCommentCount(String postId) async {
    try {
      final postIdInt = int.tryParse(postId) ?? 0;
      if (postIdInt == 0) return 0;

      final response = await _supabase.client
          .from('post_comments')
          .select('id', count: CountOption.exact)
          .eq('post_id', postIdInt);
      return response.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Formater le temps écoulé
  static String getTimeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      if (diff.inDays < 30) return 'Il y a ${diff.inDays ~/ 7}sem';
      if (diff.inDays < 365) return 'Il y a ${diff.inDays ~/ 30}mois';
      return 'Il y a ${diff.inDays ~/ 365}ans';
    } catch (e) {
      return createdAt;
    }
  }
}

/// Widget CommentTile réutilisable
class CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final VoidCallback? onDelete;
  final bool isOwner;

  const CommentTile({
    super.key,
    required this.comment,
    this.onDelete,
    this.isOwner = false,
  });

  @override
  Widget build(BuildContext context) {
    final profile = comment['profiles'] as Map<String, dynamic>?;
    final username = profile?['username'] ?? 'Anonyme';
    final avatarUrl = profile?['avatar_url'];
    final content = comment['content'] ?? '';
    final time = CommentService.getTimeAgo(comment['created_at']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CFC), Color(0xFF42C83C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
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
          // Contenu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (isOwner && onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[300],
                    height: 1.4,
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