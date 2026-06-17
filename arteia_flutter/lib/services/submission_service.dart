import 'supabase_service.dart';

class SubmissionService {
  final SupabaseService _supabase = SupabaseService();

  Future<Map<String, dynamic>?> submitArtwork({
    required String title,
    required String artistName,
    required String categorySlug,
    required String medium,
  }) async {
    return await _supabase.post('artworks', {
      'title': title,
      'artist_name': artistName,
      'category_slug': categorySlug,
      'medium': medium,
      'likes': 0,
      'views': 0,
    });
  }

  Future<Map<String, dynamic>?> submitArtist({
    required String name,
    required String categorySlug,
    required String role,
  }) async {
    return await _supabase.post('artists', {
      'name': name,
      'category_slug': categorySlug,
      'role': role,
      'likes': 0,
    });
  }

  Future<Map<String, dynamic>?> submitForumDiscussion({
    required String title,
    required String authorName,
    required String categorySlug,
  }) async {
    return await _supabase.post('forum_discussions', {
      'title': title,
      'author_name': authorName,
      'category_slug': categorySlug,
      'replies': 0,
      'time_label': 'maintenant',
      'trending': false,
    });
  }
}