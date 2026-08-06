import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hud_panel.dart';
import '../theme/app_colors.dart';

class SystemMetricsPanel extends ConsumerWidget {
  const SystemMetricsPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In the future, this will read from a metrics provider
    
    return HudPanel(
      title: 'SYSTEM STATUS',
      alignment: Alignment.centerLeft,
      children: [
        const HudMetricRow(
          label: 'CPU USAGE',
          value: '14%',
          progress: 0.14,
        ),
        const HudMetricRow(
          label: 'GPU USAGE',
          value: '42%',
          progress: 0.42,
          color: AppColors.purpleEnergy,
        ),
        const HudMetricRow(
          label: 'SYS RAM',
          value: '12.4 / 32 GB',
          progress: 0.38,
        ),
        const HudMetricRow(
          label: 'VRAM',
          value: '8.2 / 24 GB',
          progress: 0.34,
          color: AppColors.purpleEnergy,
        ),
        const Divider(color: AppColors.glassBorder, height: 24),
        const HudMetricRow(
          label: 'MODEL',
          value: 'FALCON-7B-INSTRUCT',
        ),
        const HudMetricRow(
          label: 'BACKEND',
          value: 'ONLINE',
          color: AppColors.success,
        ),
      ],
    );
  }
}
