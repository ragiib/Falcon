import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hud_panel.dart';
import '../theme/app_colors.dart';
import '../../providers/chat_provider.dart';

class ToolActivityPanel extends ConsumerWidget {
  const ToolActivityPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiStateProvider);
    
    // Mock tool activity based on state
    bool isSearching = aiState == AiState.thinking;
    bool isFileIO = aiState == AiState.generating;

    return HudPanel(
      title: 'ACTIVE TOOLS',
      alignment: Alignment.centerRight,
      children: [
        HudMetricRow(
          label: 'WEB SEARCH',
          value: isSearching ? 'RUNNING' : 'STANDBY',
          color: isSearching ? AppColors.purpleEnergy : AppColors.textDisabled,
        ),
        HudMetricRow(
          label: 'FILE I/O',
          value: isFileIO ? 'WRITE' : 'IDLE',
          color: isFileIO ? AppColors.blueEnergy : AppColors.textDisabled,
        ),
        HudMetricRow(
          label: 'TERMINAL',
          value: 'IDLE',
          color: AppColors.textDisabled,
        ),
        const Divider(color: AppColors.glassBorder, height: 24),
        const HudMetricRow(
          label: 'TOOLCHAIN',
          value: 'SECURE',
          color: AppColors.success,
        ),
      ],
    );
  }
}
