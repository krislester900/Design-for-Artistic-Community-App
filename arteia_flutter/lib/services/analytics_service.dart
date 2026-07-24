import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AnalyticsService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  // Event types
  static const String EVENT_APP_OPEN = 'app_open';
  static const String EVENT_POST_VIEW = 'post_view';
  static const String EVENT_POST_LIKE = 'post_like';
  static const String EVENT_POST_UNLIKE = 'post_unlike';
  static const String EVENT_POST_COMMENT = 'post_comment';
  static const String EVENT_POST_SHARE = 'post_share';
  static const String EVENT_POST_UPLOAD = 'post_upload';
  static const String EVENT_USER_FOLLOW = 'user_follow';
  static const String EVENT_USER_UNFOLLOW = 'user_unfollow';
  static const String EVENT_SEARCH = 'search';
  static const String EVENT_NOTIFICATION_OPEN = 'notification_open';
  static const String EVENT_SETTINGS_OPEN = 'settings_open';
  static const String EVENT_AI_ASSISTANT_USE = 'ai_assistant_use';

  // Buffer for batching events
  final List<Map<String, dynamic>> _eventBuffer = [];
  Timer? _flushTimer;
  static const int _batchSize = 10;
  static const Duration _flushInterval = Duration(seconds: 30);

  /// Initialiser le service d'analytics
  Future<void> initialize() async {
    // Flush timer
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushEvents());
    
    // Track app open
    await trackEvent(EVENT_APP_OPEN, {'timestamp': DateTime.now().toIso8601String()});
  }

  /// Tracker un événement
  Future<void> trackEvent(String eventName, Map<String, dynamic>? parameters) async {
    final user = _supabase.currentUser;
    
    final event = {
      'event_name': eventName,
      'user_id': user?.id ?? 'anonymous',
      'parameters': parameters ?? {},
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'flutter',
      'app_version': '1.0.0',
    };

    _eventBuffer.add(event);

    // Flush if batch size reached
    if (_eventBuffer.length >= _batchSize) {
      await _flushEvents();
    }
  }

  /// Envoyer les événements en batch
  Future<void> _flushEvents() async {
    if (_eventBuffer.isEmpty) return;

    final eventsToSend = List<Map<String, dynamic>>.from(_eventBuffer);
    _eventBuffer.clear();

    try {
      await _client.from('analytics_events').insert(eventsToSend);
    } catch (_) {
      _eventBuffer.addAll(eventsToSend);
    }
  }

  // ==================== SPECIFIC TRACKERS ====================

  /// Tracker la vue d'un post
  Future<void> trackPostView(String postId, Map<String, dynamic> postData) async {
    await trackEvent(EVENT_POST_VIEW, {
      'post_id': postId,
      'post_type': postData['type'] ?? 'unknown',
      'category': postData['categories']?['title'] ?? 'unknown',
    });
  }

  /// Tracker un like
  Future<void> trackPostLike(String postId) async {
    await trackEvent(EVENT_POST_LIKE, {'post_id': postId});
  }

  /// Tracker un unlike
  Future<void> trackPostUnlike(String postId) async {
    await trackEvent(EVENT_POST_UNLIKE, {'post_id': postId});
  }

  /// Tracker un commentaire
  Future<void> trackPostComment(String postId, String commentLength) async {
    await trackEvent(EVENT_POST_COMMENT, {
      'post_id': postId,
      'comment_length': commentLength,
    });
  }

  /// Tracker un partage
  Future<void> trackPostShare(String postId, String shareMethod) async {
    await trackEvent(EVENT_POST_SHARE, {
      'post_id': postId,
      'share_method': shareMethod, // 'native', 'clipboard', 'social'
    });
  }

  /// Tracker un upload de post
  Future<void> trackPostUpload(String postType, int fileSizeMB) async {
    await trackEvent(EVENT_POST_UPLOAD, {
      'post_type': postType,
      'file_size_mb': fileSizeMB,
    });
  }

  /// Tracker un follow
  Future<void> trackUserFollow(String followedUserId) async {
    await trackEvent(EVENT_USER_FOLLOW, {'followed_user_id': followedUserId});
  }

  /// Tracker un unfollow
  Future<void> trackUserUnfollow(String unfollowedUserId) async {
    await trackEvent(EVENT_USER_UNFOLLOW, {'unfollowed_user_id': unfollowedUserId});
  }

  /// Tracker une recherche
  Future<void> trackSearch(String query, int resultsCount) async {
    await trackEvent(EVENT_SEARCH, {
      'query': query,
      'results_count': resultsCount,
    });
  }

  /// Tracker l'ouverture d'une notification
  Future<void> trackNotificationOpen(String notificationType, String? postId) async {
    await trackEvent(EVENT_NOTIFICATION_OPEN, {
      'notification_type': notificationType,
      'post_id': postId,
    });
  }

  /// Tracker l'ouverture des paramètres
  Future<void> trackSettingsOpen(String settingsTab) async {
    await trackEvent(EVENT_SETTINGS_OPEN, {'settings_tab': settingsTab});
  }

  /// Tracker l'utilisation de l'IA assistant
  Future<void> trackAIAssistantUse(String queryType, int responseLength) async {
    await trackEvent(EVENT_AI_ASSISTANT_USE, {
      'query_type': queryType,
      'response_length': responseLength,
    });
  }

  // ==================== ANALYTICS DATA ====================

  /// Obtenir les statistiques d'un utilisateur
  Future<Map<String, dynamic>> getUserAnalytics(String userId) async {
    try {
      final views = await _client
          .from('analytics_events')
          .select()
          .filter('user_id', 'eq', userId)
          .filter('event_name', 'eq', 'post_view');
      
      final likes = await _client
          .from('analytics_events')
          .select()
          .filter('user_id', 'eq', userId)
          .filter('event_name', 'eq', 'post_like');
      
      final comments = await _client
          .from('analytics_events')
          .select()
          .filter('user_id', 'eq', userId)
          .filter('event_name', 'eq', 'post_comment');

      return {
        'totalViews': (views as List).length,
        'totalLikes': (likes as List).length,
        'totalComments': (comments as List).length,
        'engagementRate': 0.0,
        'viewsByDay': <String, int>{},
        'viewsByCountry': <String, int>{},
      };
    } catch (e) {
      return {
        'totalViews': 0,
        'totalLikes': 0,
        'totalComments': 0,
        'engagementRate': 0.0,
        'viewsByDay': <String, int>{},
        'viewsByCountry': <String, int>{},
      };
    }
  }

  // ==================== USER PROPERTIES ====================

  /// Mettre à jour les propriétés utilisateur
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      await _client.from('analytics_user_properties').upsert({
        'user_id': user.id,
        'properties': properties,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('🔴 Error setting user properties: $e');
    }
  }

  /// Mettre à jour le nombre de posts de l'utilisateur
  Future<void> updateUserPostCount(int postCount) async {
    await setUserProperties({'total_posts': postCount});
  }

  /// Mettre à jour le nombre de likes de l'utilisateur
  Future<void> updateUserLikeCount(int likeCount) async {
    await setUserProperties({'total_likes': likeCount});
  }

  /// Mettre à jour le nombre de followers
  Future<void> updateUserFollowersCount(int followersCount) async {
    await setUserProperties({'followers_count': followersCount});
  }

  // ==================== PERFORMANCE ====================

  /// Tracker le temps de chargement
  Future<void> trackLoadTime(String screenName, int milliseconds) async {
    await trackEvent('load_time', {
      'screen_name': screenName,
      'load_time_ms': milliseconds,
    });
  }

  /// Tracker une erreur
  Future<void> trackError(String errorType, String errorMessage, Map<String, dynamic>? context) async {
    await trackEvent('error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'context': context ?? {},
    });
  }

  // ==================== CLEANUP ====================

  /// Nettoyer les ressources
  void dispose() {
    _flushTimer?.cancel();
    _flushEvents();
  }
}