import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'procedural_charts.dart';

class LeftTelemetryStack extends StatelessWidget {
  const LeftTelemetryStack({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. Audio Waveform & Oscilloscope Box
          const HudBox(
            title: 'AUDIO OSCILLOSCOPE // SAMPLERATE 44.1k',
            subtitle: 'CH-01 OK',
            height: 95,
            child: AnimatedOscilloscope(height: 55, frequency: 3.0),
          ),

          const SizedBox(height: 4),

          // 2. CPU #1 Load Chart (Matching reference CPU #1 085%)
          HudBox(
            title: 'CPU #1 PERFORMANCE LOAD',
            subtitle: '085%',
            height: 120,
            child: Column(
              children: const [
                AnimatedLineChart(
                  height: 65,
                  dataPoints: [0.2, 0.4, 0.35, 0.85, 0.6, 0.85, 0.45, 0.7, 0.3, 0.85],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('USAGE: 085%', style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono')),
                    Text('TEMP: 42.0°C', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 3. Central Processors List / Radar Sweep & Signal Analyzer
          HudBox(
            title: 'CENTRAL PROCESSORS & RADAR RADIAL',
            subtitle: 'SWEEP ACTIVE',
            height: 105,
            child: Row(
              children: const [
                RadarSweepWidget(size: 70),
                SizedBox(width: 8),
                Expanded(
                  child: AnimatedOscilloscope(
                    height: 60,
                    color: AppColors.electricBlue,
                    frequency: 5.0,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 4. Drive #1 Partition Telemetry (Matching reference DRIVE #1 C: with circular disk icon)
          HudBox(
            title: 'DRIVE #1 (C:) TELEMETRY',
            subtitle: 'NVME SSD',
            height: 110,
            child: Row(
              children: [
                // Disk Platter Icon (Matching reference circular drive icon)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cyanGlow.withOpacity(0.8), width: 1.5),
                    color: AppColors.obsidian,
                  ),
                  child: const Center(
                    child: Icon(Icons.storage, color: AppColors.cyanGlow, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildDriveRow('TOTAL SPACE', '441.1 GB', AppColors.textSecondary),
                      const SizedBox(height: 2),
                      _buildDriveRow('USED SPACE', '241.1 GB', AppColors.electricBlue),
                      const SizedBox(height: 2),
                      _buildDriveRow('FREE SPACE', '200.0 GB', AppColors.cyanGlow),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(1),
                        child: const LinearProgressIndicator(
                          value: 0.55,
                          minHeight: 4,
                          backgroundColor: AppColors.glassBorder,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyanGlow),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 5. Dual Network Traffic UP / DOWN Monitors
          SizedBox(
            height: 140,
            child: HudBox(
              title: 'NETWORK TRAFFIC TELEMETRY',
              subtitle: 'LIVE DUAL MESH',
              child: Column(
                children: const [
                  Text('TRAFFIC UP // 191.58 MB', style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  SizedBox(height: 2),
                  AnimatedOscilloscope(height: 35, frequency: 4.0),
                  SizedBox(height: 4),
                  Text('TRAFFIC DOWN // 89.31 MB', style: TextStyle(color: AppColors.electricBlue, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  SizedBox(height: 2),
                  AnimatedOscilloscope(height: 35, color: AppColors.electricBlue, frequency: 2.5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriveRow(String label, String val, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
        Text(val, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Share Tech Mono')),
      ],
    );
  }
}
