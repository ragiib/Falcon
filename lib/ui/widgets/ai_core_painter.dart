import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';

class AiCoreAnimation extends ConsumerStatefulWidget {
  const AiCoreAnimation({Key? key}) : super(key: key);

  @override
  ConsumerState<AiCoreAnimation> createState() => _AiCoreAnimationState();
}

class _AiCoreAnimationState extends ConsumerState<AiCoreAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiStateProvider);

    // Adjust animation speed based on state
    if (aiState == AiState.thinking) {
      _controller.duration = const Duration(milliseconds: 1500);
      if (!_controller.isAnimating) _controller.repeat();
    } else if (aiState == AiState.generating) {
      _controller.duration = const Duration(milliseconds: 800);
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.duration = const Duration(seconds: 4);
      if (!_controller.isAnimating) _controller.repeat();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: AiCorePainter(
            animationValue: _controller.value,
            state: aiState,
          ),
          size: const Size(150, 150),
        );
      },
    );
  }
}

class AiCorePainter extends CustomPainter {
  final double animationValue;
  final AiState state;

  AiCorePainter({required this.animationValue, required this.state});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Define colors based on state
    Color baseColor;
    switch (state) {
      case AiState.idle:
        baseColor = Colors.cyan;
        break;
      case AiState.thinking:
        baseColor = Colors.purpleAccent;
        break;
      case AiState.generating:
        baseColor = Colors.blueAccent;
        break;
    }

    // Outer glow ring
    final glowPaint = Paint()
      ..color = baseColor.withOpacity(0.1 + 0.1 * math.sin(animationValue * 2 * math.pi))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * 0.8, glowPaint);

    // Inner wave rings
    final ringPaint = Paint()
      ..color = baseColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    int numRings = state == AiState.idle ? 3 : (state == AiState.thinking ? 5 : 4);
    
    for (int i = 0; i < numRings; i++) {
      final offsetValue = (animationValue + (i / numRings)) % 1.0;
      final currentRadius = maxRadius * 0.2 + (maxRadius * 0.6 * offsetValue);
      ringPaint.color = baseColor.withOpacity(1.0 - offsetValue);
      canvas.drawCircle(center, currentRadius, ringPaint);
    }

    // Core center
    final corePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    
    double corePulse = math.sin(animationValue * 2 * math.pi) * 0.2 + 0.8;
    canvas.drawCircle(center, maxRadius * 0.2 * corePulse, corePaint);
  }

  @override
  bool shouldRepaint(covariant AiCorePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.state != state;
  }
}
