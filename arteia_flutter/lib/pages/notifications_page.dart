import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // TODO: Récupérer l'ID de l'utilisateur connecté
    final userId = 'current-user-id';
    try {
      final notifs = await _api.getNotifications(userId);
      if (mounted) {
        setState(() {
          _notifications = notifs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _notifications.isEmpty
              ? const Center(child: Text('Aucune notification', style: TextStyle(color: Colors.black)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    return _NotificationCard(notification: notif);
                  },
                ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  const _NotificationCard({required this.notification});

  IconData _getIcon(String type) {
    switch (type) {
      case 'like': return Icons.favorite;
      case 'comment': return Icons.comment;
      case 'follow': return Icons.person_add;
      case 'mention': return Icons.alternate_email;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRead = notification['read'] ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isRead ? Colors.grey[300]! : Colors.black, width: isRead ? 1 : 2),
      ),
      child: Row(
        children: [
          Icon(_getIcon(notification['type'] ?? 'notification'), size: 24, color: Colors.black),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              notification['message'] ?? 'Nouvelle notification',
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
          if (!isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}