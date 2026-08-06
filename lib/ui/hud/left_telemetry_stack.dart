import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'procedural_charts.dart';

class LeftTelemetryStack extends StatelessWidget {
  const LeftTelemetryStack({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. Audio Waveform & Samplerate Box
          const HudBox(
            title: 'AUDIO WAVEFORM // SAMPLERATE 44.1k',
            subtitle: 'CH-01 OK',
            height: 90,
            child: AnimatedOscilloscope(height: 50, frequency: 3.0),
          ),

          const SizedBox(height: 6),

          // 2. CPU Multi-Core Load Chart
          const HudBox(
            title: 'CPU PERFORMANCE LOAD',
            subtitle: 'QUAD CORE',
            height: 120,
            child: AnimatedLineChart(
              height: 80,
              dataPoints: [0.1, 0.25, 0.15, 0.45, 0.3, 0.85, 0.4, 0.6, 0.2, 0.35],
            ),
          ),

          const SizedBox(height: 6),

          // 3. AI Analytics & Signal Oscilloscope
          const HudBox(
            title: 'SIGNAL & FREQUENCY ANALYTICS',
            subtitle: 'SPECTRUM',
            height: 95,
            child: AnimatedOscilloscope(
              height: 55,
              color: AppColors.electricBlue,
              frequency: 5.0,
            ),
          ),

          const SizedBox(height: 6),

          // 4. Memory Partition Usage Stack
          HudBox(
            title: 'MEMORY ALLOCATION',
            subtitle: '8.00 GB TOTAL',
            height: 110,
            child: Column(
              children: [
                _buildMemoryBar('FREE', 0.56, '4.48 GB', AppColors.cyanGlow),
                const SizedBox(height: 4),
                _buildMemoryBar('USED', 0.44, '3.52 GB', AppColors.electricBlue),
                const SizedBox(height: 4),
                _buildMemoryBar('CACHE', 0.18, '1.44 GB', AppColors.cyanGlow),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 5. System Activity Console Logs
          SizedBox(
            height: 130,
            child: HudBox(
              title: 'SYSTEM TELEMETRY LOGS',
              subtitle: 'LIVE FEED',
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  Text('> SYS_INIT: OK', style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  Text('> CORE_SYNC: 60 FPS', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  Text('> AUDIO_IN: MAPPED', style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  Text('> MEM_ALLOC: SECURE', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  Text('> FALCON_AI: LISTENING...', style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryBar(String label, double pct, String sizeStr, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
            Text(sizeStr, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Share Tech Mono')),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 4,
            backgroundColor: AppColors.glassBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
