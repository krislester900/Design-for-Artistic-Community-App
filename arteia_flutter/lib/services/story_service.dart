import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class StoryService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final StoryService _instance = StoryService._();
  factory StoryService() => _instance;
  StoryService._();

  /// Récupérer les stories actives des utilisateurs suivis
  Future<List<Map<String, dynamic>>> getActiveStories() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    try {
      // Récupérer les utilisateurs suivis qui ont des stories actives
      final response = await _client
          .from('stories')
          .select('*, user:profiles!user_id(id, username, avatar_url, level)')
          .gt('expires_at', DateTime.now().toIso8601String())
          .filter('deleted_at', 'is', null)
          .order('created_at', ascending: false);

      // Grouper par utilisateur
      final stories = (response as List).cast<Map<String, dynamic>>();
      final grouped = <String, List<Map<String, dynamic>>>{};
      
      for (final story in stories) {
        final userId = story['user_id'] as String;
        grouped.putIfAbsent(userId, () => []).add(story);
      }

      // Formater pour l'affichage
      return grouped.entries.map((entry) {
        final firstStory = entry.value.first;
        final userProfile = firstStory['user'] as Map<String, dynamic>? ?? {};
        return {
          'user_id': entry.key,
          'username': userProfile['username'] ?? 'Anonyme',
          'avatar_url': userProfile['avatar_url'],
          'level': userProfile['level'] ?? 1,
          'stories': entry.value,
          'has_unviewed': entry.value.any((s) => !(s['viewed'] ?? false)),
        };
      }).toList();
    } catch (e) {
      print('🔴 getActiveStories error: $e');
      return [];
    }
  }

  /// Publier une story
  Future<Map<String, dynamic>> createStory({
    required String mediaUrl,
    required String mediaType,
    String? caption,
    int durationSeconds = 5,
    String? thumbnailUrl,
    bool isSpoiler = false,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    try {
      final response = await _client.from('stories').insert({
        'user_id': user.id,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'caption': caption ?? '',
        'duration_seconds': durationSeconds,
        'thumbnail_url': thumbnailUrl ?? mediaUrl,
        'is_spoiler': isSpoiler,
        'expires_at': DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
      }).select().maybeSingle();

      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('🔴 createStory error: $e');
      rethrow;
    }
  }

  /// Marquer une story comme vue
  Future<void> markAsViewed(String storyId) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      await _client.from('story_views').insert({
        'story_id': storyId,
        'viewer_id': user.id,
      });

      // Incrémenter le compteur de vues
      await _client.rpc('increment_story_views', params: {'story_id': storyId});
    } catch (e) {
      // Ignorer les doublons (déjà vu)
      if (!e.toString().contains('duplicate')) {
        print('🔴 markAsViewed error: $e');
      }
    }
  }

  /// Réagir à une story
  Future<void> reactToStory(String storyId, String emoji) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      await _client.from('story_reactions').upsert({
        'story_id': storyId,
        'user_id': user.id,
        'emoji': emoji,
      });

      // Incrémenter le compteur
      await _client.rpc('increment_story_reactions', params: {'story_id': storyId});
    } catch (e) {
      print('🔴 reactToStory error: $e');
    }
  }

  /// Répondre à une story
  Future<void> replyToStory(String storyId, String message) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      await _client.from('story_replies').insert({
        'story_id': storyId,
        'user_id': user.id,
        'message': message,
      });

      await _client.rpc('increment_story_replies', params: {'story_id': storyId});
    } catch (e) {
      print('🔴 replyToStory error: $e');
    }
  }

  /// Supprimer une story
  Future<void> deleteStory(String storyId) async {
    try {
      await _client.from('stories').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', storyId);
    } catch (e) {
      print('🔴 deleteStory error: $e');
    }
  }

  /// Créer un highlight
  Future<void> createHighlight({
    required String name,
    List<String>? storyIds,
    String? coverUrl,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      await _client.from('story_highlights').insert({
        'user_id': user.id,
        'name': name,
        'cover_image_url': coverUrl,
        'stories': storyIds ?? [],
      });
    } catch (e) {
      print('🔴 createHighlight error: $e');
    }
  }

  /// Obtenir les highlights d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserHighlights(String userId) async {
    try {
      final response = await _client
          .from('story_highlights')
          .select('*')
          .eq('user_id', userId)
          .order('sort_order', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getUserHighlights error: $e');
      return [];
    }
  }

  /// Obtenir les viewers d'une story
  Future<List<Map<String, dynamic>>> getStoryViewers(String storyId) async {
    try {
      final response = await _client
          .from('story_views')
          .select('viewer:profiles!viewer_id(id, username, avatar_url)')
          .eq('story_id', storyId)
          .order('viewed_at', ascending: false);

      return (response as List).map((item) {
        final viewer = item['viewer'] as Map<String, dynamic>? ?? {};
        return viewer;
      }).toList();
    } catch (e) {
      print('🔴 getStoryViewers error: $e');
      return [];
    }
  }

  /// Vérifier si l'utilisateur a des stories non vues
  Future<bool> hasUnviewedStories() async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('stories')
          .select('id')
          .gt('expires_at', DateTime.now().toIso8601String())
          .filter('deleted_at', 'is', null);

      final stories = response as List;
      if (stories.isEmpty) return false;

      for (final story in stories) {
        final viewed = await _client
            .from('story_views')
            .select('id')
            .eq('story_id', story['id'])
            .eq('viewer_id', user.id)
            .maybeSingle();
        if (viewed == null) return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}