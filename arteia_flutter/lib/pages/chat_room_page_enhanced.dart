import 'package:flutter/material.dart';
import '../services/chat_service_enhanced.dart';
import '../widgets/ephemeral_message_widget.dart';

class ChatRoomPageEnhanced extends StatefulWidget {
  final String channelId;
  final String channelName;

  const ChatRoomPageEnhanced({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  State<ChatRoomPageEnhanced> createState() => _ChatRoomPageEnhancedState();
}

class _ChatRoomPageEnhancedState extends State<ChatRoomPageEnhanced> {
  final ChatServiceEnhanced _chatService = ChatServiceEnhanced();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  // Options pour message éphémère
  bool _isEphemeralMode = false;
  Duration _ephemeralDuration = const Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _chatService.getActiveMessages(widget.channelId);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.isEmpty) return;

    try {
      if (_isEphemeralMode) {
        await _chatService.sendEphemeralMessage(
          channelId: widget.channelId,
          content: _controller.text,
          duration: _ephemeralDuration,
        );
      } else {
        // Message normal (à implémenter avec le service de base)
      }
      
      _controller.clear();
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      await _loadMessages();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message supprimé'),
            backgroundColor: Colors.black,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showDeleteDialog(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Supprimer le message ?', style: TextStyle(color: Colors.black)),
        content: const Text('Cette action est irréversible.', style: TextStyle(color: Colors.black)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.black)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
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
        title: Text(widget.channelName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
        actions: [
          // Toggle mode éphémère
          IconButton(
            icon: Icon(
              _isEphemeralMode ? Icons.timer : Icons.timer_outlined,
              color: _isEphemeralMode ? Colors.red : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isEphemeralMode = !_isEphemeralMode;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Indicateur mode éphémère
          if (_isEphemeralMode)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode éphémère : Les messages disparaîtront après ${_ephemeralDuration.inSeconds} secondes',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.black))
                : _messages.isEmpty
                    ? const Center(child: Text('Aucun message', style: TextStyle(color: Colors.black)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isEphemeral = message['is_ephemeral'] ?? false;
                          final isDeleted = message['deleted_at'] != null;
                          
                          if (isDeleted) {
                            return const SizedBox.shrink();
                          }

                          return _MessageBubble(
                            message: message,
                            isEphemeral: isEphemeral,
                            onDelete: () => _showDeleteDialog(message['id']),
                          );
                        },
                      ),
          ),
          // Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: _isEphemeralMode ? 'Message éphémère...' : 'Écrire un message...',
                        hintStyle: const TextStyle(color: Color(0xFF999999)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.send,
                    color: _isEphemeralMode ? Colors.red : Colors.black,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isEphemeral;
  final VoidCallback onDelete;

  const _MessageBubble({
    required this.message,
    required this.isEphemeral,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  message['profiles']?['username'] ?? 'Anonyme',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
              if (isEphemeral)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Éphémère',
                    style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message['content'] ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatTime(message['created_at']),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );

    if (isEphemeral && message['expires_at'] != null) {
      final expiresAt = DateTime.parse(message['expires_at']);
      final duration = expiresAt.difference(DateTime.now());
      
      if (duration.isNegative) {
        return const SizedBox.shrink();
      }

      return EphemeralMessageWidget(
        duration: duration,
        onExpired: () {
          // Le message sera supprimé automatiquement par la vue active_messages
        },
        child: content,
      );
    }

    return content;
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final time = DateTime.parse(timestamp);
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '2')}';
  }
}