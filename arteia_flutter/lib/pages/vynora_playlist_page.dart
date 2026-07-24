import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/web_asset_service.dart';

class VynoraPlaylistPage extends StatefulWidget {
  const VynoraPlaylistPage({super.key});

  @override
  State<VynoraPlaylistPage> createState() => _VynoraPlaylistPageState();
}

class _VynoraPlaylistPageState extends State<VynoraPlaylistPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (e) => setState(() => _error = e.description),
        ),
      );

    if (kIsWeb) {
      _controller.loadRequest(Uri.base.resolve('assets/assets/games/vynora/index.html'));
    } else {
      _controller.loadRequest(Uri.parse(
        LocalWebServer.getUrl('assets/games/vynora/index.html'),
      ));
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white)),
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
