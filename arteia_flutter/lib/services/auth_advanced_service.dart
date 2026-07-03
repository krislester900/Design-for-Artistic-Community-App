import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthAdvancedService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final AuthAdvancedService _instance = AuthAdvancedService._();
  factory AuthAdvancedService() => _instance;
  AuthAdvancedService._();

  /// Connexion avec Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      // Sur mobile, utiliser Google Sign-In natif
      // Sur web, utiliser OAuth popup
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'arteia://login',
      );
      
      return {'success': true, 'url': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Connexion avec Apple
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'arteia://login',
      );
      
      return {'success': true, 'url': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Connexion avec Twitter/X
  Future<Map<String, dynamic>> signInWithTwitter() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.twitter,
        redirectTo: kIsWeb ? null : 'arteia://login',
      );
      
      return {'success': true, 'url': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Connexion avec GitHub
  Future<Map<String, dynamic>> signInWithGitHub() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: kIsWeb ? null : 'arteia://login',
      );
      
      return {'success': true, 'url': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Connexion avec Discord
  Future<Map<String, dynamic>> signInWithDiscord() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.discord,
        redirectTo: kIsWeb ? null : 'arteia://login',
      );
      
      return {'success': true, 'url': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Connexion avec Facebook
  Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'arteia://login',
      );
      
      return {'success': true, 'url': response};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Inscription avec email/mot de passe
  Future<Map<String, dynamic>> signUpWithEmail({
    required String email,
    required String password,
    String? username,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          if (username != null) 'username': username,
        },
      );

      if (response.user != null) {
        // Créer le profil utilisateur
        await _client.from('profiles').insert({
          'id': response.user!.id,
          'email': email,
          'username': username ?? email.split('@')[0],
          'created_at': DateTime.now().toIso8601String(),
        });

        return {
          'success': true,
          'user': response.user,
          'session': response.session,
        };
      }

      return {'success': false, 'error': 'Erreur lors de l\'inscription'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Connexion avec email/mot de passe
  Future<Map<String, dynamic>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return {
        'success': true,
        'user': response.user,
        'session': response.session,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mot de passe oublié
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return {'success': true, 'message': 'Email de réinitialisation envoyé'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Supprimer le compte
  Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return {'success': false, 'error': 'Non connecté'};

      // Supprimer le profil
      await _client.from('profiles').delete().eq('id', user.id);
      
      // Supprimer l'utilisateur (nécessite une Edge Function ou admin)
      // await _client.auth.admin.deleteUser(user.id);

      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Mettre à jour le profil
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return {'success': false, 'error': 'Non connecté'};

      await _client.from('profiles').update(data).eq('id', user.id);
      
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Vérifier si l'email est vérifié
  bool isEmailVerified() {
    final user = _supabase.currentUser;
    return user?.emailConfirmedAt != null;
  }

  /// Renvoyer l'email de vérification
  Future<Map<String, dynamic>> resendVerificationEmail() async {
    try {
      final user = _supabase.currentUser;
      if (user == null) return {'success': false, 'error': 'Non connecté'};

      await _client.auth.resend(
        type: OtpType.signup,
        email: user.email ?? '',
      );

      return {'success': true, 'message': 'Email de vérification renvoyé'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}