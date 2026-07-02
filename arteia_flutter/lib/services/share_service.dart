import 'package:share_plus/share_plus.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

class ShareService {
  static final ShareService _instance = ShareService._();
  factory ShareService() => _instance;
  ShareService._();

  StreamSubscription? _linkSubscription;

  /// Partager un post
  Future<void> sharePost({
    required String postId,
    required String title,
    String? imageUrl,
    String? authorName,
  }) async {
    final url = _buildDeepLink('post', postId);
    final text = 'Découvre "$title" par $authorName sur Artéïa !\n$url';
    
    await Share.share(
      text,
      subject: title,
    );
  }

  /// Partager un profil
  Future<void> shareProfile(String userId, String username) async {
    final url = _buildDeepLink('profile', userId);
    await Share.share(
      'Découvre le profil de $username sur Artéïa !\n$url',
      subject: 'Profil Artéïa : $username',
    );
  }

  /// Partager une compétition
  Future<void> shareCompetition(String competitionId, String title) async {
    final url = _buildDeepLink('competition', competitionId);
    await Share.share(
      'Vote pour "$title" sur Artéïa !\n$url',
      subject: 'Compétition Artéïa : $title',
    );
  }

  /// Partager l'application
  Future<void> shareApp() async {
    await Share.share(
      'Rejoins-moi sur Artéïa - La communauté artistique !\nhttps://arteia.app',
      subject: 'Artéïa - Communauté artistique',
    );
  }

  /// Partager un badge
  Future<void> shareBadge(String badgeName, String badgeIcon) async {
    await Share.share(
      'J\'ai obtenu le badge $badgeIcon $badgeName sur Artéïa !\nhttps://arteia.app/badges',
      subject: 'Badge Artéïa : $badgeName',
    );
  }

  // ==================== DEEP LINKING ====================

  /// Construire un lien profond
  String _buildDeepLink(String type, String id) {
    return 'https://arteia.app/$type/$id';
  }

  /// Initialiser l'écoute des liens profonds
  void initDeepLinks() {
    _linkSubscription = linkStream.listen((String? link) {
      if (link != null) {
        _handleDeepLink(link);
      }
    });

    // Vérifier le lien qui a ouvert l'app
    getInitialLink().then((String? link) {
      if (link != null) {
        _handleDeepLink(link);
      }
    });
  }

  /// Gérer un lien profond
  void _handleDeepLink(String link) {
    final uri = Uri.parse(link);
    final segments = uri.pathSegments;

    if (segments.length >= 2) {
      final type = segments[0];
      final id = segments[1];

      // Naviguer vers la page appropriée
      switch (type) {
        case 'post':
          _navigateToPost(id);
          break;
        case 'profile':
          _navigateToProfile(id);
          break;
        case 'competition':
          _navigateToCompetition(id);
          break;
        case 'invite':
          _handleInviteCode(id);
          break;
      }
    }
  }

  /// Naviguer vers un post
  void _navigateToPost(String postId) {
    // Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(postId: postId)));
    print('📱 Deep link -> Post: $postId');
  }

  /// Naviguer vers un profil
  void _navigateToProfile(String userId) {
    // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: userId)));
    print('📱 Deep link -> Profile: $userId');
  }

  /// Naviguer vers une compétition
  void _navigateToCompetition(String competitionId) {
    print('📱 Deep link -> Competition: $competitionId');
  }

  /// Gérer un code d'invitation
  void _handleInviteCode(String code) {
    print('📱 Deep link -> Invite code: $code');
  }

  /// Nettoyer
  void dispose() {
    _linkSubscription?.cancel();
  }
}