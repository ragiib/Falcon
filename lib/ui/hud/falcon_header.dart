import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'procedural_charts.dart';

class FalconHeader extends StatefulWidget {
  const FalconHeader({Key? key}) : super(key: key);

  @override
  State<FalconHeader> createState() => _FalconHeaderState();
}

class _FalconHeaderState extends State<FalconHeader> {
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
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.obsidian.withOpacity(0.8),
        border: const Border(bottom: BorderSide(color: AppColors.glassBorder, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Telemetry Strip
          Row(
            children: [
              _buildHeaderMetric('CPU', '04%', AppColors.cyanGlow),
              _buildHeaderMetric('GPU', '12%', AppColors.cyanGlow),
              _buildHeaderMetric('RAM', '3.2 GB', AppColors.electricBlue),
              _buildHeaderMetric('NET', '128 KB/s', AppColors.cyanGlow),
            ],
          ),

          // Central OS Badge (Matches JARVIS OS Ver 1.2.8 Badge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.panelBackground.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cyanGlow.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyanGlow.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.cyanGlow,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'FALCON OS  Ver 2.0.0',
                      style: TextStyle(
                        color: AppColors.cyanGlow,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'Share Tech Mono',
                      ),
                    ),
                    Text(
                      'User: Operator // System Ready',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 8,
                        letterSpacing: 1.0,
                        fontFamily: 'Share Tech Mono',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Right Telemetry Strip & Clock
          Row(
            children: [
              _buildHeaderMetric('VOICE', 'ACTIVE', AppColors.cyanGlow),
              _buildHeaderMetric('BATTERY', '100%', AppColors.cyanGlow),
              const SizedBox(width: 12),
              Text(
                DateFormat('HH:mm:ss').format(_now),
                style: const TextStyle(
                  color: AppColors.cyanGlow,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  fontFamily: 'Share Tech Mono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              letterSpacing: 1.0,
              fontFamily: 'Share Tech Mono',
            ),
          ),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              fontFamily: 'Share Tech Mono',
            ),
          ),
        ],
      ),
    );
  }
}
