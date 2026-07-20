import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
  int _currentTopicIndex = 0;
  bool _showTopics = true;
  bool _isLoading = false;
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
                  _ThemeSwordButton(onTap: _cycleTheme, theme: _theme),
                ],
              ),
            ),

            // Messages + Card Stack avec gradient radiant
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
                        height: 350,
                        child: _TopicCardStack(
                          topics: MuseTopics.all,
                          currentIndex: _currentTopicIndex,
                          onIndexChanged: (i) => setState(() => _currentTopicIndex = i),
                          onTap: _selectTopic,
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

class _TopicCardStack extends StatefulWidget {
  final List<MuseTopic> topics;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final ValueChanged<MuseTopic> onTap;
  final MuseTheme theme;

  const _TopicCardStack({
    required this.topics,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.onTap,
    required this.theme,
  });

  @override
  State<_TopicCardStack> createState() => _TopicCardStackState();
}

class _TopicCardStackState extends State<_TopicCardStack> with SingleTickerProviderStateMixin {
  int _displayIndex = 0;
  double _dragOffset = 0;
  bool _isDragging = false;
  double _velocity = 0;
  DateTime _lastDragTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _displayIndex = widget.currentIndex;
  }

  @override
  void didUpdateWidget(covariant _TopicCardStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _displayIndex = widget.currentIndex;
    }
  }

  void _handleDragStart(Offset globalPosition) {
    setState(() {
      _isDragging = true;
      _dragOffset = 0;
      _velocity = 0;
    });
    _lastDragTime = DateTime.now();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final now = DateTime.now();
    final deltaTime = now.difference(_lastDragTime).inMilliseconds.toDouble();
    _lastDragTime = now;

    final newOffset = details.globalPosition.dx;
    setState(() {
      _dragOffset = newOffset;
      _velocity = (newOffset - _dragOffset) / (deltaTime > 1 ? deltaTime : 1);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    setState(() => _isDragging = false);

    const threshold = 50.0;
    const velocityThreshold = 0.5;

    final swipe = _dragOffset * _velocity;

    if (_dragOffset.abs() > threshold || _velocity.abs() > velocityThreshold || swipe.abs() > threshold) {
      if (_dragOffset < 0 || _velocity < -velocityThreshold || swipe < -threshold) {
        final newIndex = (_displayIndex + 1).clamp(0, widget.topics.length - 1);
        widget.onIndexChanged(newIndex);
        widget.onTap(widget.topics[newIndex]);
      } else if (_dragOffset > 0 || _velocity > velocityThreshold || swipe > threshold) {
        final newIndex = (_displayIndex - 1).clamp(0, widget.topics.length - 1);
        widget.onIndexChanged(newIndex);
        widget.onTap(widget.topics[newIndex]);
      }
    }

    _dragOffset = 0;
    _velocity = 0;
  }

  @override
  Widget build(BuildContext context) {
    final indices = [
      (_displayIndex - 1 + widget.topics.length) % widget.topics.length,
      _displayIndex,
      (_displayIndex + 1) % widget.topics.length,
      (_displayIndex + 2) % widget.topics.length,
    ];

    final scales = [0.8, 1.0, 0.9, 0.85];
    final yOffsets = [12.0, 0.0, -12.0, 0.0];
    final xOffsets = [62.0, 0.0, 32.0, 48.0];
    final rotations = [7.0, 0.0, 2.0, 4.0];

    return GestureDetector(
      onHorizontalDragStart: (d) => _handleDragStart(d.globalPosition),
      onHorizontalDragUpdate: (d) => _handleDragUpdate(d),
      onHorizontalDragEnd: _handleDragEnd,
      onTap: () => widget.onTap(widget.topics[_displayIndex]),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: List.generate(4, (i) {
            final topic = widget.topics[indices[i]];
            return _AnimatedTopicCard(
              topic: topic,
              theme: widget.theme,
              scale: scales[i],
              yOffset: yOffsets[i],
              xOffset: xOffsets[i],
              rotation: rotations[i],
              index: i,
              isDragging: _isDragging,
              dragOffset: _dragOffset,
              onTap: () => widget.onTap(topic),
            );
          }),
        ),
      ),
    );
  }
}

class _AnimatedTopicCard extends StatelessWidget {
  final MuseTopic topic;
  final MuseTheme theme;
  final double scale;
  final double yOffset;
  final double xOffset;
  final double rotation;
  final int index;
  final bool isDragging;
  final double dragOffset;
  final VoidCallback onTap;

  const _AnimatedTopicCard({
    required this.topic,
    required this.theme,
    required this.scale,
    required this.yOffset,
    required this.xOffset,
    required this.rotation,
    required this.index,
    required this.isDragging,
    required this.dragOffset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = scale == 1.0 ? 1.0 : 0.6;
    
    return Positioned(
      left: xOffset + (isDragging ? dragOffset / 4 : 0),
      top: yOffset,
      child: AnimatedBuilder(
        animation: Tween(begin: scale, end: scale).animate(
          CurvedAnimation(parent: AlwaysStoppedAnimation(1.0), curve: Curves.easeOut),
        ),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(scale == 1.0 ? 0 : (xOffset > 0 ? xOffset - 30 : 0), 0),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    width: 280,
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: theme.border.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: theme.glow,
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: theme.surface.withOpacity(0.95),
                        border: Border.all(color: theme.border.withOpacity(0.25)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                color: topic.color.withOpacity(0.1),
                              ),
                              child: Icon(topic.icon, color: topic.color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: topic.color.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  '${MuseTopics.all.indexOf(topic) + 1}/${MuseTopics.all.length}',
                                  style: TextStyle(
                                    color: theme.muted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
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

    // Pixelated sword blade
    path.moveTo(w * 0.35, h * 0.15);
    path.lineTo(w * 0.65, h * 0.15);
    path.lineTo(w * 0.75, h * 0.35);
    path.lineTo(w * 0.85, h * 0.5);
    path.lineTo(w * 0.5, h * 0.65);
    path.lineTo(w * 0.15, h * 0.5);
    path.lineTo(w * 0.25, h * 0.35);
    path.close();

    // Crossguard
    path.moveTo(w * 0.35, h * 0.35);
    path.lineTo(w * 0.65, h * 0.35);
    path.lineTo(w * 0.7, h * 0.3);
    path.lineTo(w * 0.65, h * 0.25);
    path.lineTo(w * 0.35, h * 0.25);
    path.lineTo(w * 0.3, h * 0.3);
    path.close();

    // Handle
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
          // Bouton dessiner
          _ActionButton(
            icon: Icons.brush_rounded,
            theme: theme,
            onTap: () {},
            label: 'Dessiner',
          ),
          const SizedBox(width: 10),
          // Bouton lotus
          _ActionButton(
            icon: Icons.local_florist_rounded,
            theme: theme,
            onTap: () {},
            label: 'Lotus',
          ),
          const SizedBox(width: 10),
          // Bouton ajouter
          _ActionButton(
            icon: Icons.add_rounded,
            theme: theme,
            onTap: () {},
            label: 'Ajouter',
          ),
          const SizedBox(width: 12),
          // Champ de texte
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