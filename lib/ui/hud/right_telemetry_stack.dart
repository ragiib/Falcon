import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'procedural_charts.dart';

class RightTelemetryStack extends StatefulWidget {
  const RightTelemetryStack({Key? key}) : super(key: key);

  @override
  State<RightTelemetryStack> createState() => _RightTelemetryStackState();
}

class _RightTelemetryStackState extends State<RightTelemetryStack> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 290,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. Thermal Telemetry Strip & System Uptime
          HudBox(
            title: 'SYSTEM THERMAL TELEMETRY',
            subtitle: '12 DAYS 20 HRS 06 MINS',
            height: 75,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildThermalItem('CPU', '38.5 °C'),
                _buildThermalItem('GPU', '41.0 °C'),
                _buildThermalItem('HDD', '32.0 °C'),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 2. Weather Dashboard & Digital Clock Dual Stack (Matches reference 30°C Fair & 05:15:21 PM)
          HudBox(
            title: 'ATMOSPHERIC & SYSTEM CLOCK',
            subtitle: DateFormat('yyyy.MM.dd').format(_now),
            height: 165,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '30°C',
                          style: TextStyle(
                            color: AppColors.cyanGlow,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Share Tech Mono',
                          ),
                        ),
                        Text(
                          'Fair // Clear',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono'),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          DateFormat('05:15:21 PM').format(_now),
                          style: const TextStyle(
                            color: AppColors.cyanGlow,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontFamily: 'Share Tech Mono',
                          ),
                        ),
                        const Text(
                          'MOUNTAIN STANDARD TIME',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 7, fontFamily: 'Share Tech Mono'),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: AppColors.glassBorder, height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Humidity: 44%', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                    Text('Feels Like: 30°', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                    Text('Wind: 8 km/h (E)', style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Visibility: 16.1 km', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                    Text('Pressure: 1015.2 mb', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                    Text('Sunset: 8:19 PM', style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('3-DAY FORECAST: TONIGHT 15° // TOMORROW 31°/17° // TUESDAY 33°/20°', style: TextStyle(color: AppColors.cyanGlow, fontSize: 7, fontFamily: 'Share Tech Mono')),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // 3. System RAM Telemetry (Matching reference RAM 084%)
          const HudBox(
            title: 'SYSTEM RAM PERFORMANCE LOAD',
            subtitle: '084%',
            height: 105,
            child: AnimatedLineChart(
              height: 65,
              dataPoints: [0.4, 0.5, 0.6, 0.84, 0.7, 0.84, 0.6, 0.84, 0.5, 0.84],
              color: AppColors.electricBlue,
            ),
          ),

          const SizedBox(height: 4),

          // 4. Secondary CPU #2 Telemetry
          const HudBox(
            title: 'CPU #2 SECONDARY TELEMETRY',
            subtitle: 'ACTIVE',
            height: 100,
            child: AnimatedLineChart(
              height: 60,
              dataPoints: [0.2, 0.3, 0.5, 0.4, 0.6, 0.3, 0.7, 0.5, 0.4, 0.6],
            ),
          ),

          const SizedBox(height: 4),

          // 5. System Trash / Cleanup Resource Meter (Matching reference USAGE 084%)
          SizedBox(
            height: 100,
            child: HudBox(
              title: 'SYSTEM RESOURCE CLEANUP',
              subtitle: 'USAGE 084%',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline, color: AppColors.cyanGlow, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('SYSTEM BUFFER: 84% FULL', style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontWeight: FontWeight.bold, fontFamily: 'Share Tech Mono')),
                        SizedBox(height: 2),
                        Text('AUTOCLEAN STANDBY // NOMINAL', style: TextStyle(color: AppColors.textSecondary, fontSize: 7, fontFamily: 'Share Tech Mono')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThermalItem(String label, String temp) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
        const SizedBox(height: 2),
        Text(temp, style: const TextStyle(color: AppColors.cyanGlow, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Share Tech Mono')),
      ],
    );
  }
}
