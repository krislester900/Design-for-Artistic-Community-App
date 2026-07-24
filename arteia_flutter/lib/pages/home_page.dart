import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../services/quests_service.dart';
import '../services/cache_service.dart';
import '../services/local_image_cache_service.dart';
import '../services/interactivity_service.dart';
import '../services/pagination_service.dart';
import '../services/chat_service.dart';
import '../widgets/music_player_widget.dart';
import 'post_detail_page.dart';
import 'games_hub_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _api = ApiService();
  final SupabaseService _supabase = SupabaseService();
  final QuestsService _questsService = QuestsService();
  final InteractivityService _interactivity = InteractivityService();
  LocalImageCacheService? _imageCache;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  final Set<String> _likedPostIds = {};
  bool _isOffline = false;
  PaginatedController<Map<String, dynamic>>? _postsController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initServices();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initServices() async {
    _imageCache = await LocalImageCacheService.getInstance();
    _postsController = PaginatedController<Map<String, dynamic>>(
      (page, pageSize) => _fetchPostsPage(page, pageSize),
    );
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) return;
    if (await Permission.contacts.isDenied) {
      await Permission.contacts.request();
    }
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<PaginatedResponse<Map<String, dynamic>>> _fetchPostsPage(int page, int pageSize) async {
    try {
      final allPosts = await _api.getPosts();
      final totalCount = allPosts.length;
      final start = page * pageSize;
      final end = start + pageSize;
      final paginatedItems = allPosts.sublist(start, end > totalCount ? totalCount : end);
      final hasMore = end < totalCount;
      
      return (
        items: paginatedItems,
        hasMore: hasMore,
        nextPage: hasMore ? page + 1 : null,
        totalCount: totalCount,
      );
    } catch (e) {
      return (items: <Map<String, dynamic>>[], hasMore: false, nextPage: null, totalCount: 0);
    }
  }

  Future<void> _checkLikedPosts() async {
    final user = _supabase.currentUser;
    if (user == null) return;
    for (final post in _posts) {
      final postId = post['id'];
      if (postId == null) continue;
      final liked = await _api.isPostLiked(postId, user.id);
      if (liked && mounted) {
        setState(() {
          _likedPostIds.add(postId);
        });
      }
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Try to load from cache first for instant display
      final cacheService = await CacheService.getInstance();
      final cachedPosts = cacheService.getCachedPosts();
      final cachedCategories = cacheService.getCachedCategories();

      if (cachedPosts != null && mounted) {
        setState(() {
          _posts = cachedPosts;
          _isLoading = false;
          _isOffline = false;
        });
      }

      if (cachedCategories != null && mounted) {
        setState(() {
          _categories = cachedCategories;
        });
      }

      // Then try to fetch fresh data with pagination
      try {
        final results = await Future.wait([
          _api.getCategories(),
          _postsController?.loadInitial() ?? Future.value(),
        ]);

        if (mounted && _postsController != null) {
          setState(() {
            _categories = results[0];
            _posts = _postsController!.items.toList();
            _isLoading = false;
            _isOffline = false;
          });
        }

        // Update cache with fresh data
        final cacheService = await CacheService.getInstance();
        await cacheService.cachePosts(_posts);
        await cacheService.cacheCategories(_categories);
        await cacheService.setLastSync();
      } catch (e) {
        // If network fails but we have cache, stay offline
        if (cachedPosts == null && mounted) {
          setState(() => _isLoading = false);
        }
        if (mounted) {
          setState(() => _isOffline = true);
        }
      }

      // Check liked status after posts load
      await _checkLikedPosts();

      if (_supabase.currentUser != null) {
        await ChatService().scanContactsAndFindAppUsers();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _postsController?.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Colors.black),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.black,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              // Header dynamique
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade400, Colors.purple.shade400, Colors.blue.shade400],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, color: Colors.grey[600], size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _supabase.currentUser?.email?.split('@').first ?? 'Artiste',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.black, letterSpacing: 0.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Que vas-tu créer aujourd\'hui ?',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          // TODO: notifications
                        },
                        icon: const Icon(Icons.notifications_none_rounded, color: Colors.black, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Stories
              if (_categories.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          width: 76,
                          margin: const EdgeInsets.only(right: 14),
                          child: Column(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.add_rounded, color: Colors.grey[600], size: 28),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Votre story',
                                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      final cat = _categories[index - 1];
                      final color = Color(int.parse(cat['color'].replaceFirst('#', '0xFF')));
                      return Container(
                        width: 76,
                        margin: const EdgeInsets.only(right: 14),
                        child: Column(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [color.withValues(alpha: 0.8), color],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Center(
                                child: Text(cat['icon'] ?? '', style: const TextStyle(fontSize: 28)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat['name'] ?? '',
                              style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              if (_posts.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Publications récentes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                ),
              if (_posts.isNotEmpty) ...[
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 400 + index * 60),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _PostCard(
                        postData: post,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailPage(post: post),
                            ),
                          );
                          await _checkLikedPosts();
                        },
                      ),
                    );
                  },
                ),
              ],
              if (_posts.isEmpty && !_isLoading)
                _EngagingEmptyState(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Aucune publication pour le moment',
                  subtitle: 'Soyez le premier à partager une création !',
                  actionLabel: 'Publier',
                  onAction: () {
                    // TODO: ouvrir création
                  },
                ),
              const SizedBox(height: 20),
              if (_posts.any((post) => post['type'] == 'music'))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('En écoute', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black)),
                      const SizedBox(height: 12),
                      MusicPlayerWidget(
                        audioUrl: '',
                        title: 'Titre exemple',
                        artist: 'Artiste',
                        coverUrl: null,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleLike(String postId) async {
    final user = _supabase.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour liker')),
      );
      return;
    }

    final wasLiked = _likedPostIds.contains(postId);
    final postIndex = _posts.indexWhere((p) => p['id'] == postId);
    if (postIndex == -1) return;

    setState(() {
      if (wasLiked) {
        _likedPostIds.remove(postId);
        _posts[postIndex]['likes_count'] = (_posts[postIndex]['likes_count'] ?? 0) - 1;
      } else {
        _likedPostIds.add(postId);
        _posts[postIndex]['likes_count'] = (_posts[postIndex]['likes_count'] ?? 0) + 1;
      }
    });

    try {
      if (!wasLiked) {
        await _api.likePost(postId, user.id);
        _questsService.updateQuestProgress(QuestType.like, 1);
      } else {
        await _api.unlikePost(postId, user.id);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (wasLiked) {
          _likedPostIds.add(postId);
          _posts[postIndex]['likes_count'] = (_posts[postIndex]['likes_count'] ?? 0) + 1;
        } else {
          _likedPostIds.remove(postId);
          _posts[postIndex]['likes_count'] = (_posts[postIndex]['likes_count'] ?? 0) - 1;
        }
      });
    }
  }

  Widget _PostCard({required Map<String, dynamic> postData, VoidCallback? onTap}) {
    final imageUrl = postData['image_url'] as String?;
    final isLiked = _likedPostIds.contains(postData['id']);
    final likesCount = postData['likes_count'] ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty && _imageCache != null)
              FutureBuilder<Uint8List?>(
                future: _imageCache!.getImage(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return _PostImage(
                      imageBytes: snapshot.data!,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    );
                  }
                  return _PostImageNetwork(
                    imageUrl: imageUrl,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        postData['profiles']?['avatar_url'] ?? '👤',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postData['title'] ?? 'Sans titre',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          postData['profiles']?['username'] ?? 'Anonyme',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  AnimatedButton(
                    onPressed: () {
                      _interactivity.triggerHaptic(HapticFeedbackType.light);
                      _toggleLike(postData['id']);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isLiked ? Colors.red.withValues(alpha: 0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLiked ? Colors.red.withValues(alpha: 0.2) : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isLiked ? Colors.red : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$likesCount',
                            style: TextStyle(
                              fontSize: 12,
                              color: isLiked ? Colors.red : Colors.grey[600],
                              fontWeight: isLiked ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _PostImage({required Uint8List imageBytes, required BorderRadius borderRadius}) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.memory(
        imageBytes,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _PostImageNetwork({required String imageUrl, required BorderRadius borderRadius}) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 200,
            color: Colors.grey[200],
            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _postsController?.dispose();
    super.dispose();
  }
}

class _EngagingEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;

  const _EngagingEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          children: [
            _PulsingIcon(icon: icon),
            const SizedBox(height: 28),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.3),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade500, height: 1.5, letterSpacing: 0.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.96, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: ElevatedButton(
                    onPressed: onAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.25),
                    ),
                    child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.3)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingIcon extends StatefulWidget {
  final IconData icon;
  const _PulsingIcon({required this.icon});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1800), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + 0.08 * (0.5 + 0.5 * _controller.value);
        final shadow = 0.2 + 0.25 * _controller.value;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink.shade100, Colors.purple.shade100],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: shadow),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(widget.icon, size: 40, color: Colors.pink.shade400),
          ),
        );
      },
    );
  }
}