import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import '../services/voice_recorder_service.dart';
import '../services/word_predictor_service.dart';
import '../widgets/thought_bubble_audio.dart';
import '../widgets/suggestion_overlay.dart';

// ============================================================
// INBOX — Telegram + Instagram aesthetic
// ============================================================

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;
  String? _currentUserId;
  RealtimeChannel? _realtimeSub;
  RealtimeChannel? _presenceSub;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _loadConversations();
    _setupRealtime();
  }

  void _setupRealtime() {
    _realtimeSub = _supabase
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (_) => _loadConversations(),
        )
        .subscribe();

    _presenceSub = _supabase
        .channel('public:user_presence')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_presence',
          callback: (_) => _loadConversations(),
        )
        .subscribe();
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) return;
    try {
      List<Map<String, dynamic>> convs = [];

      final data = await _supabase.rpc('get_inbox_conversations', params: {
        'current_user_id': _currentUserId,
      });
      convs = (data as List).cast<Map<String, dynamic>>();

      // Ajouter la conversation "Note à moi-même" si elle existe
      try {
        final selfChannel = await _supabase
            .from('channels')
            .select('id, name')
            .eq('type', 'self')
            .eq('created_by', _currentUserId!)
            .maybeSingle();
        if (selfChannel != null) {
          final lastMsg = await _supabase
              .from('messages')
              .select('content, created_at')
              .eq('channel_id', selfChannel['id'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          convs.insert(0, {
            'channel_id': selfChannel['id'],
            'username': 'Moi',
            'avatar_url': null,
            'last_message': lastMsg?['content'] ?? '',
            'last_message_at': lastMsg?['created_at'],
            'is_online': true,
            'other_user_id': _currentUserId,
            'channel_type': 'self',
          });
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _conversations = convs;
          _isLoading = false;
        });
      }
    } catch (_) {
      await _loadConversationsFallback();
    }
  }

  Future<void> _loadConversationsFallback() async {
    try {
      final channelIds = await _supabase
          .from('channel_members')
          .select('channel_id')
          .eq('user_id', _currentUserId!);

      if (channelIds.isEmpty) {
        if (mounted) setState(() { _isLoading = false; _conversations = []; });
        return;
      }

      final ids = (channelIds as List).map((e) => e['channel_id'] as String).toList();
      final channels = await _supabase
          .from('channels')
          .select('id')
          .inFilter('id', ids)
          .eq('type', 'direct');

      if (channels.isEmpty) {
        if (mounted) setState(() { _isLoading = false; _conversations = []; });
        return;
      }

      final chIds = (channels as List).map((e) => e['id'] as String).toList();

      final allMembers = await _supabase
          .from('channel_members')
          .select('channel_id, user_id')
          .inFilter('channel_id', chIds);

      final otherUserIds = <String>{};
      final channelOtherUser = <String, String>{};
      for (final m in allMembers as List) {
        if (m['user_id'] != _currentUserId) {
          otherUserIds.add(m['user_id'] as String);
          channelOtherUser[m['channel_id'] as String] = m['user_id'] as String;
        }
      }

      final profiles = await _supabase
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', otherUserIds.toList());

      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in profiles as List) {
        profileMap[p['id'] as String] = p as Map<String, dynamic>;
      }

      final allMessages = await _supabase
          .from('messages')
          .select('channel_id, content, created_at')
          .inFilter('channel_id', chIds)
          .order('created_at', ascending: false);

      final lastMsgs = <String, Map<String, dynamic>>{};
      for (final msg in allMessages as List) {
        final cid = msg['channel_id'] as String;
        if (!lastMsgs.containsKey(cid)) {
          lastMsgs[cid] = msg as Map<String, dynamic>;
        }
      }

      final presence = await _supabase
          .from('user_presence')
          .select('user_id, status')
          .inFilter('user_id', otherUserIds.toList());

      final presenceMap = <String, String>{};
      for (final p in presence as List) {
        presenceMap[p['user_id'] as String] = p['status'] as String;
      }

      final convs = chIds.map((chId) {
        final otherUserId = channelOtherUser[chId] ?? '';
        final profile = profileMap[otherUserId];
        final last = lastMsgs[chId];
        final status = presenceMap[otherUserId];
        return {
          'channel_id': chId,
          'other_user_id': otherUserId,
          'username': profile?['username'] ?? 'Utilisateur',
          'avatar_url': profile?['avatar_url'],
          'last_message': last?['content'] ?? '',
          'last_message_at': last?['created_at'],
          'is_online': status == 'online',
          'presence_status': status ?? 'offline',
        };
      }).toList();

      convs.sort((a, b) {
        final ta = a['last_message_at'] as String?;
        final tb = b['last_message_at'] as String?;
        if (ta == null && tb == null) return 0;
        if (ta == null) return 1;
        if (tb == null) return -1;
        return tb.compareTo(ta);
      });

      try {
        final selfChannel = await _supabase
            .from('channels')
            .select('id, name')
            .eq('type', 'self')
            .eq('created_by', _currentUserId!)
            .maybeSingle();
        if (selfChannel != null) {
          final lastMsg = await _supabase
              .from('messages')
              .select('content, created_at')
              .eq('channel_id', selfChannel['id'])
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();
          convs.insert(0, {
            'channel_id': selfChannel['id'],
            'username': 'Moi',
            'avatar_url': null,
            'last_message': lastMsg?['content'] ?? '',
            'last_message_at': lastMsg?['created_at'],
            'is_online': true,
            'other_user_id': _currentUserId,
            'channel_type': 'self',
          });
        }
      } catch (_) {}

      if (mounted) setState(() { _conversations = convs; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startNewConversation() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewConversationSheet(
        onConversationCreated: (channelId, userName) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PrivateChatPage(
                channelId: channelId,
                otherUserName: userName,
              ),
            ),
          ).then((_) => _loadConversations());
        },
      ),
    );
  }

  void _deleteConversation(String channelId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer la conversation ?',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 17),
        ),
        content: const Text('Les messages seront supprimés pour vous.',
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _supabase.from('channel_members')
                  .delete()
                  .eq('channel_id', channelId)
                  .eq('user_id', _currentUserId!);
              setState(() {
                _conversations.removeWhere((c) => c['channel_id'] == channelId);
              });
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _realtimeSub?.unsubscribe();
    _presenceSub?.unsubscribe();
    super.dispose();
  }

  Color _avatarColor(String name) {
    final hash = name.hashCode;
    final hue = hash.abs() % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.5, 0.7).toColor();
  }

  List<Color> _avatarGradient(String name) {
    final hash = name.hashCode.abs();
    final h1 = hash % 360;
    final h2 = (hash * 7) % 360;
    return [
      HSLColor.fromAHSL(1.0, h1.toDouble(), 0.6, 0.65).toColor(),
      HSLColor.fromAHSL(1.0, h2.toDouble(), 0.5, 0.55).toColor(),
    ];
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Messages',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.black, size: 22),
            onPressed: _startNewConversation,
            tooltip: 'Nouvelle conversation',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88, height: 88,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey[200]!, Colors.grey[100]!],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(44),
                        ),
                        child: Icon(Icons.chat_bubble_outline, size: 36, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 24),
                      Text('Aucun message',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      Text('Commencez une discussion\navec un artiste de la communauté',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey[400], height: 1.4),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadConversations,
                  color: Colors.black,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      final conv = _conversations[index];
                      return _InboxTile(
                        key: ValueKey(conv['channel_id']),
                        avatarUrl: conv['avatar_url'],
                        userName: conv['username'] ?? 'Utilisateur',
                        lastMessage: conv['last_message'] ?? '',
                        lastTime: conv['last_message_at'] != null
                            ? DateTime.parse(conv['last_message_at'] as String)
                            : null,
                        isOnline: conv['is_online'] ?? false,
                        initials: _initials(conv['username'] ?? '?'),
                        avatarColor: _avatarColor(conv['username'] ?? ''),
                        avatarGradient: _avatarGradient(conv['username'] ?? ''),
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (_, __, ___) => PrivateChatPage(
                                channelId: conv['channel_id'],
                                otherUserName: conv['username'] ?? 'Utilisateur',
                                otherUserId: conv['other_user_id'],
                                otherAvatarUrl: conv['avatar_url'],
                              ),
                              transitionsBuilder: (_, a, __, child) =>
                                  FadeTransition(opacity: a, child: child),
                              transitionDuration: const Duration(milliseconds: 200),
                            ),
                          ).then((_) => _loadConversations());
                        },
                        onDelete: () => _deleteConversation(conv['channel_id']),
                      );
                    },
                  ),
                ),
    );
  }
}

// ============================================================
// INBOX TILE — Telegram clean + Instagram stories ring
// ============================================================

class _InboxTile extends StatelessWidget {
  final String? avatarUrl;
  final String userName;
  final String lastMessage;
  final DateTime? lastTime;
  final bool isOnline;
  final String initials;
  final Color avatarColor;
  final List<Color> avatarGradient;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _InboxTile({
    super.key,
    required this.avatarUrl,
    required this.userName,
    required this.lastMessage,
    required this.lastTime,
    required this.isOnline,
    required this.initials,
    required this.avatarColor,
    required this.avatarGradient,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = lastTime != null ? timeago.format(lastTime!, locale: 'fr') : '';
    final isUnread = false; // TODO: track via message_reads

    return Dismissible(
      key: Key('inbox_${userName}_$lastTime'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFF3B30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // Avatar with Instagram-style gradient ring
              Container(
                width: 58, height: 58,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  gradient: isOnline
                      ? LinearGradient(
                          colors: [const Color(0xFF833AB4), const Color(0xFFFD1D1D), const Color(0xFFF77737)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        )
                      : null,
                  shape: BoxShape.circle,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: avatarUrl != null && avatarUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Center(
                                child: Text(initials,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(initials,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Text(timeStr,
                            style: TextStyle(fontSize: 12, color: isUnread ? Colors.black : Colors.grey[400]),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: isUnread ? Colors.black87 : Colors.grey[500],
                              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isOnline)
                          Container(
                            width: 8, height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF34C759),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NEW CONVERSATION — Bottom sheet style (like Telegram)
// ============================================================

class _NewConversationSheet extends StatefulWidget {
  final Function(String channelId, String userName) onConversationCreated;
  const _NewConversationSheet({required this.onConversationCreated});

  @override
  State<_NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends State<_NewConversationSheet> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    try {
      final users = await _supabase
          .from('profiles')
          .select('id, username, avatar_url, role')
          .neq('id', currentUserId!)
          .limit(50);
      if (mounted) {
        _users = (users as List).cast<Map<String, dynamic>>();
        _filteredUsers = _users;
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((u) =>
        (u['username'] as String?)?.toLowerCase().contains(query) ?? false
      ).toList();
    });
  }

  Future<void> _createSelfNote() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;
    try {
      final existing = await _supabase
          .from('channels')
          .select('id')
          .eq('type', 'self')
          .eq('created_by', currentUserId)
          .maybeSingle();
      if (existing != null) {
        widget.onConversationCreated(existing['id'] as String, 'Moi');
        return;
      }
      final channel = await _supabase
          .from('channels')
          .insert({
            'name': 'Notes personnelles',
            'type': 'self',
            'is_private': true,
            'created_by': currentUserId,
          })
          .select()
          .single();
      final channelId = channel['id'] as String;
      await _supabase.from('channel_members').insert({
        'channel_id': channelId, 'user_id': currentUserId, 'role': 'member',
      });
      widget.onConversationCreated(channelId, 'Moi');
    } catch (_) {}
  }

  Future<void> _createConversation(Map<String, dynamic> otherUser) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      final myChannels = await _supabase
          .from('channel_members')
          .select('channel_id')
          .eq('user_id', currentUserId);

      final theirChannels = await _supabase
          .from('channel_members')
          .select('channel_id')
          .eq('user_id', otherUser['id']);

      final myIds = (myChannels as List).map((e) => e['channel_id'] as String).toSet();
      final theirIds = (theirChannels as List).map((e) => e['channel_id'] as String).toSet();
      final common = myIds.intersection(theirIds);

      if (common.isNotEmpty) {
        final ch = await _supabase
            .from('channels')
            .select('id')
            .eq('id', common.first)
            .eq('type', 'direct')
            .maybeSingle();
        if (ch != null) {
          widget.onConversationCreated(ch['id'] as String, otherUser['username'] ?? 'Utilisateur');
          return;
        }
      }

      final channel = await _supabase
          .from('channels')
          .insert({
            'name': otherUser['username'] ?? 'Discussion',
            'type': 'direct',
            'is_private': true,
            'created_by': currentUserId,
          })
          .select()
          .single();

      final channelId = channel['id'] as String;

      await _supabase.from('channel_members').insert([
        {'channel_id': channelId, 'user_id': currentUserId, 'role': 'member'},
        {'channel_id': channelId, 'user_id': otherUser['id'], 'role': 'member'},
      ]);

      widget.onConversationCreated(channelId, otherUser['username'] ?? 'Utilisateur');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildSelfNoteTile() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF7C5CFC),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.edit_note, color: Colors.white, size: 24),
      ),
      title: const Text('Note à moi-même',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: const Text('Envoyer des notes, des idées, tester des commandes',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      ),
      onTap: () => _createSelfNote(),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final name = user['username'] ?? '';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: _avatarColor(name),
          borderRadius: BorderRadius.circular(24),
        ),
        child: user['avatar_url'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: CachedNetworkImage(
                  imageUrl: user['avatar_url'],
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Center(
                    child: Text(_initials(name),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(_initials(name),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
      ),
      title: Text(name,
        style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(user['role'] ?? 'artiste',
        style: TextStyle(color: Colors.grey[500], fontSize: 13),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Message',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      onTap: () => _createConversation(user),
    );
  }

  Color _avatarColor(String name) {
    final hash = name.hashCode.abs();
    final hue = hash % 360;
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.5, 0.7).toColor();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Nouvelle conversation',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Rechercher un artiste...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _filteredUsers.isEmpty && _searchController.text.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          _buildSelfNoteTile(),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text('Artistes', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 40),
                              child: Column(
                                children: [
                                  Icon(Icons.person_search, size: 48, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  Text('Aucun artiste trouvé', style: TextStyle(color: Colors.grey[400], fontSize: 15)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        children: [
                          if (_searchController.text.isEmpty) _buildSelfNoteTile(),
                          if (_searchController.text.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text('Artistes', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
                            ),
                          ..._filteredUsers.map((user) => _buildUserTile(user)),
                        ],
                      ),
          ),
          SizedBox(height: bottom),
        ],
      ),
    );
  }
}

// ============================================================
// PRIVATE CHAT — Messages vocaux + prédiction
// ============================================================

class PrivateChatPage extends StatefulWidget {
  final String channelId;
  final String otherUserName;
  final String? otherUserId;
  final String? otherAvatarUrl;

  const PrivateChatPage({
    super.key,
    required this.channelId,
    required this.otherUserName,
    this.otherUserId,
    this.otherAvatarUrl,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SupabaseClient _supabase = Supabase.instance.client;
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  final WordPredictorService _predictor = WordPredictorService();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;
  String? _currentUserName;

  bool _isRecording = false;
  String? _voiceRecordingPath;
  int _voiceRecordSeconds = 0;
  Timer? _voiceTimer;
  bool _showSuggestions = false;

  RealtimeChannel? _realtimeSub;

  @override
  void initState() {
    super.initState();
    _currentUserId = _supabase.auth.currentUser?.id;
    _currentUserName = _supabase.auth.currentUser?.email?.split('@').first ?? 'Moi';
    _loadMessages();
    _setupRealtime();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) setState(() => _showSuggestions = false);
    });
  }

  void _setupRealtime() {
    _realtimeSub = _supabase
        .channel('channel:${widget.channelId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final msg = payload.newRecord;
            if (msg['channel_id'] == widget.channelId && mounted) {
              setState(() {
                _messages.add({
                  'id': msg['id'].toString(),
                  'sender': msg['user_name'] ?? 'Anonyme',
                  'text': msg['content'] ?? '',
                  'time': _formatTime(msg['created_at']?.toString() ?? ''),
                  'isMe': msg['user_id'] == _currentUserId,
                  'isVoice': msg['is_voice'] ?? false,
                  'voiceUrl': msg['voice_url'],
                  'voiceDuration': msg['voice_duration'] ?? 0,
                });
              });
              _scrollToBottom();
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _supabase
          .from('active_messages')
          .select('*')
          .eq('channel_id', widget.channelId)
          .order('created_at', ascending: true)
          .limit(100);

      if (mounted) {
        setState(() {
          _messages = (response as List).map((msg) {
            return {
              'id': msg['id'].toString(),
              'sender': msg['user_name'] ?? 'Anonyme',
              'text': msg['content'] ?? '',
              'time': _formatTime(msg['created_at']?.toString() ?? ''),
              'isMe': msg['user_id'] == _currentUserId,
              'isVoice': msg['is_voice'] ?? false,
              'voiceUrl': msg['voice_url'],
              'voiceDuration': msg['voice_duration'] ?? 0,
            };
          }).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _predictor.learn(text);
    setState(() => _showSuggestions = false);

    try {
      _supabase.from('messages').insert({
        'channel_id': widget.channelId,
        'user_id': _currentUserId,
        'user_name': _currentUserName,
        'content': text,
        'is_voice': false,
      });
    } catch (_) {}

    _messageController.clear();
  }

  void _startRecording() {
    _voiceRecorder.startRecording().then((path) {
      if (path != null && mounted) {
        setState(() {
          _isRecording = true;
          _voiceRecordingPath = path;
          _voiceRecordSeconds = 0;
        });
        _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) setState(() => _voiceRecordSeconds++);
          if (_voiceRecordSeconds >= 60) _stopRecording();
        });
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur micro: $e'), backgroundColor: Colors.red),
        );
      }
    });
  }

  Future<void> _stopRecording() async {
    _voiceTimer?.cancel();
    final path = await _voiceRecorder.stopRecording();
    if (path != null) {
      _voiceRecordingPath = path;
      await _uploadAndSendVoice();
    }
    if (mounted) setState(() { _isRecording = false; _voiceRecordSeconds = 0; });
  }

  Future<void> _uploadAndSendVoice() async {
    if (_voiceRecordingPath == null) return;
    try {
      final audioFile = File(_voiceRecordingPath!);
      final audioFileName = 'voice_messages/${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _supabase.storage
          .from('voice-messages')
          .upload(audioFileName, audioFile);

      final voiceUrl = _supabase.storage
          .from('voice-messages')
          .getPublicUrl(audioFileName);

      await _supabase.from('messages').insert({
        'channel_id': widget.channelId,
        'user_id': _currentUserId,
        'user_name': _currentUserName,
        'content': '🎤 Message vocal',
        'is_voice': true,
        'voice_url': voiceUrl,
        'voice_duration': _voiceRecordSeconds,
      });

      _voiceRecorder.deleteRecording();
      _voiceRecordingPath = null;
    } catch (_) {
      if (mounted) {
        setState(() {
          _messages.add({
            'id': DateTime.now().toString(),
            'sender': _currentUserName ?? 'Moi',
            'text': '🎤 Message vocal (${_voiceRecordSeconds}s)',
            'time': DateTime.now().toString().substring(11, 16),
            'isMe': true,
            'isVoice': true,
            'voiceUrl': null,
            'voiceDuration': _voiceRecordSeconds,
          });
        });
        _scrollToBottom();
      }
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _voiceTimer?.cancel();
    _voiceRecorder.dispose();
    _realtimeSub?.unsubscribe();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: widget.otherAvatarUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CachedNetworkImage(
                        imageUrl: widget.otherAvatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(Icons.person, color: Colors.grey[600], size: 18),
                      ),
                    )
                  : Icon(Icons.person, color: Colors.grey[600], size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(widget.otherUserName,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.unfocus(),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.black))
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('Aucun message', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('Envoyez un message à ${widget.otherUserName}',
                                style: TextStyle(color: Colors.grey[300], fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return _PrivateMessageBubble(message: msg);
                          },
                        ),
            ),
          ),
          if (_showSuggestions)
            SuggestionOverlay(
              controller: _messageController,
              onSelect: () => _messageController.clearComposing(),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
            onLongPress: _isRecording ? null : _startRecording,
            onLongPressUp: _isRecording ? _stopRecording : null,
            child: Container(
              width: 40, height: 40,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.white : Colors.grey[600],
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _isRecording
                  ? Row(
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
                        const SizedBox(width: 8),
                        Text('${_voiceRecordSeconds}s',
                          style: const TextStyle(color: Colors.red, fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Icon(Icons.graphic_eq, color: Colors.red, size: 22),
                      ],
                    )
                  : TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      maxLines: null,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isCollapsed: true,
                      ),
                      onChanged: (_) => setState(() => _showSuggestions = true),
                      onSubmitted: (_) => _sendMessage(),
                    ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isRecording ? null : _sendMessage,
            child: Container(
              width: 40, height: 40,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: _messageController.text.isEmpty && !_isRecording
                    ? Colors.transparent
                    : Colors.black,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_upward,
                color: _messageController.text.isEmpty && !_isRecording
                    ? Colors.grey[400]
                    : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MESSAGE BUBBLE — Telegram-style
// ============================================================

class _PrivateMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  const _PrivateMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message['isMe'] == true;
    final isVoice = message['isVoice'] == true;
    final voiceUrl = message['voiceUrl'] as String?;
    final voiceDuration = message['voiceDuration'] as int? ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (isVoice && voiceUrl != null)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: ThoughtBubbleAudioPlayer(
                audioUrl: voiceUrl,
                authorName: message['sender'] ?? 'Anonyme',
                duration: Duration(seconds: voiceDuration),
              ),
            )
          else if (isVoice)
            _buildBubble(context, isMe,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_circle_filled, color: isMe ? Colors.white : Colors.black, size: 24),
                  const SizedBox(width: 8),
                  Container(width: 60, height: 2,
                    color: isMe ? Colors.white54 : Colors.grey[400],
                  ),
                  const SizedBox(width: 6),
                  Text('0:${(message['duration'] ?? voiceDuration).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 12, color: isMe ? Colors.white70 : Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            _buildBubble(context, isMe,
              Text(message['text'] ?? '',
                style: TextStyle(fontSize: 16, color: isMe ? Colors.white : Colors.black, height: 1.3),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(message['time'] ?? '',
              style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, bool isMe, Widget child) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: isMe ? const Radius.circular(4) : null,
          bottomLeft: !isMe ? const Radius.circular(4) : null,
        ),
      ),
      child: child,
    );
  }
}
