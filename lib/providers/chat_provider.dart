import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/speech_service.dart';
import '../services/stt_service.dart';
import '../services/voice_controller.dart';
import 'dart:async';

enum AiState { 
  wakeWordDetection, 
  activated, 
  greeting, 
  listening, 
  recognizingSpeech, 
  processingRequest, 
  thinking, 
  generating, 
  speaking, 
  returningToSleep, 
  error 
}

final apiServiceProvider = Provider((ref) => ApiService());

final speechServiceProvider = Provider((ref) => SpeechService());

final sttServiceProvider = Provider((ref) => SttService());

final voiceControllerProvider = Provider((ref) => VoiceController());

final aiStateProvider = StateProvider<AiState>((ref) => AiState.wakeWordDetection);

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
    _sttService.addWakeWordListener(() {
      final currentAiState = ref.read(aiStateProvider);
      if (currentAiState == AiState.wakeWordDetection) {
        activateVoiceAssistant();
      }
    });

    // Bind Recognized Speech -> STRICT GUARD: Only accept speech when in Listening state!
    _sttService.addSpeechRecognizedListener((recognizedText) {
      final currentAiState = ref.read(aiStateProvider);
      if (currentAiState == AiState.listening) {
        _voiceController.notifyRecognizingSpeech();
        sendMessage(recognizedText);
      }
    });

    // Synchronize SpeechService callbacks with AiState & VoiceController
    _speechService.onSpeechStart = () {
      final currentAiState = ref.read(aiStateProvider);
      if (currentAiState != AiState.greeting) {
        ref.read(aiStateProvider.notifier).state = AiState.speaking;
        _voiceController.notifySpeaking();
      }
    };

    _speechService.onSpeechComplete = () {
      _voiceController.notifySpeechFinished();
    };

    // Synchronize VoiceController mode with AiState
    _voiceController.onModeChanged = () {
      switch (_voiceController.mode) {
        case VoiceMode.wakeWordDetection:
          ref.read(aiStateProvider.notifier).state = AiState.wakeWordDetection;
          break;
        case VoiceMode.activated:
          ref.read(aiStateProvider.notifier).state = AiState.activated;
          break;
        case VoiceMode.greeting:
          ref.read(aiStateProvider.notifier).state = AiState.greeting;
          break;
        case VoiceMode.listening:
          ref.read(aiStateProvider.notifier).state = AiState.listening;
          break;
        case VoiceMode.recognizingSpeech:
          ref.read(aiStateProvider.notifier).state = AiState.recognizingSpeech;
          break;
        case VoiceMode.processingRequest:
          ref.read(aiStateProvider.notifier).state = AiState.processingRequest;
          break;
        case VoiceMode.thinking:
          ref.read(aiStateProvider.notifier).state = AiState.thinking;
          break;
        case VoiceMode.speaking:
          ref.read(aiStateProvider.notifier).state = AiState.speaking;
          break;
        case VoiceMode.returningToSleep:
          ref.read(aiStateProvider.notifier).state = AiState.returningToSleep;
          break;
        default:
          break;
      }
    };
  }

  /// Triggers wake-word activation greeting ("Falcon")
  Future<void> activateVoiceAssistant() async {
    // Guard: prevent repeated activations while already active/greeting/speaking
    final currentState = ref.read(aiStateProvider);
    if (currentState != AiState.wakeWordDetection && currentState != AiState.returningToSleep) {
      debugPrint('[ChatNotifier] Activation blocked — already in state: $currentState');
      return;
    }
    await _speechService.stop();
    await _voiceController.activate();
  }

  void sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    _transcriptClearTimer?.cancel();

    // Interruption handling: Immediately stop active speech playback
    await _speechService.stop();
    _voiceController.notifyProcessingRequest();

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

    await Future.delayed(const Duration(milliseconds: 300));
    _voiceController.notifyThinking();
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

    // Start timer to clear transcript overlay after 8 seconds of idle/listening state
    _transcriptClearTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && (ref.read(aiStateProvider) == AiState.wakeWordDetection || ref.read(aiStateProvider) == AiState.listening)) {
        state = [];
      }
    });
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});
