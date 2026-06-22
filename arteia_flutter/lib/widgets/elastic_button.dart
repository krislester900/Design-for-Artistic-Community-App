import 'package:flutter/material.dart';

class ElasticButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color color;
  final double width;
  final double height;
  final double borderRadius;

  const ElasticButton({
    super.key,
    required this.child,
    required this.onTap,
    this.color = Colors.black,
    this.width = 200.0,
    this.height = 50.0,
    this.borderRadius = 40.0,
  });

  @override
  State<ElasticButton> createState() => _ElasticButtonState();
}

class _ElasticButtonState extends State<ElasticButton>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  double scale = 1.0;

  void _onTap() async {
    setState(() => scale = 0.9);
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() => scale = 1.0);
    widget.onTap();
  }

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
      lowerBound: -0.5,
      upperBound: 0.5,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 0.9).animate(controller),
      child: GestureDetector(
        onTapDown: (_) => setState(() => scale = 0.9),
        onTapUp: (_) => setState(() => scale = 1.0),
        onTapCancel: () => setState(() => scale = 1.0),
        onTap: _onTap,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}