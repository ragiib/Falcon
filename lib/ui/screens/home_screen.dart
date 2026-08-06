import 'package:flutter/material.dart';
import '../animations/particle_system.dart';
import '../core_renderer/ai_core.dart';
import '../chat/chat_view.dart';
import '../hud/system_metrics_panel.dart';
import '../hud/latency_metrics_panel.dart';
import '../theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [
          // 1. Background Grid / Glow
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.5,
                  colors: [
                    AppColors.panelBackground,
                    AppColors.obsidian,
                  ],
                ),
              ),
            ),
          ),
          
          // 2. Ambient Particles
          const Positioned.fill(
            child: ParticleSystem(count: 30),
          ),

          // 3. AI Core (Centered top)
          const Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Center(
              child: AiCore(),
            ),
          ),

          // 4. Chat View (Bottom half, layered above background)
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 240), // Space for AI Core
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.obsidian.withOpacity(0.0),
                          AppColors.obsidian.withOpacity(0.8),
                          AppColors.obsidian,
                        ],
                        stops: const [0.0, 0.2, 1.0],
                      ),
                    ),
                    child: const ChatView(),
                  ),
                ),
              ],
            ),
          ),

          // 5. HUD Panels (Floating above everything)
          const SystemMetricsPanel(),
          const LatencyMetricsPanel(),
        ],
      ),
    );
  }
}
