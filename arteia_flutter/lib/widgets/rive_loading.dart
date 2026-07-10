import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// A loading overlay showing a Rive animation.
/// Used as a transition/loading animation for music and film universes.
class RiveLoading extends StatefulWidget {
  final String riveAsset;
  final VoidCallback onComplete;
  final double durationInSeconds;

  const RiveLoading({
    super.key,
    required this.riveAsset,
    required this.onComplete,
    this.durationInSeconds = 2.5,
  });

  @override
  State<RiveLoading> createState() => _RiveLoadingState();
}

class _RiveLoadingState extends State<RiveLoading> {
  RiveWidgetController? _controller;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadRive();

    // Auto-complete after timeout
    Future.delayed(Duration(milliseconds: (widget.durationInSeconds * 1000).toInt()), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  Future<void> _loadRive() async {
    try {
      final file = await File.asset(widget.riveAsset, riveFactory: Factory.rive);
      if (file == null) { if (mounted) { widget.onComplete(); } return; }
      final controller = RiveWidgetController(file);
      if (mounted) {
        setState(() {
          _controller = controller;
          _isLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        widget.onComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0a0a0a),
      child: Center(
        child: _isLoaded && _controller != null
            ? SizedBox(
                width: 300,
                height: 300,
                child: RiveWidget(
                  controller: _controller!,
                  fit: Fit.contain,
                ),
              )
            : const CircularProgressIndicator(
                color: Color(0xFF7C5CFC),
              ),
      ),
    );
  }
}