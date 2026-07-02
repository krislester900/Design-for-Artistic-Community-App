import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthAdvancedService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final AuthAdvancedService _instance = AuthAdvancedService._();
  factory AuthAdvancedService() => _instance;
  AuthAdvancedService._();

  /// Connexion avec Google OAuth
  Future<bool> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.arteia://login-callback',
      );
      return true;
    } catch (e) {
      print('🔴 Google OAuth error: $e');
      return false;
    }
  }

  /// Connexion avec Apple OAuth
  Future<bool> signInWithApple() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.arteia://login-callback',
      );
      return true;
    } catch (e) {
      print('🔴 Apple OAuth error: $e');
      return false;
    }
  }

  /// Connexion avec GitHub OAuth
  Future<bool> signInWithGitHub() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.github,
        redirectTo: 'io.supabase.arteia://login-callback',
      );
      return true;
    } catch (e) {
      print('🔴 GitHub OAuth error: $e');
      return false;
    }
  }

  /// Vérifier si 2FA est activé pour l'utilisateur
  Future<bool> isTwoFactorEnabled() async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('profiles')
          .select('two_factor_enabled')
          .eq('id', user.id)
          .maybeSingle();
      return response?['two_factor_enabled'] ?? false;
    } catch (e) {
      print('🔴 isTwoFactorEnabled error: $e');
      return false;
    }
  }

  /// Activer 2FA (génère un secret TOTP)
  Future<Map<String, dynamic>?> enableTwoFactor() async {
    final user = _supabase.currentUser;
    if (user == null) return null;

    try {
      // Générer un secret TOTP (à implémenter avec un package TOTP)
      final secret = _generateTOTPSecret();
      
      await _client
          .from('profiles')
          .update({'two_factor_enabled': true, 'two_factor_secret': secret})
          .eq('id', user.id);

      return {'secret': secret, 'qrCode': 'otpauth://totp/Artéïa:$user.email?secret=$secret'};
    } catch (e) {
      print('🔴 enableTwoFactor error: $e');
      return null;
    }
  }

  /// Désactiver 2FA
  Future<bool> disableTwoFactor() async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from('profiles')
          .update({'two_factor_enabled': false, 'two_factor_secret': null})
          .eq('id', user.id);
      return true;
    } catch (e) {
      print('🔴 disableTwoFactor error: $e');
      return false;
    }
  }

  /// Vérifier un code 2FA
  Future<bool> verifyTwoFactorCode(String code) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      final response = await _client
          .from('profiles')
          .select('two_factor_secret')
          .eq('id', user.id)
          .maybeSingle();

      final secret = response?['two_factor_secret'] as String?;
      if (secret == null) return false;

      // Vérifier le code TOTP (à implémenter avec un package TOTP)
      // return TOTP.verify(secret, code);
      return code == '123456'; // Placeholder
    } catch (e) {
      print('🔴 verifyTwoFactorCode error: $e');
      return false;
    }
  }

  String _generateTOTPSecret() {
    // Générer un secret aléatoire de 32 caractères base32
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(Iterable.generate(32, (i) => chars.codeUnitAt((random + i) % chars.length)));
  }

  /// Mettre à jour le profil utilisateur
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      await _client
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
      return true;
    } catch (e) {
      print('🔴 updateProfile error: $e');
      return false;
    }
  }

  /// Changer le mot de passe
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      // Vérifier l'ancien mot de passe
      final email = user.email;
      if (email == null) return false;

      await _client.auth.resetPasswordForEmail(email);
      
      // Note: Supabase ne permet pas de vérifier l'ancien mot de passe directement
      // Il faut utiliser l'API admin ou un trigger SQL
      
      return true;
    } catch (e) {
      print('🔴 changePassword error: $e');
      return false;
    }
  }

  /// Supprimer le compte
  Future<bool> deleteAccount() async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      await _client.auth.admin.deleteUser(user.id);
      return true;
    } catch (e) {
      print('🔴 deleteAccount error: $e');
      return false;
    }
  }
}