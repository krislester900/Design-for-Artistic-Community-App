import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class FollowService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final FollowService _instance = FollowService._();
  factory FollowService() => _instance;
  FollowService._();

  /// Follow a user
  Future<bool> followUser(String followingId) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');
    if (user.id == followingId) throw Exception('Vous ne pouvez pas vous suivre vous-même.');

    try {
      await _client.from('follows').insert({
        'follower_id': user.id,
        'following_id': followingId,
      });
      return true;
    } catch (e) {
      print('🔴 Follow error: $e');
      return false;
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(String followingId) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    try {
      await _client
          .from('follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', followingId);
      return true;
    } catch (e) {
      print('🔴 Unfollow error: $e');
      return false;
    }
  }

  /// Check if current user is following a specific user
  Future<bool> isFollowing(String followingId) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('follows')
          .select('id')
          .eq('follower_id', user.id)
          .eq('following_id', followingId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      print('🔴 isFollowing error: $e');
      return false;
    }
  }

  /// Get followers count for a user
  Future<int> getFollowersCount(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('followers_count')
          .eq('id', userId)
          .maybeSingle();
      return (response?['followers_count'] as int?) ?? 0;
    } catch (e) {
      print('🔴 getFollowersCount error: $e');
      return 0;
    }
  }

  /// Get following count for a user
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('following_count')
          .eq('id', userId)
          .maybeSingle();
      return (response?['following_count'] as int?) ?? 0;
    } catch (e) {
      print('🔴 getFollowingCount error: $e');
      return 0;
    }
  }

  /// Get list of followers for a user
  Future<List<Map<String, dynamic>>> getFollowers(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('follower_id, profiles!follows_follower_id_fkey(id, username, avatar_url)')
          .eq('following_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((item) {
        final profile = item['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'id': profile['id'],
          'username': profile['username'] ?? 'Anonyme',
          'avatar_url': profile['avatar_url'],
        };
      }).toList();
    } catch (e) {
      print('🔴 getFollowers error: $e');
      return [];
    }
  }

  /// Get list of users that a user follows
  Future<List<Map<String, dynamic>>> getFollowing(String userId) async {
    try {
      final response = await _client
          .from('follows')
          .select('following_id, profiles!follows_following_id_fkey(id, username, avatar_url)')
          .eq('follower_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((item) {
        final profile = item['profiles'] as Map<String, dynamic>? ?? {};
        return {
          'id': profile['id'],
          'username': profile['username'] ?? 'Anonyme',
          'avatar_url': profile['avatar_url'],
        };
      }).toList();
    } catch (e) {
      print('🔴 getFollowing error: $e');
      return [];
    }
  }

  /// Toggle follow status
  Future<bool> toggleFollow(String followingId) async {
    final isCurrentlyFollowing = await isFollowing(followingId);
    if (isCurrentlyFollowing) {
      return await unfollowUser(followingId);
    } else {
      return await followUser(followingId);
    }
  }
}