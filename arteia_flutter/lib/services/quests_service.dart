import 'package:flutter/foundation.dart';

enum QuestType {
  publish,      // Publier une œuvre
  like,         // Liker des œuvres
  comment,      // Commenter
  follow,       // Suivre un artiste
  dailyLogin,   // Connexion quotidienne
}

enum QuestStatus {
  pending,      // En attente
  inProgress,   // En cours
  completed,    // Terminé
  claimed,      // Récompense récupérée
}

class Quest {
  final String id;
  final String title;
  final String description;
  final QuestType type;
  final int targetCount;
  final int currentProgress;
  final QuestStatus status;
  final int rewardPoints;
  final String? rewardBadge;
  final DateTime? expiresAt;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetCount,
    this.currentProgress = 0,
    this.status = QuestStatus.pending,
    required this.rewardPoints,
    this.rewardBadge,
    this.expiresAt,
  });

  Quest copyWith({
    String? id,
    String? title,
    String? description,
    QuestType? type,
    int? targetCount,
    int? currentProgress,
    QuestStatus? status,
    int? rewardPoints,
    String? rewardBadge,
    DateTime? expiresAt,
  }) {
    return Quest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentProgress: currentProgress ?? this.currentProgress,
      status: status ?? this.status,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      rewardBadge: rewardBadge ?? this.rewardBadge,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  double get progress => targetCount > 0 ? currentProgress / targetCount : 0.0;
  bool get isCompleted => status == QuestStatus.completed || status == QuestStatus.claimed;
  bool get isClaimable => status == QuestStatus.completed;
}

class UserBadge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final DateTime unlockedAt;

  UserBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.unlockedAt,
  });
}

class QuestsService extends ChangeNotifier {
  static final QuestsService _instance = QuestsService._internal();
  factory QuestsService() => _instance;
  QuestsService._internal();

  int _userPoints = 0;
  int _userLevel = 1;
  final List<UserBadge> _userBadges = [];
  final List<Quest> _dailyQuests = [];
  final List<Quest> _weeklyQuests = [];

  int get userPoints => _userPoints;
  int get userLevel => _userLevel;
  List<UserBadge> get userBadges => List.unmodifiable(_userBadges);
  List<Quest> get dailyQuests => List.unmodifiable(_dailyQuests);
  List<Quest> get weeklyQuests => List.unmodifiable(_weeklyQuests);

  // Quêtes quotidiennes par défaut
  static List<Quest> getDefaultDailyQuests() {
    return [
      Quest(
        id: 'daily_publish',
        title: 'Créateur du jour',
        description: 'Publiez 1 œuvre',
        type: QuestType.publish,
        targetCount: 1,
        rewardPoints: 50,
        rewardBadge: '✨',
      ),
      Quest(
        id: 'daily_like',
        title: 'Appréciateur',
        description: 'Likez 5 œuvres',
        type: QuestType.like,
        targetCount: 5,
        rewardPoints: 30,
        rewardBadge: '❤️',
      ),
      Quest(
        id: 'daily_comment',
        title: 'Commentateur',
        description: 'Laissez 3 commentaires',
        type: QuestType.comment,
        targetCount: 3,
        rewardPoints: 40,
        rewardBadge: '💬',
      ),
      Quest(
        id: 'daily_login',
        title: 'Assiduité',
        description: 'Connectez-vous aujourd\'hui',
        type: QuestType.dailyLogin,
        targetCount: 1,
        rewardPoints: 20,
        rewardBadge: '📅',
      ),
    ];
  }

  // Quêtes hebdomadaires par défaut
  static List<Quest> getDefaultWeeklyQuests() {
    return [
      Quest(
        id: 'weekly_publish',
        title: 'Artiste de la semaine',
        description: 'Publiez 5 œuvres',
        type: QuestType.publish,
        targetCount: 5,
        rewardPoints: 200,
        rewardBadge: '🏆',
      ),
      Quest(
        id: 'weekly_follow',
        title: 'Community builder',
        description: 'Suivez 10 artistes',
        type: QuestType.follow,
        targetCount: 10,
        rewardPoints: 150,
        rewardBadge: '🤝',
      ),
      Quest(
        id: 'weekly_engagement',
        title: 'Super engagé',
        description: 'Likez 25 œuvres',
        type: QuestType.like,
        targetCount: 25,
        rewardPoints: 100,
        rewardBadge: '🔥',
      ),
    ];
  }

  void initialize() {
    _dailyQuests.clear();
    _weeklyQuests.clear();
    _dailyQuests.addAll(getDefaultDailyQuests());
    _weeklyQuests.addAll(getDefaultWeeklyQuests());
    notifyListeners();
  }

  void updateQuestProgress(QuestType type, int increment) {
    bool updated = false;
    
    // Mettre à jour les quêtes quotidiennes
    for (var quest in _dailyQuests) {
      if (quest.type == type && !quest.isCompleted) {
        final newProgress = quest.currentProgress + increment;
        final newStatus = newProgress >= quest.targetCount 
            ? QuestStatus.completed 
            : QuestStatus.inProgress;
        
        _dailyQuests[_dailyQuests.indexOf(quest)] = quest.copyWith(
          currentProgress: newProgress,
          status: newStatus,
        );
        updated = true;
        
        if (newStatus == QuestStatus.completed) {
          _userPoints += quest.rewardPoints;
          _checkLevelUp();
        }
      }
    }
    
    // Mettre à jour les quêtes hebdomadaires
    for (var quest in _weeklyQuests) {
      if (quest.type == type && !quest.isCompleted) {
        final newProgress = quest.currentProgress + increment;
        final newStatus = newProgress >= quest.targetCount 
            ? QuestStatus.completed 
            : QuestStatus.inProgress;
        
        _weeklyQuests[_weeklyQuests.indexOf(quest)] = quest.copyWith(
          currentProgress: newProgress,
          status: newStatus,
        );
        updated = true;
        
        if (newStatus == QuestStatus.completed) {
          _userPoints += quest.rewardPoints;
          _checkLevelUp();
        }
      }
    }
    
    if (updated) notifyListeners();
  }

  void claimQuestReward(String questId) {
    for (var quest in _dailyQuests) {
      if (quest.id == questId && quest.isClaimable) {
        final index = _dailyQuests.indexOf(quest);
        _dailyQuests[index] = quest.copyWith(status: QuestStatus.claimed);
        
        if (quest.rewardBadge != null && !_hasBadge(quest.rewardBadge!)) {
          _userBadges.add(UserBadge(
            id: quest.id,
            name: quest.title,
            description: quest.description,
            icon: quest.rewardBadge!,
            unlockedAt: DateTime.now(),
          ));
        }
        
        notifyListeners();
        return;
      }
    }
    
    for (var quest in _weeklyQuests) {
      if (quest.id == questId && quest.isClaimable) {
        final index = _weeklyQuests.indexOf(quest);
        _weeklyQuests[index] = quest.copyWith(status: QuestStatus.claimed);
        
        if (quest.rewardBadge != null && !_hasBadge(quest.rewardBadge!)) {
          _userBadges.add(UserBadge(
            id: quest.id,
            name: quest.title,
            description: quest.description,
            icon: quest.rewardBadge!,
            unlockedAt: DateTime.now(),
          ));
        }
        
        notifyListeners();
        return;
      }
    }
  }

  bool _hasBadge(String badgeIcon) {
    return _userBadges.any((b) => b.icon == badgeIcon);
  }

  void _checkLevelUp() {
    // Formule simple : niveau = sqrt(points / 100) + 1
    final newLevel = ((_userPoints / 100).sqrt().floor()) + 1;
    if (newLevel > _userLevel) {
      _userLevel = newLevel;
      // TODO: Notification de level up
    }
  }

  int getCompletedQuestsCount() {
    return _dailyQuests.where((q) => q.isCompleted).length +
           _weeklyQuests.where((q) => q.isCompleted).length;
  }

  int getTotalQuestsCount() {
    return _dailyQuests.length + _weeklyQuests.length;
  }
}

extension DoubleExtension on double {
  double sqrt() {
    return this > 0 ? (this / 2 + 1 / (2 * (this / 2 + 1 / (2 * (this / 2 + 1 / (2 * (this / 2))))))) : 0;
  }
}