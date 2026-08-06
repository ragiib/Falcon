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
      width: 280,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. Digital Clock & Date Box (Matches reference 05:15:21 PM)
          HudBox(
            title: 'LOCAL SYSTEM TIME',
            subtitle: DateFormat('yyyy.MM.dd').format(_now),
            height: 85,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('hh:mm:ss a').format(_now),
                  style: const TextStyle(
                    color: AppColors.cyanGlow,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                    fontFamily: 'Share Tech Mono',
                  ),
                ),
                Text(
                  'TIME ZONE: LOCAL // SYNCHRONIZED',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 8,
                    fontFamily: 'Share Tech Mono',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 2. Futuristic Weather Dashboard Widget (Matches reference 30°C Fair)
          HudBox(
            title: 'LOCATION & ATMOSPHERE',
            subtitle: 'STATION-01',
            height: 145,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '30°C',
                      style: TextStyle(
                        color: AppColors.cyanGlow,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Share Tech Mono',
                      ),
                    ),
                    Text(
                      'FAIR / CLEAR\nHumidity: 44%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 9,
                        fontFamily: 'Share Tech Mono',
                      ),
                    ),
                  ],
                ),
                const Divider(color: AppColors.glassBorder, height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Visibility: 16.1 km', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                    Text('Wind: 8 km/h (E)', style: TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Pressure: 1015.2 mb', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                    Text('Sunrise: 7:00 AM', style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 3. AI Tasks & Active Services Monitor
          HudBox(
            title: 'RUNNING SERVICES & TASKS',
            subtitle: '6 ACTIVE',
            height: 110,
            child: Column(
              children: [
                _buildServiceRow('FALCON_CORE_ENGINE', 'RUNNING', AppColors.cyanGlow),
                _buildServiceRow('VOICE_SYNTHESIZER', 'STANDBY', AppColors.electricBlue),
                _buildServiceRow('VISION_SENSOR_AI', 'IDLE', AppColors.textSecondary),
                _buildServiceRow('SYSTEM_TELEMETRY', 'ACTIVE', AppColors.cyanGlow),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 4. Secondary CPU / RAM Mini Line Graph
          const HudBox(
            title: 'SECONDARY CPU TELEMETRY',
            subtitle: 'CORE #2',
            height: 100,
            child: AnimatedLineChart(
              height: 60,
              dataPoints: [0.4, 0.2, 0.6, 0.3, 0.7, 0.5, 0.8, 0.4, 0.9, 0.6],
              color: AppColors.electricBlue,
            ),
          ),

          const SizedBox(height: 6),

          // 5. Storage Partitions Stack
          SizedBox(
            height: 100,
            child: HudBox(
              title: 'STORAGE PARTITIONS',
              subtitle: 'NVME / SSD',
              child: Column(
                children: [
                  _buildStorageBar('DISK #1 (C:)', 0.65, '215.6 GB FREE'),
                  const SizedBox(height: 6),
                  _buildStorageBar('DISK #2 (E:)', 0.88, '239.4 GB FREE'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String name, String status, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(status, style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.bold, fontFamily: 'Share Tech Mono')),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageBar(String label, double pct, String freeStr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.cyanGlow, fontSize: 8, fontFamily: 'Share Tech Mono')),
            Text(freeStr, style: const TextStyle(color: AppColors.textSecondary, fontSize: 8, fontFamily: 'Share Tech Mono')),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: AppColors.glassBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyanGlow),
          ),
        ),
      ],
    );
  }
}
