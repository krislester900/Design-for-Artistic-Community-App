import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';
import 'memory_service.dart';

class SampleDeviceContacts {
  static final List<Map<String, dynamic>> contacts = [
    {
      'id': '1',
      'name': 'Marie Dubois',
      'email': 'marie.dubois@email.com',
      'phone': '+33612345678',
      'avatar': 'https://example.com/avatars/marie.jpg',
    },
    {
      'id': '2',
      'name': 'Thomas Martin',
      'email': 'thomas.martin@email.com',
      'phone': '+33789012345',
      'avatar': 'https://example.com/avatars/thomas.jpg',
    },
    {
      'id': '3',
      'name': 'Sophie Laurent',
      'email': 'sophie.laurent@email.com',
      'phone': '+33698765432',
      'avatar': 'https://example.com/avatars/sophie.jpg',
    },
    {
      'id': '4',
      'name': 'Julien Petit',
      'email': 'julien.petit@email.com',
      'phone': '+33645678901',
      'avatar': 'https://example.com/avatars/julien.jpg',
    },
    {
      'id': '5',
      'name': 'Amélie Chen',
      'email': 'amelie.chen@email.com',
      'phone': '+33623456789',
      'avatar': 'https://example.com/avatars/amelie.jpg',
    },
  ];
}

class CountryCodeService {
  static final Map<String, String> countryCodes = {
    'FR': '+33',
    'US': '+1',
    'GB': '+44',
    'DE': '+49',
    'CA': '+1',
    'AU': '+61',
    'BR': '+55',
    'IN': '+91',
    'JP': '+81',
    'CN': '+86',
    'RU': '+7',
    'MX': '+52',
    'ES': '+34',
    'IT': '+39',
    'AR': '+54',
    'ZA': '+27',
    'NG': '+234',
    'KE': '+254',
    'EG': '+20',
    'PH': '+63',
  };

  static String detectCountryCode(String phoneNumber) {
    if (phoneNumber.startsWith('+33')) return 'FR';
    if (phoneNumber.startsWith('+1')) return 'US';
    if (phoneNumber.startsWith('+44')) return 'GB';
    if (phoneNumber.startsWith('+49')) return 'DE';
    if (phoneNumber.startsWith('+61')) return 'AU';
    if (phoneNumber.startsWith('+55')) return 'BR';
    if (phoneNumber.startsWith('+91')) return 'IN';
    if (phoneNumber.startsWith('+81')) return 'JP';
    if (phoneNumber.startsWith('+86')) return 'CN';
    if (phoneNumber.startsWith('+7')) return 'RU';
    if (phoneNumber.startsWith('+52')) return 'MX';
    if (phoneNumber.startsWith('+34')) return 'ES';
    if (phoneNumber.startsWith('+39')) return 'IT';
    if (phoneNumber.startsWith('+54')) return 'AR';
    if (phoneNumber.startsWith('+27')) return 'ZA';
    if (phoneNumber.startsWith('+234')) return 'NG';
    if (phoneNumber.startsWith('+254')) return 'KE';
    if (phoneNumber.startsWith('+20')) return 'EG';
    if (phoneNumber.startsWith('+63')) return 'PH';
    return 'FR';
  }

  static String normalizePhoneNumber(String phone) {
    if (phone.isEmpty) return '';
    phone = phone.trim();
    if (!phone.startsWith('+')) {
      final cc = countryCodes[detectCountryCode(phone)] ?? '+33';
      phone = '$cc${phone.replaceAll(RegExp(r'^\+?00'), '')}';
    }
    return phone;
  }
}

class Contact {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? countryCode;
  
  Contact({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.countryCode,
  });
}

class ContactMatch {
  final Contact contact;
  final bool isAppUser;
  final String? appUserId;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  
  ContactMatch({
    required this.contact,
    required this.isAppUser,
    this.appUserId,
    this.username,
    this.avatarUrl,
    this.bio,
  });
}

class ChatService {
  final SupabaseService _supabase = SupabaseService();
  final MemoryService _memoryService = MemoryService();

  Future<List<ContactMatch>> scanContactsAndFindAppUsers() async {
    try {
      final contacts = await _getDeviceContacts();
      final contactEmails = contacts.map((c) => c.email).where((e) => e.isNotEmpty).toList();
      final contactPhones = contacts.map((c) => c.phone).where((p) => p != null && p!.isNotEmpty).toList();
      
      final appUsers = await _findAppUsersByContacts(contactEmails, contactPhones);
      return _createContactMatches(contacts, appUsers);
    } catch (e) {
      debugPrint('Erreur scan contacts: $e');
      return [];
    }
  }
  
  Future<List<Contact>> _getDeviceContacts() async {
    final contacts = <Contact>[];
    
    for (final contact in SampleDeviceContacts.contacts) {
      final phone = contact['phone'] as String?;
      final normalizedPhone = phone != null ? CountryCodeService.normalizePhoneNumber(phone) : null;
      final countryCode = phone != null ? CountryCodeService.detectCountryCode(phone) : null;
      
      contacts.add(Contact(
        id: contact['id'],
        name: contact['name'],
        email: contact['email'] ?? '',
        phone: normalizedPhone,
        avatarUrl: contact['avatar'],
        countryCode: countryCode,
      ));
    }
    
    return contacts;
  }
  
  Future<List<Map<String, dynamic>>> _findAppUsersByContacts(List<String> emails, List<String?> phones) async {
    if (emails.isEmpty && phones.isEmpty) return [];
    
    try {
      final phoneList = phones.where((p) => p != null && p.isNotEmpty).toList();
      
      if (emails.isNotEmpty && phoneList.isNotEmpty) {
        dynamic query = _supabase.client.from('profiles').select('id, email, display_name, avatar_url, bio, phone_number');
        query = (query as dynamic).or('email.in.$emails,phone_number.in.$phoneList');
        final response = await query;
        return List<Map<String, dynamic>>.from(response as List);
      } else if (emails.isNotEmpty) {
        dynamic query = _supabase.client.from('profiles').select('id, email, display_name, avatar_url, bio, phone_number');
        query = (query as dynamic).in_('email', emails);
        final response = await query;
        return List<Map<String, dynamic>>.from(response as List);
      } else if (phoneList.isNotEmpty) {
        dynamic query = _supabase.client.from('profiles').select('id, email, display_name, avatar_url, bio, phone_number');
        query = (query as dynamic).in_('phone_number', phoneList);
        final response = await query;
        return List<Map<String, dynamic>>.from(response as List);
      }
      
      return [];
    } catch (e) {
      debugPrint('Erreur recherche utilisateurs: $e');
      return [];
    }
  }
  
  List<ContactMatch> _createContactMatches(
    List<Contact> deviceContacts,
    List<Map<String, dynamic>> appUsers,
  ) {
    final matches = <ContactMatch>[];
    
    for (final contact in deviceContacts) {
      Map<String, dynamic>? matchedUser;
      
      if (contact.email.isNotEmpty) {
        matchedUser = appUsers.firstWhere(
          (user) => user['email'] != null && 
                      user['email'].toString().toLowerCase() == contact.email.toLowerCase(),
          orElse: () => null as Map<String, dynamic>,
        );
      }
      
      if (matchedUser == null && contact.phone != null && contact.phone!.isNotEmpty) {
        matchedUser = appUsers.firstWhere(
          (user) => user['phone_number'] != null && 
                      user['phone_number'].toString() == contact.phone,
          orElse: () => null as Map<String, dynamic>,
        );
      }
      
      if (matchedUser != null) {
        matches.add(ContactMatch(
          contact: contact,
          isAppUser: true,
          appUserId: matchedUser['id'],
          username: matchedUser['display_name'],
          avatarUrl: matchedUser['avatar_url'],
          bio: matchedUser['bio'],
        ));
      } else {
        matches.add(ContactMatch(
          contact: contact,
          isAppUser: false,
        ));
      }
    }
    
    return matches;
  }
  
  Future<void> importContactsAsConnections({
    required String userId,
    required List<ContactMatch> contacts,
  }) async {
    try {
      final appContacts = contacts.where((c) => c.isAppUser).toList();
      
      for (final contact in appContacts) {
        final existingConnection = await _checkExistingConnection(userId, contact.appUserId);
        
        if (existingConnection == null) {
          await _createConnection(userId, contact);
        }
      }
    } catch (e) {
      debugPrint('Erreur import connections: $e');
    }
  }
  
  Future<Map<String, dynamic>?> _checkExistingConnection(String userId, String? contactId) async {
    if (contactId == null) return null;
    
    try {
      return await _supabase.client
          .from('user_connections')
          .select('id')
          .eq('user_id', userId)
          .eq('contact_id', contactId)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }
  
  Future<void> _createConnection(String userId, ContactMatch contact) async {
    try {
      await _supabase.client.from('user_connections').insert({
        'user_id': userId,
        'contact_id': contact.appUserId,
        'contact_name': contact.contact.name,
        'contact_email': contact.contact.email,
        'contact_avatar': contact.contact.avatarUrl,
        'contact_bio': contact.bio,
        'contact_phone': contact.contact.phone,
        'contact_country_code': contact.contact.countryCode,
        'status': 'accepted',
        'connection_type': 'friend',
        });
    } catch (e) {
      debugPrint('Erreur création connexion: $e');
    }
  }
  
  Future<List<Map<String, dynamic>>> getAppContacts() async {
    try {
      final currentUser = _supabase.currentUser;
      if (currentUser == null) return [];
      
      final response = await _supabase.client
          .from('user_connections')
          .select('id, contact_id, contact_name, contact_email, contact_avatar, contact_bio, contact_phone, contact_country_code, connection_type, status, created_at')
          .eq('user_id', currentUser.id)
          .eq('status', 'accepted');
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Erreur récupération contacts: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>?> findUserByUsernameOrId(String query) async {
    try {
      final response = await _supabase.client
          .from('profiles')
          .select('id, display_name, username, avatar_url, phone_number')
          .or('username.eq.$query,display_name.eq.$query,id.eq.$query')
          .single();
      
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> searchUsersByPhone(String phoneNumber) async {
    try {
      final normalizedPhone = CountryCodeService.normalizePhoneNumber(phoneNumber);
      
      final response = await _supabase.client
          .from('profiles')
          .select('id, display_name, username, avatar_url, phone_number')
          .eq('phone_number', normalizedPhone);
      
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Erreur recherche par téléphone: $e');
      return [];
    }
  }
  
  Future<String> startConversationWithContact({
    required String contactId,
    required String contactName,
    String? initialMessage,
  }) async {
    try {
      final currentUser = _supabase.currentUser;
      if (currentUser == null) throw Exception('Non connecté');
      
      final existingConversation = await _getExistingConversation(currentUser.id, contactId);
      if (existingConversation != null) {
        return existingConversation['id'];
      }
      
      final channelId = _generateChannelId(currentUser.id, contactId);
      
      await _createChannel(channelId, contactName, currentUser.id, contactId);
      
      if (initialMessage != null && initialMessage.isNotEmpty) {
        await _sendMessage(channelId, initialMessage, currentUser.id, contactId, 'initial');
      }
      
      return channelId;
    } catch (e) {
      debugPrint('Erreur création conversation: $e');
      throw Exception('Impossible de commencer la conversation');
    }
  }

  Future<void> sendMessageToContact({
    required String contactId,
    required String message,
    String? channelId,
  }) async {
    try {
      final currentUser = _supabase.currentUser;
      if (currentUser == null) throw Exception('Non connecté');
      
      final targetChannelId = channelId ?? await _getOrCreateContactChannel(currentUser.id, contactId);
      await _sendMessage(targetChannelId, message, currentUser.id, contactId, 'direct');
    } catch (e) {
      debugPrint('Erreur envoi message: $e');
    }
  }

  Future<Map<String, dynamic>?> _getExistingConversation(String userId, String contactId) async {
    try {
      return await _supabase.client
          .from('chat_channels')
          .select('id, name, last_message_at')
          .or('and(user1_id.eq.$userId,user2_id.eq.$contactId),and(user1_id.eq.$contactId,user2_id.eq.$userId)')
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  Future<void> _createChannel(String channelId, String name, String user1Id, String user2Id) async {
    try {
      await _supabase.client.from('chat_channels').insert({
        'id': channelId,
        'name': name,
        'user1_id': user1Id,
        'user2_id': user2Id,
        'last_message_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'is_group': false,
      });
    } catch (e) {
      debugPrint('Erreur création channel: $e');
    }
  }

  Future<void> _sendMessage(String channelId, String content, String senderId, String receiverId, String messageType) async {
    try {
      final sender = await _supabase.getProfile(senderId);
      
      await _supabase.client.from('chat_messages').insert({
        'channel_id': channelId,
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
        'message_type': messageType,
        'sender_name': sender?['display_name'] ?? 'Utilisateur',
        'sender_avatar': sender?['avatar_url'],
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await _updateChannelLastMessage(channelId);
    } catch (e) {
      debugPrint('Erreur envoi message: $e');
    }
  }

  Future<void> _updateChannelLastMessage(String channelId) async {
    try {
      await _supabase.client
          .from('chat_channels')
          .update({'last_message_at': DateTime.now().toIso8601String()})
          .eq('id', channelId);
    } catch (e) {
      debugPrint('Erreur mise à jour channel: $e');
    }
  }

  String _generateChannelId(String userId, String contactId) {
    final sortedIds = [userId, contactId]..sort();
    return 'dm_${sortedIds.join('_')}';
  }

  Future<String> _getOrCreateContactChannel(String userId, String contactId) async {
    final existingChannel = await _getExistingConversation(userId, contactId);
    if (existingChannel != null) {
      return existingChannel['id'];
    }
    
    final channelId = _generateChannelId(userId, contactId);
    await _createChannel(channelId, '', userId, contactId);
    return channelId;
  }

  Future<String> getAiResponse({
    required String userMessage,
    String channelId = 'muse_ai',
    int maxTokens = 1000,
  }) async {
    try {
      final prefs = await _supabase.getInteractionPreferences();
      final personalizationContext = _buildPersonalizationContext(prefs);
      final systemPrompt = _buildSystemPrompt(personalizationContext);
      final response = await _callGroqApi(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        maxTokens: maxTokens,
      );
      return response;
    } catch (e) {
      debugPrint('Erreur getAiResponse: $e');
      return "Désolé, une erreur s'est produite. Veuillez réessayer.";
    }
  }

  // ==================== COMPATIBILITY METHODS ====================
  
  Future<List<Map<String, dynamic>>> fetchMessages(String channelId, {int limit = 50}) async {
    return await _supabase.getChatMessages(channelId, limit: limit);
  }

  Future<void> sendMessage(String channelId, String content) async {
    await _supabase.sendChatMessage(channelId, content);
  }

  String _buildPersonalizationContext(Map<String, String> prefs) {
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
          context.add('Utilisez des métaphores artistiques abondantes.');
          break;
        case 'medium':
          context.add('Utilisez des métaphores artistiques modérées.');
          break;
        case 'low':
          context.add('Évitez les métaphores artistiques.');
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
      final response = await _supabase.client.functions.invoke(
        'muse-ai',
        body: {
          'system_prompt': systemPrompt,
          'user_message': userMessage,
          'max_tokens': maxTokens,
        },
      );

      final data = response.data as Map<String, dynamic>;

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
      debugPrint('Erreur dans _callGroqApi: $e');
      return "Désolé, j'ai eu un problème de connexion. Veuillez réessayer.";
    }
  }
}