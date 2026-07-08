import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class AiAssistantService {
  final SupabaseService _supabase = SupabaseService();
  
  // URL de la Edge Function (à déployer sur Supabase)
  static const String _functionUrl = 'https://wzewlweghntnqyfvhgan.supabase.co/functions/v1/ai-assistant';

  /// Envoie un message à l'assistant et reçoit une réponse
  Future<String> sendMessage({
    required String message,
    String contentType = 'general',
    List<Map<String, String>>? history,
  }) async {
    try {
      final session = _supabase.client.auth.currentSession;
      if (session == null) {
        return _getLocalResponse(message);
      }

      // Construire l'historique des messages
      final messages = <Map<String, String>>[];
      if (history != null) {
        for (final msg in history) {
          messages.add({
            'role': msg['role'] ?? 'user',
            'content': msg['content'] ?? '',
          });
        }
      }
      messages.add({'role': 'user', 'content': message});

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
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply'] as String? ?? _getLocalResponse(message);
      } else {
        // Fallback local si la fonction échoue
        return _getLocalResponse(message);
      }
    } catch (e) {
      // Fallback local en cas d'erreur réseau
      return _getLocalResponse(message);
    }
  }

  /// Envoie un message et retourne texte + éventuelle image
  Future<Map<String, dynamic>> sendMessageWithImage({
    required String message,
    String contentType = 'general',
    List<Map<String, String>>? history,
  }) async {
    try {
      final session = _supabase.client.auth.currentSession;
      if (session == null) {
        return {'text': _getLocalResponse(message), 'image_url': null};
      }

      final messages = <Map<String, String>>[];
      if (history != null) {
        for (final msg in history) {
          messages.add({'role': msg['role'] ?? 'user', 'content': msg['content'] ?? ''});
        }
      }
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse(_functionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'messages': messages,
          'context': {'contentType': contentType, 'userId': _supabase.currentUser?.id},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'text': data['reply'] as String? ?? _getLocalResponse(message),
          'image_url': data['image_url'] as String?,
        };
      }
      return {'text': _getLocalResponse(message), 'image_url': null};
    } catch (e) {
      return {'text': _getLocalResponse(message), 'image_url': null};
    }
  }

  /// Réponses locales sans besoin de backend
  String _getLocalResponse(String message) {
    final lowerMsg = message.toLowerCase();

    if (lowerMsg.contains('bonjour') || lowerMsg.contains('salut') || lowerMsg.contains('coucou')) {
      return 'Bonjour créateur ! ✨ Je suis Arteïa Muse, ton assistant artistique. Comment puis-je t\'inspirer aujourd\'hui ?';
    }
    
    if (lowerMsg.contains('idée') || lowerMsg.contains('inspire') || lowerMsg.contains('propose')) {
      return '🎨 **Idées créatives :**\n\n'
          '**Art visuel** : Essaie un autoportrait avec des formes géométriques minimalistes.\n'
          '**Musique** : Crée une boucle de 4 accords évoquant un lever de soleil.\n'
          '**Écriture** : Écris un micro-poème de 6 mots sur la renaissance créative.\n'
          '**BD** : Dessine une planche muette où le monde passe du N&B à la couleur.\n\n'
          'Quel type de création te tente ?';
    }

    if (lowerMsg.contains('merci')) {
      return 'Avec plaisir ! 🎨 Continue de créer, l\'art est un voyage sans fin. Reviens me voir quand tu veux !';
    }

    if (lowerMsg.contains('feedback') || lowerMsg.contains('retour') || lowerMsg.contains('avis')) {
      return 'Pour te donner un retour personnalisé, pourrais-tu me décrire ton œuvre ? 🎨\n\n'
          '- **Visuel** : Parle-moi des couleurs et de la composition\n'
          '- **Musique** : Décris l\'ambiance et le rythme\n'
          '- **Texte** : Partage quelques phrases\n'
          '- **BD** : Raconte-moi le concept';
    }

    if (lowerMsg.contains('fonctionnalité') || lowerMsg.contains('comment faire') || lowerMsg.contains('aide')) {
      return '🎯 **Fonctionnalités Arteïa :**\n\n'
          '📤 **Publier** → Œuvres visuelles, musique, écriture, BD\n'
          '❤️ **Interagir** → Likes, commentaires, favoris\n'
          '💬 **Chat** → Messages texte, vocaux, éphémères\n'
          '🎵 **Musique** → Lecteur intégré + upload\n'
          '📖 **Lecture** → Mode immersif pour les écrits\n'
          '🏆 **Défis** → Quêtes créatives hebdomadaires\n\n'
          'Que veux-tu savoir ?';
    }

    if (lowerMsg.contains('exercice') || lowerMsg.contains('défi') || lowerMsg.contains('challenge')) {
      return '🔥 **Défi du jour : « 10 minutes chrono »** ⏱️\n\n'
          'Prends un thème au hasard (nature, ville, rêves, émotions) et crée quelque chose en 10 minutes chrono.\n\n'
          'Pas de perfectionnisme ! L\'objectif est de libérer ta créativité sans filtre. 🎨\n\n'
          'Prêt à relever le défi ?';
    }

    if (lowerMsg.contains('qui es-tu') || lowerMsg.contains('tu fais')) {
      return 'Je suis **Arteïa Muse** ✨, l\'assistant créatif officiel d\'Arteïa !\n\n'
          'Je peux :\n'
          '🎨 Générer des idées artistiques\n'
          '💡 Donner des retours constructifs\n'
          '📚 Suggérer des techniques et exercices\n'
          '🔍 Expliquer les fonctionnalités\n\n'
          'De quoi as-tu besoin pour créer aujourd\'hui ?';
    }

    // Réponse par défaut
    return 'Je suis Arteïa Muse ✨, ton assistant créatif !\n\n'
        'Je peux t\'aider à :\n'
        '• Trouver des **idées** créatives 🎨\n'
        '• Donner des **retours** sur tes œuvres 💡\n'
        '• Suggérer des **exercices** et défis 🔥\n'
        '• Expliquer les **fonctionnalités** de l\'app 🔍\n\n'
        'De quoi as-tu envie de parler ?';
  }
}