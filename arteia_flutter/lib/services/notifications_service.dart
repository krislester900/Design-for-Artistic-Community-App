import 'package:supabase/supabase.dart';
import 'supabase_service.dart';

class NotificationsService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;

  // Get notifications for current user
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    // Get notifications from chat messages in channels the user is a member of
    final memberChannels = await _client
        .from('chat_channel_members')
        .select('channel_id')
        .eq('user_id', user.id);

    if (memberChannels.isEmpty) return [];

    final channelIds = (memberChannels as List)
        .map((m) => (m as Map<String, dynamic>)['channel_id'] as String)
        .toList();

    final messages = await _client
        .from('chat_messages')
        .select('*, profiles!author_id(email), chat_channels(name)')
        .inFilter('channel_id', channelIds)
        .neq('author_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return (messages as List).map((msg) => {
      ...msg as Map<String, dynamic>,
      'author_email': (msg['profiles'] as Map<String, dynamic>?)?['email'] ?? 'Inconnu',
      'channel_name': (msg['chat_channels'] as Map<String, dynamic>?)?['name'] ?? '',
      'type': 'message',
    }).toList();
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    final user = _supabase.currentUser;
    if (user == null) return 0;

    final memberChannels = await _client
        .from('chat_channel_members')
        .select('channel_id')
        .eq('user_id', user.id);

    if (memberChannels.isEmpty) return 0;

    final channelIds = (memberChannels as List)
        .map((m) => (m as Map<String, dynamic>)['channel_id'] as String)
        .toList();

    final response = await _client
        .from('chat_messages')
        .select('id')
        .inFilter('channel_id', channelIds)
        .neq('author_id', user.id)
        .gte('created_at', DateTime.now().subtract(const Duration(days: 7)).toIso8601String());

    return (response as List).length;
  }

  // Get friend request count
  Future<int> getFriendRequestCount() async {
    final user = _supabase.currentUser;
    if (user == null) return 0;

    final response = await _client
        .from('user_relationships')
        .select('id')
        .eq('target_id', user.id)
        .eq('status', 'pending');

    return (response as List).length;
  }
}