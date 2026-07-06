import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://wzewlweghntnqyfvhgan.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_AEgvzQeXUmhEpO7fGQPyvQ_fnzZZJNV';
}

class AuthResult {
  final User? user;
  final String? error;
  const AuthResult({this.user, this.error});
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<List<Map<String, dynamic>>> _runListQuery(dynamic query, String label) async {
    try {
      final response = await query;
      if (response is! List) {
        debugPrint('🔴 $label: Expected List, got ${response.runtimeType}');
        return [];
      }
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('🔴 $label exception: $e');
      return [];
    }
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(), password: password,
      );
      await _ensureProfile(user: response.user, displayName: _displayNameFromEmail(email));
      return AuthResult(user: response.user);
    } on AuthException catch (e) {
      return AuthResult(error: e.message);
    } catch (e) {
      return AuthResult(error: 'Connexion impossible: $e');
    }
  }

  Future<AuthResult> signUpWithEmail(String email, String password, {String? displayName}) async {
    try {
      final response = await client.auth.signUp(
        email: email.trim(), password: password,
        data: {'display_name': displayName ?? _displayNameFromEmail(email)},
      );
      await _ensureProfile(user: response.user, displayName: displayName ?? _displayNameFromEmail(email));
      return AuthResult(user: response.user);
    } on AuthException catch (e) {
      return AuthResult(error: e.message);
    } catch (e) {
      return AuthResult(error: 'Inscription impossible: $e');
    }
  }

  Future<void> _ensureProfile({User? user, String? displayName}) async {
    if (user == null) return;
    try {
      await client.from('profiles').upsert({
        'id': user.id, 'email': user.email,
        'display_name': displayName ?? user.userMetadata?['display_name'],
        'role': 'user',
      });
    } catch (e) {
      debugPrint('🔴 ensure profile exception: $e');
    }
  }

  String _displayNameFromEmail(String email) {
    final prefix = email.split('@').first.trim();
    return prefix.isEmpty ? 'Créateur' : prefix.replaceAll(RegExp(r'[._-]+'), ' ');
  }

  // ✅ Categories - pas de as dynamic
  Future<List<Map<String, dynamic>>> getCategories() async {
    return _runListQuery(client.from('categories').select().order('sort_order'), 'GET categories');
  }

  // ✅ Artistes - pas de as dynamic
  Future<List<Map<String, dynamic>>> getArtists({String? categorySlug, int limit = 20, int offset = 0}) async {
    dynamic query = client.from('artists').select().order('created_at', ascending: false).range(offset, offset + limit - 1);
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query = (query as dynamic).eq('category_slug', categorySlug);
    }
    return _runListQuery(query, 'GET artists');
  }

  // ✅ Œuvres - pas de as dynamic
  Future<List<Map<String, dynamic>>> getArtworks({String? categorySlug, int limit = 20, int offset = 0}) async {
    dynamic query = client.from('artworks').select().order('created_at', ascending: false).range(offset, offset + limit - 1);
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query = (query as dynamic).eq('category_slug', categorySlug);
    }
    return _runListQuery(query, 'GET artworks');
  }

  // ✅ Forum - pas de as dynamic
  Future<List<Map<String, dynamic>>> getForumDiscussions({String? categorySlug, int limit = 20, int offset = 0}) async {
    dynamic query = client.from('forum_discussions').select().order('created_at', ascending: false).range(offset, offset + limit - 1);
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query = (query as dynamic).eq('category_slug', categorySlug);
    }
    return _runListQuery(query, 'GET forum_discussions');
  }

  Future<List<Map<String, dynamic>>> getCommunityStats() async {
    return _runListQuery(client.from('community_stats').select().order('sort_order'), 'GET community_stats');
  }

  // ✅ Trend tags - pas de as dynamic
  Future<List<Map<String, dynamic>>> getTrendTags({String? categorySlug}) async {
    dynamic query = client.from('trend_tags').select().order('sort_order');
    if (categorySlug != null && categorySlug.isNotEmpty) {
      query = (query as dynamic).eq('category_slug', categorySlug);
    }
    return _runListQuery(query, 'GET trend_tags');
  }

  Future<List<Map<String, dynamic>>> getChatChannels() async {
    return _runListQuery(client.from('chat_channels').select().order('sort_order'), 'GET chat_channels');
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String channelId, {int limit = 50}) async {
    return _runListQuery(
      client.from('chat_messages').select().eq('channel_id', channelId).order('created_at').limit(limit),
      'GET chat_messages',
    );
  }

  Future<void> sendChatMessage(String channelId, String content) async {
    final user = currentUser;
    if (user == null) throw Exception('Connexion requise pour envoyer un message.');
    await client.from('chat_messages').insert({
      'channel_id': channelId, 'author_id': user.id,
      'author_email': user.email, 'content': content, 'message_type': 'text',
    });
  }

  Future<void> createForumDiscussion(String title, {String categorySlug = 'music'}) async {
    final user = currentUser;
    if (user == null) throw Exception('Connexion requise pour publier une discussion.');
    final displayName = user.userMetadata?['display_name'] ?? user.email?.split('@').first ?? 'Créateur';
    await client.from('forum_discussions').insert({
      'title': title, 'author_id': user.id, 'author_name': displayName,
      'category_slug': categorySlug, 'replies': 0, 'trending': false, 'time_label': 'À l\'instant',
    });
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      return await client.from('profiles').select().eq('id', userId).maybeSingle();
    } catch (e) {
      debugPrint('🔴 GET profiles exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> post(String table, Map<String, dynamic> data) async {
    try {
      return await client.from(table).insert(data).select().single();
    } catch (e) {
      debugPrint('🔴 POST $table exception: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }
}