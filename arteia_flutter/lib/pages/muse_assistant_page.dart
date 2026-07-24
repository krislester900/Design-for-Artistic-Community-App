import 'package:flutter/material.dart';
import '../services/ai_assistant_service.dart';

class MuseTheme {
  final String id;
  final String name;
  final Color background;
  final Color surface;
  final Color border;
  final Color text;
  final Color muted;
  final Color accent;
  final Color glow;

  const MuseTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.surface,
    required this.border,
    required this.text,
    required this.muted,
    required this.accent,
    required this.glow,
  });
}

class MuseThemes {
  static const light = MuseTheme(
    id: 'light',
    name: 'Blanc',
    background: Color(0xFFffffff),
    surface: Color(0xFFf5f5f5),
    border: Color(0xFF000000),
    text: Color(0xFF000000),
    muted: Color(0xFF666666),
    accent: Color(0xFF000000),
    glow: Color(0x14000000),
  );

  static const dark = MuseTheme(
    id: 'dark',
    name: 'Noir',
    background: Color(0xFF000000),
    surface: Color(0xFF1a1a1a),
    border: Color(0xFFffffff),
    text: Color(0xFFffffff),
    muted: Color(0xFFaaaaaa),
    accent: Color(0xFFffffff),
    glow: Color(0x14ffffff),
  );

  static const cyan = MuseTheme(
    id: 'cyan',
    name: 'Vert cyan',
    background: Color(0xFF000000),
    surface: Color(0xFF0a2a2a),
    border: Color(0xFF00ffcc),
    text: Color(0xFFffffff),
    muted: Color(0xFF99ffee),
    accent: Color(0xFF00ffcc),
    glow: Color(0x2000ffcc),
  );

  static const rose = MuseTheme(
    id: 'rose',
    name: 'Rose',
    background: Color(0xFF000000),
    surface: Color(0xFF2a0a1a),
    border: Color(0xFFff99cc),
    text: Color(0xFFffffff),
    muted: Color(0xFFffccdd),
    accent: Color(0xFFff99cc),
    glow: Color(0x20ff99cc),
  );

  static const all = [light, dark, cyan, rose];
}

class MuseTopic {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const MuseTopic({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class MuseTopics {
  static const all = [
    MuseTopic(id: 'art', title: 'Arts visuels', description: 'Peinture, illustration, photo', icon: Icons.palette, color: Colors.pink),
    MuseTopic(id: 'manga', title: 'Manga', description: 'Planches, chapitres', icon: Icons.auto_stories, color: Colors.purple),
    MuseTopic(id: 'music', title: 'Musique', description: 'Compositions, beats', icon: Icons.music_note, color: Colors.blue),
    MuseTopic(id: 'film', title: 'Films', description: 'Scénario, réalisation', icon: Icons.movie, color: Colors.orange),
    MuseTopic(id: 'writing', title: 'Écriture', description: 'Poésie, nouvelles', icon: Icons.edit, color: Colors.cyan),
    MuseTopic(id: 'animation', title: 'Animation', description: 'Motion design', icon: Icons.animation, color: Colors.green),
  ];
}

class _ChatBubble {
  final String text;
  final bool isUser;
  final String? imageUrl;

  _ChatBubble({required this.text, required this.isUser, this.imageUrl});
}

class MuseReply {
  final String text;
  final String? topicId;

  MuseReply({required this.text, this.topicId});
}

class MuseAssistantPage extends StatefulWidget {
  const MuseAssistantPage({super.key});

  @override
  State<MuseAssistantPage> createState() => _MuseAssistantPageState();
}

class _MuseAssistantPageState extends State<MuseAssistantPage> with SingleTickerProviderStateMixin {
  late MuseTheme _theme;
  int _themeIndex = 0;
  final List<_ChatBubble> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showTopics = true;
  bool _isLoading = false;
  VoiceActivityState _voiceState = VoiceActivityState.idle;
  final AiAssistantService _assistant = AiAssistantService();
  String _selectedCategory = 'general';

  static const _welcomeMessage = 'Bonjour créateur ! ✨ Je suis Arteïa Muse, ton assistant artistique. Comment puis-je t\'inspirer aujourd\'hui ?';

  @override
  void initState() {
    super.initState();
    _theme = MuseThemes.all[0];
    _themeIndex = 0;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addMessage(_welcomeMessage, isUser: false);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _cycleTheme() {
    setState(() {
      _themeIndex = (_themeIndex + 1) % MuseThemes.all.length;
      _theme = MuseThemes.all[_themeIndex];
    });
  }

  void _setVoiceState(VoiceActivityState state) {
    if (_voiceState == state) return;
    setState(() => _voiceState = state);
  }

  void _onVoiceTap() async {
    if (_voiceState == VoiceActivityState.listening) {
      _setVoiceState(VoiceActivityState.idle);
      return;
    }
    if (_voiceState == VoiceActivityState.speaking) {
      _setVoiceState(VoiceActivityState.idle);
      return;
    }
    _setVoiceState(VoiceActivityState.listening);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _setVoiceState(VoiceActivityState.processing);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    _setVoiceState(VoiceActivityState.speaking);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;
    _setVoiceState(VoiceActivityState.idle);
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _addMessage(text, isUser: true);
    
    setState(() => _isLoading = true);

    try {
      final history = List<Map<String, String>>.from(
        _messages.whereType<_ChatBubble>().map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
      );
      
      final result = await _assistant.sendMessageWithImage(
        message: text,
        contentType: _selectedCategory,
        history: history,
      );

      _addMessage(result['text'] as String, isUser: false, imageUrl: result['image_url'] as String?);
    } catch (e) {
      _addMessage('Désolé, une erreur est survenue. Réessaie ! 🙏', isUser: false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _selectTopic(MuseTopic topic) {
    setState(() {
      _showTopics = false;
      _selectedCategory = topic.id;
    });
    _textController.text = 'Parle-moi de : ${topic.title}';
    _sendMessage();
  }

  void _addMessage(String text, {required bool isUser, String? imageUrl}) {
    setState(() {
      _messages.add(_ChatBubble(text: text, isUser: isUser, imageUrl: imageUrl));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _theme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header minimaliste
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: _theme.border.withOpacity(0.15))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _theme.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Muse',
                    style: TextStyle(
                      color: _theme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2,
                    ),
                  ),
                  const Spacer(),
                  VoiceActivityIndicator(
                    state: _voiceState,
                    accent: _theme.accent,
                    glow: _theme.glow,
                    onTap: _onVoiceTap,
                  ),
                  const SizedBox(width: 12),
                  _ThemeSwordButton(onTap: _cycleTheme, theme: _theme),
                ],
              ),
            ),

            // Messages avec gradient radiant
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.2,
                    colors: [
                      _theme.glow,
                      _theme.background,
                    ],
                  ),
                ),
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  children: [
                    if (_showTopics) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 320,
                        child: _TopicCardStack(
                          topics: MuseTopics.all,
                          onTopicTap: (index) => _selectTopic(MuseTopics.all[index]),
                          theme: _theme,
                        ),
                      ),
                    ],
                    ..._messages.map((message) => _MessageBubble(message: message, theme: _theme)),
                    if (_isLoading) _buildTypingIndicator(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Bottom bar avec boutons arrondis
            _BottomBar(
              theme: _theme,
              onSend: (_) => _sendMessage(),
              controller: _textController,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_theme.accent, _theme.glow],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: Text('✨', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _theme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: Radius.zero,
              ),
              border: Border.all(color: _theme.border.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(400),
                const SizedBox(width: 4),
                _dot(800),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _theme.text.withOpacity(value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _TopicCardStack extends StatelessWidget {
  final List<MuseTopic> topics;
  final ValueChanged<int> onTopicTap;
  final MuseTheme theme;

  const _TopicCardStack({
    required this.topics,
    required this.onTopicTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: topics.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final topic = topics[index];
        return GestureDetector(
          onTap: () => onTopicTap(index),
          child: Container(
            width: 200,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.border.withOpacity(0.2)),
              color: theme.surface.withOpacity(0.95),
              boxShadow: [
                BoxShadow(
                  color: theme.glow,
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(topic.icon, color: topic.color, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    topic.title,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topic.description,
                    style: TextStyle(
                      color: theme.muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class _MessageBubble extends StatelessWidget {
  final _ChatBubble message;
  final MuseTheme theme;

  const _MessageBubble({required this.message, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.accent, theme.glow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: Text('✨', style: TextStyle(fontSize: 14))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: message.isUser
                    ? theme.surface.withOpacity(0.9)
                    : Color.lerp(theme.surface, theme.background, 0.1),
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: message.isUser ? const Radius.circular(16) : Radius.zero,
                  bottomRight: message.isUser ? Radius.zero : const Radius.circular(16),
                ),
                border: Border.all(
                  color: message.isUser
                      ? theme.border.withOpacity(0.3)
                      : theme.border.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.imageUrl!,
                        width: 240,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(width: 240, height: 180, color: theme.background, child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: theme.accent)));
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _ThemeSwordButton extends StatelessWidget {
  final VoidCallback onTap;
  final MuseTheme theme;

  const _ThemeSwordButton({required this.onTap, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: theme.border.withOpacity(0.3)),
        ),
        child: CustomPaint(
          painter: _ZeldaSwordPainter(theme: theme),
          size: const Size(24, 24),
        ),
      ),
    );
  }
}

class _ZeldaSwordPainter extends CustomPainter {
  final MuseTheme theme;

  _ZeldaSwordPainter({required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = theme.accent
      ..style = PaintingStyle.fill;

    final path = Path();
    final h = size.height;
    final w = size.width;

    path.moveTo(w * 0.35, h * 0.15);
    path.lineTo(w * 0.65, h * 0.15);
    path.lineTo(w * 0.75, h * 0.35);
    path.lineTo(w * 0.85, h * 0.5);
    path.lineTo(w * 0.5, h * 0.65);
    path.lineTo(w * 0.15, h * 0.5);
    path.lineTo(w * 0.25, h * 0.35);
    path.close();

    path.moveTo(w * 0.35, h * 0.35);
    path.lineTo(w * 0.65, h * 0.35);
    path.lineTo(w * 0.7, h * 0.3);
    path.lineTo(w * 0.65, h * 0.25);
    path.lineTo(w * 0.35, h * 0.25);
    path.lineTo(w * 0.3, h * 0.3);
    path.close();

    path.moveTo(w * 0.4, h * 0.65);
    path.lineTo(w * 0.6, h * 0.65);
    path.lineTo(w * 0.6, h * 0.85);
    path.lineTo(w * 0.4, h * 0.85);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ZeldaSwordPainter oldDelegate) => oldDelegate.theme != theme;
}

class _BottomBar extends StatelessWidget {
  final MuseTheme theme;
  final ValueChanged<String> onSend;
  final TextEditingController controller;
  final bool isLoading;

  const _BottomBar({required this.theme, required this.onSend, required this.controller, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 14,
      ),
      decoration: BoxDecoration(
        color: theme.background.withOpacity(0.95),
        border: Border(top: BorderSide(color: theme.border.withOpacity(0.15))),
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.brush_rounded,
            theme: theme,
            onTap: () {},
            label: 'Dessiner',
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.local_florist_rounded,
            theme: theme,
            onTap: () {},
            label: 'Lotus',
          ),
          const SizedBox(width: 10),
          _ActionButton(
            icon: Icons.add_rounded,
            theme: theme,
            onTap: () {},
            label: 'Ajouter',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.border.withOpacity(0.2)),
                color: theme.surface.withOpacity(0.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: TextStyle(color: theme.text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Écris à Muse…',
                        hintStyle: TextStyle(color: theme.muted, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (_) => onSend(controller.text),
                      textInputAction: TextInputAction.send,
                    ),
                  ),
                  GestureDetector(
                    onTap: isLoading ? null : () => onSend(controller.text),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [theme.accent, theme.glow],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                        color: theme.text,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final MuseTheme theme;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.border.withOpacity(0.2)),
          color: theme.surface.withOpacity(0.6),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.accent, size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: theme.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum VoiceActivityState { idle, listening, processing, speaking }

class VoiceActivityIndicator extends StatelessWidget {
  final VoiceActivityState state;
  final Color accent;
  final Color glow;
  final VoidCallback? onTap;

  const VoiceActivityIndicator({
    super.key,
    required this.state,
    required this.accent,
    required this.glow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: state == VoiceActivityState.idle ? _surfaceColor() : accent,
          boxShadow: [
            if (state != VoiceActivityState.idle)
              BoxShadow(
                color: glow,
                blurRadius: 24,
                spreadRadius: 4,
              ),
          ],
        ),
        child: Center(
          child: _buildContent(),
        ),
      ),
    );
  }

  Color _surfaceColor() {
    return Colors.grey.withValues(alpha: 0.08);
  }

  Widget _buildContent() {
    switch (state) {
      case VoiceActivityState.idle:
        return Icon(Icons.mic_none_rounded, color: Colors.grey[400], size: 28);
      case VoiceActivityState.listening:
        return _WaveformAnimation(color: Colors.white);
      case VoiceActivityState.processing:
        return _PulsingDots(color: Colors.white);
      case VoiceActivityState.speaking:
        return _SpeakingRings(accent: accent);
    }
  }
}

class _WaveformAnimation extends StatefulWidget {
  final Color color;
  const _WaveformAnimation({required this.color});

  @override
  State<_WaveformAnimation> createState() => _WaveformAnimationState();
}

class _WaveformAnimationState extends State<_WaveformAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final start = i * 0.15;
            final phase = ((_controller.value + start) % 1.0);
            final scale = 1.0 + 0.8 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2);
            final height = 6 + 14 * (scale - 1.0);
            return Container(
              width: 3,
              height: height,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PulsingDots extends StatelessWidget {
  final Color color;
  const _PulsingDots({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Dot(color: color, delay: 0),
        const SizedBox(width: 4),
        _Dot(color: color, delay: 1),
        const SizedBox(width: 4),
        _Dot(color: color, delay: 2),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final int delay;
  const _Dot({required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color.withValues(alpha: value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class _SpeakingRings extends StatelessWidget {
  final Color accent;
  const _SpeakingRings({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _Ring(color: accent, delay: 0),
        _Ring(color: accent, delay: 1),
        _Ring(color: accent, delay: 2),
        Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  final Color color;
  final int delay;
  const _Ring({required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 1400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final scale = 0.6 + 0.8 * value;
        final alpha = 1.0 - value;
        return Container(
          width: 40 * scale,
          height: 40 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: alpha * 0.6), width: 2),
          ),
        );
      },
    );
  }
}