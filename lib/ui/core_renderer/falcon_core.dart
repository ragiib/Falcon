import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/audio_provider.dart';
import '../theme/app_colors.dart';

class FalconCore extends ConsumerStatefulWidget {
  final double size;
  const FalconCore({Key? key, this.size = 400}) : super(key: key);

  @override
  ConsumerState<FalconCore> createState() => _FalconCoreState();
}

class _FalconCoreState extends ConsumerState<FalconCore> with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Initialize particles
    for (int i = 0; i < 25; i++) {
      _resetParticle(i);
    }
  }

  void _resetParticle(int index) {
    final angle = _random.nextDouble() * 2 * math.pi;
    final dist = 40.0 + _random.nextDouble() * 60.0;
    if (index >= _particles.length) {
      _particles.add(_Particle(
        angle: angle,
        radius: dist,
        maxRadius: 180.0 + _random.nextDouble() * 40.0,
        speed: 1.0 + _random.nextDouble() * 2.0,
        size: 1.0 + _random.nextDouble() * 2.5,
        alpha: 0.2 + _random.nextDouble() * 0.8,
      ));
    } else {
      _particles[index] = _Particle(
        angle: angle,
        radius: dist,
        maxRadius: 180.0 + _random.nextDouble() * 40.0,
        speed: 1.0 + _random.nextDouble() * 2.0,
        size: 1.0 + _random.nextDouble() * 2.5,
        alpha: 0.2 + _random.nextDouble() * 0.8,
      );
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiStateProvider);
    final amplitude = ref.watch(audioAmplitudeProvider);

    // Adjust speed based on state & audio amplitude
    if (aiState == AiState.speaking || aiState == AiState.generating) {
      _rotationController.duration = const Duration(seconds: 4);
    } else if (aiState == AiState.thinking) {
      _rotationController.duration = const Duration(seconds: 3);
    } else {
      _rotationController.duration = const Duration(seconds: 14);
    }

    if (!_rotationController.isAnimating) _rotationController.repeat();

    // Update particle positions
    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.radius += p.speed * (1.0 + amplitude * 3.0);
      p.alpha -= 0.01;
      if (p.radius >= p.maxRadius || p.alpha <= 0) {
        _resetParticle(i);
      }
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationController, _pulseController]),
        builder: (context, child) {
          return CustomPaint(
            painter: _FalconCorePainter(
              rotation: _rotationController.value,
              pulse: _pulseController.value,
              amplitude: amplitude,
              state: aiState,
              particles: _particles,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

class _Particle {
  double angle;
  double radius;
  double maxRadius;
  double speed;
  double size;
  double alpha;

  _Particle({
    required this.angle,
    required this.radius,
    required this.maxRadius,
    required this.speed,
    required this.size,
    required this.alpha,
  });
}

class _FalconCorePainter extends CustomPainter {
  final double rotation;
  final double pulse;
  final double amplitude;
  final AiState state;
  final List<_Particle> particles;

  _FalconCorePainter({
    required this.rotation,
    required this.pulse,
    required this.amplitude,
    required this.state,
    required this.particles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = math.min(size.width, size.height) / 2;

    // Amplitude scale expansion
    final scale = 1.0 + (amplitude * 0.15) + (pulse * 0.03);
    final baseRadius = maxR * 0.85 * scale;

    final cyanGlow = AppColors.cyanGlow;
    final brightBlue = AppColors.electricBlue;

    // 1. Outward Background Aura & Radial Bloom
    final auraPaint = Paint()
      ..color = cyanGlow.withOpacity(0.12 + (amplitude * 0.25) + (pulse * 0.05))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius * 1.1, auraPaint);

    // 2. Outward Energy Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      final px = center.dx + p.radius * math.cos(p.angle);
      final py = center.dy + p.radius * math.sin(p.angle);
      particlePaint.color = cyanGlow.withOpacity(p.alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), p.size, particlePaint);
    }

    // 3. Outer Radial Degree Ticks & Compass Ring (Clockwise)
    _drawOuterDegreeRing(canvas, center, baseRadius * 0.95, rotation * 2 * math.pi, cyanGlow);

    // 4. Middle Mechanical Ring with Segmented Teeth (Counter-Clockwise)
    _drawMechanicalTeethRing(canvas, center, baseRadius * 0.78, -rotation * 1.5 * math.pi, cyanGlow);

    // 5. Circular Audio Waveform Ring (Driven by Amplitude)
    _drawAudioWaveformRing(canvas, center, baseRadius * 0.62, amplitude, cyanGlow);

    // 6. Inner Concentric Segmented Ring
    _drawInnerSegmentedRing(canvas, center, baseRadius * 0.48, rotation * 3 * math.pi, brightBlue);

    // 7. Iconic Central Triangular Energy Core (Arc Reactor Core)
    _drawTriangularCore(canvas, center, baseRadius * 0.32, pulse, amplitude, cyanGlow);

    // 8. Glowing Core Nucleus & Center Text
    final coreNucleusPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius * 0.08 + (amplitude * 10), coreNucleusPaint);

    // Center Technical Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'FALCON',
        style: TextStyle(
          color: cyanGlow,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
          fontFamily: 'Share Tech Mono',
          shadows: [
            Shadow(color: cyanGlow, blurRadius: 8),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy + baseRadius * 0.12),
    );
  }

  void _drawOuterDegreeRing(Canvas canvas, Offset center, double radius, double rot, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final trackPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius, trackPaint);

    final tickPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 72; i++) {
      final angle = i * (2 * math.pi / 72);
      final isMajor = i % 6 == 0;
      final len = isMajor ? 8.0 : 4.0;
      final p1 = Offset((radius - len) * math.cos(angle), (radius - len) * math.sin(angle));
      final p2 = Offset(radius * math.cos(angle), radius * math.sin(angle));
      canvas.drawLine(p1, p2, isMajor ? (tickPaint..strokeWidth = 2.0) : (tickPaint..strokeWidth = 1.0));
    }
    canvas.restore();
  }

  void _drawMechanicalTeethRing(Canvas canvas, Offset center, double radius, double rot, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final teethPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    const int teeth = 12;
    final sweep = (2 * math.pi) / teeth;
    for (int i = 0; i < teeth; i++) {
      final startAngle = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        sweep * 0.6,
        false,
        teethPaint,
      );
    }
    canvas.restore();
  }

  void _drawAudioWaveformRing(Canvas canvas, Offset center, double radius, double amp, Color color) {
    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    const count = 120;
    for (int i = 0; i < count; i++) {
      final angle = i * (2 * math.pi / count);
      // Generate real-time spike amplitude
      final noise = math.sin(angle * 8 + (amp * 10)) * math.cos(angle * 4);
      final spike = (amp * 20.0 * noise.abs()) + 2.0;
      final r = radius + spike;
      final px = center.dx + r * math.cos(angle);
      final py = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();
    canvas.drawPath(path, wavePaint);
  }

  void _drawInnerSegmentedRing(Canvas canvas, Offset center, double radius, double rot, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final ringPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const count = 4;
    final sweep = (2 * math.pi) / count;
    for (int i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        i * sweep + 0.1,
        sweep - 0.2,
        false,
        ringPaint,
      );
    }
    canvas.restore();
  }

  void _drawTriangularCore(Canvas canvas, Offset center, double radius, double pulse, double amp, Color color) {
    final triPaint = Paint()
      ..color = color.withOpacity(0.85 + (pulse * 0.15))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final glowTriPaint = Paint()
      ..color = color.withOpacity(0.3 + (amp * 0.4))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 10);

    final path = Path();
    for (int i = 0; i < 3; i++) {
      // Inverted triangle angles: -pi/2, -pi/2 + 2pi/3, -pi/2 + 4pi/3
      final angle = (i * 2 * math.pi / 3) - (math.pi / 2) + math.pi; // Inverted
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.close();

    canvas.drawPath(path, glowTriPaint);
    canvas.drawPath(path, triPaint);
  }

  @override
  bool shouldRepaint(covariant _FalconCorePainter oldDelegate) => true;
}
