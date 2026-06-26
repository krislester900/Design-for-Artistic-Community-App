import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Minimalist black & white animated logo for Artéïa
class ArteiaLogo extends StatefulWidget {
  final double size;
  final bool showText;
  final bool isAnimated;

  const ArteiaLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.isAnimated = true,
  });

  @override
  State<ArteiaLogo> createState() => _ArteiaLogoState();
}

class _ArteiaLogoState extends State<ArteiaLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    if (widget.isAnimated) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = math.sin(_controller.value * 2 * math.pi);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Minimalist animated "A" mark
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white : Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.15 * (pulse * 0.5 + 0.5)),
                    blurRadius: 6 + (pulse * 3),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontSize: widget.size * 0.55,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
            if (widget.showText) ...[
              const SizedBox(width: 10),
              Text(
                'Artéïa',
                style: TextStyle(
                  fontSize: widget.size * 0.55,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}