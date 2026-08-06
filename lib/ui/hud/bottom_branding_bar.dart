import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'procedural_charts.dart';

class BottomBrandingBar extends StatelessWidget {
  const BottomBrandingBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.obsidian.withOpacity(0.95),
        border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Network Traffic UP Graph
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'NETWORK TRAFFIC UP // 191.58 MB',
                  style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono'),
                ),
                SizedBox(height: 2),
                AnimatedOscilloscope(height: 35, frequency: 4.0),
              ],
            ),
          ),

          // Center Branding (Matches STARK INDUSTRIES logo location)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: AppColors.cyanGlow, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    'FALCON OS',
                    style: TextStyle(
                      color: AppColors.cyanGlow,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6.0,
                      fontFamily: 'Share Tech Mono',
                      shadows: [
                        Shadow(color: AppColors.cyanGlow.withOpacity(0.8), blurRadius: 12),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.bolt, color: AppColors.cyanGlow, size: 20),
                ],
              ),
              const SizedBox(height: 2),
              const Text(
                'QUANTUM AI OPERATING SYSTEM // AUTHORIZED ACCESS ONLY',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 7,
                  letterSpacing: 2.0,
                  fontFamily: 'Share Tech Mono',
                ),
              ),
            ],
          ),

          // Right Network Traffic DOWN Graph
          SizedBox(
            width: 260,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  'NETWORK TRAFFIC DOWN // 89.31 MB',
                  style: TextStyle(color: AppColors.electricBlue, fontSize: 8, fontFamily: 'Share Tech Mono'),
                ),
                SizedBox(height: 2),
                AnimatedOscilloscope(height: 35, color: AppColors.electricBlue, frequency: 2.5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
