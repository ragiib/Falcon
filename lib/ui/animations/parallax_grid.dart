import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ParallaxGridBackground extends StatefulWidget {
  const ParallaxGridBackground({Key? key}) : super(key: key);

  @override
  State<ParallaxGridBackground> createState() => _ParallaxGridBackgroundState();
}

class _ParallaxGridBackgroundState extends State<ParallaxGridBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _mousePosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 30)
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _mousePosition = event.localPosition;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: GridPainter(
              animationValue: _controller.value,
              mousePosition: _mousePosition,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  final double animationValue;
  final Offset mousePosition;

  GridPainter({required this.animationValue, required this.mousePosition});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyanGlow.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double gridSize = 50.0;
    
    // Parallax effect based on mouse
    final double offsetX = (mousePosition.dx / size.width - 0.5) * 40.0;
    final double offsetY = (mousePosition.dy / size.height - 0.5) * 40.0;
    
    // Constant slow drift
    final double driftY = animationValue * gridSize;

    // Draw vertical lines
    for (double x = 0; x <= size.width + gridSize; x += gridSize) {
      canvas.drawLine(
        Offset(x - offsetX, 0),
        Offset(x + offsetX, size.height),
        paint,
      );
    }

    // Draw horizontal lines with drift
    for (double y = -gridSize; y <= size.height + gridSize; y += gridSize) {
      canvas.drawLine(
        Offset(0, y + driftY - offsetY),
        Offset(size.width, y + driftY + offsetY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.mousePosition != mousePosition;
  }
}
