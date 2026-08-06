import 'package:flutter/material.dart';
import 'ai_core.dart';
import '../theme/app_colors.dart';

class CoreHub extends StatelessWidget {
  const CoreHub({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: 800,
        height: 400,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Left Command Panels
            Positioned(
              left: 50,
              bottom: 120,
              child: _buildCommandMenu(
                context, 
                ['Computer', 'Documents', 'Downloads', 'Movies', 'Music'],
                isLeft: true,
              ),
            ),
            
            // Right Command Panels
            Positioned(
              right: 50,
              bottom: 120,
              child: _buildCommandMenu(
                context, 
                ['Network', 'Control Panel', 'Game Booster', 'THESIS', 'Settings'],
                isLeft: false,
              ),
            ),
            
            // Central AI Core
            const Positioned(
              bottom: -50, // Shifted down slightly to anchor to bottom
              child: SizedBox(
                width: 350,
                height: 350,
                child: AiCore(),
              ),
            ),
            
            // Core HUD Overlays (Technical text over the core)
            Positioned(
              bottom: 20,
              left: 250,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('HOST: FALCON-MAIN', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.cyanGlow)),
                  Text('OS: WINDOWS 11', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.cyanGlow)),
                  Text('STATUS: CONNECTED', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.cyanGlow)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommandMenu(BuildContext context, List<String> commands, {required bool isLeft}) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: commands.map((cmd) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.cyanGlow.withOpacity(0.1),
            border: Border.all(color: AppColors.cyanGlow.withOpacity(0.3)),
          ),
          child: Text(
            cmd,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.cyanGlow,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
}
