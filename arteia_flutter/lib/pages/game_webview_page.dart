import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GameWebviewPage extends StatefulWidget {
  final String title;
  final String assetPath;

  const GameWebviewPage({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<GameWebviewPage> createState() => _GameWebviewPageState();
}

class _GameWebviewPageState extends State<GameWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
          _injectTouchControls();
        },
      ))
      ..loadFlutterAsset(widget.assetPath);
  }

  /// Injecte des contrôles tactiles adaptés au Samsung A17 (1080x2340)
  Future<void> _injectTouchControls() async {
    await _controller.runJavaScript('''
(function() {
  if (document.getElementById('__touch_controls')) return;

  var container = document.createElement('div');
  container.id = '__touch_controls';
  container.style.cssText = 'position:fixed;bottom:0;left:0;right:0;z-index:9999;display:flex;justify-content:center;gap:12px;padding:16px 20px 32px;background:linear-gradient(transparent,rgba(0,0,0,0.7));pointer-events:none';

  var keys = [
    {label:'←', key:'ArrowLeft'},
    {label:'↑', key:'ArrowUp'},
    {label:'↓', key:'ArrowDown'},
    {label:'→', key:'ArrowRight'},
    {label:'␣', key:' ', w:2},
    {label:'↵', key:'Enter', w:2},
  ];

  keys.forEach(function(k) {
    var btn = document.createElement('button');
    btn.textContent = k.label;
    var w = k.w ? 80*k.w : 80;
    btn.style.cssText = 'pointer-events:auto;width:'+w+'px;height:72px;font-size:28px;border:2px solid rgba(255,255,255,0.4);border-radius:16px;background:rgba(255,255,255,0.12);color:white;backdrop-filter:blur(6px);-webkit-backdrop-filter:blur(6px);touch-action:manipulation;user-select:none;-webkit-user-select:none;font-weight:bold';
    btn.addEventListener('touchstart', function(e) {
      e.preventDefault();
      btn.style.background = 'rgba(255,255,255,0.35)';
      btn.style.transform = 'scale(0.92)';
      document.dispatchEvent(new KeyboardEvent('keydown', {key: k.key, bubbles: true}));
    });
    btn.addEventListener('touchend', function(e) {
      e.preventDefault();
      btn.style.background = 'rgba(255,255,255,0.12)';
      btn.style.transform = 'scale(1)';
      document.dispatchEvent(new KeyboardEvent('keyup', {key: k.key, bubbles: true}));
    });
    container.appendChild(btn);
  });

  document.body.appendChild(container);
})();
''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7C5CFC),
              ),
            ),
        ],
      ),
    );
  }
}