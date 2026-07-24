import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';

class LocalChatRepository {
  static const String _boxName = 'local_chat';
  static const String _queueKey = '__pending_queue__';
  Box? _box;

  Future<void> init() async {
    if (kIsWeb) return;
    try {
      _box = await Hive.openBox(_boxName);
    } catch (_) {}
  }

  bool get isAvailable => _box != null;

  Future<void> saveMessage(Map<String, dynamic> message) async {
    if (_box == null) return;
    await _box!.put(message['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(), message);
  }

  Future<void> saveMessages(String channelId, List<Map<String, dynamic>> messages) async {
    if (_box == null) return;
    for (final msg in messages) {
      await saveMessage(msg);
    }
  }

  Future<List<Map<String, dynamic>>> getMessages(String channelId) async {
    if (_box == null) return [];
    final results = <Map<String, dynamic>>[];
    for (final key in _box!.keys) {
      if (key == _queueKey) continue;
      final value = _box!.get(key);
      if (value is Map) {
        final msg = Map<String, dynamic>.from(value);
        if (msg['channel_id'] == channelId) {
          results.add(msg);
        }
      }
    }
    results.sort((a, b) => (a['created_at'] ?? '').toString().compareTo((b['created_at'] ?? '').toString()));
    return results;
  }

  Future<void> enqueuePending(Map<String, dynamic> message) async {
    if (_box == null) return;
    final queue = _box!.get(_queueKey, defaultValue: <Map<String, dynamic>>[]) as List;
    queue.add(message);
    await _box!.put(_queueKey, queue);
  }

  Future<List<Map<String, dynamic>>> drainPendingQueue() async {
    if (_box == null) return [];
    final queue = _box!.get(_queueKey, defaultValue: <Map<String, dynamic>>[]) as List;
    await _box!.delete(_queueKey);
    return queue.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> markSynced(String messageId) async {
    if (_box == null) return;
    final value = _box!.get(messageId);
    if (value is Map) {
      final updated = Map<String, dynamic>.from(value);
      updated['synced'] = true;
      await _box!.put(messageId, updated);
    }
  }

  Future<void> clearChannel(String channelId) async {
    if (_box == null) return;
    final keysToDelete = <String>[];
    for (final key in _box!.keys) {
      if (key == _queueKey) continue;
      final value = _box!.get(key);
      if (value is Map && value['channel_id'] == channelId) {
        keysToDelete.add(key.toString());
      }
    }
    for (final key in keysToDelete) {
      await _box!.delete(key);
    }
  }

  Future<Map<String, dynamic>?> getConversationSettings(String channelId) async {
    if (_box == null) return null;
    final key = '__settings__$channelId';
    final value = _box!.get(key);
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  Future<void> saveConversationSettings(String channelId, Map<String, dynamic> settings) async {
    if (_box == null) return;
    final key = '__settings__$channelId';
    await _box!.put(key, settings);
  }

  Future<void> deleteConversation(String channelId) async {
    if (_box == null) return;
    final keysToDelete = <String>[];
    for (final key in _box!.keys) {
      if (key == _queueKey) continue;
      final value = _box!.get(key);
      if (value is Map && value['channel_id'] == channelId) {
        keysToDelete.add(key.toString());
      }
    }
    for (final key in keysToDelete) {
      await _box!.delete(key);
    }
    await _box!.delete('__settings__$channelId');
  }
}
