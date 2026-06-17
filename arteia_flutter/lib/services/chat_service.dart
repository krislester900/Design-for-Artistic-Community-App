import 'supabase_service.dart';

class ChatService {
  final SupabaseService _supabase = SupabaseService();

  // Channels
  Future<List<Map<String, dynamic>>> fetchChannels() async {
    return await _supabase.getChatChannels();
  }

  // Messages
  Future<List<Map<String, dynamic>>> fetchMessages(String channelId, {int limit = 50}) async {
    return await _supabase.getChatMessages(channelId, limit: limit);
  }

  Future<void> sendMessage(String channelId, String content) async {
    await _supabase.sendChatMessage(channelId, content);
  }
}