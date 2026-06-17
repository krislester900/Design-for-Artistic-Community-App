import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/loading_screen.dart';
import 'pages/home_page.dart';
import 'pages/explore_page.dart';
import 'pages/search_page.dart';
import 'pages/community_page.dart';
import 'pages/profile_page.dart';
import 'pages/universe_page.dart';
import 'pages/notifications_page.dart';
import 'pages/music_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const ArteiaApp());
}

class ArteiaApp extends StatelessWidget {
  const ArteiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Artéïa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.arteiaTheme,
      home: const LoadingScreenWrapper(),
    );
  }
}

class LoadingScreenWrapper extends StatefulWidget {
  const LoadingScreenWrapper({super.key});

  @override
  State<LoadingScreenWrapper> createState() => _LoadingScreenWrapperState();
}

class _LoadingScreenWrapperState extends State<LoadingScreenWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Timeout de sécurité : 5 secondes max
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingScreen(
        onComplete: () {
          if (mounted) setState(() => _isLoading = false);
        },
      );
    }
    return const MainScreen();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isDrawerOpen = false;

  final List<Widget> _pages = [
    const HomePage(),
    const ExplorePage(),
    const SearchPage(),
    const CommunityPage(),
    const ProfilePage(),
  ];

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  void openUniverse(String slug) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UniversePage(slug: slug)),
    );
  }

  void openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16, right: 16, bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isDrawerOpen = !_isDrawerOpen),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.menu, size: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C5CFC), Color(0xFF00D4AA)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C5CFC).withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text('Artéïa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.dark_mode, size: 18),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ['Accueil', 'Univers', 'Rechercher', 'Communauté', 'Profil'][_currentIndex],
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 3,
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _pages,
                ),
              ),
            ],
          ),
          if (_isDrawerOpen)
            GestureDetector(
              onTap: () => setState(() => _isDrawerOpen = false),
              child: Container(color: Colors.black54),
            ),
          if (_isDrawerOpen)
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: _buildDrawer(context),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 4,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.95),
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: switchTab,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF7C5CFC),
          unselectedItemColor: Colors.grey.withOpacity(0.5),
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined, size: 22), activeIcon: Icon(Icons.home, size: 22), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.compass_calibration_outlined, size: 22), activeIcon: Icon(Icons.compass_calibration, size: 22), label: 'Univers'),
            BottomNavigationBarItem(icon: Icon(Icons.search, size: 22), activeIcon: Icon(Icons.search, size: 22), label: 'Rechercher'),
            BottomNavigationBarItem(icon: Icon(Icons.message_outlined, size: 22), activeIcon: Icon(Icons.message, size: 22), label: 'Communauté'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline, size: 22), activeIcon: Icon(Icons.person, size: 22), label: 'Profil'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C5CFC), Color(0xFF00D4AA)]),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: const Color(0xFF7C5CFC).withOpacity(0.3), blurRadius: 12)],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Artéïa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Communauté artistique', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.home, 'Accueil', () { switchTab(0); setState(() => _isDrawerOpen = false); }),
                _drawerItem(Icons.compass_calibration_outlined, 'Explorer', () { switchTab(1); setState(() => _isDrawerOpen = false); }),
                _drawerItem(Icons.search, 'Rechercher', () { switchTab(2); setState(() => _isDrawerOpen = false); }),
                _drawerItem(Icons.message_outlined, 'Communauté', () { switchTab(3); setState(() => _isDrawerOpen = false); }, badge: 3),
                _drawerItem(Icons.person_outline, 'Profil', () { switchTab(4); setState(() => _isDrawerOpen = false); }),
                const Divider(),
                _drawerItem(Icons.notifications_outlined, 'Notifications', () { setState(() => _isDrawerOpen = false); openNotifications(); }, badge: 5),
                _drawerItem(Icons.favorite_border, 'Favoris', () {}, badge: 24),
                _drawerItem(Icons.bookmark_border, 'Enregistrés', () {}, badge: 8),
                _drawerItem(Icons.trending_up, 'Tendances', () {}),
                const Divider(),
                _drawerItem(Icons.music_note, 'Musique', () { Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicPage())); setState(() => _isDrawerOpen = false); }),
                _drawerItem(Icons.palette_outlined, 'Art Visuel', () { openUniverse('visual-art'); setState(() => _isDrawerOpen = false); }),
                _drawerItem(Icons.menu_book, 'Manga', () { openUniverse('manga'); setState(() => _isDrawerOpen = false); }),
                _drawerItem(Icons.movie_outlined, 'Films', () { openUniverse('film'); setState(() => _isDrawerOpen = false); }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {int? badge}) {
    return ListTile(
      leading: Icon(icon, size: 20, color: Colors.grey[400]),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: badge != null
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