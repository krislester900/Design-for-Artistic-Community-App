import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service unifié de gestion d'erreurs
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._();

  /// Retourne un message utilisateur compréhensible
  String getUserFriendlyMessage(dynamic error) {
    if (error is PostgrestException) {
      return _handlePostgrestError(error);
    }
    if (error is AuthException) {
      return _handleAuthError(error);
    }
    if (error is Exception) {
      return _handleException(error);
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }

  String _handlePostgrestError(PostgrestException error) {
    switch (error.code) {
      case '23505': return 'Cette entrée existe déjà';
      case '23503': return 'Référence invalide';
      case '42P01': return 'Table non trouvée';
      case '42703': return 'Colonne non trouvée';
      default: return 'Erreur base de données: ${error.message}';
    }
  }

  String _handleAuthError(AuthException error) {
    if (error.message.contains('Invalid login credentials')) {
      return 'Email ou mot de passe incorrect';
    }
    if (error.message.contains('User already registered')) {
      return 'Cet email est déjà inscrit';
    }
    if (error.message.contains('Password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return 'Erreur d\'authentification: ${error.message}';
  }

  String _handleException(Exception error) {
    final message = error.toString();
    if (message.contains('SocketException')) return 'Erreur de connexion réseau';
    if (message.contains('TimeoutException')) return 'Délai d\'attente dépassé';
    return message;
  }

  void logError(dynamic error, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('🔴 ERROR: $error');
      if (stackTrace != null) {
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }
}