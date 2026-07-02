import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class InvitationService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final InvitationService _instance = InvitationService._();
  factory InvitationService() => _instance;
  InvitationService._();

  /// Inviter par email
  Future<Map<String, dynamic>> inviteByEmail({
    required String email,
    String? message,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) return {'success': false, 'error': 'Non connecté'};

    try {
      // Vérifier que l'email n'est pas déjà invité
      final existing = await _client
          .from('invitations')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (existing != null) return {'success': false, 'error': 'Cet email a déjà été invité'};

      // Vérifier que l'email n'est pas déjà inscrit
      final registered = await _client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (registered != null) return {'success': false, 'error': 'Cet utilisateur est déjà inscrit'};

      // Créer l'invitation
      final code = _generateInviteCode();
      await _client.from('invitations').insert({
        'sender_id': user.id,
        'email': email,
        'code': code,
        'message': message ?? 'Rejoins-moi sur Artéïa !',
        'status': 'pending',
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });

      // Appeler l'Edge Function pour envoyer l'email
      await _client.functions.invoke('send-invitation-email', body: {
        'email': email,
        'code': code,
        'sender_name': user.email ?? 'Un ami',
        'message': message ?? 'Rejoins-moi sur Artéïa !',
      });

      return {
        'success': true,
        'code': code,
        'message': '✅ Invitation envoyée par email à $email',
      };
    } catch (e) {
      print('🔴 inviteByEmail error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Inviter par SMS
  Future<Map<String, dynamic>> inviteBySms({
    required String phoneNumber,
    String? message,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) return {'success': false, 'error': 'Non connecté'};

    try {
      final code = _generateInviteCode();
      await _client.from('invitations').insert({
        'sender_id': user.id,
        'phone': phoneNumber,
        'code': code,
        'message': message ?? 'Rejoins-moi sur Artéïa !',
        'status': 'pending',
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
      });

      // Appeler Edge Function pour SMS
      await _client.functions.invoke('send-invitation-sms', body: {
        'phone': phoneNumber,
        'code': code,
        'message': message ?? 'Rejoins-moi sur Artéïa ! Télécharge l\'app : https://arteia.app',
      });

      return {
        'success': true,
        'code': code,
        'message': '✅ Invitation envoyée par SMS au $phoneNumber',
      };
    } catch (e) {
      print('🔴 inviteBySms error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Partager un lien d'invitation
  String getShareLink(String code) {
    return 'https://arteia.app/invite?code=$code';
  }

  /// Récupérer les statistiques d'invitation
  Future<Map<String, dynamic>> getInvitationStats() async {
    final user = _supabase.currentUser;
    if (user == null) return {};

    try {
      final invites = await _client
          .from('invitations')
          .select('status')
          .eq('sender_id', user.id);

      final list = invites as List;
      return {
        'total': list.length,
        'pending': list.where((i) => i['status'] == 'pending').length,
        'accepted': list.where((i) => i['status'] == 'accepted').length,
        'expired': list.where((i) => i['status'] == 'expired').length,
      };
    } catch (e) {
      print('🔴 getInvitationStats error: $e');
      return {};
    }
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().microsecondsSinceEpoch;
    return String.fromCharCodes(
      Iterable.generate(8, (i) => chars.codeUnitAt((random + i * 13) % chars.length)),
    );
  }
}