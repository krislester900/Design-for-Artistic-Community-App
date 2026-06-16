import 'package:supabase/supabase.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://wzewlweghntnqyfvhgan.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_AEgvzQeXUmhEpO7fGQPyvQ_fnzZZJNV';
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal() {
    _client = SupabaseClient(SupabaseConfig.supabaseUrl, SupabaseConfig.supabaseAnonKey);
  }

  late final SupabaseClient _client;
  SupabaseClient get client => _client;

  // Auth methods
  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isAuthenticated => currentUser != null;

  // Sign in with email
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(email: email, password: password);
  }

  // Sign up with email
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // Profile methods
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _client.from('profiles').select().eq('id', userId).maybeSingle();
    return response;
  }

  // Categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client.from('categories').select().order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  // Artists
  Future<List<Map<String, dynamic>>> getArtists({String? categorySlug, int limit = 20, int offset = 0}) async {
    var query = _client.from('artists').select();
    if (categorySlug != null) {
      query = query.eq('category_slug', categorySlug);
    }
    final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  // Artworks
  Future<List<Map<String, dynamic>>> getArtworks({String? categorySlug, int limit = 20, int offset = 0}) async {
    var query = _client.from('artworks').select();
    if (categorySlug != null) {
      query = query.eq('category_slug', categorySlug);
    }
    final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  // Forum discussions
  Future<List<Map<String, dynamic>>> getForumDiscussions({String? categorySlug, int limit = 20, int offset = 0}) async {
    var query = _client.from('forum_discussions').select();
    if (categorySlug != null) {
      query = query.eq('category_slug', categorySlug);
    }
    final response = await query.order('created_at', ascending: false).range(offset, offset + limit - 1);
    return List<Map<String, dynamic>>.from(response);
  }

  // Trend tags
  Future<List<Map<String, dynamic>>> getTrendTags({String? categorySlug}) async {
    var query = _client.from('trend_tags').select();
    if (categorySlug != null) {
      query = query.eq('category_slug', categorySlug);
    }
    final response = await query.order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  // Community events
  Future<List<Map<String, dynamic>>> getCommunityEvents({String? categorySlug}) async {
    var query = _client.from('community_events').select();
    if (categorySlug != null) {
      query = query.eq('category_slug', categorySlug);
    }
    final response = await query.order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  // Community stats
  Future<List<Map<String, dynamic>>> getCommunityStats() async {
    final response = await _client.from('community_stats').select().order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  // Chat channels
  Future<List<Map<String, dynamic>>> getChatChannels() async {
    final response = await _client.from('chat_channels').select().order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }

  // Chat messages for a channel
  Future<List<Map<String, dynamic>>> getChatMessages(String channelId, {int limit = 50}) async {
    final response = await _client
        .from('chat_messages')
        .select('*, profiles!author_id(email)')
        .eq('channel_id', channelId)
        .order('created_at', ascending: true)
        .limit(limit);
    return List<Map<String, dynamic>>.from(response);
  }

  // Send a chat message
  Future<void> sendChatMessage(String channelId, String content) async {
    final userId = currentUser?.id;
    if (userId == null) return;
    await _client.from('chat_messages').insert({
      'channel_id': channelId,
      'author_id': userId,
      'content': content,
    });
  }
}