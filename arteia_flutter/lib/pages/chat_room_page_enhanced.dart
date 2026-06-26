import 'dart:io';
import 'package:flutter/material.dart';
import '../services/chat_service_enhanced.dart';
import '../services/voice_recorder_service.dart';
import '../services/supabase_service.dart';
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
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  final SupabaseService _supabase = SupabaseService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  // Options pour message éphémère
  bool _isEphemeralMode = false;
  Duration _ephemeralDuration = const Duration(seconds: 30);

  // Voice message state
  bool _isRecordingVoice = false;
  Duration _voiceRecordingDuration = Duration.zero;
  String? _voiceRecordingPath;
  int _voiceRecordSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _checkMicPermission();
  }

  Future<void> _checkMicPermission() async {
    if (!kIsWeb) {
      await _voiceRecorder.hasPermission();
    }
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

  Future<void> _startVoiceRecording() async {
    if (kIsWeb) return;
    try {
      final path = await _voiceRecorder.startRecording();
      if (path != null) {
        setState(() {
          _isRecordingVoice = true;
          _voiceRecordingPath = path;
          _voiceRecordSeconds = 0;
          _voiceRecordingDuration = Duration.zero;
        });
        _startVoiceTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur micro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _stopVoiceRecording() async {
    final path = await _voiceRecorder.stopRecording();
    if (path != null) {
      _voiceRecordingPath = path;
    }
    setState(() => _isRecordingVoice = false);
  }

  void _cancelVoiceRecording() {
    _voiceRecorder.deleteRecording();
    setState(() {
      _isRecordingVoice = false;
      _voiceRecordingPath = null;
      _voiceRecordingDuration = Duration.zero;
      _voiceRecordSeconds = 0;
    });
  }

  void _startVoiceTimer() {
    _voiceRecordSeconds = 0;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _isRecordingVoice) {
        _voiceRecordSeconds++;
        setState(() {
          _voiceRecordingDuration = Duration(seconds: _voiceRecordSeconds);
        });
        return true;
      }
      return false;
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _sendVoiceMessage() async {
    if (_voiceRecordingPath == null) return;

    try {
      final user = _supabase.currentUser;
      if (user == null) return;

      final audioFile = File(_voiceRecordingPath!);
      final audioFileName = 'voice_messages/${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _supabase.client.storage
          .from('posts')
          .upload(audioFileName, audioFile);

      final audioUrl = _supabase.client.storage
          .from('posts')
          .getPublicUrl(audioFileName);

      await _chatService.sendMessage(
        widget.channelId,
        content: '🎤 Message vocal',
        audioUrl: audioUrl,
        audioDuration: _voiceRecordingDuration.inSeconds,
        isEphemeral: _isEphemeralMode,
        ephemeralDuration: _isEphemeralMode ? _ephemeralDuration : null,
      );

      _voiceRecorder.deleteRecording();
      setState(() {
        _isRecordingVoice = false;
        _voiceRecordingPath = null;
        _voiceRecordingDuration = Duration.zero;
        _voiceRecordSeconds = 0;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur envoi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _voiceRecorder.dispose();
    super.dispose();
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                if (_isRecordingVoice) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(_voiceRecordingDuration),
                          style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red, size: 20),
                          onPressed: _cancelVoiceRecording,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.red, size: 20),
                          onPressed: _sendVoiceMessage,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
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
                  IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: _isEphemeralMode ? Colors.red : Colors.black,
                    ),
                    onPressed: _startVoiceRecording,
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      Icons.send,
                      color: _isEphemeralMode ? Colors.red : Colors.black,
                    ),
                    onPressed: _sendMessage,
                  ),
                ],
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