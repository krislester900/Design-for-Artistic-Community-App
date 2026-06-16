import 'package:supabase/supabase.dart';
import 'supabase_service.dart';

class SubmissionService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;

  // Submit artwork
  Future<Map<String, dynamic>> submitArtwork({
    required String title,
    required String artistName,
    required String categorySlug,
    required String medium,
    String? imageUrl,
  }) async {
    final response = await _client
        .from('artworks')
        .insert({
          'title': title,
          'artist_name': artistName,
          'category_slug': categorySlug,
          'medium': medium,
          'image': imageUrl ?? '',
          'likes': 0,
          'views': 0,
        })
        .select()
        .single();
    return response as Map<String, dynamic>;
  }

  // Submit artist profile
  Future<Map<String, dynamic>> submitArtist({
    required String name,
    required String categorySlug,
    required String role,
    required String image,
    required String featuredWork,
  }) async {
    final response = await _client
        .from('artists')
        .insert({
          'name': name,
          'category_slug': categorySlug,
          'role': role,
          'image': image,
          'featured_work': featuredWork,
          'likes': 0,
        })
        .select()
        .single();
    return response as Map<String, dynamic>;
  }

  // Submit forum discussion
  Future<Map<String, dynamic>> submitForumDiscussion({
    required String title,
    required String authorName,
    required String categorySlug,
  }) async {
    final response = await _client
        .from('forum_discussions')
        .insert({
          'title': title,
          'author_name': authorName,
          'category_slug': categorySlug,
          'replies': 0,
          'time_label': 'maintenant',
          'trending': false,
        })
        .select()
        .single();
    return response as Map<String, dynamic>;
  }

  // Like artwork
  Future<void> likeArtwork(String artworkId) async {
    await _client.rpc('increment_likes', params: {'artwork_id': artworkId});
  }

  // View artwork
  Future<void> viewArtwork(String artworkId) async {
    await _client.rpc('increment_views', params: {'artwork_id': artworkId});
  }

  // Get user's submissions
  Future<List<Map<String, dynamic>>> getUserArtworks(String artistName) async {
    final response = await _client
        .from('artworks')
        .select('*')
        .eq('artist_name', artistName)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  // Get user's discussions
  Future<List<Map<String, dynamic>>> getUserDiscussions(String authorName) async {
    final response = await _client
        .from('forum_discussions')
        .select('*')
        .eq('author_name', authorName)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }
}