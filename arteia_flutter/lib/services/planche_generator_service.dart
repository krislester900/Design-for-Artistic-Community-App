import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class PlancheGeneratorService {
  final SupabaseService _supabase = SupabaseService();

  static const String _functionUrl = 'https://wzewlweghntnqyfvhgan.supabase.co/functions/v1/planche-generator';

  Future<List<Map<String, dynamic>>> getStyles() async {
    try {
      final response = await _supabase.client
          .from('ai_manga_styles')
          .select('id, name, slug, mangaka, description, style_tags, sample_image_url, generation_count, training_status')
          .eq('is_active', true)
          .order('generation_count', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getLayouts() async {
    try {
      final response = await _supabase.client
          .from('ai_planche_layouts')
          .select('*')
          .eq('is_active', true)
          .order('id');
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> generatePlanche({
    required String scene,
    required String styleSlug,
    String? layoutType,
    List<Map<String, String>>? characters,
    String? title,
    int pageNumber = 1,
    int totalPages = 1,
  }) async {
    final session = _supabase.client.auth.currentSession;
    if (session == null) {
      return {'error': 'Connecte-toi pour générer une planche'};
    }

    try {
      final body = <String, dynamic>{
        'scene': scene,
        'style_slug': styleSlug,
      };
      if (layoutType != null) body['layout_type'] = layoutType;
      if (characters != null) body['characters'] = characters;
      if (title != null) body['title'] = title;
      body['page_number'] = pageNumber;
      body['total_pages'] = totalPages;

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return {'error': data['error'] ?? 'Erreur (${response.statusCode})'};
    } catch (e) {
      return {'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> getPlancheStatus(int plancheId) async {
    try {
      final response = await http.get(
        Uri.parse('$_functionUrl?planche_id=$plancheId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'status': 'unknown'};
    } catch (e) {
      return {'status': 'error', 'error': '$e'};
    }
  }

  Future<List<Map<String, dynamic>>> getMyPlanches({int limit = 20}) async {
    try {
      final response = await _supabase.client
          .from('ai_planches')
          .select('*')
          .eq('user_id', _supabase.currentUser?.id ?? '')
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }
}
