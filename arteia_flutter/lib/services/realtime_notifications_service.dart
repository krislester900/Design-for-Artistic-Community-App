import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class RealtimeNotificationsService {
  final SupabaseService _supabase = SupabaseService();
  final List<StreamSubscription> _subscriptions = [];
  
  StreamController<Map<String, dynamic>>? _notificationController;
  StreamController<int>? _unreadCountController;

  SupabaseClient get _client => _supabase.client;

  /// Get notifications stream
  Stream<Map<String, dynamic>> get notificationStream {
    _notificationController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _notificationController!.stream;
  }

  /// Get unread count stream
  Stream<int> get unreadCountStream {
    _unreadCountController ??= StreamController<int>.broadcast();
    return _unreadCountController!.stream;
  }

  /// Start listening to real-time notifications
  void startListening() {
    final user = _supabase.currentUser;
    if (user == null) return;

    // Listen for new notifications
    final notificationSub = _client
        .channel('public:notifications')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            final newNotification = payload.newRecord as Map<String, dynamic>;
            _notificationController?.add(newNotification);
            _updateUnreadCount();
          },
        ).subscribe();

    _subscriptions.add(notificationSub as StreamSubscription);

    // Listen for follow changes
    final followSub = _client
        .channel('public:follows')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'follows',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'following_id',
            value: user.id,
          ),
          callback: (payload) {
            final newFollow = payload.newRecord as Map<String, dynamic>;
            _notificationController?.add({
              'type': 'follow',
              'from_user_id': newFollow['follower_id'],
              'message': 'a commencé à vous suivre',
              'created_at': DateTime.now().toIso8601String(),
              'read': false,
            });
            _updateUnreadCount();
          },
        ).subscribe();

    _subscriptions.add(followSub as StreamSubscription);

    // Listen for likes
    final likeSub = _client
        .channel('public:likes')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'likes',
          callback: (payload) async {
            final newLike = payload.newRecord as Map<String, dynamic>;
            // Get post owner to notify
            final postResponse = await _client
                .from('posts')
                .select('user_id, title')
                .eq('id', newLike['post_id'])
                .maybeSingle();

            if (postResponse != null && postResponse['user_id'] == user.id) {
              _notificationController?.add({
                'type': 'like',
                'from_user_id': newLike['user_id'],
                'post_id': newLike['post_id'],
                'message': 'a aimé votre publication "${postResponse['title'] ?? ''}"',
                'created_at': DateTime.now().toIso8601String(),
                'read': false,
              });
              _updateUnreadCount();
            }
          },
        ).subscribe();

    _subscriptions.add(likeSub as StreamSubscription);
  }

  /// Stop listening to real-time notifications
  void stopListening() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _notificationController?.close();
    _unreadCountController?.close();
    _notificationController = null;
    _unreadCountController = null;
  }

  /// Update unread count
  Future<void> _updateUnreadCount() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('read', false);

      _unreadCountController?.add((response as List).length);
    } catch (e) {
      print('🔴 Unread count error: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('user_id', user.id)
          .eq('read', false);
      
      _unreadCountController?.add(0);
    } catch (e) {
      print('🔴 markAllAsRead error: $e');
    }
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
      
      _updateUnreadCount();
    } catch (e) {
      print('🔴 markAsRead error: $e');
    }
  }

  /// Get initial unread count
  Future<int> getInitialUnreadCount() async {
    final user = _supabase.currentUser;
    if (user == null) return 0;

    try {
      final response = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('read', false);

      return (response as List).length;
    } catch (e) {
      print('🔴 Initial unread count error: $e');
      return 0;
    }
  }
}