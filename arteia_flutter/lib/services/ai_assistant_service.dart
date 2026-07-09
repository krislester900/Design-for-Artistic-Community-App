import 'dart:convert';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

class AiAssistantService {
  final SupabaseService _supabase = SupabaseService();

  static const String _functionUrl = 'https://wzewlweghntnqyfvhgan.supabase.co/functions/v1/ai-assistant';

  Future<String> sendMessage({
    required String message,
    String contentType = 'general',
    List<Map<String, String>>? history,
  }) async {
    try {
      final session = _supabase.client.auth.currentSession;
      if (session == null) return _getLocalResponse(message);

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
          'context': {
            'contentType': contentType,
            'userId': _supabase.currentUser?.id,
            'userName': _supabase.currentUser?.userMetadata?['full_name'] ?? _supabase.currentUser?.email,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply'] as String? ?? _getLocalResponse(message);
      }
      return _getLocalResponse(message);
    } catch (_) {
      return _getLocalResponse(message);
    }
  }

  Future<Map<String, dynamic>> sendMessageWithImage({
    required String message,
    String contentType = 'general',
    List<Map<String, String>>? history,
  }) async {
    try {
      final session = _supabase.client.auth.currentSession;
      if (session == null) return {'text': _getLocalResponse(message), 'image_url': null, 'planche_id': null};

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
          'context': {
            'contentType': contentType,
            'userId': _supabase.currentUser?.id,
            'userName': _supabase.currentUser?.userMetadata?['full_name'] ?? _supabase.currentUser?.email,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return {
          'text': data['reply'] as String? ?? _getLocalResponse(message),
          'image_url': data['image_url'] as String?,
          'planche_id': data['planche_id'] as String?,
        };
      }
      return {'text': _getLocalResponse(message), 'image_url': null, 'planche_id': null};
    } catch (_) {
      return {'text': _getLocalResponse(message), 'image_url': null, 'planche_id': null};
    }
  }

  String _getLocalResponse(String message) {
    final m = message.toLowerCase();

    if (m.contains('bonjour') || m.contains('salut') || m.contains('coucou') || m.contains('hey')) {
      return 'Hé ! Ravie de te retrouver ✨ Dis-moi, qu\'est-ce qui te traverse l\'esprit créatif aujourd\'hui ?';
    }

    if (m.contains('idée') || m.contains('inspire') || m.contains('inspiration')) {
      return 'Et si tu faisais un autoportrait… mais uniquement avec des formes géométriques ? '
          'Parfois, se limiter libère. Sinon, j\'ai aussi des pistes en musique ou en écriture. '
          'Ça te parle ?';
    }

    if (m.contains('merci')) {
      return 'C\'est tout moi 🌸 Reviens quand tu veux, je suis là. Et surtout : continue de créer, '
          'même imparfait. C\'est comme ça qu\'on grandit.';
    }

    if (m.contains('feedback') || m.contains('retour') || m.contains('avis') || m.contains('critique')) {
      return 'Avec plaisir. Décris-moi ce que tu as créé — je te promets un retour sincère, '
          'pas juste des compliments. Parle-moi de ce que tu cherchais à exprimer.';
    }

    if (m.contains('triste') || m.contains('bloqué') || m.contains('découragé') || m.contains('frustré')) {
      return 'Je t\'entends. Le blocage créatif, c\'est pas un défaut — c\'est un signe que quelque chose '
          'veut sortir mais trouve pas son chemin. Change d\'outil : si tu dessines sur tablette, '
          'prends un crayon. 5 minutes, sans pression. Et si ça ne vient toujours pas, '
          'c\'est peut-être juste un signe qu\'il faut remplir le réservoir.';
    }

    if (m.contains('manga') || m.contains('animé') || m.contains('anime')) {
      return 'Ah, un(e) passionné(e) de manga ! Ce que j\'adore dans ce medium, c\'est cette capacité '
          'à faire passer des émotions énormes avec quelques traits. Si tu veux, on peut '
          'créer une planche ensemble — tu décris la scène, je m\'occupe du découpage.';
    }

    return 'Je t\'écoute. Parle-moi de ce qui te traverse — une idée, une frustration, une envie, '
        'même vague. Parfois, c\'est en mettant des mots sur ce qui bouge à l\'intérieur '
        'que les meilleures choses commencent.';
  }
}