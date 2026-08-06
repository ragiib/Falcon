import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Particle {
  Offset position;
  Offset velocity;
  double radius;
  double alpha;
  
  Particle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.alpha,
  });
}

class ParticleSystem extends StatefulWidget {
  final int count;
  final Color color;

  const ParticleSystem({
    Key? key,
    this.count = 40,
    this.color = AppColors.cyanGlow,
  }) : super(key: key);

  @override
  State<ParticleSystem> createState() => _ParticleSystemState();
}

class _ParticleSystemState extends State<ParticleSystem> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];
  final math.Random random = math.Random();
  bool _initialized = false;
  Size _lastSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  void _initParticles(Size size) {
    if (_initialized && size == _lastSize) return;
    particles.clear();
    for (int i = 0; i < widget.count; i++) {
      particles.add(
        Particle(
          position: Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
          velocity: Offset((random.nextDouble() - 0.5) * 0.5, (random.nextDouble() - 0.5) * 0.5),
          radius: random.nextDouble() * 2 + 1,
          alpha: random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
    _initialized = true;
    _lastSize = size;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        _initParticles(size);

        return RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: ParticlePainter(
                  particles: particles,
                  color: widget.color,
                ),
              );
            },
          ),
        );
      }
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final Color color;

  ParticlePainter({required this.particles, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      // Update position
      p.position += p.velocity;

      // Wrap around screen
      if (p.position.dx < 0) p.position = Offset(size.width, p.position.dy);
      if (p.position.dx > size.width) p.position = Offset(0, p.position.dy);
      if (p.position.dy < 0) p.position = Offset(p.position.dx, size.height);
      if (p.position.dy > size.height) p.position = Offset(p.position.dx, 0);

      // Draw particle
      final paint = Paint()
        ..color = color.withOpacity(p.alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return true; // We always want to repaint when the animation ticks
  }
}
