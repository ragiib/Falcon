import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'hud_components.dart';

class TopHeader extends StatefulWidget {
  const TopHeader({Key? key}) : super(key: key);

  @override
  State<TopHeader> createState() => _TopHeaderState();
}

class _TopHeaderState extends State<TopHeader> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
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
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Clock
          AngledBorder(
            isLeft: true,
            angleSize: 20,
            borderWidth: 2,
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('HH:mm:ss').format(_now),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.cyanGlow,
                      fontFamily: 'Share Tech Mono',
                      letterSpacing: 4.0,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STANDARD TIME',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textPrimary),
                      ),
                      Text(
                        DateFormat('yyyy.MM.dd').format(_now),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const LinearBar(label: '', value: 1.0),
                ],
              ),
            ),
          ),

          // Center Info
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                _buildMetricBox('UPTIME', '00 1:53', context),
                const SizedBox(width: 16),
                _buildMetricBox('POWER', 'AC LINE', context),
                const SizedBox(width: 16),
                _buildMetricBox('BATTERY', '100%', context, color: AppColors.success),
              ],
            ),
          ),

          // Right side: Drive/Storage
          AngledBorder(
            isLeft: false,
            angleSize: 20,
            borderWidth: 2,
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('[STORAGE]', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 8),
                  const LinearBar(label: 'MAIN DRIVE', value: 0.65),
                  const SizedBox(height: 4),
                  const LinearBar(label: 'BACKUP DRIVE', value: 0.12, color: AppColors.purpleEnergy),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, BuildContext context, {Color color = AppColors.cyanGlow}) {
    return Column(
      children: [
        Text('[$label]', style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
