import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import 'dart:async';

enum AiState { 
  idle, 
  listening, 
  thinking, 
  generating, 
  speaking, 
  toolExecution, 
  success, 
  warning, 
  error, 
  shutdown 
}

final apiServiceProvider = Provider((ref) => ApiService());

final aiStateProvider = StateProvider<AiState>((ref) => AiState.idle);

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;
  Timer? _transcriptClearTimer;

  ChatNotifier(this.ref) : super([]) {
    // Init session on startup
    ref.read(apiServiceProvider).initSession();
  }

  void sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    _transcriptClearTimer?.cancel();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    var aiMsg = ChatMessage(
      id: aiMsgId,
      content: '',
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    // Only keep the latest exchange in state for the temporary transcript overlay
    state = [userMsg, aiMsg];
    
    // Set state to thinking
    ref.read(aiStateProvider.notifier).state = AiState.thinking;

    final stream = ref.read(apiServiceProvider).sendChatMessage(content);
    
    bool isFirstToken = true;
    await for (final token in stream) {
      if (isFirstToken) {
        // We'll consider generating text to also be the speaking phase for the visualizer
        ref.read(aiStateProvider.notifier).state = AiState.speaking;
        isFirstToken = false;
      }
      
      // Update the AI message with new token
      state = state.map((msg) {
        if (msg.id == aiMsgId) {
          return msg.copyWith(content: msg.content + token);
        }
        return msg;
      }).toList();
    }

    // Set back to idle and mark streaming false
    ref.read(aiStateProvider.notifier).state = AiState.idle;
    state = state.map((msg) {
      if (msg.id == aiMsgId) {
        return msg.copyWith(isStreaming: false);
      }
      return msg;
    }).toList();

    // Start timer to clear transcript
    _transcriptClearTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && ref.read(aiStateProvider) == AiState.idle) {
        state = [];
      }
    });
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});
