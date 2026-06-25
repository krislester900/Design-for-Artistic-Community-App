import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Innovative animated logo for Artéïa
/// Features an artistic "A" monogram with animated brush-stroke effects
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
        final rotation = _controller.value * 2 * math.pi;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated logo mark - gradient sphere with letter
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  startAngle: rotation,
                  endAngle: rotation + math.pi * 2,
                  colors: const [
                    Color(0xFF7C5CFC), // Purple
                    Color(0xFFFF6B9D), // Pink
                    Color(0xFF00D4AA), // Teal
                    Color(0xFF7C5CFC), // Back to purple
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C5CFC).withOpacity(0.3 + (pulse * 0.15)),
                    blurRadius: 8 + (pulse * 4),
                    spreadRadius: 1 + (pulse * 2),
                  ),
                ],
              ),
              child: Center(
                child: CustomPaint(
                  painter: _ArteiaLetterPainter(
                    progress: _controller.value,
                    isDark: isDark,
                  ),
                  size: Size(widget.size * 0.6, widget.size * 0.6),
                ),
              ),
            ),
            if (widget.showText) ...[
              const SizedBox(width: 10),
              // Gradient text
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    const Color(0xFF7C5CFC),
                    Color.lerp(
                      const Color(0xFF00D4AA),
                      const Color(0xFFFF6B9D),
                      (math.sin(rotation) * 0.5 + 0.5),
                    )!,
                  ],
                ).createShader(bounds),
                child: Text(
                  'Artéïa',
                  style: TextStyle(
                    fontSize: widget.size * 0.55,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Custom painter for the artistic "A" letterform
class _ArteiaLetterPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _ArteiaLetterPainter({required this.progress, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final s = size.width / 30;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0 * s;

    // Left leg of A
    paint.color = Colors.white.withOpacity(0.9);
    final leftPath = Path()
      ..moveTo(center.dx - 10 * s, center.dy + 8 * s)
      ..cubicTo(
        center.dx - 8 * s, center.dy - 1 * s,
        center.dx - 3 * s, center.dy - 8 * s,
        center.dx, center.dy - 11 * s,
      );
    
    final leftMetrics = leftPath.computeMetrics();
    for (final metric in leftMetrics) {
      final drawLength = metric.length * (progress % 1.0);
      final extractPath = metric.extractPath(0, drawLength);
      canvas.drawPath(extractPath, paint);
    }

    // Right leg of A (offset phase)
    paint.color = Colors.white.withOpacity(0.7);
    final rightPath = Path()
      ..moveTo(center.dx + 10 * s, center.dy + 8 * s)
      ..cubicTo(
        center.dx + 8 * s, center.dy - 1 * s,
        center.dx + 3 * s, center.dy - 8 * s,
        center.dx, center.dy - 11 * s,
      );
    
    final rightMetrics = rightPath.computeMetrics();
    final phaseOffset = (progress + 0.3) % 1.0;
    for (final metric in rightMetrics) {
      final drawLength = metric.length * phaseOffset;
      final extractPath = metric.extractPath(0, drawLength);
      canvas.drawPath(extractPath, paint);
    }

    // Crossbar of A
    paint.color = Colors.white.withOpacity(0.85);
    paint.strokeWidth = 2.0 * s;
    final crossPhase = (progress + 0.6) % 1.0;
    final crossPath = Path()
      ..moveTo(center.dx - 6 * s, center.dy - 2 * s)
      ..lineTo(center.dx + 6 * s, center.dy - 2 * s);
    
    final crossMetrics = crossPath.computeMetrics();
    for (final metric in crossMetrics) {
      final drawLength = metric.length * crossPhase;
      final extractPath = metric.extractPath(0, drawLength);
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ArteiaLetterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

extension on double {
  double get degrees => this * (math.pi / 180);
}