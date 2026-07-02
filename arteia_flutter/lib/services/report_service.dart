import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class ReportService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => _supabase.client;
  static final ReportService _instance = ReportService._();
  factory ReportService() => _instance;
  ReportService._();

  /// Récupérer les raisons de signalement
  Future<List<Map<String, dynamic>>> getReportReasons() async {
    try {
      final response = await _client
          .from('report_reasons')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getReportReasons error: $e');
      return [];
    }
  }

  /// Signaler un contenu
  Future<Map<String, dynamic>> reportContent({
    required String contentType, // 'post', 'comment', 'message', 'profile', 'story'
    required String contentId,
    required String reasonId,
    String? description,
    String? reportedUserId,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) return {'success': false, 'error': 'Non connecté'};

    try {
      await _client.from('reports').insert({
        'reporter_id': user.id,
        'reported_user_id': reportedUserId,
        'content_type': contentType,
        'content_id': contentId,
        'reason_id': reasonId,
        'description': description ?? '',
        'status': 'pending',
      });

      return {
        'success': true,
        'message': '✅ Signalement envoyé. Merci de contribuer à la sécurité de la communauté.',
      };
    } catch (e) {
      print('🔴 reportContent error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Vérifier si l'utilisateur est banni
  Future<bool> isBanned() async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      final result = await _client.rpc('is_user_banned', params: {
        'p_user_id': user.id,
      });
      return result == true;
    } catch (e) {
      print('🔴 isBanned error: $e');
      return false;
    }
  }

  /// Obtenir les signalements de l'utilisateur (admin)
  Future<List<Map<String, dynamic>>> getReports({String? status}) async {
    try {
      var query = _client
          .from('reports')
          .select('*, reporter:profiles!reporter_id(id, username), reason:report_reasons(code, label_fr)')
          .order('created_at', ascending: false)
          .limit(50);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getReports error: $e');
      return [];
    }
  }

  /// Traiter un signalement (admin)
  Future<bool> processReport({
    required String reportId,
    required String status, // 'resolved', 'dismissed'
    String? actionTaken,
    String? moderatorNote,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      await _client.from('reports').update({
        'status': status,
        'action_taken': actionTaken ?? '',
        'moderator_id': user.id,
        'moderator_note': moderatorNote ?? '',
        'resolved_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);

      return true;
    } catch (e) {
      print('🔴 processReport error: $e');
      return false;
    }
  }

  /// Bannir un utilisateur (admin)
  Future<bool> banUser({
    required String userId,
    required String reason,
    String? reportId,
    bool isPermanent = false,
    int? durationDays,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      await _client.from('bans').insert({
        'user_id': userId,
        'moderator_id': user.id,
        'reason': reason,
        'report_id': reportId,
        'is_permanent': isPermanent,
        'expires_at': isPermanent ? null : DateTime.now().add(Duration(days: durationDays ?? 7)).toIso8601String(),
      });

      return true;
    } catch (e) {
      print('🔴 banUser error: $e');
      return false;
    }
  }

  /// Lever un bannissement (admin)
  Future<bool> unbanUser(String banId) async {
    try {
      await _client.from('bans').update({
        'is_active': false,
        'lifted_at': DateTime.now().toIso8601String(),
      }).eq('id', banId);

      return true;
    } catch (e) {
      print('🔴 unbanUser error: $e');
      return false;
    }
  }

  /// Obtenir les logs de modération automatique
  Future<List<Map<String, dynamic>>> getAutoModerationLogs({int limit = 50}) async {
    try {
      final response = await _client
          .from('auto_moderation_logs')
          .select('*, user:profiles!user_id(id, username)')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getAutoModerationLogs error: $e');
      return [];
    }
  }

  /// Vérifier le contenu avec l'IA (appelle Edge Function)
  Future<Map<String, dynamic>> moderateContent({
    required String text,
    String? contentType,
  }) async {
    try {
      final response = await _client.functions.invoke('moderate-content', body: {
        'text': text,
        'content_type': contentType ?? 'text',
      });

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('🔴 moderateContent error: $e');
      return {
        'is_appropriate': true,
        'confidence': 1.0,
        'categories': [],
        'error': e.toString(),
      };
    }
  }
}