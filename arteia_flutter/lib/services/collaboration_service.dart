import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class CollaborationService {
  final SupabaseService _supabase = SupabaseService();
  SupabaseClient get _client => Supabase.instance.client;
  static final CollaborationService _instance = CollaborationService._();
  factory CollaborationService() => _instance;
  CollaborationService._();

  /// Créer un projet collaboratif
  Future<Map<String, dynamic>> createProject({
    required String title,
    required String description,
    required String category,
    required List<String> roles,
    int maxCollaborators = 5,
    String? coverImageUrl,
    List<String>? tags,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    try {
      final response = await _client.from('collaboration_projects').insert({
        'title': title,
        'description': description,
        'creator_id': user.id,
        'category': category,
        'roles': roles,
        'max_collaborators': maxCollaborators,
        'cover_image_url': coverImageUrl ?? '',
        'tags': tags ?? [],
        'status': 'open',
        'is_open': true,
      }).select().maybeSingle();

      return response as Map<String, dynamic>? ?? {};
    } catch (e) {
      print('🔴 createProject error: $e');
      rethrow;
    }
  }

  /// Obtenir les projets ouverts
  Future<List<Map<String, dynamic>>> getOpenProjects({String? category}) async {
    try {
      var filter = _client
          .from('collaboration_projects')
          .select('*, creator:profiles!creator_id(id, username, avatar_url, level)');

      if (category != null) {
        filter = filter.eq('category', category);
      }
      filter = filter.eq('is_open', true);
      final response = await filter.order('created_at', ascending: false).limit(50);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getOpenProjects error: $e');
      return [];
    }
  }

  /// Obtenir les projets de l'utilisateur
  Future<List<Map<String, dynamic>>> getUserProjects() async {
    final user = _supabase.currentUser;
    if (user == null) return [];

    try {
      final response = await _client
          .from('collaboration_projects')
          .select('*, creator:profiles!creator_id(id, username, avatar_url)')
          .or('creator_id.eq.${user.id},and(contributors.cs.{${user.id}})')
          .order('updated_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getUserProjects error: $e');
      return [];
    }
  }

  /// Postuler à un projet
  Future<bool> applyToProject({
    required String projectId,
    required String role,
    String? message,
    String? portfolioUrl,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) throw Exception('Session requise.');

    try {
      await _client.from('collaboration_applications').insert({
        'project_id': projectId,
        'applicant_id': user.id,
        'role': role,
        'message': message ?? '',
        'portfolio_url': portfolioUrl ?? '',
        'status': 'pending',
      });
      return true;
    } catch (e) {
      print('🔴 applyToProject error: $e');
      return false;
    }
  }

  /// Accepter/Rejeter une candidature
  Future<bool> processApplication(String applicationId, String status) async {
    try {
      await _client.from('collaboration_applications').update({
        'status': status,
      }).eq('id', applicationId);

      // Si accepté, ajouter comme contributeur
      if (status == 'accepted') {
        final app = await _client
            .from('collaboration_applications')
            .select('project_id, applicant_id, role')
            .eq('id', applicationId)
            .maybeSingle();

        if (app != null) {
          await _client.from('collaboration_contributors').insert({
            'project_id': app['project_id'],
            'user_id': app['applicant_id'],
            'role': app['role'],
          });
        }
      }

      return true;
    } catch (e) {
      print('🔴 processApplication error: $e');
      return false;
    }
  }

  /// Envoyer un message dans le projet
  Future<bool> sendMessage(String projectId, String message, {String? attachmentUrl}) async {
    final user = _supabase.currentUser;
    if (user == null) return false;

    try {
      await _client.from('collaboration_messages').insert({
        'project_id': projectId,
        'user_id': user.id,
        'message': message,
        'attachment_url': attachmentUrl ?? '',
      });
      return true;
    } catch (e) {
      print('🔴 sendMessage error: $e');
      return false;
    }
  }

  /// Obtenir les messages d'un projet
  Future<List<Map<String, dynamic>>> getMessages(String projectId) async {
    try {
      final response = await _client
          .from('collaboration_messages')
          .select('*, user:profiles!user_id(id, username, avatar_url)')
          .eq('project_id', projectId)
          .order('created_at', ascending: true);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getMessages error: $e');
      return [];
    }
  }

  /// Obtenir les candidatures d'un projet
  Future<List<Map<String, dynamic>>> getApplications(String projectId) async {
    try {
      final response = await _client
          .from('collaboration_applications')
          .select('*, applicant:profiles!applicant_id(id, username, avatar_url, level)')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getApplications error: $e');
      return [];
    }
  }

  /// Obtenir les contributeurs d'un projet
  Future<List<Map<String, dynamic>>> getContributors(String projectId) async {
    try {
      final response = await _client
          .from('collaboration_contributors')
          .select('*, user:profiles!user_id(id, username, avatar_url, level)')
          .eq('project_id', projectId);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      print('🔴 getContributors error: $e');
      return [];
    }
  }

  /// Mettre à jour le statut du projet
  Future<bool> updateProjectStatus(String projectId, String status) async {
    try {
      await _client.from('collaboration_projects').update({
        'status': status,
        'is_open': status == 'open',
        'completed_at': status == 'completed' ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', projectId);
      return true;
    } catch (e) {
      print('🔴 updateProjectStatus error: $e');
      return false;
    }
  }
}