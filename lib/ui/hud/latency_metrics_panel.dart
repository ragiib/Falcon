import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hud_panel.dart';
import '../theme/app_colors.dart';
import '../../providers/chat_provider.dart';

class LatencyMetricsPanel extends ConsumerWidget {
  const LatencyMetricsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiStateProvider);
    
    String status = "IDLE";
    Color statusColor = AppColors.cyanGlow;
    if (aiState == AiState.thinking) {
      status = "ANALYZING";
      statusColor = AppColors.purpleEnergy;
    } else if (aiState == AiState.generating) {
      status = "GENERATING";
      statusColor = AppColors.blueEnergy;
    }

    return HudPanel(
      title: 'PERFORMANCE',
      alignment: Alignment.centerRight,
      children: [
        HudMetricRow(
          label: 'STATUS',
          value: status,
          color: statusColor,
        ),
        const HudMetricRow(
          label: 'LATENCY',
          value: '24ms',
        ),
        const HudMetricRow(
          label: 'TPS',
          value: '42.5',
          color: AppColors.purpleEnergy,
        ),
        const Divider(color: AppColors.glassBorder, height: 24),
        const HudMetricRow(
          label: 'INTENT',
          value: 'CONVERSATION',
        ),
        const HudMetricRow(
          label: 'PROFILE',
          value: 'BALANCED',
        ),
      ],
    );
  }
}
