import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

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
                  _buildHeaderMetric('TIME', '00:00:02', AppColors.textSecondary),
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

          // 2. Center Circular Camera Lens & User Badge (Exact match to JARVIS OS Ver 1.2.8 Badge)
          Align(
            alignment: Alignment.center,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.panelBackground.withOpacity(0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.cyanGlow.withOpacity(0.7), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyanGlow.withOpacity(0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.obsidian,
                      border: Border.all(color: AppColors.cyanGlow, width: 1.5),
                    ),
                    child: const Icon(Icons.person, color: AppColors.cyanGlow, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
