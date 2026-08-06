import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/chat_provider.dart';
import '../widgets/chat_message_bubble.dart';

class TemporaryTranscriptOverlay extends ConsumerWidget {
  const TemporaryTranscriptOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatProvider);

    if (messages.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedOpacity(
      opacity: messages.isEmpty ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.5),
              Colors.black.withOpacity(0.8),
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: messages.map((msg) => ChatMessageBubble(message: msg)).toList(),
        ),
      ),
    );
  }
}
