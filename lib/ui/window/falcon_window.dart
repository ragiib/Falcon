import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FalconWindow extends StatelessWidget {
  final Widget child;

  const FalconWindow({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WindowBorder(
        color: AppColors.cyanGlow.withOpacity(0.3),
        width: 1,
        child: Column(
          children: [
            const CustomTitleBar(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class CustomTitleBar extends StatelessWidget {
  const CustomTitleBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Container(
        color: AppColors.obsidian,
        child: Row(
          children: [
            Expanded(
              child: MoveWindow(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.blur_on, color: AppColors.cyanGlow, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'FALCON AI',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const WindowButtons(),
          ],
        ),
      ),
    );
  }
}

final buttonColors = WindowButtonColors(
  iconNormal: AppColors.textSecondary,
  mouseOver: AppColors.cyanGlow.withOpacity(0.2),
  mouseDown: AppColors.cyanGlow.withOpacity(0.4),
  iconMouseOver: AppColors.textPrimary,
  iconMouseDown: AppColors.textPrimary,
);

final closeButtonColors = WindowButtonColors(
  mouseOver: AppColors.error,
  mouseDown: AppColors.error.withOpacity(0.8),
  iconNormal: AppColors.textSecondary,
  iconMouseOver: Colors.white,
);

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
