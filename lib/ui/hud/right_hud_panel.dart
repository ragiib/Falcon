import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'hud_components.dart';

class RightHudPanel extends StatelessWidget {
  const RightHudPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Panel Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const SizedBox(height: 100), // Push down below header
                
                // Mini Pie Charts Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildMiniPieChart('[SWAP]', 0.05, context),
                    const SizedBox(width: 24),
                    _buildMiniPieChart('[CPU]', 0.07, context),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Context / Vision Box (Placeholder for future)
                AngledBorder(
                  isLeft: false,
                  angleSize: 10,
                  borderWidth: 1,
                  child: Container(
                    width: 250,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppColors.panelBackground.withOpacity(0.3),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(Icons.visibility_outlined, color: AppColors.cyanGlow.withOpacity(0.5), size: 48),
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Text('CONTEXT SENSOR', style: Theme.of(context).textTheme.labelSmall),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Text('STANDBY', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.warning)),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Secondary Gauges
                const Align(
                  alignment: Alignment.centerRight,
                  child: CircularGauge(
                    value: 0.3,
                    size: 80,
                    label: '[SYS]',
                    centerText: '30',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Vertical Tab Bar
          _buildVerticalTabs(context),
        ],
      ),
    );
  }
  
  Widget _buildMiniPieChart(String label, double value, BuildContext context) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        SizedBox(
          width: 50,
          height: 50,
          child: CustomPaint(
            painter: _MiniPieChartPainter(value: value),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalTabs(BuildContext context) {
    final tabs = ['TOOLS', 'VISION', 'AUDIO', 'MEMORY', 'SYS'];
    
    return Container(
      width: 40,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        children: tabs.map((tab) => _buildVerticalTab(tab, context, isActive: tab == 'TOOLS')).toList(),
      ),
    );
  }

  Widget _buildVerticalTab(String label, BuildContext context, {bool isActive = false}) {
    return RotatedBox(
      quarterTurns: 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isActive ? AppColors.cyanGlow.withOpacity(0.2) : Colors.transparent,
          border: isActive ? const Border(bottom: BorderSide(color: AppColors.cyanGlow, width: 2)) : null,
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isActive ? AppColors.cyanGlow : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}

class _MiniPieChartPainter extends CustomPainter {
  final double value;

  _MiniPieChartPainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final bgPaint = Paint()
      ..color = AppColors.glassBorder
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    final activePaint = Paint()
      ..color = AppColors.textSecondary
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * value,
      true,
      activePaint,
    );
    
    // Draw text inside
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(value * 100).toInt()}%',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'Share Tech Mono'),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
