import 'package:flutter/material.dart';
import 'dart:async';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  final List<Map<String, dynamic>> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    // Simulation de chargement
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _startNewConversation() {
    showDialog(
      context: context,
      builder: (context) => _NewConversationDialog(
        onConversationCreated: (conversation) {
          setState(() {
            _conversations.insert(0, conversation);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Messages',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
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
                      Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune conversation',
                        style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Commencez une discussion !',
                        style: TextStyle(fontSize: 14, color: Colors.grey[300]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) {
                    final conv = _conversations[index];
                    return _ConversationTile(
                      conversation: conv,
                      onTap: () => _openConversation(conv),
                    );
                  },
                ),
    );
  }

  void _openConversation(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatPage(
          conversationId: conversation['id'],
          otherUserName: conversation['userName'],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation['unread'] == true;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasUnread ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUnread ? Colors.black : const Color(0xFFE0E0E0),
            width: hasUnread ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[300]!, Colors.grey[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.person,
                color: Colors.grey[600],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            // Infos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation['userName'] ?? 'Utilisateur',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        conversation['time'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conversation['lastMessage'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: hasUnread ? Colors.black : Colors.grey[600],
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Indicateur non lu
            if (hasUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NewConversationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onConversationCreated;

  const _NewConversationDialog({required this.onConversationCreated});

  @override
  State<_NewConversationDialog> createState() => _NewConversationDialogState();
}

class _NewConversationDialogState extends State<_NewConversationDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _users = [
    {'name': 'Luna', 'role': 'Artiste'},
    {'name': 'DJ Metro', 'role': 'Musicien'},
    {'name': 'Trio Blue', 'role': 'Groupe'},
    {'name': 'The Wild', 'role': 'Artiste'},
    {'name': 'Star Light', 'role': 'Chanteur'},
  ];
  List<Map<String, dynamic>> _filteredUsers = [];

  @override
  void initState() {
    super.initState();
    _filteredUsers = _users;
    _searchController.addListener(_filterUsers);
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUsers = _users.where((user) {
        return user['name']!.toLowerCase().contains(query) ||
            user['role']!.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Nouvelle conversation',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: 'Rechercher un utilisateur...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            itemCount: _filteredUsers.length,
            itemBuilder: (context, index) {
              final user = _filteredUsers[index];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.person, color: Colors.grey[600]),
                ),
                title: Text(
                  user['name']!,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  user['role']!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                onTap: () {
                  widget.onConversationCreated({
                    'id': DateTime.now().toString(),
                    'userName': user['name'],
                    'lastMessage': 'Nouvelle conversation',
                    'time': 'Maintenant',
                    'unread': true,
                  });
                },
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Page de chat privé
class PrivateChatPage extends StatefulWidget {
  final String conversationId;
  final String otherUserName;

  const PrivateChatPage({
    super.key,
    required this.conversationId,
    required this.otherUserName,
  });

  @override
  State<PrivateChatPage> createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() {});
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().toString(),
        'sender': 'Moi',
        'text': text,
        'time': DateTime.now().toString().substring(11, 16),
        'isMe': true,
        'isVoice': false,
      });
    });
    _messageController.clear();
    _scrollToBottom();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _recordingDuration++);
        if (_recordingDuration >= 15) {
          _stopRecording();
        }
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _messages.add({
          'id': DateTime.now().toString(),
          'sender': 'Moi',
          'text': '🎤 Message vocal (${_recordingDuration}s)',
          'time': DateTime.now().toString().substring(11, 16),
          'isMe': true,
          'isVoice': true,
          'duration': _recordingDuration,
        });
      });
      _scrollToBottom();
    }
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
    _recordingTimer?.cancel();
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
        title: Text(
          widget.otherUserName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Aucun message',
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _PrivateMessageBubble(message: msg);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onLongPress: _isRecording ? null : _startRecording,
            onLongPressUp: _isRecording ? _stopRecording : null,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _isRecording ? Colors.red : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: _isRecording ? Colors.white : Colors.black,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isRecording
                  ? Row(
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
                        const SizedBox(width: 8),
                        Text(
                          'Enregistrement ${_recordingDuration}s',
                          style: const TextStyle(color: Colors.red, fontSize: 14),
                        ),
                        const Spacer(),
                        Icon(Icons.graphic_eq, color: Colors.red, size: 20),
                      ],
                    )
                  : TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isRecording ? null : _sendMessage,
            child: Container(
              width: 44, height: 44,
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateMessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const _PrivateMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message['isMe'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message['sender'] ?? 'Anonyme',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w500),
              ),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMe ? Colors.black : Colors.grey[100],
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isMe ? const Radius.circular(4) : null,
                bottomLeft: !isMe ? const Radius.circular(4) : null,
              ),
            ),
            child: message['isVoice'] == true
                ? _buildVoiceBubble()
                : Text(
                    message['text'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: isMe ? Colors.white : Colors.black,
                      height: 1.4,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Text(
              message['time'] ?? '',
              style: const TextStyle(fontSize: 11, color: Color(0xFFCCCCCC)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceBubble() {
    final duration = message['duration'] ?? 3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_circle_filled,
          color: message['isMe'] == true ? Colors.white : Colors.black,
          size: 28,
        ),
        const SizedBox(width: 8),
        Container(
          width: 80,
          height: 2,
          color: message['isMe'] == true ? Colors.white54 : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text(
          '0:${duration.toString().padLeft(2, '0')}',
          style: TextStyle(
            fontSize: 12,
            color: message['isMe'] == true ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}