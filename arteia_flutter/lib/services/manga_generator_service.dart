import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class MangaGeneratorService {
  final SupabaseService _supabase = SupabaseService();

  static const String _functionUrl = 'https://wzewlweghntnqyfvhgan.supabase.co/functions/v1/manga-generator';
  static const String _trainUrl = 'https://wzewlweghntnqyfvhgan.supabase.co/functions/v1/manga-trainer';

  Future<List<Map<String, dynamic>>> getStyles() async {
    try {
      final response = await _supabase.client
          .from('ai_training_stats')
          .select('*')
          .order('reference_count', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      try {
        final response = await _supabase.client
            .from('ai_manga_styles')
            .select('id, name, slug, mangaka, description, style_tags, sample_image_url, generation_count, training_status, reference_count, lora_url')
            .eq('is_active', true)
            .order('generation_count', ascending: false);
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {
        return [];
      }
    }
  }

  Future<Map<String, dynamic>?> getGlobalStats() async {
    try {
      final response = await _supabase.client
          .from('ai_global_stats')
          .select('*')
          .limit(1);
      if (response.isNotEmpty) return response[0] as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getMyGenerations({int limit = 20}) async {
    try {
      final response = await _supabase.client
          .from('ai_generations')
          .select('id, prompt, image_url, style_id, is_liked, likes_count, created_at')
          .eq('user_id', _supabase.currentUser?.id ?? '')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> generate({
    required String prompt,
    required String styleSlug,
  }) async {
    final session = _supabase.client.auth.currentSession;
    if (session == null) {
      return {'error': 'Connecte-toi pour générer des images'};
    }

    try {
      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'prompt': prompt,
          'style_slug': styleSlug,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'error': data['error'] ?? 'Erreur de génération (${response.statusCode})'};
    } catch (e) {
      return {'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> checkStatus(String predictionId) async {
    try {
      final response = await http.get(
        Uri.parse('$_functionUrl?prediction_id=$predictionId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'status': 'unknown'};
    } catch (e) {
      return {'status': 'error', 'error': '$e'};
    }
  }

  Future<void> toggleLike(int generationId, bool currentlyLiked) async {
    try {
      await _supabase.client
          .from('ai_generations')
          .update({'is_liked': !currentlyLiked, 'likes_count': currentlyLiked ? 0 : 1})
          .eq('id', generationId);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> getTrainingStatus(String slug) async {
    try {
      final styleRes = await _supabase.client.from('ai_manga_styles').select('id').eq('slug', slug).limit(1).single();
      final styleId = styleRes['id'] as int;

      final refs = await _supabase.client
          .from('ai_manga_references')
          .select('id, image_url, used_in_training, downloaded, created_at')
          .eq('style_id', styleId)
          .order('created_at', ascending: false);

      final jobList = await _supabase.client
          .from('ai_training_jobs')
          .select('*')
          .eq('style_id', styleId)
          .order('created_at', ascending: false)
          .limit(1);
      final job = jobList.isNotEmpty ? jobList[0] : null;

      return {'references': List<Map<String, dynamic>>.from(refs), 'job': job};
    } catch (e) {
      return {'references': <Map<String, dynamic>>[], 'job': null};
    }
  }

  Future<void> addReference(String slug, String imageUrl) async {
    final session = _supabase.client.auth.currentSession;
    if (session == null) return;
    await http.post(
      Uri.parse(_trainUrl),
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${session.accessToken}' },
      body: jsonEncode({ 'action': 'add_reference', 'style_slug': slug, 'image_url': imageUrl }),
    );
  }

  Future<Map<String, dynamic>> startTraining(String slug) async {
    final session = _supabase.client.auth.currentSession;
    if (session == null) return {'error': 'Non connecté'};
    final response = await http.post(
      Uri.parse(_trainUrl),
      headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${session.accessToken}' },
      body: jsonEncode({ 'action': 'start_training', 'style_slug': slug }),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
