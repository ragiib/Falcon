import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';
import '../theme/app_colors.dart';

class HudPanel extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Alignment alignment;
  
  const HudPanel({
    Key? key,
    required this.title,
    required this.children,
    this.alignment = Alignment.centerLeft,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: GlassContainer(
          padding: const EdgeInsets.all(16.0),
          opacity: 0.05,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 220,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.memory, size: 14, color: AppColors.cyanGlow),
                    const SizedBox(width: 8),
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.cyanGlow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HudMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final double? progress;
  final Color? color;

  const HudMetricRow({
    Key? key,
    required this.label,
    required this.value,
    this.progress,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color ?? AppColors.textPrimary,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.glassBorder,
                color: color ?? AppColors.cyanGlow,
                minHeight: 2,
              ),
            ),
          ]
        ],
      ),
    );
  }
}
