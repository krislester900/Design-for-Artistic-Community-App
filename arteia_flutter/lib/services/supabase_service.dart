import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class SupabaseConfig {
  static const String supabaseUrl = 'https://wzewlweghntnqyfvhgan.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_AEgvzQeXUmhEpO7fGQPyvQ_fnzZZJNV';
}

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  String get _baseUrl => SupabaseConfig.supabaseUrl;
  String get _apiKey => SupabaseConfig.supabaseAnonKey;

  Map<String, String> get _headers => {
    'apikey': _apiKey,
    'Authorization': 'Bearer $_apiKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  // Generic GET request
  Future<List<Map<String, dynamic>>> _get(String table, {
    String? filter,
    String? order,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    var url = '$_baseUrl/rest/v1/$table?select=*';
    if (filter != null) url += '&$filter';
    if (order != null) url += '&order=$order.${ascending ? 'asc' : 'desc'}';
    if (limit != null) url += '&limit=$limit';
    if (offset != null) url += '&offset=$offset';

    try {
      print('🔵 DEBUG GET: $url');
      final response = await http.get(Uri.parse(url), headers: _headers);
      print('🔵 DEBUG GET $table: status=${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = List<Map<String, dynamic>>.from(data ?? []);
        print('🟢 DEBUG GET $table: SUCCESS - ${result.length} items');
        return result;
      }
      print('🔴 GET $table error: ${response.statusCode} ${response.body}');
      return [];
    } catch (e) {
      print('🔴 GET $table exception: $e');
      return [];
    }
  }

  // Generic POST request (public - accessible from other services)
  Future<Map<String, dynamic>?> post(String table, Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rest/v1/$table'),
        headers: _headers,
        body: json.encode(body),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) return data.first;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      print('POST $table error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('POST $table exception: $e');
      return null;
    }
  }

  // Generic PATCH request
  Future<bool> _patch(String table, String id, Map<String, dynamic> body) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/rest/v1/$table?id=eq.$id'),
        headers: _headers,
        body: json.encode(body),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('PATCH $table exception: $e');
      return false;
    }
  }

  // Generic DELETE request
  Future<bool> _delete(String table, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/rest/v1/$table?id=eq.$id'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      print('DELETE $table exception: $e');
      return false;
    }
  }

  // Categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    return await _get('categories', order: 'sort_order');
  }

  // Artists
  Future<List<Map<String, dynamic>>> getArtists({String? categorySlug, int limit = 20, int offset = 0}) async {
    String? filter;
    if (categorySlug != null) filter = 'category_slug=eq.$categorySlug';
    return await _get('artists', filter: filter, order: 'created_at', limit: limit, offset: offset);
  }

  // Artworks
  Future<List<Map<String, dynamic>>> getArtworks({String? categorySlug, int limit = 20, int offset = 0}) async {
    String? filter;
    if (categorySlug != null) filter = 'category_slug=eq.$categorySlug';
    return await _get('artworks', filter: filter, order: 'created_at', limit: limit, offset: offset);
  }

  // Forum discussions
  Future<List<Map<String, dynamic>>> getForumDiscussions({String? categorySlug, int limit = 20, int offset = 0}) async {
    String? filter;
    if (categorySlug != null) filter = 'category_slug=eq.$categorySlug';
    return await _get('forum_discussions', filter: filter, order: 'created_at', limit: limit, offset: offset);
  }

  // Community stats
  Future<List<Map<String, dynamic>>> getCommunityStats() async {
    return await _get('community_stats', order: 'sort_order');
  }

  // Trend tags
  Future<List<Map<String, dynamic>>> getTrendTags({String? categorySlug}) async {
    String? filter;
    if (categorySlug != null) filter = 'category_slug=eq.$categorySlug';
    return await _get('trend_tags', filter: filter, order: 'sort_order');
  }

  // Chat channels
  Future<List<Map<String, dynamic>>> getChatChannels() async {
    return await _get('chat_channels', order: 'sort_order');
  }

  // Chat messages
  Future<List<Map<String, dynamic>>> getChatMessages(String channelId, {int limit = 50}) async {
    return await _get('chat_messages', filter: 'channel_id=eq.$channelId', order: 'created_at', limit: limit);
  }

  // Send chat message
  Future<void> sendChatMessage(String channelId, String content) async {
    await post('chat_messages', {
      'channel_id': channelId,
      'content': content,
    });
  }

  // Profile
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final results = await _get('profiles', filter: 'id=eq.$userId', limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  // Auth (simplified - no Supabase Auth SDK needed for public data)
  bool get isAuthenticated => false;
  dynamic get currentUser => null;
  dynamic get currentSession => null;

  Future<void> signOut() async {}
}