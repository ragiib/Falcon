import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../theme/app_colors.dart';

class LiveStatusIndicator extends ConsumerWidget {
  const LiveStatusIndicator({Key? key}) : super(key: key);

  String _getStatusText(AiState state) {
    switch (state) {
      case AiState.wakeWordDetection:
        return 'STATUS: WAKE WORD DETECTION';
      case AiState.activated:
        return 'STATUS: ACTIVATED';
      case AiState.greeting:
        return 'STATUS: GREETING';
      case AiState.listening:
        return 'STATUS: LISTENING';
      case AiState.recognizingSpeech:
        return 'STATUS: RECOGNIZING SPEECH';
      case AiState.processingRequest:
        return 'STATUS: PROCESSING REQUEST';
      case AiState.thinking:
        return 'STATUS: THINKING';
      case AiState.generating:
        return 'STATUS: GENERATING RESPONSE';
      case AiState.speaking:
        return 'STATUS: SPEAKING';
      case AiState.returningToSleep:
        return 'STATUS: RETURNING TO SLEEP';
      case AiState.error:
        return 'STATUS: ERROR';
    }
  }

  Color _getStatusColor(AiState state) {
    switch (state) {
      case AiState.activated:
      case AiState.greeting:
      case AiState.listening:
      case AiState.speaking:
        return AppColors.cyanGlow;
      case AiState.recognizingSpeech:
      case AiState.processingRequest:
      case AiState.thinking:
      case AiState.generating:
        return AppColors.electricBlue;
      case AiState.wakeWordDetection:
      case AiState.returningToSleep:
        return AppColors.textSecondary;
      case AiState.error:
        return const Color(0xFFFF3366);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiState = ref.watch(aiStateProvider);
    final statusText = _getStatusText(aiState);
    final statusColor = _getStatusColor(aiState);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.panelBackground.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing status indicator pulsing dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, val, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor.withOpacity(val),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(val * 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Animated Status Label
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: Text(
              statusText,
              key: ValueKey<String>(statusText),
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.8,
                fontFamily: 'Share Tech Mono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
