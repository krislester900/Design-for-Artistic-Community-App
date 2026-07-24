import 'package:supabase_flutter/supabase_flutter.dart';

class ChatServiceEnhanced {
  final SupabaseClient _client = Supabase.instance.client;

  // Supprimer un message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client
          .from('chat_messages')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', messageId);
    } catch (e) {
      print('Erreur deleteMessage: $e');
      rethrow;
    }
  }

  // Envoyer un message éphémère
  Future<void> sendEphemeralMessage({
    required String channelId,
    required String content,
    required Duration duration,
  }) async {
    try {
      final expiresAt = DateTime.now().add(duration);
      final userId = _client.auth.currentUser?.id;

      await _client.from('chat_messages').insert({
        'channel_id': channelId,
        'author_id': userId,
        'content': content,
        'message_type': 'text',
        'is_ephemeral': true,
        'expires_at': expiresAt.toIso8601String(),
      });
    } catch (e) {
      print('Erreur sendEphemeralMessage: $e');
      rethrow;
    }
  }

  // Envoyer un message (texte ou vocal)
  Future<void> sendMessage(String channelId, {
    required String content,
    String? voiceUrl,
    int? voiceDuration,
    bool isEphemeral = false,
    Duration? ephemeralDuration,
  }) async {
    try {
      final expiresAt = isEphemeral && ephemeralDuration != null
          ? DateTime.now().add(ephemeralDuration)
          : null;
      final userId = _client.auth.currentUser?.id;

      await _client.from('chat_messages').insert({
        'channel_id': channelId,
        'author_id': userId,
        'content': content,
        'message_type': voiceUrl != null ? 'voice' : 'text',
        'voice_url': voiceUrl,
        'voice_duration': voiceDuration ?? 0,
        'is_ephemeral': isEphemeral,
        'expires_at': expiresAt?.toIso8601String(),
      });
    } catch (e) {
      print('Erreur sendMessage: $e');
      rethrow;
    }
  }

  // Récupérer les messages actifs (non supprimés, non expirés)
  Future<List<Map<String, dynamic>>> getActiveMessages(String channelId) async {
    try {
      final response = await _client
          .from('active_messages')
          .select('*, profiles(username, avatar_url)')
          .eq('channel_id', channelId)
          .order('created_at', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur getActiveMessages: $e');
      return [];
    }
  }

  // Vérifier si un message est éphémère et quand il expire
  Future<Duration?> getMessageExpiry(String messageId) async {
    try {
      final response = await _client
          .from('chat_messages')
          .select('is_ephemeral, expires_at')
          .eq('id', messageId)
          .single();
      
      if (response['is_ephemeral'] == true && response['expires_at'] != null) {
        final expiresAt = DateTime.parse(response['expires_at']);
        final now = DateTime.now();
        final remaining = expiresAt.difference(now);
        
        if (remaining.isNegative) {
          return null; // Message expiré
        }
        return remaining;
      }
      return null; // Message non éphémère
    } catch (e) {
      print('Erreur getMessageExpiry: $e');
      return null;
    }
  }

  // Nettoyer les messages éphémères expirés (à appeler périodiquement)
  Future<void> cleanupExpiredMessages() async {
    try {
      await _client.rpc('cleanup_ephemeral_messages');
    } catch (e) {
      print('Erreur cleanupExpiredMessages: $e');
    }
  }
}