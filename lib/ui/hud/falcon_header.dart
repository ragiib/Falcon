import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'live_status_indicator.dart';

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
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.obsidian.withOpacity(0.92),
        border: const Border(bottom: BorderSide(color: AppColors.glassBorder, width: 1)),
      ),
      child: Stack(
        children: [
          // 1. Left & Right Telemetry Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left Telemetry Strip
              Row(
                children: [
                  _buildHeaderMetric('SAMPLERATE', 'OK HD', AppColors.cyanGlow),
                  _buildHeaderMetric('BITRATE', '512Kbps', AppColors.cyanGlow),
                  _buildHeaderMetric('CHANNELS', '02', AppColors.electricBlue),
                ],
              ),

              // Right Telemetry Strip
              Row(
                children: [
                  _buildHeaderMetric('SYS_STATUS', 'NOMINAL', AppColors.cyanGlow),
                  _buildHeaderMetric('ENCRYPTION', 'AES-256', AppColors.electricBlue),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm:ss').format(_now),
                    style: const TextStyle(
                      color: AppColors.cyanGlow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                      fontFamily: 'Share Tech Mono',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Center Live Animated Status Indicator Banner
          const Align(
            alignment: Alignment.center,
            child: LiveStatusIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 8,
              letterSpacing: 1.0,
              fontFamily: 'Share Tech Mono',
            ),
          ),
          Text(
            val,
            style: TextStyle(
              color: color,
              fontSize: 9,
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
