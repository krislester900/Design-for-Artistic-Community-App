import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../pages/inbox_page.dart';
import '../pages/settings_page.dart';
import '../pages/notifications_page_enhanced.dart';
import '../pages/favorites_page.dart';
import '../pages/quests_page.dart';
import '../pages/theme_customizer_page.dart';
import '../pages/music_page.dart';
import '../pages/universe_page.dart';
import '../pages/artwork_upload_page.dart';
import '../pages/music_upload_page.dart';
import '../pages/writing_page.dart';
import '../pages/comics_upload_page.dart';
import '../pages/auth_page.dart';
import '../pages/ai_assistant_page.dart';
import 'arteia_logo.dart';

class AppDrawer extends StatelessWidget {
  final Function(int) onTabSelected;
  final VoidCallback onClose;

  const AppDrawer({
    super.key,
    required this.onTabSelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.3)),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildMenuItems(context, appState)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          const ArteiaLogo(
            size: 36,
            showText: false,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Artéïa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              Text('Communauté artistique', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context, AppState appState) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _drawerItem(Icons.home, 'Accueil', () => _selectTab(context, 0)),
        _drawerItem(Icons.compass_calibration_outlined, 'Explorer', () => _selectTab(context, 1)),
        _drawerItem(Icons.search, 'Rechercher', () => _selectTab(context, 2)),
        _drawerItem(Icons.message_outlined, 'Communauté', () => _selectTab(context, 3), badge: appState.unreadMessages),
        _drawerItem(Icons.person_outline, 'Profil', () => _selectTab(context, 4)),
        _drawerItem(Icons.inbox, 'Messages', () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const InboxPage()));
          onClose();
        }, badge: appState.unreadMessages),
        _drawerItem(Icons.add_circle_outline, 'Publier', () {
          _showUploadDialog(context);
          onClose();
        }),
        _drawerItem(Icons.auto_awesome, 'Arteïa Muse ✨', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AiAssistantPage()));
        }),
        const Divider(),
        _drawerItem(Icons.notifications_outlined, 'Notifications', () {
          appState.resetNotifications();
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPageEnhanced()));
        }, badge: appState.unreadNotifications),
        _drawerItem(Icons.favorite_border, 'Favoris', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
        }, badge: appState.favoritesCount),
        _drawerItem(Icons.bookmark_border, 'Enregistrés', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()));
        }),
        _drawerItem(Icons.emoji_events, 'Quêtes', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestsPage()));
        }),
        _drawerItem(Icons.settings, 'Paramètres', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
        }),
        _drawerItem(Icons.trending_up, 'Tendances', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UniversePage()));
        }),
        const Divider(),
        _drawerItem(Icons.music_note, 'Musique', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPage()));
        }),
        _drawerItem(Icons.palette_outlined, 'Art Visuel', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UniversePage()));
        }),
        _drawerItem(Icons.menu_book, 'Manga', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UniversePage()));
        }),
        _drawerItem(Icons.movie_outlined, 'Films', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UniversePage()));
        }),
        const Divider(),
        _drawerItem(Icons.login, 'Connexion / Inscription', () {
          onClose();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthPage()));
        }),
      ],
    );
  }

  void _selectTab(BuildContext context, int index) {
    onTabSelected(index);
    onClose();
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle publication', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xFF7C5CFC)),
              title: const Text('Œuvre visuelle'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ArtworkUploadPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_note, color: Color(0xFF00D4AA)),
              title: const Text('Musique'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicUploadPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFFFF6B9D)),
              title: const Text('Écriture'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WritingPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.orange),
              title: const Text('BD / Manga'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ComicsUploadPage()));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {int badge = 0}) {
    final hasBadge = badge > 0;
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[400]),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: hasBadge
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C5CFC).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$badge', style: const TextStyle(fontSize: 10, color: Color(0xFF7C5CFC), fontWeight: FontWeight.bold)),
            )
          : const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}