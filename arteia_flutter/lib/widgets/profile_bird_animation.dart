import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileBirdAnimation extends StatefulWidget {
  final VoidCallback? onAnimationComplete;
  final bool autoPlay;

  const ProfileBirdAnimation({
    super.key,
    this.onAnimationComplete,
    this.autoPlay = true,
  });

  @override
  State<ProfileBirdAnimation> createState() => _ProfileBirdAnimationState();
}

class _ProfileBirdAnimationState extends State<ProfileBirdAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flyAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _collisionAnimation;

  AnimationState _currentState = AnimationState.flying;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _flyAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _collisionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    if (widget.autoPlay) {
      _startFlyingAnimation();
    }
  }

  void _startFlyingAnimation() {
    if (_isAnimating) return;
    _isAnimating = true;
    _currentState = AnimationState.flying;

    _controller.duration = const Duration(milliseconds: 800);
    _controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _isAnimating = false;
          _currentState = AnimationState.hidden;
        });
        widget.onAnimationComplete?.call();
      }
    });
  }

  void _triggerBounceAndCollision() {
    if (_isAnimating || _currentState != AnimationState.flying) return;
    _isAnimating = true;

    // Bounce phase
    _currentState = AnimationState.bouncing;
    _controller.duration = const Duration(milliseconds: 600);
    _controller.forward().then((_) {
      // Collision phase
      _currentState = AnimationState.colliding;
      _controller.duration = const Duration(milliseconds: 400);
      _controller.forward().then((_) {
        // Reset and fly again
        _controller.reset();
        _currentState = AnimationState.flying;
        _isAnimating = false;
        _startFlyingAnimation();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentState == AnimationState.hidden) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _triggerBounceAndCollision,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return _buildBird();
        },
      ),
    );
  }

  Widget _buildBird() {
    double translateY = 0;
    double opacity = 1.0;

    switch (_currentState) {
      case AnimationState.flying:
        translateY = -15 * _flyAnimation.value;
        opacity = 1.0 - _flyAnimation.value;
        break;
      case AnimationState.bouncing:
        final bounceValue = _bounceAnimation.value;
        if (bounceValue < 0.33) {
          translateY = -8 * (bounceValue / 0.33);
        } else if (bounceValue < 0.66) {
          translateY = 4 * ((bounceValue - 0.33) / 0.33);
        } else {
          translateY = 0;
        }
        break;
      case AnimationState.colliding:
        final collisionValue = _collisionAnimation.value;
        if (collisionValue < 0.25) {
          translateY = -3 * (collisionValue / 0.25);
        } else if (collisionValue < 0.5) {
          translateY = 3 * ((collisionValue - 0.25) / 0.25);
        } else {
          translateY = 0;
        }
        break;
      case AnimationState.hidden:
        return const SizedBox.shrink();
    }

    return Transform.translate(
      offset: Offset(0, translateY),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF7C5CFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0xFF7C5CFC),
                blurRadius: 12,
                spreadRadius: 0.3,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

enum AnimationState {
  flying,
  bouncing,
  colliding,
  hidden,
}