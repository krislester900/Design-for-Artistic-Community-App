import 'package:supabase_flutter/supabase_flutter.dart';

class ApiService {
  final SupabaseClient _client = Supabase.instance.client;

  // Récupérer tous les posts
  Future<List<Map<String, dynamic>>> getPosts() async {
    try {
      final response = await _client
          .from('posts')
          .select('*, profiles(username, avatar_url)')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur getPosts: $e');
      return [];
    }
  }

  // Récupérer les catégories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client
          .from('categories')
          .select()
          .order('name');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur getCategories: $e');
      return [];
    }
  }

  // Récupérer les posts d'une catégorie
  Future<List<Map<String, dynamic>>> getPostsByCategory(String categorySlug) async {
    try {
      final response = await _client
          .from('posts')
          .select('*, profiles(username, avatar_url)')
          .eq('category_slug', categorySlug)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur getPostsByCategory: $e');
      return [];
    }
  }

  // Rechercher des posts
  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    try {
      final response = await _client
          .from('posts')
          .select('*, profiles(username, avatar_url)')
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur searchPosts: $e');
      return [];
    }
  }

  // Récupérer le profil utilisateur
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      return response;
    } catch (e) {
      print('Erreur getUserProfile: $e');
      return null;
    }
  }

  // Créer un post
  Future<void> createPost(Map<String, dynamic> post) async {
    try {
      await _client.from('posts').insert(post);
    } catch (e) {
      print('Erreur createPost: $e');
      rethrow;
    }
  }

  // Ajouter un like
  Future<void> likePost(String postId, String userId) async {
    try {
      await _client.from('likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    } catch (e) {
      print('Erreur likePost: $e');
      rethrow;
    }
  }

  // Supprimer un like
  Future<void> unlikePost(String postId, String userId) async {
    try {
      await _client
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } catch (e) {
      print('Erreur unlikePost: $e');
      rethrow;
    }
  }

  // Vérifier si un post est liké
  Future<bool> isPostLiked(String postId, String userId) async {
    try {
      final response = await _client
          .from('likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', userId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      print('Erreur isPostLiked: $e');
      return false;
    }
  }

  // Récupérer les notifications
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Erreur getNotifications: $e');
      return [];
    }
  }

  // Marquer une notification comme lue
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true})
          .eq('id', notificationId);
    } catch (e) {
      print('Erreur markNotificationAsRead: $e');
      rethrow;
    }
  }
}