import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// CustomPainter that renders the full-bleed horizontal center axis,
/// angled cyan HUD callout lines, circuit traces, and crosshair reticles.
class HudVectorOverlay extends StatelessWidget {
  const HudVectorOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _HudVectorPainter(),
      ),
    );
  }
}

class _HudVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final coreR = size.width * 0.20;

    final linePaint = Paint()
      ..color = AppColors.cyanGlow.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final axisPaint = Paint()
      ..color = AppColors.cyanGlow.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = AppColors.cyanGlow
      ..style = PaintingStyle.fill;

    // 1. Full-Bleed Horizontal Center Axis (Extending to screen edges)
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);

    // 2. Crosshair Target Reticles
    _drawReticle(canvas, Offset(size.width * 0.22, center.dy - coreR * 1.1), linePaint);
    _drawReticle(canvas, Offset(size.width * 0.22, center.dy + coreR * 0.5), linePaint);
    _drawReticle(canvas, Offset(size.width * 0.78, center.dy - coreR * 1.1), linePaint);
    _drawReticle(canvas, Offset(size.width * 0.78, center.dy + coreR * 0.5), linePaint);

    // 3. Top-Left Angled Callout Line
    final p1Start = Offset(center.dx - coreR * 0.7, center.dy - coreR * 0.7);
    final p1Mid = Offset(center.dx - coreR * 1.3, center.dy - coreR * 1.1);
    final p1End = Offset(size.width * 0.22, center.dy - coreR * 1.1);

    final path1 = Path()
      ..moveTo(p1Start.dx, p1Start.dy)
      ..lineTo(p1Mid.dx, p1Mid.dy)
      ..lineTo(p1End.dx, p1End.dy);
    canvas.drawPath(path1, linePaint);
    canvas.drawCircle(p1Start, 2.5, dotPaint);

    // 4. Bottom-Left Angled Callout Line
    final p2Start = Offset(center.dx - coreR * 0.9, center.dy + coreR * 0.3);
    final p2Mid = Offset(center.dx - coreR * 1.4, center.dy + coreR * 0.5);
    final p2End = Offset(size.width * 0.22, center.dy + coreR * 0.5);

    final path2 = Path()
      ..moveTo(p2Start.dx, p2Start.dy)
      ..lineTo(p2Mid.dx, p2Mid.dy)
      ..lineTo(p2End.dx, p2End.dy);
    canvas.drawPath(path2, linePaint);
    canvas.drawCircle(p2Start, 2.5, dotPaint);

    // 5. Top-Right Angled Callout Line
    final p3Start = Offset(center.dx + coreR * 0.7, center.dy - coreR * 0.7);
    final p3Mid = Offset(center.dx + coreR * 1.3, center.dy - coreR * 1.1);
    final p3End = Offset(size.width * 0.78, center.dy - coreR * 1.1);

    final path3 = Path()
      ..moveTo(p3Start.dx, p3Start.dy)
      ..lineTo(p3Mid.dx, p3Mid.dy)
      ..lineTo(p3End.dx, p3End.dy);
    canvas.drawPath(path3, linePaint);
    canvas.drawCircle(p3Start, 2.5, dotPaint);

    // 6. Bottom-Right Angled Callout Line
    final p4Start = Offset(center.dx + coreR * 0.9, center.dy + coreR * 0.3);
    final p4Mid = Offset(center.dx + coreR * 1.4, center.dy + coreR * 0.5);
    final p4End = Offset(size.width * 0.78, center.dy + coreR * 0.5);

    final path4 = Path()
      ..moveTo(p4Start.dx, p4Start.dy)
      ..lineTo(p4Mid.dx, p4Mid.dy)
      ..lineTo(p4End.dx, p4End.dy);
    canvas.drawPath(path4, linePaint);
    canvas.drawCircle(p4Start, 2.5, dotPaint);
  }

  void _drawReticle(Canvas canvas, Offset pos, Paint paint) {
    const r = 5.0;
    canvas.drawLine(Offset(pos.dx - r, pos.dy), Offset(pos.dx + r, pos.dy), paint);
    canvas.drawLine(Offset(pos.dx, pos.dy - r), Offset(pos.dx, pos.dy + r), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
