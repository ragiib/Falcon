import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import 'live_status_indicator.dart';
import '../../providers/chat_provider.dart';

class FalconHeader extends ConsumerStatefulWidget {
  const FalconHeader({Key? key}) : super(key: key);

  @override
  ConsumerState<FalconHeader> createState() => _FalconHeaderState();
}

class _FalconHeaderState extends ConsumerState<FalconHeader> {
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).fetchOperatingMode();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(operationModeProvider);
    final isLoading = ref.watch(isModelLoadingProvider);

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
              // Left Telemetry Strip + Mode Toggle Button
              Row(
                children: [
                  _buildHeaderMetric('SAMPLERATE', 'OK HD', AppColors.cyanGlow),
                  _buildHeaderMetric('BITRATE', '512Kbps', AppColors.cyanGlow),
                  const SizedBox(width: 8),
                  _buildModeToggle(context, mode, isLoading),
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

  Widget _buildModeToggle(BuildContext context, String mode, bool isLoading) {
    final isOffline = mode == 'offline_ai';
    final activeColor = isOffline ? const Color(0xFFA855F7) : AppColors.cyanGlow;

    return InkWell(
      onTap: isLoading
          ? null
          : () {
              ref.read(chatProvider.notifier).toggleOperationMode();
            },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: activeColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activeColor.withOpacity(0.8), width: 1),
          boxShadow: [
            BoxShadow(
              color: activeColor.withOpacity(0.25),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyanGlow),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'LOADING QWEN...',
                style: TextStyle(
                  color: AppColors.cyanGlow,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontFamily: 'Share Tech Mono',
                ),
              ),
            ] else ...[
              Icon(
                isOffline ? Icons.memory : Icons.bolt,
                size: 12,
                color: activeColor,
              ),
              const SizedBox(width: 5),
              Text(
                isOffline ? 'OFFLINE AI (QWEN 7B)' : 'AGENT MODE',
                style: TextStyle(
                  color: activeColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontFamily: 'Share Tech Mono',
                ),
              ),
            ]
          ],
        ),
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
