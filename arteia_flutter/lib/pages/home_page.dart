import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../services/quests_service.dart';
import '../services/cache_service.dart';
import '../services/local_image_cache_service.dart';
import '../services/interactivity_service.dart';
import '../services/pagination_service.dart';
import '../widgets/music_player_widget.dart';
import 'post_detail_page.dart';

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
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.black,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  // Hero card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bienvenue sur', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        const SizedBox(height: 4),
                        const Text('Artéïa', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('La communauté artistique', style: TextStyle(fontSize: 13, color: Colors.grey[300])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Catégories
                  if (_categories.isNotEmpty) ...[
                    const Text('Univers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final color = Color(int.parse(cat['color'].replaceFirst('#', '0xFF')));
                          return GestureDetector(
                            onTap: () {
                              // TODO: Navigate to universe page
                            },
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(cat['icon'], style: const TextStyle(fontSize: 24)),
                                  const SizedBox(height: 4),
                                  Text(cat['name'], style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Posts récents
                  if (_posts.isNotEmpty) ...[
                    const Text('Publications récentes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                            final post = _posts[index];
                            return _PostCard(
                              postData: post,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PostDetailPage(post: post),
                                  ),
                                );
                                // Refresh liked status when returning
                                await _checkLikedPosts();
                              },
                            );
                      },
                    ),
                  ],
                  
                  // Player musical (si un post musique est présent)
                  if (_posts.any((post) => post['type'] == 'music')) ...[
                    const SizedBox(height: 20),
                    const Text('En écoute', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 12),
                    MusicPlayerWidget(
                      audioUrl: '',
                      title: 'Titre exemple',
                      artist: 'Artiste',
                      coverUrl: null,
                    ),
                  ],
                ],
              ),
            ),
            if (_isOffline)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Mode hors-ligne - Données en cache',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.isNotEmpty && _imageCache != null)
              FutureBuilder<Uint8List?>(
                future: _imageCache!.getImage(imageUrl),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    // Display cached image
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.memory(
                        snapshot.data!,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    );
                  }
                  // Fallback to network image
                  return ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        );
                      },
                      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                        // Cache the image when loaded
                        if (frame != null && wasSynchronouslyLoaded == false) {
                          // We can't easily get bytes from network image here
                          // This is handled by a separate cache mechanism
                        }
                        return child;
                      },
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        postData['profiles']?['avatar_url'] ?? '👤',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          postData['title'] ?? 'Sans titre',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          postData['profiles']?['username'] ?? 'Anonyme',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                        color: isLiked ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
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
                              fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
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

  @override
  void dispose() {
    _scrollController.dispose();
    _postsController?.dispose();
    super.dispose();
  }
}