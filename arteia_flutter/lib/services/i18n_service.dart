import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class I18nService extends ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final I18nService _instance = I18nService._();
  factory I18nService() => _instance;
  I18nService._();

  String _currentLang = 'fr';
  String get currentLang => _currentLang;
  
  Map<String, Map<String, String>> _translations = {};
  List<Map<String, dynamic>> _supportedLanguages = [];

  static const Map<String, String> languageNames = {
    'fr': 'Français',
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
    'it': 'Italiano',
    'pt': 'Português',
    'ar': 'العربية',
    'zh': '中文',
  };

  static const Map<String, String> languageFlags = {
    'fr': '🇫🇷',
    'en': '🇬🇧',
    'es': '🇪🇸',
    'de': '🇩🇪',
    'it': '🇮🇹',
    'pt': '🇵🇹',
    'ar': '🇸🇦',
    'zh': '🇨🇳',
  };

  /// Initialiser la langue depuis le profil
  Future<void> initialize() async {
    final user = _supabase.currentUser;
    if (user != null) {
      try {
        final profile = await _client
            .from('profiles')
            .select('preferred_language')
            .eq('id', user.id)
            .maybeSingle();
        _currentLang = profile?['preferred_language'] as String? ?? 'fr';
      } catch (e) {
        _currentLang = 'fr';
      }
    }
    await _loadTranslations();
    await _loadLanguages();
  }

  /// Charger les traductions depuis Supabase
  Future<void> _loadTranslations() async {
    try {
      final response = await _client
          .from('translations')
          .select('key, fr, en, es, de, it, pt, ar, zh');

      final translations = <String, Map<String, String>>{};
      for (final row in response as List) {
        final key = row['key'] as String;
        translations[key] = {
          'fr': row['fr'] as String? ?? '',
          'en': row['en'] as String? ?? '',
          'es': row['es'] as String? ?? '',
          'de': row['de'] as String? ?? '',
          'it': row['it'] as String? ?? '',
          'pt': row['pt'] as String? ?? '',
          'ar': row['ar'] as String? ?? '',
          'zh': row['zh'] as String? ?? '',
        };
      }
      _translations = translations;
    } catch (e) {
      print('🔴 loadTranslations error: $e');
    }
  }

  /// Charger les langues supportées
  Future<void> _loadLanguages() async {
    try {
      final response = await _client
          .from('supported_languages')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      _supportedLanguages = (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 loadLanguages error: $e');
    }
  }

  /// Traduire une clé
  String translate(String key, {Map<String, String>? params}) {
    final translation = _translations[key]?[_currentLang];
    if (translation == null) return key;

    if (params != null) {
      return params.entries.fold(translation, (prev, entry) {
        return prev.replaceAll('{{${entry.key}}}', entry.value);
      });
    }
    return translation;
  }

  /// Changer la langue
  Future<void> setLanguage(String langCode) async {
    if (!languageNames.containsKey(langCode)) return;

    _currentLang = langCode;
    notifyListeners();

    // Sauvegarder dans le profil
    final user = _supabase.currentUser;
    if (user != null) {
      try {
        await _client
            .from('profiles')
            .update({'preferred_language': langCode})
            .eq('id', user.id);
      } catch (e) {
        print('🔴 setLanguage error: $e');
      }
    }
  }

  /// Obtenir les langues supportées
  List<Map<String, dynamic>> getSupportedLanguages() => _supportedLanguages;

  /// Obtenir le nom natif d'une langue
  String getNativeName(String code) => languageNames[code] ?? code;

  /// Obtenir le drapeau d'une langue
  String getFlag(String code) => languageFlags[code] ?? '🌐';

  /// Vérifier si la langue est RTL
  bool isRtl(String code) => code == 'ar';

  /// Traductions statiques (fallback)
  static const Map<String, Map<String, String>> fallbackTranslations = {
    'app_name': {
      'fr': 'Artéïa',
      'en': 'Artéïa',
      'es': 'Artéïa',
      'de': 'Artéïa',
    },
    'welcome': {
      'fr': 'Bienvenue sur Artéïa',
      'en': 'Welcome to Artéïa',
      'es': 'Bienvenido a Artéïa',
      'de': 'Willkommen bei Artéïa',
    },
    'home': {
      'fr': 'Accueil',
      'en': 'Home',
      'es': 'Inicio',
      'de': 'Startseite',
    },
    'explore': {
      'fr': 'Explorer',
      'en': 'Explore',
      'es': 'Explorar',
      'de': 'Entdecken',
    },
    'search': {
      'fr': 'Rechercher',
      'en': 'Search',
      'es': 'Buscar',
      'de': 'Suchen',
    },
    'profile': {
      'fr': 'Profil',
      'en': 'Profile',
      'es': 'Perfil',
      'de': 'Profil',
    },
    'settings': {
      'fr': 'Paramètres',
      'en': 'Settings',
      'es': 'Ajustes',
      'de': 'Einstellungen',
    },
    'notifications': {
      'fr': 'Notifications',
      'en': 'Notifications',
      'es': 'Notificaciones',
      'de': 'Benachrichtigungen',
    },
    'favorites': {
      'fr': 'Favoris',
      'en': 'Favorites',
      'es': 'Favoritos',
      'de': 'Favoriten',
    },
    'likes': {
      'fr': 'J\'aime',
      'en': 'Likes',
      'es': 'Me gusta',
      'de': 'Gefällt mir',
    },
    'comments': {
      'fr': 'Commentaires',
      'en': 'Comments',
      'es': 'Comentarios',
      'de': 'Kommentare',
    },
    'share': {
      'fr': 'Partager',
      'en': 'Share',
      'es': 'Compartir',
      'de': 'Teilen',
    },
    'follow': {
      'fr': 'Suivre',
      'en': 'Follow',
      'es': 'Seguir',
      'de': 'Folgen',
    },
    'unfollow': {
      'fr': 'Ne plus suivre',
      'en': 'Unfollow',
      'es': 'Dejar de seguir',
      'de': 'Entfolgen',
    },
    'login': {
      'fr': 'Connexion',
      'en': 'Login',
      'es': 'Iniciar sesión',
      'de': 'Anmelden',
    },
    'register': {
      'fr': 'S\'inscrire',
      'en': 'Register',
      'es': 'Registrarse',
      'de': 'Registrieren',
    },
    'logout': {
      'fr': 'Déconnexion',
      'en': 'Logout',
      'es': 'Cerrar sesión',
      'de': 'Abmelden',
    },
    'post': {
      'fr': 'Publier',
      'en': 'Post',
      'es': 'Publicar',
      'de': 'Veröffentlichen',
    },
    'delete': {
      'fr': 'Supprimer',
      'en': 'Delete',
      'es': 'Eliminar',
      'de': 'Löschen',
    },
    'cancel': {
      'fr': 'Annuler',
      'en': 'Cancel',
      'es': 'Cancelar',
      'de': 'Abbrechen',
    },
    'confirm': {
      'fr': 'Confirmer',
      'en': 'Confirm',
      'es': 'Confirmar',
      'de': 'Bestätigen',
    },
    'loading': {
      'fr': 'Chargement...',
      'en': 'Loading...',
      'es': 'Cargando...',
      'de': 'Laden...',
    },
    'error': {
      'fr': 'Erreur',
      'en': 'Error',
      'es': 'Error',
      'de': 'Fehler',
    },
    'no_internet': {
      'fr': 'Pas de connexion internet',
      'en': 'No internet connection',
      'es': 'Sin conexión a internet',
      'de': 'Keine Internetverbindung',
    },
    'retry': {
      'fr': 'Réessayer',
      'en': 'Retry',
      'es': 'Reintentar',
      'de': 'Wiederholen',
    },
  };

  /// Traduction statique (fallback si pas chargé)
  String t(String key, {Map<String, String>? params}) {
    // Essayer la traduction chargée
    final loaded = translate(key, params: params);
    if (loaded != key) return loaded;

    // Fallback statique
    final fallback = fallbackTranslations[key]?[_currentLang];
    if (fallback != null) {
      if (params != null) {
        return params.entries.fold(fallback, (prev, entry) {
          return prev.replaceAll('{{${entry.key}}}', entry.value);
        });
      }
      return fallback;
    }

    return key;
  }
}

/// Extension pour traduire facilement depuis les widgets
extension I18nExtension on BuildContext {
  String t(String key, {Map<String, String>? params}) {
    return I18nService().t(key, params: params);
  }
}