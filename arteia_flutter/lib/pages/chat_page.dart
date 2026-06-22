import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isRecording = false;
  bool _isLoading = true;
  String? _currentUserId;
  String? _currentUserName;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _initUser();
    _setupRealtimeSubscription();
  }

  Future<void> _initUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
        _currentUserName = user.email?.split('@').first ?? 'Utilisateur';
      });
    }
    await _loadMessages();
  }

  void _setupRealtimeSubscription() {
    _supabase
        .channel('public:messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            if (mounted) {
              final newMsg = payload.newRecord;
              setState(() {
                _messages.add({
                  'id': newMsg['id'].toString(),
                  'user': newMsg['user_name'] ?? 'Anonyme',
                  'text': newMsg['content'] ?? '',
                  'time': _formatTime(newMsg['created_at']?.toString() ?? ''),
                  'isMe': newMsg['user_id'] == _currentUserId,
                  'isVoice': newMsg['is_voice'] ?? false,
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
          .from('messages')
          .select('*')
          .order('created_at', ascending: true)
          .limit(50);

      if (mounted) {
        setState(() {
          _messages = (response as List).map((msg) {
            return {
              'id': msg['id'].toString(),
              'user': msg['user_name'] ?? 'Anonyme',
              'text': msg['content'] ?? '',
              'time': _formatTime(msg['created_at']?.toString() ?? ''),
              'isMe': msg['user_id'] == _currentUserId,
              'isVoice': msg['is_voice'] ?? false,
            };
          }).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      // Fallback si Supabase n'est pas disponible
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await _supabase.from('messages').insert({
        'user_id': _currentUserId ?? 'anonymous',
        'user_name': _currentUserName ?? 'Utilisateur',
        'content': text,
        'is_voice': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      _messageController.clear();
    } catch (e) {
      // Fallback local si Supabase n'est pas disponible
      if (mounted) {
        setState(() {
          _messages.add({
            'id': DateTime.now().toString(),
            'user': _currentUserName ?? 'Moi',
            'text': text,
            'time': DateTime.now().toString().substring(11, 16),
            'isMe': true,
            'isVoice': false,
          });
        });
        _messageController.clear();
        _scrollToBottom();
      }
    }
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
      });

      // Ajouter le message vocal
      setState(() {
        _messages.add({
          'id': DateTime.now().toString(),
          'user': _currentUserName ?? 'Moi',
          'text': '🎤 Message vocal (${_recordingDuration}s)',
          'time': DateTime.now().toString().substring(11, 16),
          'isMe': true,
          'isVoice': true,
          'duration': _recordingDuration,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message vocal envoyé'),
          backgroundColor: Colors.black,
          duration: Duration(seconds: 1),
        ),
      );
      _scrollToBottom();
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
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
        title: const Text(
          'Discussions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text('Aucun message', style: TextStyle(fontSize: 18, color: Colors.grey[400])),
                              const SizedBox(height: 8),
                              Text('Soyez le premier à écrire !', style: TextStyle(fontSize: 14, color: Colors.grey[300])),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => _MessageBubble(message: _messages[index]),
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
          // Bouton micro
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
          // Champ de texte
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
          // Bouton envoyer
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

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message['isMe'] == true;
    final isVoice = message['isVoice'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 4),
              child: Text(
                message['user'] ?? 'Anonyme',
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999), fontWeight: FontWeight.w500),
              ),
            ),
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: EdgeInsets.all(isVoice ? 10 : 14),
            decoration: BoxDecoration(
              color: isMe ? Colors.black : Colors.grey[100],
              borderRadius: BorderRadius.circular(20).copyWith(
                bottomRight: isMe ? const Radius.circular(4) : null,
                bottomLeft: !isMe ? const Radius.circular(4) : null,
              ),
            ),
            child: isVoice ? _buildVoiceBubble() : _buildTextBubble(),
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

  Widget _buildTextBubble() {
    return Text(
      message['text'] ?? '',
      style: TextStyle(
        fontSize: 15,
        color: message['isMe'] == true ? Colors.white : Colors.black,
        height: 1.4,
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