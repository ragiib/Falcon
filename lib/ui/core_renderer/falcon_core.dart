import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../../providers/audio_provider.dart';
import '../theme/app_colors.dart';

class FalconCore extends ConsumerStatefulWidget {
  final double size;
  const FalconCore({Key? key, this.size = 560}) : super(key: key);

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
      duration: const Duration(seconds: 16),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    for (int i = 0; i < 40; i++) {
      _resetParticle(i);
    }
  }

  void _resetParticle(int index) {
    final angle = _random.nextDouble() * 2 * math.pi;
    final dist = 60.0 + _random.nextDouble() * 100.0;
    if (index >= _particles.length) {
      _particles.add(_Particle(
        angle: angle,
        radius: dist,
        maxRadius: 240.0 + _random.nextDouble() * 60.0,
        speed: 1.2 + _random.nextDouble() * 2.5,
        size: 1.0 + _random.nextDouble() * 2.5,
        alpha: 0.2 + _random.nextDouble() * 0.8,
      ));
    } else {
      _particles[index] = _Particle(
        angle: angle,
        radius: dist,
        maxRadius: 240.0 + _random.nextDouble() * 60.0,
        speed: 1.2 + _random.nextDouble() * 2.5,
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

    if (aiState == AiState.speaking || aiState == AiState.generating) {
      _rotationController.duration = const Duration(seconds: 4);
    } else if (aiState == AiState.thinking) {
      _rotationController.duration = const Duration(seconds: 3);
    } else if (aiState == AiState.listening || aiState == AiState.recognizingSpeech) {
      _rotationController.duration = const Duration(seconds: 5);
    } else {
      _rotationController.duration = const Duration(seconds: 16);
    }

    if (!_rotationController.isAnimating) _rotationController.repeat();

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      p.radius += p.speed * (1.0 + amplitude * 3.5);
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

    final scale = 1.0 + (amplitude * 0.12) + (pulse * 0.02);
    final baseRadius = maxR * 0.92 * scale;

    final cyanGlow = AppColors.cyanGlow;
    final brightBlue = AppColors.electricBlue;

    // 1. Radial Energy Aura Bloom
    final auraPaint = Paint()
      ..color = cyanGlow.withOpacity(0.18 + (amplitude * 0.35) + (pulse * 0.05))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, baseRadius * 1.05, auraPaint);

    // 2. Outward Energy Particles
    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (var p in particles) {
      final px = center.dx + p.radius * math.cos(p.angle);
      final py = center.dy + p.radius * math.sin(p.angle);
      particlePaint.color = cyanGlow.withOpacity(p.alpha.clamp(0.0, 1.0));
      canvas.drawCircle(Offset(px, py), p.size, particlePaint);
    }

    // 3. Outer Compass Ring with Degree Markings (0°, 90°, 180°, 270°)
    _drawOuterCompassRing(canvas, center, baseRadius * 0.96, rotation * 2 * math.pi, cyanGlow);

    // 4. Mode Selection Button Arc Ring (SAFE MODE, DESK MODE, PL OFF, DOCS, CTRL, SYS, VOL, EQ)
    _drawModeSelectionArc(canvas, center, baseRadius * 0.83, -rotation * math.pi, cyanGlow);

    // 5. Segmented Mechanical Ring with 16 Teeth
    _drawSegmentedMechanicalRing(canvas, center, baseRadius * 0.69, -rotation * 1.5 * math.pi, cyanGlow);

    // 6. Circular Audio Waveform Ring
    _drawAudioWaveformRing(canvas, center, baseRadius * 0.55, amplitude, cyanGlow);

    // 7. Inner Concentric Segmented Arc Ring
    _drawInnerConcentricRing(canvas, center, baseRadius * 0.43, rotation * 3 * math.pi, brightBlue);

    // 8. Inverted Triangular Arc Reactor Core (Exact match to reference)
    _drawTriangularCore(canvas, center, baseRadius * 0.29, pulse, amplitude, cyanGlow);

    // 9. Core Nucleus & Center Telemetry Numbers (-04.12 / 83)
    _drawCoreNucleusAndTelemetry(canvas, center, baseRadius * 0.29, pulse, amplitude, cyanGlow);
  }

  void _drawOuterCompassRing(Canvas canvas, Offset center, double radius, double rot, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final trackPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius, trackPaint);

    final tickPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < 120; i++) {
      final angle = i * (2 * math.pi / 120);
      final isMajor = i % 10 == 0;
      final len = isMajor ? 12.0 : 4.0;
      final p1 = Offset((radius - len) * math.cos(angle), (radius - len) * math.sin(angle));
      final p2 = Offset(radius * math.cos(angle), radius * math.sin(angle));
      canvas.drawLine(p1, p2, isMajor ? (tickPaint..strokeWidth = 2.0) : (tickPaint..strokeWidth = 1.0));
    }

    // Degree Labels (0°, 90°, 180°, 270°)
    const degrees = ['0°', '90°', '180°', '270°'];
    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final px = (radius - 20) * math.cos(angle);
      final py = (radius - 20) * math.sin(angle);
      final tp = TextPainter(
        text: TextSpan(
          text: degrees[i],
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
            fontFamily: 'Share Tech Mono',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
    }

    canvas.restore();
  }

  void _drawModeSelectionArc(Canvas canvas, Offset center, double radius, double rot, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final ringPaint = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(Offset.zero, radius, ringPaint);

    final labels = ['SAFE MODE', 'DESK MODE', 'PL OFF', 'DOCS', 'CTRL', 'SYS', 'VOL', 'EQ', 'MUTE', 'CFS'];
    final count = labels.length;
    for (int i = 0; i < count; i++) {
      final angle = i * (2 * math.pi / count);
      final px = radius * math.cos(angle);
      final py = radius * math.sin(angle);

      final circlePaint = Paint()
        ..color = color.withOpacity(0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(Offset(px, py), 10.0, circlePaint);

      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(
            color: color,
            fontSize: 5.5,
            fontWeight: FontWeight.bold,
            fontFamily: 'Share Tech Mono',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(px - tp.width / 2, py - tp.height / 2));
    }
    canvas.restore();
  }

  void _drawSegmentedMechanicalRing(Canvas canvas, Offset center, double radius, double rot, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final teethPaint = Paint()
      ..color = color.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;

    const int teeth = 16;
    final sweep = (2 * math.pi) / teeth;
    for (int i = 0; i < teeth; i++) {
      final startAngle = i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        sweep * 0.65,
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
    const count = 160;
    for (int i = 0; i < count; i++) {
      final angle = i * (2 * math.pi / count);
      final noise = math.sin(angle * 12 + (amp * 14)) * math.cos(angle * 6);
      final spike = (amp * 24.0 * noise.abs()) + 2.0;
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

  void _drawInnerConcentricRing(Canvas canvas, Offset center, double radius, double rot, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rot);

    final ringPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const count = 6;
    final sweep = (2 * math.pi) / count;
    for (int i = 0; i < count; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        i * sweep + 0.1,
        sweep - 0.25,
        false,
        ringPaint,
      );
    }
    canvas.restore();
  }

  void _drawTriangularCore(Canvas canvas, Offset center, double radius, double pulse, double amp, Color color) {
    final triPaint = Paint()
      ..color = color.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final glowTriPaint = Paint()
      ..color = color.withOpacity(0.4 + (amp * 0.4))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 14);

    final path = Path();
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) + (math.pi / 2); // Pointing downwards
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

  void _drawCoreNucleusAndTelemetry(Canvas canvas, Offset center, double radius, double pulse, double amp, Color color) {
    final nucleusPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 10)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 14 + (amp * 6), nucleusPaint);

    // Number '83' in center (matching reference)
    final numPainter = TextPainter(
      text: const TextSpan(
        text: '83',
        style: TextStyle(
          color: AppColors.obsidian,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Share Tech Mono',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    numPainter.layout();
    numPainter.paint(canvas, Offset(center.dx - numPainter.width / 2, center.dy - numPainter.height / 2));

    // Telemetry '-04.12' under triangle
    final subTextPainter = TextPainter(
      text: TextSpan(
        text: '-04.12',
        style: TextStyle(
          color: color,
          fontSize: 8.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'Share Tech Mono',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subTextPainter.layout();
    subTextPainter.paint(canvas, Offset(center.dx - subTextPainter.width / 2, center.dy + radius * 0.45));
  }

  @override
  bool shouldRepaint(covariant _FalconCorePainter oldDelegate) => true;
}
