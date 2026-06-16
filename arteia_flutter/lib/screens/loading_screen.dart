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
  late AnimationController _particleController;
  late AnimationController _logoController;
  late AnimationController _progressController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _logoGlow;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(begin: 0.5, end: 1).animate(CurvedAnimation(parent: _logoController, curve: Curves.elasticOut));
    _logoGlow = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeInOut));
    _progress = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic));

    _mainController.forward();
    _logoController.forward();
    _progressController.forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Animated background gradient
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _BackgroundPainter(
                  progress: _particleController.value,
                  glow: _logoGlow.value,
                ),
                size: Size.infinite,
              );
            },
          ),
          // Glassmorphism overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryViolet.withOpacity(0.1),
                  Colors.transparent,
                  AppTheme.primaryPink.withOpacity(0.05),
                ],
              ),
            ),
          ),
          // Content
          Center(
            child: AnimatedBuilder(
              animation: _fadeAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      AnimatedBuilder(
                        animation: _scaleAnim,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnim.value,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primaryViolet, AppTheme.primaryTeal],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryViolet.withOpacity(0.4 * _logoGlow.value),
                                    blurRadius: 40 * _logoGlow.value,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: AppTheme.primaryTeal.withOpacity(0.2 * _logoGlow.value),
                                    blurRadius: 60 * _logoGlow.value,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      // Title with glow effect
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppTheme.primaryViolet, AppTheme.primaryPink, AppTheme.primaryTeal],
                        ).createShader(bounds),
                        child: const Text(
                          'Artéïa',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Communauté Artistique',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted.withOpacity(_fadeAnim.value),
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Progress bar
                      AnimatedBuilder(
                        animation: _progress,
                        builder: (context, child) {
                          return Column(
                            children: [
                              Container(
                                width: 200,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.cardDark,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _progress.value,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [AppTheme.primaryViolet, AppTheme.primaryTeal],
                                      ),
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryViolet.withOpacity(0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                '${(_progress.value * 100).toInt()}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted.withOpacity(0.6),
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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

class _BackgroundPainter extends CustomPainter {
  final double progress;
  final double glow;

  _BackgroundPainter({required this.progress, required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Floating particles
    final random = Random(42);
    for (int i = 0; i < 30; i++) {
      final x = (random.nextDouble() * size.width);
      final y = (random.nextDouble() * size.height);
      final radius = random.nextDouble() * 3 + 1;
      final opacity = (sin(progress * 2 * pi + i) * 0.5 + 0.5) * 0.3;

      paint.color = [
        AppTheme.primaryViolet,
        AppTheme.primaryTeal,
        AppTheme.primaryPink,
      ][i % 3].withOpacity(opacity);

      canvas.drawCircle(Offset(x, y - progress * 50 % size.height), radius, paint);
    }

    // Glow orbs
    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryViolet.withOpacity(0.15 * glow),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.3, size.height * 0.4), radius: 200));
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), 200, paint);

    paint.shader = RadialGradient(
      colors: [
        AppTheme.primaryTeal.withOpacity(0.1 * glow),
        Colors.transparent,
      ],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.7, size.height * 0.6), radius: 180));
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.6), 180, paint);
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) => true;
}