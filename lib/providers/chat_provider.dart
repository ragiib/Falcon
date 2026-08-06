import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/speech_service.dart';
import '../services/stt_service.dart';
import '../services/voice_controller.dart';
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

final speechServiceProvider = Provider((ref) => SpeechService());

final sttServiceProvider = Provider((ref) => SttService());

final voiceControllerProvider = Provider((ref) => VoiceController());

final aiStateProvider = StateProvider<AiState>((ref) => AiState.idle);

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;
  Timer? _transcriptClearTimer;
  final SpeechService _speechService = SpeechService();
  final SttService _sttService = SttService();
  final VoiceController _voiceController = VoiceController();

  ChatNotifier(this.ref) : super([]) {
    // Init session, TTS, STT, and VoiceController on startup
    ref.read(apiServiceProvider).initSession();
    _speechService.init();

    // Start native continuous background STT listener for wake word "Falcon"
    _sttService.startListening();

    // Bind Wake-Word Detection ("Falcon") -> Triggers activation sequence automatically
    _sttService.onWakeWordDetected = () {
      activateVoiceAssistant();
    };

    // Bind Recognized Speech -> Sends text directly to LLM if in listening mode
    _sttService.onSpeechRecognized = (recognizedText) {
      final currentAiState = ref.read(aiStateProvider);
      if (currentAiState == AiState.listening || currentAiState == AiState.idle) {
        sendMessage(recognizedText);
      }
    };

    // Synchronize SpeechService callbacks with AiState & VoiceController
    _speechService.onSpeechStart = () {
      ref.read(aiStateProvider.notifier).state = AiState.speaking;
      _voiceController.notifySpeaking();
    };

    _speechService.onSpeechComplete = () {
      if (ref.read(aiStateProvider) == AiState.speaking) {
        // Continuous conversation mode: Transition to listening automatically after speech
        ref.read(aiStateProvider.notifier).state = AiState.listening;
        _voiceController.notifySpeechFinished();
      }
    };

    // Synchronize VoiceController mode with AiState
    _voiceController.onModeChanged = () {
      switch (_voiceController.mode) {
        case VoiceMode.activated:
        case VoiceMode.greeting:
          ref.read(aiStateProvider.notifier).state = AiState.speaking;
          break;
        case VoiceMode.listening:
        case VoiceMode.continuousConversation:
          ref.read(aiStateProvider.notifier).state = AiState.listening;
          break;
        case VoiceMode.processing:
          ref.read(aiStateProvider.notifier).state = AiState.thinking;
          break;
        case VoiceMode.speaking:
          ref.read(aiStateProvider.notifier).state = AiState.speaking;
          break;
        case VoiceMode.idle:
        case VoiceMode.returningToIdle:
          ref.read(aiStateProvider.notifier).state = AiState.idle;
          break;
        default:
          break;
      }
    };
  }

  /// Triggers wake-word activation greeting ("Falcon")
  Future<void> activateVoiceAssistant() async {
    await _speechService.stop();
    await _voiceController.activate();
  }

  void sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    _transcriptClearTimer?.cancel();

    // Interruption handling: Immediately stop any active speech playback
    await _speechService.stop();
    _voiceController.notifyProcessing();

    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    final aiMsgId = (DateTime.now().millisecondsSinceEpoch + 1).toString();
    final aiMsg = ChatMessage(
      id: aiMsgId,
      content: '',
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    // Keep latest exchange in state for temporary transcript overlay
    state = [userMsg, aiMsg];
    
    // Set state to thinking
    ref.read(aiStateProvider.notifier).state = AiState.thinking;

    final stream = ref.read(apiServiceProvider).sendChatMessage(content);
    
    bool isFirstToken = true;
    await for (final token in stream) {
      if (isFirstToken) {
        ref.read(aiStateProvider.notifier).state = AiState.generating;
        isFirstToken = false;
      }

      // Stream incoming token directly into TTS engine for low-latency sentence speech
      _speechService.handleStreamingToken(token);
      
      // Update AI message with new token
      state = state.map((msg) {
        if (msg.id == aiMsgId) {
          return msg.copyWith(content: msg.content + token);
        }
        return msg;
      }).toList();
    }

    // Finalize sentence buffer for TTS
    _speechService.finalizeStreaming();

    // Mark message streaming complete
    state = state.map((msg) {
      if (msg.id == aiMsgId) {
        return msg.copyWith(isStreaming: false);
      }
      return msg;
    }).toList();

    // Start timer to clear transcript overlay after 6 seconds of idle/listening state
    _transcriptClearTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && (ref.read(aiStateProvider) == AiState.idle || ref.read(aiStateProvider) == AiState.listening)) {
        state = [];
      }
    });
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});
