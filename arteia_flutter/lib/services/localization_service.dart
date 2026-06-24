import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppStrings {
  static const Map<String, Map<String, String>> _localized = {
    'fr': {
      'app_name': 'Artéïa',
      'app_tagline': 'Communauté artistique',
      'home': 'Accueil',
      'explore': 'Explorer',
      'search': 'Rechercher',
      'community': 'Communauté',
      'profile': 'Profil',
      'settings': 'Paramètres',
      'notifications': 'Notifications',
      'messages': 'Messages',
      'favorites': 'Favoris',
      'saved': 'Enregistrés',
      'quests': 'Quêtes',
      'trending': 'Tendances',
      'music': 'Musique',
      'visual_art': 'Art Visuel',
      'manga': 'Manga',
      'movies': 'Films',
      'login': 'Connexion',
      'signup': 'Inscription',
      'publish': 'Publier',
      'like': 'J\'aime',
      'comment': 'Commenter',
      'share': 'Partager',
      'save': 'Enregistrer',
      'follow': 'Suivre',
      'unfollow': 'Ne plus suivre',
      'loading': 'Chargement...',
      'error': 'Erreur',
      'retry': 'Réessayer',
      'cancel': 'Annuler',
      'confirm': 'Confirmer',
      'offline': 'Mode hors-ligne',
      'online': 'En ligne',
      'dark_mode': 'Mode sombre',
      'light_mode': 'Mode clair',
      'language': 'Langue',
      'region': 'Région',
      'timezone': 'Fuseau horaire',
      'cache': 'Cache & Stockage',
      'privacy': 'Confidentialité',
      'about': 'À propos',
      'version': 'Version',
      'developers': 'Développeurs',
      'terms': 'Conditions d\'utilisation',
      'privacy_policy': 'Politique de confidentialité',
      'welcome': 'Bienvenue sur',
      'recent_posts': 'Publications récentes',
      'no_posts': 'Aucune publication',
      'no_comments': 'Aucun commentaire',
      'be_first_comment': 'Soyez le premier à commenter!',
      'add_comment': 'Ajouter un commentaire...',
      'login_to_comment': 'Connectez-vous pour commenter',
      'login_to_like': 'Connectez-vous pour liker',
      'new_publication': 'Nouvelle publication',
      'visual_work': 'Œuvre visuelle',
      'writing': 'Écriture',
      'comics': 'BD / Manga',
      'thought_bubble': 'Bulle de pensée',
      'audio_message': 'Message audio',
      'add_image': 'Ajouter une image',
      'record_audio': 'Commencer l\'enregistrement',
      'stop_recording': 'Arrêter',
      'publish_thought': 'Publier',
      'your_thought': 'Votre pensée',
      'express_yourself': 'Exprimez-vous librement...',
    },
    'en': {
      'app_name': 'Artéïa',
      'app_tagline': 'Artistic Community',
      'home': 'Home',
      'explore': 'Explore',
      'search': 'Search',
      'community': 'Community',
      'profile': 'Profile',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'messages': 'Messages',
      'favorites': 'Favorites',
      'saved': 'Saved',
      'quests': 'Quests',
      'trending': 'Trending',
      'music': 'Music',
      'visual_art': 'Visual Art',
      'manga': 'Manga',
      'movies': 'Movies',
      'login': 'Login',
      'signup': 'Sign Up',
      'publish': 'Publish',
      'like': 'Like',
      'comment': 'Comment',
      'share': 'Share',
      'save': 'Save',
      'follow': 'Follow',
      'unfollow': 'Unfollow',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'offline': 'Offline mode',
      'online': 'Online',
      'dark_mode': 'Dark mode',
      'light_mode': 'Light mode',
      'language': 'Language',
      'region': 'Region',
      'timezone': 'Timezone',
      'cache': 'Cache & Storage',
      'privacy': 'Privacy',
      'about': 'About',
      'version': 'Version',
      'developers': 'Developers',
      'terms': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',
      'welcome': 'Welcome to',
      'recent_posts': 'Recent posts',
      'no_posts': 'No posts yet',
      'no_comments': 'No comments',
      'be_first_comment': 'Be the first to comment!',
      'add_comment': 'Add a comment...',
      'login_to_comment': 'Log in to comment',
      'login_to_like': 'Log in to like',
      'new_publication': 'New publication',
      'visual_work': 'Visual artwork',
      'writing': 'Writing',
      'comics': 'Comics / Manga',
      'thought_bubble': 'Thought bubble',
      'audio_message': 'Audio message',
      'add_image': 'Add an image',
      'record_audio': 'Start recording',
      'stop_recording': 'Stop',
      'publish_thought': 'Publish',
      'your_thought': 'Your thought',
      'express_yourself': 'Express yourself...',
    },
  };

  static String _currentLang = 'fr';

  static String get currentLang => _currentLang;

  static void setLang(String lang) {
    if (_localized.containsKey(lang)) {
      _currentLang = lang;
    }
  }

  static String tr(String key) {
    return _localized[_currentLang]?[key] ?? _localized['fr']?[key] ?? key;
  }

  static List<String> get supportedLanguages => _localized.keys.toList();

  static String languageName(String code) {
    switch (code) {
      case 'fr': return 'Français';
      case 'en': return 'English';
      default: return code;
    }
  }
}

class LocalizationService extends ChangeNotifier {
  static const _langKey = 'app_language';

  LocalizationService() {
    _loadSavedLang();
  }

  Future<void> _loadSavedLang() async {
    try {
      final box = await Hive.openBox('arteia_cache');
      final saved = box.get(_langKey, defaultValue: 'fr') as String;
      AppStrings.setLang(saved);
      notifyListeners();
    } catch (_) {}
  }

  String get currentLang => AppStrings.currentLang;

  void setLang(String lang) async {
    AppStrings.setLang(lang);
    try {
      final box = await Hive.openBox('arteia_cache');
      await box.put(_langKey, lang);
    } catch (_) {}
    notifyListeners();
  }

  List<String> get supportedLanguages => AppStrings.supportedLanguages;

  String languageName(String code) => AppStrings.languageName(code);
}