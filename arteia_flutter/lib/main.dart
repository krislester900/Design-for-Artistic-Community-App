import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;
import 'package:hive_flutter/hive_flutter.dart';
import 'utils/app_constants.dart';
import 'services/supabase_service.dart';
import 'services/theme_service.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/loading_screen.dart';
import 'widgets/app_drawer.dart';
import 'widgets/error_boundary.dart';
import 'pages/home_page.dart';
import 'pages/explore_page.dart';
import 'pages/search_page.dart';
import 'pages/profile_page.dart';
import 'pages/universe_page.dart';
import 'pages/notifications_page_enhanced.dart';
import 'pages/auth_page.dart';
import 'pages/chat_page.dart';
import 'pages/favorites_page.dart';
import 'pages/artwork_upload_page.dart';
import 'pages/music_upload_page.dart';
import 'pages/writing_page.dart';
import 'pages/comics_upload_page.dart';
import 'pages/quests_page.dart';
import 'widgets/page_transition.dart';
import 'widgets/arteia_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local cache (skip on web)
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    try {
      await Hive.initFlutter();
      await Hive.openBox('arteia_cache');
    } catch (e) {
      debugPrint('Hive initialization skipped: $e');
    }
  }
  
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    publishableKey: SupabaseConfig.supabaseAnonKey,
  );
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
    final themeService = ThemeService();
    return MaterialApp(
      title: 'Artéïa',
      debugShowCheckedModeBanner: false,
      theme: themeService.theme,
      darkTheme: AppTheme.arteiaDarkTheme,
      themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const ErrorBoundary(
        child: LoadingScreenWrapper(),
      ),
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
    _checkInitialization();
    _startRealtimeNotifications();
  }
  
  void _startRealtimeNotifications() {
    final appState = AppState();
    appState.startListening();
  }

  Future<void> _checkInitialization() async {
    // Wait minimum duration for smooth UX
    await Future.delayed(AppConstants.loadingScreenMinDuration);
    
    if (!mounted) return;
    
    // Check if Supabase is ready
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null || !_isLoading) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      // If error, still proceed after delay
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    const ChatPage(),
    const ProfilePage(),
  ];

  void switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  void openUniverse(String slug) {
    final animationAsset = PageTransitionConfig.getAnimationFor(slug);
    if (animationAsset != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => PageTransitionOverlay(
          riveAsset: animationAsset,
          onComplete: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UniversePage()),
            );
          },
          durationInSeconds: 1.8,
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UniversePage()),
      );
    }
  }

  void openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsPageEnhanced()),
    );
  }

  void openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FavoritesPage()),
    );
  }

  void openQuests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuestsPage()),
    );
  }

  void openUpload() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardDark,
        title: const Text('Nouvelle publication', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryViolet.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.image, color: AppTheme.primaryViolet),
              ),
              title: const Text('Œuvre visuelle', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ArtworkUploadPage()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.music_note, color: AppTheme.primaryTeal),
              ),
              title: const Text('Musique', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MusicUploadPage()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryPink.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit, color: AppTheme.primaryPink),
              ),
              title: const Text('Écriture', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const WritingPage()));
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.orange),
              ),
              title: const Text('BD / Manga', style: TextStyle(color: Colors.white)),
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

  void openAuth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthPage()),
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
                    const ArteiaLogo(
                      size: 32,
                      showText: false,
                    ),
                    const SizedBox(width: 10),
                    Text('Artéïa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      onPressed: openUpload,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Publier une œuvre',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ['Accueil', 'Univers', 'Rechercher', 'Discussions', 'Profil'][_currentIndex],
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
              child: AppDrawer(
                onTabSelected: switchTab,
                onClose: () => setState(() => _isDrawerOpen = false),
              ),
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

}