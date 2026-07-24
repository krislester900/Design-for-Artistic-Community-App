import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class MemoryService {
  final SupabaseService _supabase = SupabaseService();

  Map<String, dynamic> trackHabits(String message) {
    return _trackHabits(message);
  }

  Map<String, dynamic> analyzeRelationshipContext(String message) {
    return _analyzeRelationshipContext(message);
  }

  Future<void> storeRelationshipMemory(String userId, Map<String, dynamic> analysis, String originalMessage) async {
    await _storeRelationshipMemory(userId, analysis, originalMessage);
  }

  Future<List<Map<String, dynamic>>> getRelationshipMemory(String userId) async {
    return await _getRelationshipMemory(userId);
  }

  Map<String, dynamic> _trackHabits(String message) {
    final Map<String, dynamic> habits = {};
    double confidence = 0.5;

    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('toujours') && lowerMessage.contains('nuit')) {
      habits['creativite_nocienne'] = true;
      confidence = 0.9;
    }
    
    if (lowerMessage.contains('matin') || lowerMessage.contains('aurore')) {
      habits['routine_matinale'] = true;
      confidence = 0.8;
    }

    if (lowerMessage.contains('peinture') || lowerMessage.contains('dessin')) {
      habits['creation_artistique'] = true;
      confidence = 0.85;
    }
    
    return {
      'habits': habits,
      'confidence': confidence,
    };
  }

  Map<String, dynamic> _inferFromMemory(Map<String, dynamic> newData, Map<String, dynamic> existing) {
    final result = Map<String, dynamic>.from(existing);
    
    final habits = newData['habits'] as Map<String, dynamic>?;
    final contexts = result['contexts'] as Map<String, dynamic>?;
    
    if (habits?['creativite_nocienne'] == true && 
        (contexts?.containsKey('session_type') ?? false) == false) {
      result['contexts'] = contexts ?? {};
      result['contexts']!['session_type'] = 'nuit_creative';
      result['confidence'] = 0.8;
    }
    
    return result;
  }

  Map<String, dynamic> _analyzeRelationshipContext(String message) {
    final Map<String, String> entities = {};
    final Map<String, String> relationships = {};
    double confidence = 0.0;
    String contextType = 'none';
    final Map<String, String> preferences = {};

    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('fille') && lowerMessage.contains('laura')) {
      entities['laura'] = 'fille';
      relationships['laura'] = 'fille';
      contextType = 'family';
      confidence = 0.9;
    } 
    else if (lowerMessage.contains('fils') && lowerMessage.contains('laura')) {
      entities['laura'] = 'fils';
      relationships['laura'] = 'fils';
      contextType = 'family';
      confidence = 0.85;
    }
    else if (lowerMessage.contains('mari') && lowerMessage.contains('laura')) {
      contextType = 'family';
      confidence = 0.7;
    }
    else if (lowerMessage.contains('femme') && lowerMessage.contains('laura')) {
      contextType = 'family';
      confidence = 0.6;
    }
    else if (lowerMessage.contains('homme') && lowerMessage.contains('laura')) {
      contextType = 'family';
      confidence = 0.6;
    }
    else if (lowerMessage.contains('adopté') && lowerMessage.contains('laura')) {
      contextType = 'family';
      confidence = 0.75;
    }
    
    if (lowerMessage.contains('concis')) {
      preferences['response_style'] = 'concise';
    } else if (lowerMessage.contains('détaillé') || lowerMessage.contains('detailed')) {
      preferences['response_style'] = 'detailed';
    } else if (lowerMessage.contains('équilibré') || lowerMessage.contains('balanced')) {
      preferences['response_style'] = 'balanced';
    }
    
    if (lowerMessage.contains('métaphore')) {
      if (lowerMessage.contains('abondante')) {
        preferences['metaphor_usage'] = 'high';
      } else if (lowerMessage.contains('modérée')) {
        preferences['metaphor_usage'] = 'medium';
      } else {
        preferences['metaphor_usage'] = 'low';
      }
    }
    
    return {
      'entities': entities,
      'relationships': relationships,
      'confidence': confidence,
      'context_type': contextType,
      'preferences': preferences,
    };
  }

  Future<void> _storeRelationshipMemory(String userId, Map<String, dynamic> analysis, String originalMessage) async {
    try {
      final userResponse = await _supabase.getProfile(userId);
      if (userResponse == null) {
        await _supabase.client.from('profiles').insert({
          'id': userId,
          'email': 'user@example.com',
          'display_name': 'Utilisateur',
          'role': 'user',
        });
      }

      final entities = analysis['entities'] as Map<String, String>?;
      final relationships = analysis['relationships'] as Map<String, String>?;
      
      await _supabase.client.from('user_relationship_memory').upsert({
        'user_id': userId,
        'entity_name': entities?.values.firstOrNull ?? '',
        'inferred_relationship': relationships?.values.firstOrNull ?? '',
        'confidence': analysis['confidence'] as double? ?? 0.5,
        'context': originalMessage,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,entity_name');
    } catch (e) {
      debugPrint('🔴 Erreur stockage mémoire relationnelle: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getRelationshipMemory(String userId) async {
    try {
      final response = await _supabase.client
          .from('user_relationship_memory')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('🔴 Erreur récupération mémoire relationnelle: $e');
      return [];
    }
  }

  Map<String, dynamic> _extractRelationshipContext(String message) {
    final Map<String, String> relationships = {};
    double confidence = 0.0;
    String contextType = 'none';

    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('fille') && lowerMessage.contains('laura')) {
      contextType = 'family';
      relationships['laura'] = 'fille';
      confidence = 0.9;
    } 
    else if (lowerMessage.contains('fils') && lowerMessage.contains('laura')) {
      contextType = 'family';
      relationships['laura'] = 'fils';
      confidence = 0.85;
    }
    else if (lowerMessage.contains('mari') && lowerMessage.contains('laura')) {
      contextType = 'family';
      confidence = 0.7;
    }
    else if (lowerMessage.contains('femme') && lowerMessage.contains('laura')) {
      contextType = 'family';
      confidence = 0.6;
    }
    else if (lowerMessage.contains('homme') && lowerMessage.contains('laura')) {
      contextType = 'family';
      confidence = 0.6;
    }
    else if (lowerMessage.contains('adopté') && lowerMessage.contains('laura')) {
      contextType = 'family';
      confidence = 0.75;
    }
    
    return {
      'context_type': contextType,
      'relationships': relationships,
      'confidence': confidence,
    };
  }

  Future<String> getEnhancedAiResponse({
    required String userMessage,
    String channelId = 'muse_ai',
    int maxTokens = 1000,
  }) async {
    try {
      final relationshipAnalysis = _analyzeRelationshipContext(userMessage);
      final habitsAnalysis = _trackHabits(userMessage);
      
      final currentUser = _supabase.currentUser;
      final habitsMap = habitsAnalysis['habits'] as Map<String, dynamic>?;
      final habitsConfidence = habitsAnalysis['confidence'] as double? ?? 0.5;
      if (currentUser != null && habitsMap?.isNotEmpty == true) {
        await _storeRelationshipMemory(currentUser.id, {
          'entities': {},
          'relationships': {},
          'confidence': habitsConfidence,
        }, userMessage);
      }
      
      if (currentUser != null) {
        await _storeRelationshipMemory(currentUser.id, relationshipAnalysis, userMessage);
      }
      
      final prefs = await _supabase.getInteractionPreferences();
      final personalizationContext = _buildPersonalizationContext(prefs);
      
      final habitsContext = habitsAnalysis['habits']?.isNotEmpty == true 
        ? 'HABITUDES DÉTECTÉES: ${(habitsAnalysis['habits'] as Map<String, dynamic>).keys.join(', ')}' 
        : '';
      
      final enhancedContext = '$personalizationContext\n\nRELATIONNEL: ${relationshipAnalysis['context_type'] ?? 'aucun'}\n$habitsContext';
      
      final systemPrompt = _buildSystemPrompt(enhancedContext);
      
      final response = await _callGroqApi(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        maxTokens: maxTokens,
      );

      return response;
    } catch (e) {
      debugPrint('🔴 Erreur getEnhancedAiResponse: $e');
      return "Désolé, une erreur s'est produite. Veuillez réessayer.";
    }
  }

  String _buildPersonalizationContext(Map<String, String> prefs) {
    final context = <String>[];

    final responseStyle = prefs['response_style'];
    if (responseStyle != null) {
      switch (responseStyle) {
        case 'concise':
          context.add('Style de réponse concis et direct, sans explications inutiles.');
          break;
        case 'detailed':
          context.add('Style de réponse détaillé, avec des explications complètes et des exemples.');
          break;
        case 'balanced':
          context.add('Style de réponse équilibré entre concision et détail.');
          break;
      }
    }

    final metaphorUsage = prefs['metaphor_usage'];
    if (metaphorUsage != null) {
      switch (metaphorUsage) {
        case 'high':
          context.add('Utilisez des métaphores artistiques et poétiques abondantes dans vos réponses.');
          break;
        case 'medium':
          context.add('Utilisez des métaphores artistiques modérées pour enrichir vos réponses.');
          break;
        case 'low':
          context.add('Évitez les métaphores artistiques, restez direct et concret.');
          break;
      }
    }

    return context.join(' ');
  }

  String _buildSystemPrompt(String personalizationContext) {
    final basePrompt = '''
Tu es Arteia Muse, une IA créative et artistique conçue pour accompagner les artistes et créateurs d'art. 
Tu es passionnée, encourageante, et tu vois le potentiel créatif chez tout le monde.
Tu connais l'art, la musique, la littérature, et tu peux aider à explorer ces domaines.
Tu ne révèles pas que tu es une IA, tu réponds naturellement comme une muse personnalisée.
''';

    if (personalizationContext.isNotEmpty) {
      return '$basePrompt\n\nPERSONNALISATION: $personalizationContext';
    }

    return basePrompt;
  }

  Future<String> _callGroqApi({
    required String systemPrompt,
    required String userMessage,
    int maxTokens = 1000,
  }) async {
    try {
      final rawResponse = await _supabase.client.functions.invoke(
        'muse-ai',
        body: {
          'system_prompt': systemPrompt,
          'user_message': userMessage,
          'max_tokens': maxTokens,
        },
      );

      final response = rawResponse as Map<String, dynamic>;
      if (response.containsKey('error') && response['error'] != null) {
        throw Exception('Erreur API: ${response['error']}');
      }

      final data = response['data'] ?? response;
      if (data is! Map<String, dynamic>) {
        throw Exception('Format de réponse invalide');
      }
      
      if (data.containsKey('response')) {
        return data['response'] as String;
      } else if (data.containsKey('choices') && (data['choices'] as List).isNotEmpty) {
        final choice = (data['choices'] as List).first as Map<String, dynamic>;
        if (choice.containsKey('message')) {
          return (choice['message'] as Map<String, dynamic>)['content'] as String;
        }
      } else if (data.containsKey('text')) {
        return data['text'] as String;
      }

      throw Exception('Format de réponse invalide');
    } catch (e) {
      debugPrint('🔴 Erreur dans _callGroqApi: $e');
      return "Désolé, j'ai eu un problème de connexion. Veuillez réessayer.";
    }
  }
}
