import 'dart:async';
import 'supabase_service.dart';

class PushNotificationsService {
  final SupabaseService _supabase = SupabaseService();

  static final PushNotificationsService _instance = PushNotificationsService._();
  factory PushNotificationsService() => _instance;
  PushNotificationsService._();

  Future<void> initialize() async {}

  Future<void> subscribeToTopic(String topic) async {}

  Future<void> unsubscribeFromTopic(String topic) async {}

  Future<String?> getToken() async => null;

  Future<bool> areNotificationsEnabled() async => false;

  Future<bool> requestPermission() async => false;

  Future<void> openSettings() async {}

  void dispose() {}
}
