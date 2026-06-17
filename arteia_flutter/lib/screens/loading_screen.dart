import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoadingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const LoadingScreen({super.key, required this.onComplete});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _blinkController;
  late AnimationController _meltController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _meltAnim;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3800));
    _blinkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000));
    _meltController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.2, curve: Curves.easeOut)));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.03).animate(CurvedAnimation(parent: _mainController, curve: const Interval(0.2, 0.6, curve: Curves.easeOut)));
    _meltAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _meltController, curve: Curves.easeIn));

    _mainController.forward();
    _blinkController.repeat();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) _meltController.forward();
    });

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _blinkController.dispose();
    _meltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Stack(
        children: [
          // Alien SVG
          Center(
            child: AnimatedBuilder(
              animation: _fadeAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, _meltAnim.value * 80),
                      child: Transform.scale(
                        scale: 1.0 + _meltAnim.value * 0.8,
                        child: SizedBox(
                          width: 180,
                          height: 240,
                          child: CustomPaint(
                            painter: _AlienPainter(
                              blinkValue: _blinkController.value,
                              meltValue: _meltAnim.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Puddle
          Positioned(
            bottom: 0.42,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                final puddleOpacity = _mainController.value > 0.85 ? (_mainController.value - 0.85) * 6.67 : 0.0;
                return Opacity(
                  opacity: puddleOpacity.clamp(0.0, 1.0),
                  child: CustomPaint(
                    size: const Size(160, 40),
                    painter: _PuddlePainter(),
                  ),
                );
              },
            ),
          ),
          // Text
          Positioned(
            bottom: 0.15,
            left: 0,
            right: 0,
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                final textOpacity = _mainController.value > 0.6 ? 1.0 - (_mainController.value - 0.6) * 2.5 : 1.0;
                return Opacity(
                  opacity: textOpacity.clamp(0.0, 1.0),
                  child: const Text(
                    'ARTÉÏA',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Alien Block',
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.35,
                      color: Colors.white70,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlienPainter extends CustomPainter {
  final double blinkValue;
  final double meltValue;

  _AlienPainter({required this.blinkValue, required this.meltValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Head
    paint.color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(centerX, centerY + 10), width: 144, height: 180),
      paint,
    );

    // Eyes background
    paint.color = const Color(0xFF0a0a0a);
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX - 28, centerY), width: 48, height: 60), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX + 28, centerY), width: 48, height: 60), paint);

    // Blink effect
    final leftLidScale = blinkValue < 0.42 || blinkValue > 0.46 ? 1.0 : 0.05;
    final rightLidScale = blinkValue < 0.55 || blinkValue > 0.59 ? 1.0 : 0.05;

    // Left eye lid
    canvas.save();
    canvas.translate(centerX - 28, centerY);
    canvas.scale(1, leftLidScale);
    paint.color = Colors.white;
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 48, height: 60), paint);
    canvas.restore();

    // Right eye lid
    canvas.save();
    canvas.translate(centerX + 28, centerY);
    canvas.scale(1, rightLidScale);
    paint.color = Colors.white;
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 0), width: 48, height: 60), paint);
    canvas.restore();

    // Pupils
    paint.color = Colors.white;
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX - 28, centerY + 2), width: 28, height: 36), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(centerX + 28, centerY + 2), width: 28, height: 36), paint);

    // Eye shine
    paint.color = const Color(0xFF0a0a0a);
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX - 32, centerY - 4), 5, paint);
    canvas.drawCircle(Offset(centerX + 24, centerY - 4), 5, paint);

    // Nose
    strokePaint.color = const Color(0xFF333333);
    canvas.drawLine(Offset(centerX - 4, centerY + 30), Offset(centerX, centerY + 38), strokePaint);
    canvas.drawLine(Offset(centerX + 4, centerY + 30), Offset(centerX, centerY + 38), strokePaint);

    // Mouth
    final path = Path();
    path.moveTo(centerX - 18, centerY + 55);
    path.quadraticBezierTo(centerX, centerY + 65, centerX + 18, centerY + 55);
    strokePaint.color = const Color(0xFF444444);
    canvas.drawPath(path, strokePaint);

    // Antennas
    strokePaint.color = Colors.white.withOpacity(0.6);
    strokePaint.strokeWidth = 2;
    canvas.drawLine(Offset(centerX - 40, centerY - 85), Offset(centerX - 25, centerY - 55), strokePaint);
    canvas.drawCircle(Offset(centerX - 43, centerY - 88), 5, paint..color = Colors.white.withOpacity(0.8));
    canvas.drawLine(Offset(centerX + 40, centerY - 85), Offset(centerX + 25, centerY - 55), strokePaint);
    canvas.drawCircle(Offset(centerX + 43, centerY - 88), 5, paint..color = Colors.white.withOpacity(0.8));
  }

  @override
  bool shouldRepaint(covariant _AlienPainter oldDelegate) => true;
}

class _PuddlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white.withOpacity(0.15), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width, height: size.height));

    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width, height: size.height * 0.4),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}