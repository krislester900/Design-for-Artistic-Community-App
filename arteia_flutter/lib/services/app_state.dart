import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._();
  factory AppState() => _instance;
  AppState._();

  final SupabaseService _supabase = SupabaseService();

  // Online/offline state
  bool _isOnline = true;
  bool get isOnline => _isOnline;
  set isOnline(bool value) {
    if (_isOnline != value) {
      _isOnline = value;
      notifyListeners();
    }
  }

  // Unread notifications count
  int _unreadNotifications = 0;
  int get unreadNotifications => _unreadNotifications;
  set unreadNotifications(int value) {
    _unreadNotifications = value;
    notifyListeners();
  }

  // Unread messages count
  int _unreadMessages = 0;
  int get unreadMessages => _unreadMessages;
  set unreadMessages(int value) {
    _unreadMessages = value;
    notifyListeners();
  }

  // Favorites count
  int _favoritesCount = 0;
  int get favoritesCount => _favoritesCount;
  set favoritesCount(int value) {
    _favoritesCount = value;
    notifyListeners();
  }

  // Selected tab index
  int _selectedTab = 0;
  int get selectedTab => _selectedTab;
  set selectedTab(int value) {
    _selectedTab = value;
    notifyListeners();
  }

  // Current user ID
  String? get currentUserId => _supabase.currentUser?.id;

  // Listen for real-time updates
  void startListening() {
    try {
      _supabase.client
          .channel('app_state')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            callback: (payload) {
              final newNotification = payload.newRecord;
              if (newNotification['user_id'] == currentUserId) {
                _unreadNotifications++;
                notifyListeners();
              }
            },
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'messages',
            callback: (payload) {
              final newMessage = payload.newRecord;
              if (newMessage['receiver_id'] == currentUserId) {
                _unreadMessages++;
                notifyListeners();
              }
            },
          )
          .subscribe();
    } catch (_) {}
  }

  // Reset counts
  void resetNotifications() {
    _unreadNotifications = 0;
    notifyListeners();
  }

  void resetMessages() {
    _unreadMessages = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    try {
      final client = Supabase.instance.client;
      final channel = client.channel('app_state');
      client.removeChannel(channel);
    } catch (_) {}
    super.dispose();
  }
}

// Extension to easily access AppState
extension AppStateExtension on BuildContext {
  AppState get appState => AppState();
}