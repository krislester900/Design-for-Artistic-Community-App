import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Maps each page/slug to its Rive transition animation
class PageTransitionConfig {
  static const Map<String, String> pageAnimations = {
    'home': 'assets/animations/cloudy-walk.riv',
    'music': 'assets/animations/rock-girl.riv',
    'community': 'assets/animations/smiley-stress-reliever.riv',
    'film': 'assets/animations/rock-girl.riv',
    'visual-art': 'assets/animations/cloudy-walk.riv',
    'manga': 'assets/animations/cloudy-walk.riv',
    'literature': 'assets/animations/cloudy-walk.riv',
    'animation': 'assets/animations/cloudy-walk.riv',
  };

  static String? getAnimationFor(String slug) {
    return pageAnimations[slug];
  }
}

/// Shows a full-screen Rive animation as a page transition overlay
class PageTransitionOverlay extends StatefulWidget {
  final String riveAsset;
  final VoidCallback onComplete;
  final double durationInSeconds;

  const PageTransitionOverlay({
    super.key,
    required this.riveAsset,
    required this.onComplete,
    this.durationInSeconds = 2.0,
  });

  @override
  State<PageTransitionOverlay> createState() => _PageTransitionOverlayState();
}

class _PageTransitionOverlayState extends State<PageTransitionOverlay> {
  RiveWidgetController? _controller;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRive();

    Future.delayed(Duration(milliseconds: (widget.durationInSeconds * 1000).toInt()), () {
      if (mounted) widget.onComplete();
    });
  }

  Future<void> _loadRive() async {
    try {
      final file = await File.asset(widget.riveAsset, riveFactory: Factory.rive);
      if (file == null) { if (mounted) widget.onComplete(); return; }
      final controller = RiveWidgetController(file);
      if (mounted) {
        setState(() {
          _controller = controller;
          _isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0a0a0a),
      child: Center(
        child: _isLoaded && _controller != null
            ? SizedBox(
                width: 350,
                height: 350,
                child: RiveWidget(
                  controller: _controller!,
                  fit: Fit.contain,
                ),
              )
            : const CircularProgressIndicator(color: Color(0xFF7C5CFC)),
      ),
    );
  }
}