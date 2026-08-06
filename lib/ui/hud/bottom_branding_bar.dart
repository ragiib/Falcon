import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BottomBrandingBar extends StatelessWidget {
  const BottomBrandingBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.obsidian.withOpacity(0.95),
        border: const Border(top: BorderSide(color: AppColors.glassBorder, width: 1)),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cyanGlow.withOpacity(0.7), width: 1.5),
            color: AppColors.panelBackground.withOpacity(0.6),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shield, color: AppColors.cyanGlow, size: 18),
              const SizedBox(width: 12),
              Text(
                'FALCON OS',
                style: TextStyle(
                  color: AppColors.cyanGlow,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8.0,
                  fontFamily: 'Share Tech Mono',
                  shadows: [
                    Shadow(color: AppColors.cyanGlow.withOpacity(0.9), blurRadius: 16),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.shield, color: AppColors.cyanGlow, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
