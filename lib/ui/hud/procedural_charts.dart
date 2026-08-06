import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Technical HUD Container with thin glowing cyan borders, corner brackets & BackdropFilter glassmorphism
class HudBox extends StatelessWidget {
  final Widget child;
  final String? title;
  final String? subtitle;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;

  const HudBox({
    Key? key,
    required this.child,
    this.title,
    this.subtitle,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.all(2.0),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: CustomPaint(
            painter: _HudBoxPainter(),
            child: Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _BlinkingLedIndicator(),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  title!.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.cyanGlow,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    fontFamily: 'Share Tech Mono',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              subtitle!.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 8,
                                letterSpacing: 1.0,
                                fontFamily: 'Share Tech Mono',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BlinkingLedIndicator extends StatefulWidget {
  @override
  State<_BlinkingLedIndicator> createState() => _BlinkingLedIndicatorState();
}

class _BlinkingLedIndicatorState extends State<_BlinkingLedIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cyanGlow.withOpacity(0.3 + (_controller.value * 0.7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyanGlow.withOpacity(_controller.value),
                blurRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HudBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.cyanGlow.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final fillPaint = Paint()
      ..color = AppColors.panelBackground.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);

    // Corner Bracket Accents
    final accentPaint = Paint()
      ..color = AppColors.cyanGlow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const cornerLen = 6.0;
    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), accentPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), accentPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLen, 0), accentPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), accentPaint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), accentPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLen), accentPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLen, size.height), accentPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLen), accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated Radar Sweep Widget
class RadarSweepWidget extends StatefulWidget {
  final double size;
  const RadarSweepWidget({Key? key, this.size = 80}) : super(key: key);

  @override
  State<RadarSweepWidget> createState() => _RadarSweepWidgetState();
}

class _RadarSweepWidgetState extends State<RadarSweepWidget> with SingleTickerProviderStateMixin {
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RadarSweepPainter(angle: _controller.value * 2 * math.pi),
        );
      },
    );
  }
}

class _RadarSweepPainter extends CustomPainter {
  final double angle;
  _RadarSweepPainter({required this.angle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    final circlePaint = Paint()
      ..color = AppColors.cyanGlow.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, r * 0.33, circlePaint);
    canvas.drawCircle(center, r * 0.66, circlePaint);
    canvas.drawCircle(center, r, circlePaint);

    // Crosshairs
    canvas.drawLine(Offset(center.dx - r, center.dy), Offset(center.dx + r, center.dy), circlePaint);
    canvas.drawLine(Offset(center.dx, center.dy - r), Offset(center.dx, center.dy + r), circlePaint);

    // Sweep Arc
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2,
        colors: [
          AppColors.cyanGlow.withOpacity(0.6),
          AppColors.cyanGlow.withOpacity(0.0),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, r, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarSweepPainter oldDelegate) => oldDelegate.angle != angle;
}

/// Real-time Oscilloscope Waveform Widget
class AnimatedOscilloscope extends StatefulWidget {
  final double height;
  final Color color;
  final double frequency;

  const AnimatedOscilloscope({
    Key? key,
    this.height = 40,
    this.color = AppColors.cyanGlow,
    this.frequency = 2.0,
  }) : super(key: key);

  @override
  State<AnimatedOscilloscope> createState() => _AnimatedOscilloscopeState();
}

class _AnimatedOscilloscopeState extends State<AnimatedOscilloscope>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _OscilloscopePainter(
            time: _controller.value,
            color: widget.color,
            frequency: widget.frequency,
          ),
        );
      },
    );
  }
}

class _OscilloscopePainter extends CustomPainter {
  final double time;
  final Color color;
  final double frequency;

  _OscilloscopePainter({
    required this.time,
    required this.color,
    required this.frequency,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 15) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 10) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final midY = size.height / 2;
    path.moveTo(0, midY);

    for (double x = 0; x < size.width; x += 2) {
      final normalizedX = x / size.width;
      final y = midY +
          math.sin((normalizedX * frequency * 2 * math.pi) - (time * 2 * math.pi)) * (size.height * 0.35) +
          math.cos((normalizedX * 5 * math.pi) + (time * 4 * math.pi)) * (size.height * 0.1);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _OscilloscopePainter oldDelegate) =>
      oldDelegate.time != time;
}

/// Animated Multi-Line Performance Chart (CPU / Memory load)
class AnimatedLineChart extends StatefulWidget {
  final double height;
  final List<double> dataPoints;
  final Color color;

  const AnimatedLineChart({
    Key? key,
    this.height = 60,
    required this.dataPoints,
    this.color = AppColors.cyanGlow,
  }) : super(key: key);

  @override
  State<AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _LineChartPainter(
            data: widget.dataPoints,
            shift: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final double shift;
  final Color color;

  _LineChartPainter({
    required this.data,
    required this.shift,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (data.length - 1);
    path.moveTo(0, size.height * (1.0 - data.first));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height * (1.0 - data.first));

    for (int i = 1; i < data.length; i++) {
      final x = i * stepX;
      final animatedVal = (data[i] + math.sin(shift * 2 * math.pi + i) * 0.05).clamp(0.05, 0.95);
      final y = size.height * (1.0 - animatedVal);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.shift != shift;
}
