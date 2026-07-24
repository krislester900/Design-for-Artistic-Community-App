import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VynoraMusicPage extends StatefulWidget {
  const VynoraMusicPage({super.key});

  @override
  State<VynoraMusicPage> createState() => _VynoraMusicPageState();
}

class _VynoraMusicPageState extends State<VynoraMusicPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
      
    if (kIsWeb) {
      _controller.loadRequest(Uri.base.resolve('assets/assets/games/vynora/index.html'));
    } else {
      _controller.setBackgroundColor(Colors.black);
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      _controller.loadFlutterAsset('assets/games/vynora/index.html');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}