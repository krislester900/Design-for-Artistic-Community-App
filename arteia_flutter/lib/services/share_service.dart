import 'dart:async';

class ShareService {
  static final ShareService _instance = ShareService._();
  factory ShareService() => _instance;
  ShareService._();

  Future<void> sharePost({
    required String postId,
    required String title,
    String? imageUrl,
    String? authorName,
  }) async {}

  Future<void> shareProfile(String userId, String username) async {}

  Future<void> shareCompetition(String competitionId, String title) async {}

  Future<void> shareApp() async {}

  Future<void> shareBadge(String badgeName, String badgeIcon) async {}

  String _buildDeepLink(String type, String id) => 'https://arteia.app/$type/$id';

  void initDeepLinks() {}

  void _handleDeepLink(String link) {}

  void _navigateToPost(String postId) {}

  void _navigateToProfile(String userId) {}

  void _navigateToCompetition(String competitionId) {}

  void _handleInviteCode(String code) {}

  void dispose() {}
}
