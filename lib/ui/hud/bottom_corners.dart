import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BottomCorners extends StatelessWidget {
  const BottomCorners({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 0,
          left: 0,
          child: CustomPaint(
            size: const Size(400, 150),
            painter: _BottomCornerPainter(isLeft: true),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(400, 150),
            painter: _BottomCornerPainter(isLeft: false),
          ),
        ),
      ],
    );
  }
}

class _BottomCornerPainter extends CustomPainter {
  final bool isLeft;

  _BottomCornerPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.cyanGlow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final fillPaint = Paint()
      ..color = AppColors.cyanGlow.withOpacity(0.05)
      ..style = PaintingStyle.fill;

    final path = Path();
    
    if (isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(size.width * 0.7, size.height);
      path.lineTo(size.width, size.height * 0.4);
      path.lineTo(size.width, 0);
      path.lineTo(size.width - 20, 0);
      path.lineTo(size.width - 20, size.height * 0.3);
      path.lineTo(size.width * 0.65, size.height - 20);
      path.lineTo(0, size.height - 20);
    } else {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width * 0.3, size.height);
      path.lineTo(0, size.height * 0.4);
      path.lineTo(0, 0);
      path.lineTo(20, 0);
      path.lineTo(20, size.height * 0.3);
      path.lineTo(size.width * 0.35, size.height - 20);
      path.lineTo(size.width, size.height - 20);
    }
    
    path.close();
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
    
    // Draw some tech "keyboard" like rectangles inside
    final rectPaint = Paint()..color = AppColors.cyanGlow.withOpacity(0.3)..style = PaintingStyle.fill;
    
    canvas.save();
    if (isLeft) {
      canvas.translate(size.width * 0.3, size.height * 0.6);
      canvas.rotate(-0.4); // Angle to match
      for (int i = 0; i < 5; i++) {
        canvas.drawRect(Rect.fromLTWH(i * 30.0, 0, 20, 40), rectPaint);
      }
    } else {
      canvas.translate(size.width * 0.5, size.height * 0.4);
      canvas.rotate(0.4); // Angle to match
      for (int i = 0; i < 5; i++) {
        canvas.drawRect(Rect.fromLTWH(i * 30.0, 0, 20, 40), rectPaint);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
