import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';

class ChatRoomPage extends StatefulWidget {
  final String channelId;
  final String channelName;
  const ChatRoomPage({super.key, required this.channelId, required this.channelName});

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.fetchMessages(widget.channelId);
      if (mounted) setState(() { _messages = messages; _isLoading = false; });
      _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; });
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

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final content = _messageController.text;
    _messageController.clear();
    try {
      await _chatService.sendMessage(widget.channelId, content);
      _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primaryViolet, AppTheme.primaryTeal]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.chat, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.channelName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('en ligne', style: TextStyle(fontSize: 11, color: AppTheme.primaryTeal)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.phone, size: 20), onPressed: () {}),
          IconButton(icon: const Icon(Icons.videocam, size: 20), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryViolet))
              : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.textMuted.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('Aucun message', style: TextStyle(color: AppTheme.textMuted)),
                        Text('Envoyez le premier message !', style: TextStyle(fontSize: 12, color: AppTheme.textMuted.withOpacity(0.6))),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = false; // À connecter avec l'user connecté
                      return _MessageBubble(
                        message: msg['content'] ?? '',
                        time: msg['created_at'] ?? '',
                        isMe: isMe,
                      );
                    },
                  ),
          ),
          // Input bar
          Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              left: 8, right: 8, top: 8,
            ),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              border: Border(top: BorderSide(color: AppTheme.divider.withOpacity(0.5))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryViolet, size: 24),
                  onPressed: () {},
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDarkLight,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.divider.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppTheme.textLight, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.primaryViolet, size: 24),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.time,
    required this.isMe,
  });

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMe
                ? const LinearGradient(colors: [AppTheme.primaryViolet, Color(0xFF6B4CE6)])
                : LinearGradient(colors: [AppTheme.cardDarkLight, AppTheme.cardDarkLight]),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : AppTheme.textLight,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _formatTime(time),
            style: TextStyle(fontSize: 10, color: AppTheme.textMuted.withOpacity(0.5)),
          ),
        ],
      ),
    );
  }
}