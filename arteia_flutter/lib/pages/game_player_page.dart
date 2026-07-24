import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/web_asset_service.dart';

class GamePlayerPage extends StatefulWidget {
  final String title;
  final String? localAssetPath;
  final String? remoteUrl;

  const GamePlayerPage({
    super.key,
    required this.title,
    this.localAssetPath,
    this.remoteUrl,
  }) : assert(localAssetPath != null || remoteUrl != null, 'Must provide either localAssetPath or remoteUrl');

  @override
  State<GamePlayerPage> createState() => _GamePlayerPageState();
}

class _GamePlayerPageState extends State<GamePlayerPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Forcer le mode paysage pour les jeux
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    _controller = WebViewController()
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate());

    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    }

    if (widget.localAssetPath != null) {
      if (kIsWeb) {
        _controller.loadRequest(Uri.base.resolve('assets/assets/${widget.localAssetPath}'));
      } else {
        _controller.loadRequest(Uri.parse(
          LocalWebServer.getUrl('assets/${widget.localAssetPath}'),
        ));
      }
    } else if (widget.remoteUrl != null) {
      _controller.loadRequest(Uri.parse(widget.remoteUrl!));
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    // Restaurer l'orientation portrait en quittant le jeu
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.deepOrange),
            ),
          // Bouton retour flottant
          Positioned(
            top: 20,
            left: 20,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
