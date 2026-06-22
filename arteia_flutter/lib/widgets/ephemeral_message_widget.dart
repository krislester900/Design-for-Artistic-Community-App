import 'package:flutter/material.dart';
import 'dart:async';

class EphemeralMessageWidget extends StatefulWidget {
  final Duration duration;
  final Widget child;
  final VoidCallback? onExpired;

  const EphemeralMessageWidget({
    super.key,
    required this.duration,
    required this.child,
    this.onExpired,
  });

  @override
  State<EphemeralMessageWidget> createState() => _EphemeralMessageWidgetState();
}

class _EphemeralMessageWidgetState extends State<EphemeralMessageWidget> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.duration;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remaining = _remaining - const Duration(seconds: 1);
      });
      
      if (_remaining <= Duration.zero) {
        timer.cancel();
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Timer indicator
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatDuration(_remaining),
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        // Progress bar
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: LinearProgressIndicator(
            value: _remaining.inMilliseconds / widget.duration.inMilliseconds,
            backgroundColor: Colors.transparent,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
            minHeight: 2,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) {
      return '${seconds}s';
    } else {
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      return '${minutes}m ${remainingSeconds}s';
    }
  }
}