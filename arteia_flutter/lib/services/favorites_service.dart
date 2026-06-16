import 'package:supabase/supabase.dart';
import 'supabase_service.dart';

class FavoritesService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;

  // Toggle favorite on artwork
  Future<bool> toggleFavoriteArtwork(String artworkId) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    // Check if already favorited
    final existing = await _client
        .from('artwork_favorites')
        .select('id')
        .eq('user_id', user.id)
        .eq('artwork_id', artworkId)
        .maybeSingle();

    if (existing != null) {
      await _client.from('artwork_favorites').delete().eq('id', existing['id']);
      return false; // removed
    }

    await _client.from('artwork_favorites').insert({
      'user_id': user.id,
      'artwork_id': artworkId,
    });
    return true; // added
  }

  // Check if artwork is favorited
  Future<bool> isArtworkFavorited(String artworkId) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    final existing = await _client
        .from('artwork_favorites')
        .select('id')
        .eq('user_id', user.id)
        .eq('artwork_id', artworkId)
        .maybeSingle();

    return existing != null;
  }

  // Get user's favorite artworks
  Future<List<Map<String, dynamic>>> getFavoriteArtworks() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('artwork_favorites')
        .select('artworks(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => (item as Map<String, dynamic>)['artworks'] as Map<String, dynamic>)
        .toList();
  }

  // Get favorite count for artwork
  Future<int> getFavoriteCount(String artworkId) async {
    final response = await _client
        .from('artwork_favorites')
        .select('id')
        .eq('artwork_id', artworkId);
    return (response as List).length;
  }

  // Bookmark artwork (save for later)
  Future<bool> toggleBookmarkArtwork(String artworkId) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    final existing = await _client
        .from('artwork_bookmarks')
        .select('id')
        .eq('user_id', user.id)
        .eq('artwork_id', artworkId)
        .maybeSingle();

    if (existing != null) {
      await _client.from('artwork_bookmarks').delete().eq('id', existing['id']);
      return false;
    }

    await _client.from('artwork_bookmarks').insert({
      'user_id': user.id,
      'artwork_id': artworkId,
    });
    return true;
  }

  // Get bookmarked artworks
  Future<List<Map<String, dynamic>>> getBookmarkedArtworks() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('artwork_bookmarks')
        .select('artworks(*)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => (item as Map<String, dynamic>)['artworks'] as Map<String, dynamic>)
        .toList();
  }
}