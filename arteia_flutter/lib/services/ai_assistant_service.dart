import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';
import 'memory_service.dart';

class AiAssistantService {
  final SupabaseService _supabase = SupabaseService();
  final MemoryService _memory = MemoryService();

  // ==================== API GRATUITES ====================
  
  // Groq (100% gratuit, ultra rapide) - PRIORITAIRE
  // Clé API de Krislester (https://console.groq.com)
  static const String _groqApiKey = ''; // Clé Krislester
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  // Hugging Face (100% gratuit, limité)
  // Inscrivez-vous sur https://huggingface.co pour obtenir un token
  static const String _hfApiKey = ''; // Ajoutez votre token HuggingFace ici
  static const String _hfUrl = 'https://api-inference.huggingface.co/models/mistralai/Mistral-7B-Instruct-v0.3';
  
  // Ollama (serveur local ou cloud)
  static const String _ollamaUrl = 'http://localhost:11434/api/chat';
  static const String _ollamaUrlBackup = 'http://localhost:11434/api/chat';
  
  // Supabase Edge Function (fallback)
  static const String _functionUrl = 'https://wzewlweghntnqyfvhgan.supabase.co/functions/v1/ai-assistant';
  
  // RAG : Base de connaissances
  static const int _ragTopK = 3; // Nombre de connaissances à récupérer
  
  // Modèle principal : Qwen 2.5 Coder 7B (gratuit, rapide, performant)
  static const _modelPriority = [
    'qwen2.5-coder:7b',  // Modèle principal pour le code et l'IA
  ];

  String _selectModel(String message) {
    // Toujours utiliser Qwen 2.5 Coder 7B
    return 'qwen2.5-coder:7b';
  }

  bool _needsWebSearch(String message) {
    final m = message.toLowerCase();
    if (m.contains('nouvelle') || m.contains('actualité') || m.contains('dernier') ||
        m.contains('récents') || m.contains('news') || m.contains('info') ||
        m.contains('aujourd\'hui') || m.contains('2024') || m.contains('2025') ||
        m.contains('2026') || m.contains('2027') ||
        m.contains('qui est') || m.contains('qu\'est-ce que') || m.contains('c\'est quoi') ||
        m.contains('définition') || m.contains('défini') ||
        m.contains('histoire de') || m.contains('origine') ||
        m.contains('population') || m.contains('capitale') || m.contains('président') ||
        m.contains('récent') || m.contains('découverte') || m.contains('invention') ||
        m.contains('météo') || m.contains('heure') || m.contains('date') ||
        m.contains('latest') || m.contains('current') ||
        m.contains('who is') || m.contains('what is') || m.contains('definition') ||
        m.contains('history of') || m.contains('capital of') || m.contains('president of') ||
        m.contains('population of') || m.contains('weather') || m.contains('time in')) {
      return true;
    }
    return false;
  }

  /// Détecte si la question est factuelle (nécessite une recherche web)
  bool _isFactualQuestion(String message) {
    final m = message.toLowerCase().trim();
    // Question avec ? ou mots interrogatifs
    if (m.contains('?') || m.contains('qui') || m.contains('quoi') || m.contains('comment') ||
        m.contains('pourquoi') || m.contains('quand') || m.contains('où') || m.contains('combien') ||
        m.contains('what') || m.contains('when') || m.contains('where') || m.contains('how') ||
        m.contains('why') || m.contains('who') || m.contains('which')) {
      return true;
    }
    // Question courte (moins de 15 mots)
    final wordCount = m.split(' ').where((w) => w.isNotEmpty).length;
    if (wordCount <= 15 && (m.contains('est') || m.contains('sont') || m.contains('c\'est') || m.contains('ce sont'))) {
      return true;
    }
    return false;
  }

  Future<String?> _searchWeb(String query) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.duckduckgo.com/?q=${Uri.encodeQueryComponent(query)}&format=json&skip_disambig=1'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = <String>[];
        final answer = data['Answer'] as String?;
        final abstract = data['AbstractText'] as String?;
        final source = data['AbstractSource'] as String?;

        if (answer != null && answer.isNotEmpty) results.add('Réponse: $answer');
        if (abstract != null && abstract.isNotEmpty) results.add('$abstract');
        if (source != null && source.isNotEmpty) results.add('Source: $source');

        final topics = data['RelatedTopics'] as List<dynamic>?;
        if (topics != null) {
          for (final topic in topics) {
            if (topic is Map<String, dynamic>) {
              final text = topic['Text'] as String?;
              if (text != null && text.isNotEmpty) {
                results.add('- $text');
                if (results.length >= 6) break;
              }
            }
          }
        }

        if (results.isNotEmpty) return results.join('\n');
      }
    } catch (_) {}
    return null;
  }

  Future<String> sendMessage({
    required String message,
    String contentType = 'general',
    List<Map<String, String>>? history,
  }) async {
    if (message.trim().isEmpty) return '';

    String? userId;
    Map<String, String> prefs = {};
    List<Map<String, dynamic>> relationshipMemory = [];
    Map<String, dynamic> habitsAnalysis = {'habits': <String, dynamic>{}, 'confidence': 0.5};

    try {
      userId = _supabase.currentUser?.id;
      if (userId != null) {
        prefs = await _supabase.getInteractionPreferences();
        relationshipMemory = await _memory.getRelationshipMemory(userId);
      }
      habitsAnalysis = _memory.trackHabits(message);
    } on Exception catch (_) {
      // Supabase not initialized or unavailable; continue without personalization
    } catch (_) {
      // Supabase not initialized or unavailable; continue without personalization
    }

    final personalizationContext = _buildPersonalizationContext(prefs, relationshipMemory, habitsAnalysis);

    // 1. RAG : Récupérer les connaissances pertinentes
    final relevantKnowledge = await _getRelevantKnowledge(message, contentType);
    
    // 2. Recherche web SYSTÉMATIQUE pour les questions factuelles
    String? webResults;
    if (_needsWebSearch(message) || _isFactualQuestion(message)) {
      webResults = await _searchWeb(message);
    }

    // 3. Essayer Groq (100% gratuit, ultra rapide) avec résultats web
    if (_groqApiKey.isNotEmpty) {
      try {
        final groqResponse = await _tryGroq(message, history, relevantKnowledge, webResults, personalizationContext);
        if (groqResponse != null) {
          await _saveConversation(message, groqResponse, contentType);
          await _updateMemoryFromMessage(message, userId);
          return groqResponse;
        }
      } catch (_) {}
    }

    // 4. Essayer Hugging Face (100% gratuit)
    if (_hfApiKey.isNotEmpty) {
      try {
        final hfResponse = await _tryHuggingFace(message, relevantKnowledge);
        if (hfResponse != null) {
          await _saveConversation(message, hfResponse, contentType);
          await _updateMemoryFromMessage(message, userId);
          return hfResponse;
        }
      } catch (_) {}
    }

    // 5. Essayer Ollama (si serveur disponible)
    try {
      final ollamaResponse = await _tryOllama(message, contentType, history, relevantKnowledge, webResults, personalizationContext);
      if (ollamaResponse != null) {
        await _saveConversation(message, ollamaResponse, contentType);
        await _updateMemoryFromMessage(message, userId);
        return ollamaResponse;
      }
    } catch (_) {}

    // 6. Fallback : Edge Function Supabase
    try {
      final session = _supabase.client.auth.currentSession;
      if (session != null) {
        final messages = <Map<String, String>>[];
        if (history != null) {
          for (final msg in history) {
            messages.add({'role': msg['role'] ?? 'user', 'content': msg['content'] ?? ''});
          }
        }
        
        final enrichedMessage = _enrichWithRAG(message, relevantKnowledge);
        messages.add({'role': 'user', 'content': enrichedMessage});

        final response = await http.post(
          Uri.parse(_functionUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${session.accessToken}',
          },
          body: jsonEncode({
            'messages': messages,
            'context': {
              'contentType': contentType,
              'userId': _supabase.currentUser?.id,
              'userName': _supabase.currentUser?.userMetadata?['full_name'] ?? _supabase.currentUser?.email,
              'ragContext': relevantKnowledge.map((k) => k['content']).toList(),
              'preferences': prefs,
              'relationshipMemory': relationshipMemory,
              'habits': habitsAnalysis['habits'],
            },
          }),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final reply = data['reply'] as String?;
          if (reply != null && reply.isNotEmpty) {
            await _saveConversation(message, reply, contentType);
            await _updateMemoryFromMessage(message, userId);
            return reply;
          }
        }
      }
    } catch (_) {}

    // 7. Fallback final : réponse locale améliorée avec RAG
    final localResponse = _getLocalResponse(message, relevantKnowledge, personalizationContext);
    await _saveConversation(message, localResponse, contentType);
    await _updateMemoryFromMessage(message, userId);
    return localResponse;
  }

  Future<Map<String, dynamic>> sendMessageWithImage({
    required String message,
    String contentType = 'general',
    List<Map<String, String>>? history,
  }) async {
    final text = await sendMessage(message: message, contentType: contentType, history: history);
    return {'text': text, 'image_url': null, 'planche_id': null};
  }

  // ==================== GROQ (100% GRATUIT, ULTRA RAPIDE) ====================

  Future<String?> _tryGroq(
    String message,
    List<Map<String, String>>? history,
    List<Map<String, dynamic>> knowledge,
    String? webResults,
    String personalizationContext,
  ) async {
    if (_groqApiKey.isEmpty) return null;

    try {
      final messages = <Map<String, dynamic>>[];
      
      final systemContent = StringBuffer();
      systemContent.write('Tu es Arteïa Muse, une IA créative pour artistes.');
      systemContent.write(' Tu parles français, ton style est poétique, visuel et inspirant.');
      systemContent.write(' Tu réponds en 2-3 phrases max, avec des métaphores artistiques quand c\'est pertinent.');
      systemContent.write(' Tu ne donnes pas de longs blocs de texte : préfère des phrases rythmées, imagées, musicales.');
      systemContent.write(' Si on te demande du code, donne un exemple court et commenté.');
      systemContent.write(' Si des résultats web sont fournis, utilise-les pour répondre précisément.');
      
      if (personalizationContext.isNotEmpty) {
        systemContent.write('\n\nContexte personnalisé : $personalizationContext');
      }
      
      if (knowledge.isNotEmpty) {
        systemContent.write('\n\nConnaissances :\n');
        for (final k in knowledge.take(2)) {
          systemContent.write('- ${k['title']}: ${k['content']}\n');
        }
      }

      if (webResults != null && webResults.isNotEmpty) {
        systemContent.write('\n\nRésultats web :\n');
        systemContent.write(webResults);
        systemContent.write('\n\nBase-toi sur ces résultats pour répondre précisément.');
      }

      messages.add({'role': 'system', 'content': systemContent.toString()});

      if (history != null) {
        for (final msg in history.take(10)) {
          final role = msg['role'] == 'assistant' ? 'assistant' : 'user';
          messages.add({'role': role, 'content': msg['content'] ?? ''});
        }
      }
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant', // Modèle rapide et gratuit
          'messages': messages,
          'temperature': 0.8, // Plus créatif et adaptatif
          'max_tokens': 1000, // Réponses plus longues et complètes
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['choices']?[0]?['message']?['content'] as String?;
        if (content != null && content.isNotEmpty) return content;
      }
    } catch (_) {}
    return null;
  }

  // ==================== HUGGING FACE (100% GRATUIT) ====================

  Future<String?> _tryHuggingFace(
    String message,
    List<Map<String, dynamic>> knowledge,
  ) async {
    if (_hfApiKey.isEmpty) return null;

    try {
      // Construire le prompt
      final prompt = StringBuffer();
      if (knowledge.isNotEmpty) {
        prompt.write('Contexte : ${knowledge.first['content']}\n\n');
      }
      prompt.write('Utilisateur : $message\nAssistant :');

      final response = await http.post(
        Uri.parse(_hfUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_hfApiKey',
        },
        body: jsonEncode({
          'inputs': prompt.toString(),
          'parameters': {
            'max_length': 500,
            'temperature': 0.7,
            'top_p': 0.9,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        if (data.isNotEmpty) {
          final generated = data[0]['generated_text'] as String?;
          if (generated != null && generated.isNotEmpty) {
            // Extraire seulement la réponse de l'assistant
            final parts = generated.split('Assistant :');
            if (parts.length > 1) return parts.last.trim();
            return generated;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  // ==================== OLLAMA (LLM LOCAL/CLOUD) ====================

  Future<String?> _tryOllama(
    String message,
    String contentType,
    List<Map<String, String>>? history,
    List<Map<String, dynamic>> knowledge,
    String? webResults,
    String personalizationContext,
  ) async {
    final preferredModel = _selectModel(message);
    final urls = [_ollamaUrl, _ollamaUrlBackup];

    for (final baseUrl in urls) {
      for (final model in _buildModelList(preferredModel)) {
        try {
          final ollamaMessages = <Map<String, dynamic>>[];
          
          final systemContent = StringBuffer();
          systemContent.write('Tu es Arteïa Muse, une IA créative pour artistes.');
          systemContent.write(' Tu parles français, ton style est poétique, visuel et inspirant.');
          systemContent.write(' Tu réponds en 2-3 phrases max, avec des métaphores artistiques quand c\'est pertinent.');
          systemContent.write(' Tu ne donnes pas de longs blocs de texte : préfère des phrases rythmées, imagées, musicales.');
          systemContent.write(' Si on te demande du code, donne un exemple court et commenté.');
          
          if (personalizationContext.isNotEmpty) {
            systemContent.write('\n\nContexte personnalisé : $personalizationContext');
          }
          
          if (knowledge.isNotEmpty) {
            systemContent.write('\n\nConnaissances :\n');
            for (final k in knowledge.take(2)) {
              systemContent.write('- ${k['title']}: ${k['content']}\n');
            }
          }

          ollamaMessages.add({'role': 'system', 'content': systemContent.toString()});

          if (history != null) {
            for (final msg in history.take(10)) {
              final role = msg['role'] == 'assistant' ? 'assistant' : 'user';
              ollamaMessages.add({'role': role, 'content': msg['content'] ?? ''});
            }
          }
          ollamaMessages.add({'role': 'user', 'content': message});

          final response = await http.post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'messages': ollamaMessages,
              'stream': false,
              'options': {
                'temperature': 0.7,
                'num_ctx': 2048,
                'num_predict': 500,
              },
            }),
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final content = data['message']?['content'] as String?;
            if (content != null && content.isNotEmpty) return content;
          }
        } catch (_) {}
      }
    }
    return null;
  }

  List<String> _buildModelList(String preferred) {
    final list = <String>[];
    list.add(preferred);
    for (final model in _modelPriority) {
      if (model != preferred) list.add(model);
    }
    return list;
  }

  // ==================== RAG (Retrieval-Augmented Generation) ====================

  /// Récupérer les connaissances pertinentes depuis la base de connaissances
  Future<List<Map<String, dynamic>>> _getRelevantKnowledge(String message, String category) async {
    try {
      final keywords = message.toLowerCase().split(' ').where((w) => w.length > 3).toList();
      
      if (keywords.isEmpty) return [];

      // Recherche simple par mots-clés (peut être amélioré avec des embeddings)
      final response = await _supabase.client
          .from('ai_knowledge_base')
          .select('id, title, content, category, usage_count, helpful_count')
          .eq('category', category)
          .or('title.ilike.%${keywords.first}%,content.ilike.%${keywords.first}%')
          .order('helpful_count', ascending: false)
          .limit(_ragTopK);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Enrichir le message avec le contexte RAG
  String _enrichWithRAG(String message, List<Map<String, dynamic>> knowledge) {
    if (knowledge.isEmpty) return message;

    final context = knowledge.map((k) {
      final title = k['title'] ?? '';
      final content = k['content'] ?? '';
      return '[$title] $content';
    }).join('\n\n');

    return 'Contexte de connaissances pertinentes :\n$context\n\nQuestion de l\'utilisateur : $message';
  }

  /// Enregistrer la conversation dans la base de données
  Future<void> _saveConversation(String userMessage, String assistantReply, String category) async {
    try {
      final session = _supabase.client.auth.currentSession;
      if (session == null) return;

      await _supabase.client.from('ai_conversations').insert({
        'user_id': session.user.id,
        'category': category,
        'user_message': userMessage,
        'assistant_reply': assistantReply,
        'model_used': 'qwen3:8b', // Peut être amélioré
        'response_time_ms': 0, // À mesurer
      });
    } catch (e) {
      // Silencieux : ne pas bloquer la conversation si l'enregistrement échoue
    }
  }

  /// Enregistrer le feedback utilisateur
  Future<void> submitFeedback({
    required String conversationId,
    required int rating,
    bool isHelpful = true,
    String? feedbackText,
  }) async {
    try {
      final session = _supabase.client.auth.currentSession;
      if (session == null) return;

      await _supabase.client.from('ai_feedback').insert({
        'user_id': session.user.id,
        'conversation_id': int.tryParse(conversationId),
        'rating': rating,
        'is_helpful': isHelpful,
        'feedback_text': feedbackText,
      });
    } catch (e) {
      print('Erreur feedback: $e');
    }
  }

  // ==================== RÉPONSES LOCALES AMÉLIORÉES ====================

  String _getLocalResponse(String message, List<Map<String, dynamic>> knowledge, [String personalizationContext = '']) {
    final m = message.toLowerCase().trim();

    if (knowledge.isNotEmpty) {
      final bestMatch = knowledge.first;
      final content = bestMatch['content'] ?? '';
      if (content.isNotEmpty) {
        return '$content\n\n— Source : ${bestMatch['title']}';
      }
    }

    if (m.contains('1+1') || m.contains('1 + 1')) {
      return '1 + 1 = 2 ! C\'est la base des mathématiques 🧮';
    }
    
    final calcRegex = RegExp(r'^[\d\s\+\-\*\/\(\)\.]+$');
    if (m.replaceAll(' ', '').length < 20 && calcRegex.hasMatch(m.replaceAll(' ', ''))) {
      try {
        final sanitized = m.replaceAll(' ', '');
        if (sanitized.contains('+') || sanitized.contains('-') || sanitized.contains('*') || sanitized.contains('/')) {
          if (m.contains('+')) {
            final parts = m.split('+');
            if (parts.length == 2) {
              final a = double.tryParse(parts[0].trim());
              final b = double.tryParse(parts[1].trim());
              if (a != null && b != null) {
                final result = a + b;
                return '$a + $b = ${result == result.toInt() ? result.toInt() : result}';
              }
            }
          }
        }
      } catch (_) {}
    }

    if (m.contains('bonjour') || m.contains('salut') || m.contains('coucou') || m.contains('hey') || m.contains('hello')) {
      return 'Hé ! Ravie de te retrouver ✨';
    }

    if (m.contains('idée') || m.contains('inspire') || m.contains('inspiration')) {
      final ideas = [
        'Et si tu faisais un autoportrait… mais uniquement avec des formes géométriques ?',
        '4 accords, un lever de soleil en tête. Commence en mineur, termine en majeur.',
        'Un micro-poème de 6 mots sur la première fois que tu as créé quelque chose qui t\'a surpris.',
        'Une planche muette : un personnage découvre un monde en noir et blanc — chaque chose qu\'il touche prend vie en couleur.',
        'Dessine ton état d\'esprit actuel sous forme de paysage imaginaire.',
      ];
      return ideas[m.hashCode.abs() % ideas.length];
    }

    if (m.contains('merci') || m.contains('thanks')) {
      return 'Avec plaisir !';
    }

    if (m.contains('manga') || m.contains('animé') || m.contains('anime')) {
      return 'Ah, un(e) passionné(e) de manga ! Ce qui rend ce medium si puissant, c\'est cette capacité à faire passer des émotions énormes avec quelques traits bien placés.';
    }

    if (m.contains('qui es-tu') || m.contains('qui es tu') || m.contains('ton nom') || m.contains('comment tu t\'appelles')) {
      return 'Je suis Arteïa Muse, ton assistant créatif personnel ! Je suis là pour t\'inspirer, te conseiller et t\'aider dans tes projets artistiques ✨';
    }

    if (m.contains('que peux-tu faire') || m.contains('que sais-tu faire') || m.contains('comment tu fonctionnes')) {
      return 'Je peux te donner des idées créatives, des conseils artistiques, t\'aider avec l\'écriture, le dessin, la musique, et bien plus encore ! Pose-moi n\'importe quelle question ! 🎨';
    }

    final wordCount = m.split(' ').where((w) => w.isNotEmpty).length;
    if (wordCount <= 3 && !m.contains('?')) {
      return 'Intéressant ! Peux-tu me donner plus de détails pour que je puisse mieux t\'aider ?';
    }

    return 'Je comprends ta question. Peux-tu me donner plus de détails ? Je suis là pour t\'aider avec tes projets créatifs 🎨';
  }

  String _buildPersonalizationContext(
    Map<String, String> prefs,
    List<Map<String, dynamic>> relationshipMemory,
    Map<String, dynamic> habitsAnalysis,
  ) {
    final context = <String>[];

    final responseStyle = prefs['response_style'];
    if (responseStyle != null) {
      switch (responseStyle) {
        case 'concise':
          context.add('Style de réponse concis et direct.');
          break;
        case 'detailed':
          context.add('Style de réponse détaillé et complet.');
          break;
        case 'balanced':
          context.add('Style de réponse équilibré.');
          break;
      }
    }

    final metaphorUsage = prefs['metaphor_usage'];
    if (metaphorUsage != null) {
      switch (metaphorUsage) {
        case 'high':
          context.add('Utilise des métaphores artistiques abondantes.');
          break;
        case 'medium':
          context.add('Utilise des métaphores artistiques modérées.');
          break;
        case 'low':
          context.add('Évite les métaphores artistiques, reste direct.');
          break;
      }
    }

    final habits = habitsAnalysis['habits'] as Map<String, dynamic>?;
    if (habits != null && habits.isNotEmpty) {
      final labels = habits.keys.join(', ');
      context.add('Habitudes détectées : $labels');
    }

    if (relationshipMemory.isNotEmpty) {
      final relations = relationshipMemory.map((r) => r['entity_name'] ?? '').where((e) => e.isNotEmpty).toList();
      if (relations.isNotEmpty) {
        context.add('Contexte relationnel : ${relations.join(', ')}');
      }
    }

    return context.join(' | ');
  }

  Future<void> _updateMemoryFromMessage(String message, String? userId) async {
    if (userId == null || userId.isEmpty) return;
    try {
      final relationshipAnalysis = _memory.analyzeRelationshipContext(message);
      final habitsAnalysis = _memory.trackHabits(message);
      
      await _memory.storeRelationshipMemory(userId, relationshipAnalysis, message);
      
      final habitsMap = habitsAnalysis['habits'] as Map<String, dynamic>?;
      final habitsConfidence = habitsAnalysis['confidence'] as double? ?? 0.5;
      if (habitsMap != null && habitsMap.isNotEmpty) {
        await _memory.storeRelationshipMemory(userId, {
          'entities': {},
          'relationships': {},
          'confidence': habitsConfidence,
        }, message);
      }
    } catch (_) {}
  }
}
