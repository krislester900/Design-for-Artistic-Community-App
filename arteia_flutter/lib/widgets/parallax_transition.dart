import 'package:flutter/material.dart';

class ParallaxTransition extends StatefulWidget {
  final Widget child;
  final double parallaxOffset;
  final Duration duration;

  const ParallaxTransition({
    super.key,
    required this.child,
    this.parallaxOffset = 150.0,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  State<ParallaxTransition> createState() => _ParallaxTransitionState();
}

class _ParallaxTransitionState extends State<ParallaxTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    animation = Tween(begin: 0.0, end: 1.0).animate(controller)
      ..addListener(() => setState(() {}));

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: animation.value * -widget.parallaxOffset,
          left: 0,
          right: 0,
          child: Opacity(
            opacity: Curves.easeInOutQuad.transform(animation.value),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}