import 'package:supabase/supabase.dart';
import 'supabase_service.dart';

class ChatService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;

  // Channels
  Future<List<Map<String, dynamic>>> fetchChannels() async {
    final response = await _client
        .from('chat_channels')
        .select('*')
        .order('sort_order', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> fetchChannelById(String id) async {
    final response = await _client
        .from('chat_channels')
        .select('*')
        .eq('id', id)
        .single();
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createChannel({
    required String name,
    required String description,
    required String type,
    String? categorySlug,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    final response = await _client
        .from('chat_channels')
        .insert({
          'name': name,
          'description': description,
          'type': type,
          'category_slug': categorySlug,
          'created_by': user.id,
        })
        .select()
        .single();

    // Auto-join creator as owner
    await _client.from('chat_channel_members').insert({
      'channel_id': response['id'],
      'user_id': user.id,
      'role': 'owner',
    });

    return response as Map<String, dynamic>;
  }

  Future<void> joinChannel(String channelId) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');
    await _client.from('chat_channel_members').insert({
      'channel_id': channelId,
      'user_id': user.id,
      'role': 'member',
    });
  }

  Future<void> leaveChannel(String channelId) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');
    await _client
        .from('chat_channel_members')
        .delete()
        .eq('channel_id', channelId)
        .eq('user_id', user.id);
  }

  Future<void> deleteChannel(String channelId) async {
    await _client.from('chat_channels').delete().eq('id', channelId);
  }

  // Messages
  Future<List<Map<String, dynamic>>> fetchMessages(
    String channelId, {
    int limit = 50,
    String? beforeId,
  }) async {
    var query = _client
        .from('chat_messages')
        .select('*, profiles!author_id(email)')
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .limit(limit);

    if (beforeId != null) {
      query = query.lt('id', beforeId);
    }

    final response = await query;
    return (response as List).map((msg) => {
      ...msg as Map<String, dynamic>,
      'author_email': (msg['profiles'] as Map<String, dynamic>?)?['email'] ?? 'Inconnu',
    }).toList().reversed.toList();
  }

  Future<Map<String, dynamic>> sendMessage(
    String channelId,
    String content, {
    String? replyTo,
    String? attachmentUrl,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');
    if (content.trim().isEmpty) throw Exception('Message vide.');

    final response = await _client
        .from('chat_messages')
        .insert({
          'channel_id': channelId,
          'author_id': user.id,
          'content': content.trim(),
          'reply_to': replyTo,
          'attachment_url': attachmentUrl,
        })
        .select('*, profiles!author_id(email)')
        .single();

    return {
      ...response as Map<String, dynamic>,
      'author_email': (response['profiles'] as Map<String, dynamic>?)?['email'] ?? 'Inconnu',
    };
  }

  Future<void> editMessage(String messageId, String content) async {
    await _client
        .from('chat_messages')
        .update({
          'content': content,
          'edited_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId);
  }

  Future<void> deleteMessage(String messageId) async {
    await _client.from('chat_messages').delete().eq('id', messageId);
  }

  // Channel Members
  Future<List<Map<String, dynamic>>> fetchChannelMembers(String channelId) async {
    final response = await _client
        .from('chat_channel_members')
        .select('*, profiles!user_id(email)')
        .eq('channel_id', channelId);
    return (response as List).map((m) => {
      ...m as Map<String, dynamic>,
      'email': (m['profiles'] as Map<String, dynamic>?)?['email'] ?? 'Inconnu',
    }).toList();
  }

  // Groups
  Future<List<Map<String, dynamic>>> fetchGroups() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('chat_group_members')
        .select('chat_groups(*)')
        .eq('user_id', user.id);
    return (response as List)
        .map((item) => (item as Map<String, dynamic>)['chat_groups'] as Map<String, dynamic>)
        .toList();
  }

  // Friends / Relationships
  Future<Map<String, dynamic>> fetchFriends() async {
    final user = _supabase.currentUser;
    if (user == null) return {'friends': [], 'pending': []};

    final response = await _client
        .from('user_relationships')
        .select('*, requester:requester_id(email), target:target_id(email)')
        .or('requester_id.eq.${user.id},target_id.eq.${user.id}');

    final rels = (response as List).map((r) => {
      ...r as Map<String, dynamic>,
      'requester_email': (r['requester'] as Map<String, dynamic>?)?['email'],
      'target_email': (r['target'] as Map<String, dynamic>?)?['email'],
    }).toList();

    final friends = rels.where((r) => r['status'] == 'accepted').toList();
    final pending = rels.where((r) =>
      r['status'] == 'pending' && r['target_id'] == user.id).toList();

    return {'friends': friends, 'pending': pending};
  }

  Future<void> sendFriendRequest(String targetEmail) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    final profiles = await _client
        .from('profiles')
        .select('id, email')
        .eq('email', targetEmail)
        .limit(1);

    if (profiles.isEmpty) throw Exception('Utilisateur introuvable.');
    final target = profiles.first;
    if (target['id'] == user.id) throw Exception('Tu ne peux pas t\'ajouter toi-même.');

    await _client.from('user_relationships').insert({
      'requester_id': user.id,
      'target_id': target['id'],
      'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String requesterId) async {
    final user = _supabase.currentUser;
    await _client
        .from('user_relationships')
        .update({'status': 'accepted'})
        .eq('requester_id', requesterId)
        .eq('target_id', user?.id ?? '');
  }

  Future<void> declineFriendRequest(String requesterId) async {
    await _client
        .from('user_relationships')
        .delete()
        .eq('requester_id', requesterId)
        .eq('status', 'pending');
  }

  // Presence
  Future<void> updatePresence(String status) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    await _client.from('user_presence').upsert({
      'user_id': user.id,
      'status': status,
      'last_seen_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  // Typing indicators
  Future<void> setTyping(String channelId, bool isTyping) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    if (isTyping) {
      await _client.from('typing_indicators').upsert({
        'user_id': user.id,
        'channel_id': channelId,
        'started_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,channel_id');
    } else {
      await _client
          .from('typing_indicators')
          .delete()
          .eq('user_id', user.id)
          .eq('channel_id', channelId);
    }
  }

  // Search messages
  Future<List<Map<String, dynamic>>> searchMessages(String channelId, String query) async {
    final response = await _client
        .from('chat_messages')
        .select('*, profiles!author_id(email)')
        .eq('channel_id', channelId)
        .ilike('content', '%$query%')
        .order('created_at', ascending: false)
        .limit(50);
    return (response as List).map((msg) => {
      ...msg as Map<String, dynamic>,
      'author_email': (msg['profiles'] as Map<String, dynamic>?)?['email'] ?? 'Inconnu',
    }).toList();
  }

  // Voice messages
  Future<String> uploadVoiceMessage(List<int> audioBytes, String channelId, String fileName) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    final path = '$channelId/${user.id/${DateTime.now().millisecondsSinceEpoch}-$fileName';
    await _client.storage.from('chat-attachments').uploadBinary(path, audioBytes,
      fileOptions: const FileOptions(contentType: 'audio/webm'));

    return _client.storage.from('chat-attachments').getPublicUrl(path);
  }

  // Sticker messages
  Future<Map<String, dynamic>> sendStickerMessage(
    String channelId, String stickerId, String stickerUrl) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    final response = await _client
        .from('chat_messages')
        .insert({
          'channel_id': channelId,
          'author_id': user.id,
          'content': stickerUrl,
          'message_type': 'sticker',
          'sticker_id': stickerId,
        })
        .select('*, profiles!author_id(email)')
        .single();

    return {
      ...response as Map<String, dynamic>,
      'author_email': (response['profiles'] as Map<String, dynamic>?)?['email'] ?? 'Inconnu',
    };
  }

  // GIF messages
  Future<Map<String, dynamic>> sendGifMessage(String channelId, String gifUrl) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    final response = await _client
        .from('chat_messages')
        .insert({
          'channel_id': channelId,
          'author_id': user.id,
          'content': gifUrl,
          'message_type': 'gif',
        })
        .select('*, profiles!author_id(email)')
        .single();

    return {
      ...response as Map<String, dynamic>,
      'author_email': (response['profiles'] as Map<String, dynamic>?)?['email'] ?? 'Inconnu',
    };
  }

  // Pin messages
  Future<void> togglePinMessage(String messageId) async {
    final msg = await _client
        .from('chat_messages')
        .select('is_pinned')
        .eq('id', messageId)
        .single();

    await _client
        .from('chat_messages')
        .update({'is_pinned': !(msg['is_pinned'] ?? false)})
        .eq('id', messageId);
  }

  Future<List<Map<String, dynamic>>> fetchPinnedMessages(String channelId) async {
    final response = await _client
        .from('chat_messages')
        .select('*, profiles!author_id(email)')
        .eq('channel_id', channelId)
        .eq('is_pinned', true)
        .order('created_at', ascending: false);
    return (response as List).map((msg) => {
      ...msg as Map<String, dynamic>,
      'author_email': (msg['profiles'] as Map<String, dynamic>?)?['email'] ?? 'Inconnu',
    }).toList();
  }

  // Reactions
  Future<bool> toggleReaction(String messageId, String emoji) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    final existing = await _client
        .from('chat_message_reactions')
        .select('id')
        .eq('message_id', messageId)
        .eq('user_id', user.id)
        .eq('emoji', emoji)
        .maybeSingle();

    if (existing != null) {
      await _client.from('chat_message_reactions').delete().eq('id', existing['id']);
      return false;
    }

    await _client.from('chat_message_reactions').insert({
      'message_id': messageId,
      'user_id': user.id,
      'emoji': emoji,
    });
    return true;
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchReactions(List<String> messageIds) async {
    if (messageIds.isEmpty) return {};
    final response = await _client
        .from('chat_message_reactions')
        .select('*')
        .inFilter('message_id', messageIds);

    final map = <String, List<Map<String, dynamic>>>{};
    for (final r in response) {
      final msgId = r['message_id'] as String;
      map.putIfAbsent(msgId, () => []).add(r as Map<String, dynamic>);
    }
    return map;
  }
}