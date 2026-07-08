import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class PushNotificationsService {
  final SupabaseService _supabase = SupabaseService();

  static final PushNotificationsService _instance = PushNotificationsService._();
  factory PushNotificationsService() => _instance;
  PushNotificationsService._();

  Future<void> initialize() async {}

  Future<void> _updateTokenInDatabase(String token) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      await _supabase.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
    } catch (_) {}
  }

  Future<void> subscribeToTopic(String topic) async {}

  Future<void> unsubscribeFromTopic(String topic) async {}

  Future<String?> getToken() async => null;

  Future<bool> areNotificationsEnabled() async => false;

  Future<bool> requestPermission() async => false;

  Future<void> openSettings() async {}

  void dispose() {}
}
