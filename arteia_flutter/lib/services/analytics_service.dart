class CreatorAnalytics {
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final double engagementRate;
  final Map<String, int> viewsByDay;
  final Map<String, int> viewsByCountry;
  final List<String> topPosts;
  final List<String> trending;

  CreatorAnalytics({
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalShares = 0,
    this.engagementRate = 0.0,
    this.viewsByDay = const {},
    this.viewsByCountry = const {},
    this.topPosts = const [],
    this.trending = const [],
  });
}

class AnalyticsService {
  CreatorAnalytics getAnalytics(String userId) {
    // Ici on simule des données analytics
    return CreatorAnalytics(
      totalViews: 1234,
      totalLikes: 89,
      totalComments: 34,
      totalShares: 12,
      engagementRate: 7.2,
      viewsByDay: {
        'Lun': 45, 'Mar': 78, 'Mer': 120, 'Jeu': 95, 'Ven': 156, 'Sam': 210, 'Dim': 180,
      },
      viewsByCountry: {
        'France': 450, 'Canada': 234, 'Belgique': 123, 'Suisse': 89, 'USA': 76,
      },
      topPosts: [
        'Mon œuvre la plus vue',
        'Création du mois',
        'Projet collaboratif',
      ],
      trending: ['+15% cette semaine', 'Top 10 art visuel', 'Recommandé par l\'équipe'],
    );
  }

  double calculateEngagementRate(int likes, int comments, int views) {
    if (views == 0) return 0.0;
    return ((likes + comments) / views * 100);
  }
}