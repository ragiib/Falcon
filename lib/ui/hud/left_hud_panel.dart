import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'hud_components.dart';

class LeftHudPanel extends StatelessWidget {
  const LeftHudPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vertical Tab Bar
          _buildVerticalTabs(context),
          
          const SizedBox(width: 16),
          
          // Main Panel Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100), // Push down below header
                
                // RAM Gauge
                Row(
                  children: [
                    const CircularGauge(
                      value: 0.43,
                      label: '[RAM]',
                      centerText: '43%',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('FREE: 56%', style: Theme.of(context).textTheme.bodySmall),
                          Text('USED: 43%', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.cyanGlow)),
                          const SizedBox(height: 8),
                          const LinearBar(label: 'ALLOCATED', value: 0.7),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // CPU Stats
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.glassBorder),
                    color: AppColors.panelBackground.withOpacity(0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('[CPU]', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 16),
                      const LinearBar(label: 'CORE 0', value: 0.12),
                      const SizedBox(height: 8),
                      const LinearBar(label: 'CORE 1', value: 0.45),
                      const SizedBox(height: 8),
                      const LinearBar(label: 'CORE 2', value: 0.08),
                      const SizedBox(height: 8),
                      const LinearBar(label: 'CORE 3', value: 0.92, color: AppColors.warning),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Network graph mock
                Text('[NETWORK]', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.cyanGlow.withOpacity(0.3))),
                  ),
                  child: CustomPaint(
                    size: const Size(double.infinity, 60),
                    painter: _MockNetworkPainter(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalTabs(BuildContext context) {
    final tabs = ['ASUS', 'Maintenance', 'General', 'Visual Tools'];
    
    return Container(
      width: 40,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        children: tabs.map((tab) => _buildVerticalTab(tab, context, isActive: tab == 'Maintenance')).toList(),
      ),
    );
  }

  Widget _buildVerticalTab(String label, BuildContext context, {bool isActive = false}) {
    return RotatedBox(
      quarterTurns: 3,
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

class _MockNetworkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cyanGlow.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    path.moveTo(0, size.height / 2);
    
    // Draw some random spikes
    final intervals = [0.1, 0.2, 0.25, 0.3, 0.4, 0.6, 0.7, 0.8, 0.9];
    
    for (var x in intervals) {
      final actualX = size.width * x;
      path.lineTo(actualX, size.height / 2);
      path.lineTo(actualX + 2, 0); // spike up
      path.lineTo(actualX + 4, size.height); // spike down
      path.lineTo(actualX + 6, size.height / 2);
    }
    
    path.lineTo(size.width, size.height / 2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
