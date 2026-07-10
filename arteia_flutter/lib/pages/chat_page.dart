import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../services/voice_recorder_service.dart';
import '../services/word_predictor_service.dart';
import '../widgets/thought_bubble_audio.dart';
import '../widgets/suggestion_overlay.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceRecorderService _voiceRecorder = VoiceRecorderService();
  final WordPredictorService _predictor = WordPredictorService();
  final SupabaseClient _supabase = Supabase.instance.client;
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _messages = [];
  bool _isRecording = false;
  bool _isLoading = true;
  bool _showSuggestions = false;
  String? _currentUserId;
  String? _currentUserName;
  String? _defaultChannelId;
  String? _voiceRecordingPath;
  int _voiceRecordSeconds = 0;
  Timer? _voiceTimer;

  @override
  void initState() {
    super.initState();
    _initUser();
    _setupRealtimeSubscription();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) setState(() => _showSuggestions = false);
    });
  }

  Future<void> _initUser() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
        _currentUserName = user.email?.split('@').first ?? 'Utilisateur';
      });
    }
    await _loadDefaultChannel();
    await _loadMessages();
  }

  Future<void> _loadDefaultChannel() async {
    try {
      final channels = await _supabase
          .from('channels')
          .select('id')
          .eq('type', 'general')
          .limit(1);
      if (channels.isNotEmpty) {
        _defaultChannelId = channels[0]['id']?.toString();
      }
    } catch (_) {}
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
                  'voiceUrl': newMsg['voice_url'],
                  'voiceDuration': newMsg['voice_duration'] ?? 0,
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
              'voiceUrl': msg['voice_url'],
              'voiceDuration': msg['voice_duration'] ?? 0,
            };
          }).toList();
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _predictor.learn(text);
    setState(() => _showSuggestions = false);

    try {
      await _supabase.from('messages').insert({
        'channel_id': _defaultChannelId,
        'user_id': _currentUserId ?? 'anonymous',
        'user_name': _currentUserName ?? 'Utilisateur',
        'content': text,
        'is_voice': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      _messageController.clear();
    } catch (e) {
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
    _voiceRecorder.startRecording().then((path) {
      if (path != null && mounted) {
        setState(() {
          _isRecording = true;
          _voiceRecordingPath = path;
          _voiceRecordSeconds = 0;
        });
        _voiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() => _voiceRecordSeconds++);
            if (_voiceRecordSeconds >= 60) {
              _stopRecording();
            }
          }
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
    if (mounted) {
      setState(() {
        _isRecording = false;
        _voiceRecordSeconds = 0;
      });
    }
  }

  Future<void> _uploadAndSendVoice() async {
    if (_voiceRecordingPath == null || _defaultChannelId == null) return;

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
        'channel_id': _defaultChannelId,
        'user_id': _currentUserId ?? 'anonymous',
        'user_name': _currentUserName ?? 'Utilisateur',
        'content': '🎤 Message vocal',
        'is_voice': true,
        'voice_url': voiceUrl,
        'voice_duration': _voiceRecordSeconds,
        'created_at': DateTime.now().toIso8601String(),
      });

      _voiceRecorder.deleteRecording();
      _voiceRecordingPath = null;
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'id': DateTime.now().toString(),
            'user': _currentUserName ?? 'Moi',
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
    _voiceTimer?.cancel();
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
                _showSuggestions
                    ? SuggestionOverlay(
                        controller: _messageController,
                        onSelect: () => _messageController.clearComposing(),
                      )
                    : const SizedBox.shrink(),
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
                                  'Enregistrement ${_voiceRecordSeconds}s',
                                  style: const TextStyle(color: Colors.red, fontSize: 14),
                                ),
                                const Spacer(),
                                Icon(Icons.graphic_eq, color: Colors.red, size: 20),
                              ],
                            )
                          : TextField(
                              controller: _messageController,
                              focusNode: _focusNode,
                              style: const TextStyle(color: Colors.black, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'Écrire un message...',
                                hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 15),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                              onChanged: (_) => setState(() => _showSuggestions = true),
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

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMe = message['isMe'] == true;
    final isVoice = message['isVoice'] == true;
    final voiceUrl = message['voiceUrl'] as String?;
    final voiceDuration = message['voiceDuration'] as int? ?? 0;

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
          if (isVoice && voiceUrl != null)
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: ThoughtBubbleAudioPlayer(
                audioUrl: voiceUrl,
                authorName: message['user'] ?? 'Anonyme',
                duration: Duration(seconds: voiceDuration),
              ),
            )
          else
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
    final duration = message['voiceDuration'] ?? message['duration'] ?? 3;
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
