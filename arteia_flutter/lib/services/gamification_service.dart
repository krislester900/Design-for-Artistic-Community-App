import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service de gamification : niveaux, badges, classements
class GamificationService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final GamificationService _instance = GamificationService._();
  factory GamificationService() => _instance;
  GamificationService._();

  // ==================== NIVEAUX ====================

  /// XP requis par niveau
  static const List<int> xpPerLevel = [
    0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 8500,  // Niveaux 1-10
    11500, 15000, 19000, 23500, 28500, 34000, 40000, 50000, 60000, 75000, // Niveaux 11-20
  ];

  /// Actions qui donnent de l'XP
  static const Map<String, int> xpActions = {
    'like': 5,
    'comment': 10,
    'post': 25,
    'follow': 3,
    'share': 8,
    'daily_login': 15,
    'donation_sent': 20,
    'donation_received': 10,
    'competition_entry': 30,
    'competition_vote': 5,
    'profile_complete': 50,
    'chat_message': 2,
  };

  /// Calculer le niveau à partir de l'XP total
  int calculateLevel(int totalXp) {
    for (int i = xpPerLevel.length - 1; i >= 0; i--) {
      if (totalXp >= xpPerLevel[i]) return i + 1;
    }
    return 1;
  }

  /// Calculer l'XP pour le niveau actuel
  int xpForCurrentLevel(int level) {
    if (level <= 1) return xpPerLevel[0];
    if (level >= xpPerLevel.length) return xpPerLevel.last;
    return xpPerLevel[level - 1];
  }

  /// Calculer la progression dans le niveau actuel (0.0 - 1.0)
  double levelProgress(int totalXp) {
    final level = calculateLevel(totalXp);
    final currentLevelXp = xpForCurrentLevel(level);
    final nextLevelXp = level < xpPerLevel.length ? xpPerLevel[level] : xpPerLevel.last;
    final xpInLevel = totalXp - currentLevelXp;
    final xpNeeded = nextLevelXp - currentLevelXp;
    return xpNeeded > 0 ? (xpInLevel / xpNeeded).clamp(0.0, 1.0) : 1.0;
  }

  /// Ajouter de l'XP
  Future<Map<String, dynamic>> addXp(String action, {int? customAmount}) async {
    final user = _supabase.currentUser;
    if (user == null) return {'success': false, 'error': 'Non connecté'};

    final xpAmount = customAmount ?? xpActions[action] ?? 1;

    try {
      // Récupérer l'XP actuel
      final profile = await _client
          .from('profiles')
          .select('xp, level, daily_xp')
          .eq('id', user.id)
          .maybeSingle();

      final currentXp = (profile?['xp'] as int?) ?? 0;
      final currentLevel = (profile?['level'] as int?) ?? 1;
      final dailyXp = (profile?['daily_xp'] as int?) ?? 0;
      final newXp = currentXp + xpAmount;
      final newLevel = calculateLevel(newXp);
      final leveledUp = newLevel > currentLevel;

      // Mettre à jour le profil
      await _client
          .from('profiles')
          .update({
            'xp': newXp,
            'level': newLevel,
            'daily_xp': dailyXp + xpAmount,
            'last_xp_action': action,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);

      return {
        'success': true,
        'xp_gained': xpAmount,
        'total_xp': newXp,
        'level': newLevel,
        'leveled_up': leveledUp,
        'progress': levelProgress(newXp),
      };
    } catch (e) {
      print('🔴 addXp error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ==================== BADGES ====================

  /// Tous les badges disponibles
  static const List<Map<String, dynamic>> allBadges = [
    {'id': 'first_like', 'name': 'Premier Like', 'description': 'Donnez votre premier like', 'icon': '❤️', 'xp_reward': 10},
    {'id': 'post_master', 'name': 'Maître Posteur', 'description': 'Publiez 10 œuvres', 'icon': '🎨', 'xp_reward': 100},
    {'id': 'commentator', 'name': 'Commentateur', 'description': 'Commentez 20 publications', 'icon': '💬', 'xp_reward': 50},
    {'id': 'social_butterfly', 'name': 'Papillon Social', 'description': 'Suivez 15 artistes', 'icon': '🦋', 'xp_reward': 75},
    {'id': 'donor', 'name': 'Généreux', 'description': 'Envoyez votre premier don', 'icon': '💰', 'xp_reward': 50},
    {'id': 'voter', 'name': 'Électeur', 'description': 'Votez 10 fois', 'icon': '🗳️', 'xp_reward': 30},
    {'id': 'winner', 'name': 'Champion', 'description': 'Gagnez une compétition', 'icon': '🏆', 'xp_reward': 500},
    {'id': 'streak_7', 'name': 'Assidu', 'description': 'Connectez-vous 7 jours d\'affilée', 'icon': '🔥', 'xp_reward': 200},
    {'id': 'streak_30', 'name': 'Dévoué', 'description': 'Connectez-vous 30 jours d\'affilée', 'icon': '💎', 'xp_reward': 1000},
    {'id': 'collector', 'name': 'Collectionneur', 'description': 'Recevez 5 badges', 'icon': '🏅', 'xp_reward': 150},
    {'id': 'famous', 'name': 'Célèbre', 'description': 'Atteignez 100 followers', 'icon': '🌟', 'xp_reward': 300},
    {'id': 'explorer', 'name': 'Explorateur', 'description': 'Visitez 5 univers différents', 'icon': '🌍', 'xp_reward': 40},
    {'id': 'artist', 'name': 'Artiste Complet', 'description': 'Publiez dans 3 catégories différentes', 'icon': '🎭', 'xp_reward': 200},
    {'id': 'million', 'name': 'Million', 'description': 'Atteignez 1M de likes total', 'icon': '⭐', 'xp_reward': 10000},
    {'id': 'veteran', 'name': 'Vétéran', 'description': 'Restez actif pendant 1 an', 'icon': '🎖️', 'xp_reward': 5000},
  ];

  /// Récupérer les badges de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserBadges() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('user_badges')
          .select('*, badge:badges(*)')
          .eq('user_id', user.id);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getUserBadges error: $e');
      return [];
    }
  }

  /// Attribuer un badge si l'utilisateur remplit les conditions
  Future<Map<String, dynamic>?> awardBadge(String badgeId) async {
    final user = _supabase.currentUser;
    if (user == null) return null;

    // Vérifier si déjà possédé
    final existing = await _client
        .from('user_badges')
        .select('id')
        .eq('user_id', user.id)
        .eq('badge_id', badgeId)
        .maybeSingle();

    if (existing != null) return null; // Déjà possédé

    try {
      final badge = allBadges.firstWhere((b) => b['id'] == badgeId);
      
      await _client.from('user_badges').insert({
        'user_id': user.id,
        'badge_id': badgeId,
        'badge_name': badge['name'],
        'badge_icon': badge['icon'],
        'awarded_at': DateTime.now().toIso8601String(),
      });

      // Donner l'XP bonus du badge
      await addXp('badge', customAmount: badge['xp_reward'] as int? ?? 0);

      return {
        'id': badgeId,
        'name': badge['name'],
        'icon': badge['icon'],
        'description': badge['description'],
        'xp_reward': badge['xp_reward'],
      };
    } catch (e) {
      print('🔴 awardBadge error: $e');
      return null;
    }
  }

  // ==================== CLASSEMENTS ====================

  /// Récupérer le classement général (top 100)
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 100}) async {
    try {
      final response = await _client
          .from('profiles')
          .select('id, username, avatar_url, level, xp, badges_count')
          .order('xp', ascending: false)
          .limit(limit);

      return (response as List).asMap().entries.map((entry) {
        final profile = entry.value as Map<String, dynamic>;
        return {
          'rank': entry.key + 1,
          ...profile,
        };
      }).toList();
    } catch (e) {
      print('🔴 getLeaderboard error: $e');
      return [];
    }
  }

  /// Récupérer le classement par catégorie
  Future<List<Map<String, dynamic>>> getCategoryLeaderboard(String category) async {
    try {
      final response = await _client
          .from('posts')
          .select('user_id, profiles!user_id(id, username, avatar_url), count:posts.count')
          .eq('type', category)
          .order('count', ascending: false)
          .limit(50);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getCategoryLeaderboard error: $e');
      return [];
    }
  }

  /// Récupérer le rang de l'utilisateur connecté
  Future<int> getUserRank() async {
    final user = _supabase.currentUser;
    if (user == null) return 0;

    try {
      final profile = await _client
          .from('profiles')
          .select('xp')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) return 0;

      final xp = profile['xp'] as int? ?? 0;

      final count = await _client
          .from('profiles')
          .select('id', count: CountOption.exact)
          .gt('xp', xp);

      return count.length + 1;
    } catch (e) {
      print('🔴 getUserRank error: $e');
      return 0;
    }
  }

  // ==================== CHECK QUOTIDIEN ====================

  /// Vérifier la connexion quotidienne (streak)
  Future<void> checkDailyLogin() async {
    final user = _supabase.currentUser;
    if (user == null) return;

    try {
      final profile = await _client
          .from('profiles')
          .select('last_login_date, streak')
          .eq('id', user.id)
          .maybeSingle();

      final lastLogin = profile?['last_login_date'] as String?;
      final currentStreak = (profile?['streak'] as int?) ?? 0;
      final today = DateTime.now();

      if (lastLogin != null) {
        final lastDate = DateTime.parse(lastLogin);
        final diff = today.difference(lastDate).inDays;

        if (diff == 0) return; // Déjà connecté aujourd'hui
        if (diff == 1) {
          // Connexion consécutive
          final newStreak = currentStreak + 1;
          await _client.from('profiles').update({
            'last_login_date': today.toIso8601String(),
            'streak': newStreak,
          }).eq('id', user.id);

          await addXp('daily_login');

          // Vérifier les badges de streak
          if (newStreak >= 7) await awardBadge('streak_7');
          if (newStreak >= 30) await awardBadge('streak_30');
        } else {
          // Streak brisé
          await _client.from('profiles').update({
            'last_login_date': today.toIso8601String(),
            'streak': 1,
          }).eq('id', user.id);
        }
      } else {
        // Première connexion
        await _client.from('profiles').update({
          'last_login_date': today.toIso8601String(),
          'streak': 1,
        }).eq('id', user.id);
      }
    } catch (e) {
      print('🔴 checkDailyLogin error: $e');
    }
  }
}