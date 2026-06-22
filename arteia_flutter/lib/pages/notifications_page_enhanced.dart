import 'dart:async';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notifications_service.dart';
import '../services/realtime_notifications_service.dart';
import '../theme/app_theme.dart';

class NotificationsPageEnhanced extends StatefulWidget {
  const NotificationsPageEnhanced({super.key});

  @override
  State<NotificationsPageEnhanced> createState() => _NotificationsPageEnhancedState();
}

class _NotificationsPageEnhancedState extends State<NotificationsPageEnhanced> {
  final SupabaseService _supabase = SupabaseService();
  final NotificationsService _notificationsService = NotificationsService();
  final RealtimeNotificationsService _realtimeService = RealtimeNotificationsService();

  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  StreamSubscription? _notificationSub;
  StreamSubscription? _unreadSub;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _setupRealtime();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final user = _supabase.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final notificationsList = await _notificationsService.getNotifications();
      final unreadCount = await _realtimeService.getInitialUnreadCount();

      if (mounted) {
        setState(() {
          _notifications = notificationsList;
          _unreadCount = unreadCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setupRealtime() {
    _realtimeService.startListening();

    _notificationSub = _realtimeService.notificationStream.listen((notification) {
      if (mounted) {
        setState(() {
          _notifications.insert(0, notification);
          _unreadCount++;
        });
      }
    });

    _unreadSub = _realtimeService.unreadCountStream.listen((count) {
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    });
  }

  Future<void> _markAllAsRead() async {
    await _realtimeService.markAllAsRead();
    setState(() {
      _unreadCount = 0;
      for (var notif in _notifications) {
        notif['read'] = true;
      }
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les notifications marquées comme lues'), backgroundColor: Colors.green),
      );
    }
  }

  Future<void> _markAsRead(String notificationId, int index) async {
    await _realtimeService.markAsRead(notificationId);
    setState(() {
      _notifications[index]['read'] = true;
      _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
    });
  }

  String _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return '❤️';
      case 'comment':
        return '💬';
      case 'follow':
        return '👤';
      case 'favorite':
        return '⭐';
      case 'mention':
        return '@';
      default:
        return '🔔';
    }
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return '';
    try {
      final date = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 1) return 'À l\'instant';
      if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
      if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
      return 'Il y a ${diff.inDays ~/ 7}sem';
    } catch (e) {
      return createdAt;
    }
  }

  @override
  void dispose() {
    _notificationSub?.cancel();
    _unreadSub?.cancel();
    _realtimeService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.cardDark,
        title: Row(
          children: [
            const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_unreadCount',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text('Tout lire', style: TextStyle(color: AppTheme.primaryViolet, fontSize: 13)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
          : _supabase.currentUser == null
              ? _buildLoginPrompt()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 80, color: Colors.grey[600]),
            const SizedBox(height: 16),
            const Text('Connectez-vous', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Pour voir vos notifications en temps réel',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryViolet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(Icons.notifications_none, size: 64, color: AppTheme.primaryViolet),
            ),
            const SizedBox(height: 20),
            const Text('Aucune notification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text(
              'Vous recevrez des notifications quand quelqu\'un\nlike, commente ou vous suit',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList() {
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: AppTheme.primaryViolet,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notif = _notifications[index];
          final isUnread = notif['read'] != true;
          return _NotificationTile(
            icon: _getNotificationIcon(notif['type'] ?? ''),
            message: notif['message'] ?? '',
            time: _getTimeAgo(notif['created_at']),
            isUnread: isUnread,
            onTap: isUnread ? () => _markAsRead(notif['id'], index) : null,
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String icon;
  final String message;
  final String time;
  final bool isUnread;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.icon,
    required this.message,
    required this.time,
    required this.isUnread,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread ? AppTheme.primaryViolet.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(color: AppTheme.primaryViolet.withOpacity(0.2))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isUnread 
                    ? AppTheme.primaryViolet.withOpacity(0.2)
                    : AppTheme.cardDarkLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnread ? Colors.white : Colors.grey[400],
                            fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryPink,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}