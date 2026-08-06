import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

// --- ANGLED BORDER --- //
class AngledBorder extends StatelessWidget {
  final Widget child;
  final bool isLeft;
  final double angleSize;
  final double borderWidth;

  const AngledBorder({
    Key? key,
    required this.child,
    this.isLeft = true,
    this.angleSize = 10.0,
    this.borderWidth = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AngledBorderPainter(isLeft: isLeft, angleSize: angleSize, borderWidth: borderWidth),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: child,
      ),
    );
  }
}

class _AngledBorderPainter extends CustomPainter {
  final bool isLeft;
  final double angleSize;
  final double borderWidth;

  _AngledBorderPainter({required this.isLeft, required this.angleSize, required this.borderWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyanGlow.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path();
    
    if (isLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(angleSize, 0);
      path.lineTo(0, angleSize);
      path.lineTo(0, size.height - angleSize);
      path.lineTo(angleSize, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width - angleSize, 0);
      path.lineTo(size.width, angleSize);
      path.lineTo(size.width, size.height - angleSize);
      path.lineTo(size.width - angleSize, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
    
    // Draw corner accents
    final accentPaint = Paint()
      ..color = AppColors.cyanGlow
      ..style = PaintingStyle.fill;
      
    if (isLeft) {
      canvas.drawRect(Rect.fromLTWH(angleSize, -1, 10, borderWidth * 2), accentPaint);
      canvas.drawRect(Rect.fromLTWH(angleSize, size.height - borderWidth, 10, borderWidth * 2), accentPaint);
    } else {
      canvas.drawRect(Rect.fromLTWH(size.width - angleSize - 10, -1, 10, borderWidth * 2), accentPaint);
      canvas.drawRect(Rect.fromLTWH(size.width - angleSize - 10, size.height - borderWidth, 10, borderWidth * 2), accentPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- CIRCULAR GAUGE --- //
class CircularGauge extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final String label;
  final String centerText;
  final Color color;

  const CircularGauge({
    Key? key,
    required this.value,
    this.size = 100,
    required this.label,
    required this.centerText,
    this.color = AppColors.cyanGlow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularGaugePainter(value: value, color: color),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                centerText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double value;
  final Color color;

  _CircularGaugePainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;
    canvas.drawCircle(center, radius, trackPaint);

    // Segmented value track
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.square;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * value;

    // Draw dashed progress
    const int dashCount = 20;
    final double dashSweep = sweepAngle / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle + (i * dashSweep),
          dashSweep,
          false,
          activePaint,
        );
      }
    }
    
    // Outer tick marks
    final tickPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    for (int i = 0; i < 36; i++) {
      final angle = i * (2 * math.pi / 36);
      final p1 = Offset(center.dx + (radius + 2) * math.cos(angle), center.dy + (radius + 2) * math.sin(angle));
      final p2 = Offset(center.dx + (radius + 6) * math.cos(angle), center.dy + (radius + 6) * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// --- LINEAR BAR --- //
class LinearBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const LinearBar({Key? key, required this.label, required this.value, this.color = AppColors.cyanGlow}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelSmall),
            Text('${(value * 100).toInt()}%', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 4),
        CustomPaint(
          size: const Size(double.infinity, 8),
          painter: _LinearBarPainter(value: value, color: color),
        ),
      ],
    );
  }
}

class _LinearBarPainter extends CustomPainter {
  final double value;
  final Color color;

  _LinearBarPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = AppColors.glassBorder..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final fillWidth = size.width * value;
    final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    
    // Segmented linear bar
    const segmentWidth = 4.0;
    const gap = 1.0;
    for(double x = 0; x < fillWidth; x += (segmentWidth + gap)) {
      canvas.drawRect(Rect.fromLTWH(x, 1, segmentWidth, size.height - 2), fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
