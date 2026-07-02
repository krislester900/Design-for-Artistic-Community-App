import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class PushNotificationsService {
  final SupabaseService _supabase = SupabaseService();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  StreamSubscription<RemoteMessage>? _messageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  
  static final PushNotificationsService _instance = PushNotificationsService._();
  factory PushNotificationsService() => _instance;
  PushNotificationsService._();

  /// Initialiser les notifications push
  Future<void> initialize() async {
    // Demander la permission sur iOS
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else {
      print('⚠️ Notification permission denied');
    }

    // Initialiser les notifications locales
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(initSettings);

    // Écouter les messages en foreground
    _messageSubscription = FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Écouter les changements de token
    _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen(_updateTokenInDatabase);

    // Envoyer le token initial
    final token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _updateTokenInDatabase(token);
    }

    // Gérer les messages quand l'app est ouverte depuis le background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  /// Gérer les messages en foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 Message reçu en foreground: ${message.notification?.title}');

    // Afficher une notification locale
    const androidDetails = AndroidNotificationDetails(
      'arteia_channel',
      'Artéïa Notifications',
      channelDescription: 'Notifications pour Artéïa',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.notification.hashCode,
      message.notification?.title ?? 'Artéïa',
      message.notification?.body ?? '',
      notificationDetails,
      payload: message.data['type'],
    );
  }

  /// Gérer l'ouverture de l'app depuis une notification
  Future<void> _handleMessageOpenedApp(RemoteMessage message) async {
    print('📱 App ouverte depuis notification: ${message.data['type']}');
    
    final type = message.data['type'];
    final postId = message.data['post_id'];
    final userId = message.data['user_id'];

    // Naviguer vers la page appropriée
    if (type == 'like' && postId != null) {
      // Naviguer vers le post
      // Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(postId: postId)));
    } else if (type == 'follow' && userId != null) {
      // Naviguer vers le profil
      // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)));
    } else if (type == 'comment' && postId != null) {
      // Naviguer vers le post
      // Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(postId: postId)));
    }
  }

  /// Mettre à jour le token FCM dans la base de données
  Future<void> _updateTokenInDatabase(String token) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      await _supabase.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', user.id);
      print('✅ FCM token updated in database');
    } catch (e) {
      print('🔴 Error updating FCM token: $e');
    }
  }

  /// S'abonner à un topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Subscribed to topic: $topic');
  }

  /// Se désabonner d'un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('✅ Unsubscribed from topic: $topic');
  }

  /// S'abonner aux notifications d'un utilisateur
  Future<void> subscribeToUserNotifications(String userId) async {
    await subscribeToTopic('user_$userId');
  }

  /// Se désabonner des notifications d'un utilisateur
  Future<void> unsubscribeFromUserNotifications(String userId) async {
    await unsubscribeFromTopic('user_$userId');
  }

  /// Obtenir le token FCM actuel
  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Vérifier si les notifications sont autorisées
  Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Demander la permission pour les notifications
  Future<bool> requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Ouvrir les paramètres de notification (iOS)
  Future<void> openSettings() async {
    await _firebaseMessaging.openNotificationSettings();
  }

  /// Nettoyer les ressources
  void dispose() {
    _messageSubscription?.cancel();
    _tokenRefreshSubscription?.cancel();
  }
}