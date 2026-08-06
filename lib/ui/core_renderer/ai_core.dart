import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/audio_provider.dart';
import '../theme/app_colors.dart';

class AiCore extends ConsumerStatefulWidget {
  const AiCore({Key? key}) : super(key: key);

  @override
  ConsumerState<AiCore> createState() => _AiCoreState();
}

class _AiCoreState extends ConsumerState<AiCore> with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiStateProvider);
    final amplitude = ref.watch(audioAmplitudeProvider);

    // Adjust speeds based on state
    switch (aiState) {
      case AiState.idle:
      case AiState.listening:
        _mainController.duration = const Duration(seconds: 12);
        _pulseController.duration = const Duration(seconds: 3);
        break;
      case AiState.thinking:
        _mainController.duration = const Duration(seconds: 4);
        _pulseController.duration = const Duration(seconds: 1);
        break;
      case AiState.generating:
      case AiState.speaking:
        _mainController.duration = const Duration(seconds: 2);
        _pulseController.duration = const Duration(milliseconds: 500);
        break;
      default:
        _mainController.duration = const Duration(seconds: 12);
        _pulseController.duration = const Duration(seconds: 3);
    }
    
    if (!_mainController.isAnimating) _mainController.repeat();
    if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _pulseController]),
        builder: (context, child) {
          return CustomPaint(
            painter: AiCorePainter(
              rotationValue: _mainController.value,
              pulseValue: _pulseController.value,
              state: aiState,
              amplitude: amplitude,
            ),
            size: const Size(350, 350), // Larger for center of screen
          );
        },
      ),
    );
  }
}

class AiCorePainter extends CustomPainter {
  final double rotationValue;
  final double pulseValue;
  final AiState state;
  final double amplitude;

  AiCorePainter({
    required this.rotationValue,
    required this.pulseValue,
    required this.state,
    required this.amplitude,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    Color primaryColor = AppColors.cyanGlow;
    Color secondaryColor = AppColors.blueEnergy;

    switch (state) {
      case AiState.thinking:
        primaryColor = AppColors.purpleEnergy;
        secondaryColor = AppColors.cyanGlow;
        break;
      case AiState.speaking:
      case AiState.generating:
        primaryColor = AppColors.blueEnergy;
        secondaryColor = AppColors.cyanGlow;
        break;
      case AiState.error:
        primaryColor = AppColors.error;
        secondaryColor = Colors.redAccent;
        break;
      case AiState.warning:
        primaryColor = AppColors.warning;
        secondaryColor = Colors.orangeAccent;
        break;
      case AiState.success:
        primaryColor = AppColors.success;
        secondaryColor = Colors.greenAccent;
        break;
      default:
        break;
    }

    // React to amplitude: boost scale and glow
    final dynamicScale = 1.0 + (amplitude * 0.4);
    final baseRadius = maxRadius * 0.8 * dynamicScale;

    // 1. Outer ambient glow
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.15 + (0.1 * pulseValue) + (amplitude * 0.2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius, glowPaint);

    // 2. Rotating orbital rings
    _drawOrbitalRing(canvas, center, baseRadius * 0.9, rotationValue * 2 * math.pi, primaryColor, 2.0);
    _drawOrbitalRing(canvas, center, baseRadius * 0.75, -rotationValue * 3 * math.pi, secondaryColor, 1.0, dashed: true);
    _drawOrbitalRing(canvas, center, baseRadius * 0.6, rotationValue * 1.5 * math.pi, primaryColor, 1.5);

    // 3. Inner energy wave propagation
    final wavePaint = Paint()
      ..color = primaryColor.withOpacity(0.4 * (1 - pulseValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, baseRadius * 0.4 + (baseRadius * 0.3 * pulseValue), wavePaint);

    // 4. Core Nucleus (reacts strongly to amplitude)
    final corePaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 15)
      ..style = PaintingStyle.fill;
    final nucleusSize = baseRadius * 0.15 + (baseRadius * 0.05 * pulseValue) + (baseRadius * 0.2 * amplitude);
    canvas.drawCircle(center, nucleusSize, corePaint);

    // 5. Nucleus Aura
    final auraPaint = Paint()
      ..color = secondaryColor.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, nucleusSize * 1.5, auraPaint);
  }

  void _drawOrbitalRing(Canvas canvas, Offset center, double radius, double rotation, Color color, double strokeWidth, {bool dashed = false}) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (dashed) {
      const int dashCount = 12;
      final double dashSweep = (2 * math.pi) / (dashCount * 2);
      for (int i = 0; i < dashCount; i++) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset.zero, radius: radius),
          i * 2 * dashSweep,
          dashSweep,
          false,
          paint,
        );
      }
    } else {
      final Gradient gradient = SweepGradient(
        colors: [color.withOpacity(0.1), color, color.withOpacity(0.1)],
        stops: const [0.0, 0.5, 1.0],
      );
      paint.shader = gradient.createShader(Rect.fromCircle(center: Offset.zero, radius: radius));
      canvas.drawCircle(Offset.zero, radius, paint);
    }
    
    final orbitalPaint = Paint()..color = Colors.white..style = PaintingStyle.fill..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
    canvas.drawCircle(Offset(radius, 0), strokeWidth * 2, orbitalPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AiCorePainter oldDelegate) {
    return oldDelegate.rotationValue != rotationValue ||
           oldDelegate.pulseValue != pulseValue ||
           oldDelegate.state != state ||
           oldDelegate.amplitude != amplitude;
  }
}
