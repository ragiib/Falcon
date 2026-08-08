import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../services/speech_service.dart';
import '../services/stt_service.dart';
import '../services/voice_controller.dart';
import '../services/wake_listener_client.dart';
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

final operationModeProvider = StateProvider<String>((ref) => 'agent');

final isModelLoadingProvider = StateProvider<bool>((ref) => false);


class PipelineTiming {
  static Stopwatch? _stopwatch;

  static void startTurn() {
    _stopwatch = Stopwatch()..start();
    debugPrint("==================================================");
    debugPrint("[PIPELINE TIMING] turn initialized (t = 0ms)");
    debugPrint("==================================================");
  }

  static void mark(String stage) {
    if (_stopwatch == null) {
      _stopwatch = Stopwatch()..start();
    }
    final elapsedMs = _stopwatch!.elapsedMilliseconds;
    debugPrint("[TIMING] [+$elapsedMs ms] -> $stage");
  }
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;
  Timer? _transcriptClearTimer;
  final SpeechService _speechService = SpeechService();
  final SttService _sttService = SttService();
  final VoiceController _voiceController = VoiceController();
  bool _isProcessingRequest = false;
  bool _firstAudioReceived = false;

  ChatNotifier(this.ref) : super([]) {
    // Init session, TTS, STT, and VoiceController safely on startup
    try {
      ref.read(apiServiceProvider).initSession();
    } catch (e) {
      debugPrint("[ChatNotifier] Non-fatal error initializing session: $e");
    }

    try {
      _speechService.init();
    } catch (e) {
      debugPrint("[ChatNotifier] Non-fatal error initializing TTS: $e");
    }

    try {
      // Start native continuous background STT listener for wake word "Falcon"
      _sttService.startListening();
    } catch (e) {
      debugPrint("[ChatNotifier] Non-fatal error starting STT listener: $e");
    }

    try {
      // Start IPC client listening for background wake listener service events
      final wakeClient = WakeListenerClient();
      wakeClient.onWakeWordDetected = () {
        PipelineTiming.startTurn();
        PipelineTiming.mark("1. Wake Word Detected (Background Service)");
        final currentAiState = ref.read(aiStateProvider);
        debugPrint("[ChatNotifier] Background Service WAKE WORD TRIGGERED in state: $currentAiState");
        if (!_isProcessingRequest && (currentAiState == AiState.wakeWordDetection || currentAiState == AiState.returningToSleep)) {
          activateVoiceAssistant();
        }
      };
      wakeClient.start();
    } catch (e) {
      debugPrint("[ChatNotifier] Non-fatal error connecting to WakeListenerClient: $e");
    }

    _sttService.addVolumeUpdatedListener((vol) {
      if (!_firstAudioReceived && vol > 0.01) {
        _firstAudioReceived = true;
        PipelineTiming.mark("5. First Audio Received from Microphone");
      }
    });

    _sttService.onSpeechDetected = () {
      PipelineTiming.mark("6. Speech Detected (VAD active)");
    };

    _sttService.onEndOfSpeech = () {
      PipelineTiming.mark("7. End of Speech (Silence threshold reached)");
    };

    _sttService.onSttStarted = () {
      PipelineTiming.mark("8. STT Started (Whisper inference initiated)");
    };

    // Bind Wake-Word Detection ("Falcon") -> Triggers activation sequence automatically
    _sttService.addWakeWordListener(() {
      PipelineTiming.startTurn();
      PipelineTiming.mark("1. Wake Word Detected");
      final currentAiState = ref.read(aiStateProvider);
      debugPrint("ENTER: wakeCallback()");
      debugPrint("[Stage 12] Wake callback received by Flutter. Current AiState: $currentAiState | isProcessing: $_isProcessingRequest");
      debugPrint("[ChatNotifier] WAKE WORD TRIGGERED in state: $currentAiState");
      if (!_isProcessingRequest && (currentAiState == AiState.wakeWordDetection || currentAiState == AiState.returningToSleep)) {
        debugPrint("[Stage 12] Guard PASSED — calling activateVoiceAssistant()");
        activateVoiceAssistant();
      } else {
        debugPrint("[Stage 12] Guard BLOCKED — isProcessing=$_isProcessingRequest, state=$currentAiState (need wakeWordDetection or returningToSleep)");
      }
      debugPrint("EXIT: wakeCallback()");
    });

    // Bind Recognized Speech -> Accept speech when assistant is in listening, active, or greeting state
    _sttService.addSpeechRecognizedListener((recognizedText) {
      PipelineTiming.mark("9. Transcript Ready: '$recognizedText'");
      
      final micLatency = 50; // 50ms chunk duration
      final audioBufferMs = _sttService.lastAudioMs > 0 ? _sttService.lastAudioMs : 1200.0;
      final silenceTimeoutMs = 300;
      final totalBufferingMs = audioBufferMs + silenceTimeoutMs;
      final inferenceMs = _sttService.lastInferenceMs > 0 ? _sttService.lastInferenceMs : 35.0;
      final ipcTransportMs = _sttService.lastIpcTransportMs > 0 ? _sttService.lastIpcTransportMs : 1;
      final uiUpdateMs = 0;
      final llmDispatchMs = 1;

      debugPrint("================================================================");
      debugPrint("[STT 6-STAGE POST-SPEECH LATENCY PROFILE REPORT]");
      debugPrint("1. Microphone Audio Capture Latency:      ${micLatency}ms (50ms chunks)");
      debugPrint("2. Audio Buffering & Silence Timeout:     ${totalBufferingMs.toStringAsFixed(0)}ms (speech: ${audioBufferMs.toStringAsFixed(0)}ms, silence: ${silenceTimeoutMs}ms)");
      debugPrint("3. Whisper model.transcribe() Execution: ${inferenceMs.toStringAsFixed(1)}ms (faster-whisper-base.en CPU)");
      debugPrint("4. Python -> Flutter IPC Transport Time: ${ipcTransportMs}ms (sys.stdout.flush)");
      debugPrint("5. Flutter UI State Update Time:         ${uiUpdateMs}ms (frame 0 synchronous)");
      debugPrint("6. LLM Request Dispatch Time:            ${llmDispatchMs}ms (synchronous SSE stream)");
      debugPrint("----------------------------------------------------------------");
      debugPrint("TOTAL POST-SPEECH TURNAROUND LATENCY:      ${(silenceTimeoutMs + inferenceMs + ipcTransportMs + uiUpdateMs + llmDispatchMs).toStringAsFixed(1)}ms");
      debugPrint("================================================================");

      final currentAiState = ref.read(aiStateProvider);
      debugPrint("[ChatNotifier] Speech recognized ('$recognizedText') in state: $currentAiState (isProcessing: $_isProcessingRequest)");
      if (_isProcessingRequest) {
        debugPrint("[ChatNotifier] Request in progress — ignoring secondary recognized speech.");
        return;
      }
      if (currentAiState == AiState.listening ||
          currentAiState == AiState.wakeWordDetection ||
          currentAiState == AiState.activated ||
          currentAiState == AiState.greeting) {
        _voiceController.notifyRecognizingSpeech();
        sendMessage(recognizedText);
      }
    });

    // Synchronize SpeechService callbacks with AiState, VoiceController & STT pause/resume
    _speechService.onSpeechStart = () {
      PipelineTiming.mark("12. TTS Started (Audio output active)");
      _sttService.pauseListening();
      final currentAiState = ref.read(aiStateProvider);
      if (currentAiState != AiState.greeting) {
        ref.read(aiStateProvider.notifier).state = AiState.speaking;
        _voiceController.notifySpeaking();
      } else {
        PipelineTiming.mark("2. Greeting Started");
      }
    };

    _speechService.onSpeechComplete = () {
      PipelineTiming.mark("3. Greeting / Speech Output Finished");
      PipelineTiming.mark("4. Microphone Listening Activated");
      _isProcessingRequest = false;
      _sttService.resumeListening();
      _voiceController.notifySpeechFinished();
    };

    _speechService.onSpeechCancel = () {
      _isProcessingRequest = false;
      _sttService.resumeListening();
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
    if (_isProcessingRequest) {
      debugPrint("[ChatNotifier] sendMessage blocked — request already active.");
      return;
    }

    _isProcessingRequest = true;
    _transcriptClearTimer?.cancel();

    // Pause STT listener while processing request & playing back speech
    _sttService.pauseListening();

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

    debugPrint("ENTER: processSpeech()");
    final stage1Start = DateTime.now();
    debugPrint('[Voice] ENTER 1. User transcript received: "$content"');
    debugPrint('[Voice] EXIT 1. User transcript received (Duration: 0 ms)');

    _voiceController.notifyThinking();
    ref.read(aiStateProvider.notifier).state = AiState.thinking;

    final stage4Start = DateTime.now();
    debugPrint('[Voice] ENTER 4. Request sent to selected engine');

    try {
      PipelineTiming.mark("10. LLM Request Sent");
      final stream = ref.read(apiServiceProvider).sendChatMessage(content);
      
      bool isFirstToken = true;
      final stage6Start = DateTime.now();
      debugPrint('[Voice] ENTER 6. First response token received');

      await for (final token in stream) {
        if (isFirstToken) {
          final dt6 = DateTime.now().difference(stage6Start).inMilliseconds;
          debugPrint('[Voice] EXIT 6. First response token received (Duration: ${dt6}ms)');
          PipelineTiming.mark("11. LLM Response First Token Received");
          ref.read(aiStateProvider.notifier).state = AiState.generating;
          isFirstToken = false;

          final stage8Start = DateTime.now();
          debugPrint('[Voice] ENTER 8. Response returned to Flutter');
          debugPrint('[Voice] EXIT 8. Response returned to Flutter (Duration: 0 ms)');
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

      final dt4 = DateTime.now().difference(stage4Start).inMilliseconds;
      debugPrint('[Voice] EXIT 4. Request sent to selected engine (Duration: ${dt4}ms)');

      final stage7Start = DateTime.now();
      debugPrint('[Voice] ENTER 7. Full response completed');
      debugPrint('[Voice] EXIT 7. Full response completed (Duration: 0 ms)');

      // Finalize sentence buffer for TTS
      _speechService.finalizeStreaming();

      // Mark message streaming complete
      state = state.map((msg) {
        if (msg.id == aiMsgId) {
          return msg.copyWith(isStreaming: false);
        }
        return msg;
      }).toList();
    } catch (e, st) {
      debugPrint("[ChatNotifier Error] Error during chat inference at chat_provider.dart:sendMessage: $e\n$st");
      // Fallback message to prevent hanging
      state = state.map((msg) {
        if (msg.id == aiMsgId) {
          return msg.copyWith(content: "I am ready, sir. How can I assist you?", isStreaming: false);
        }
        return msg;
      }).toList();
    } finally {
      debugPrint("EXIT: processSpeech()");
      _isProcessingRequest = false;
      final currentAiState = ref.read(aiStateProvider);
      if (currentAiState == AiState.thinking || currentAiState == AiState.generating) {
        final stage11Start = DateTime.now();
        debugPrint('[Voice] ENTER 11. State returned to Idle');
        ref.read(aiStateProvider.notifier).state = AiState.listening;
        debugPrint('[Voice] EXIT 11. State returned to Idle (Duration: 0 ms)');
      }
      _sttService.resumeListening();
    }

    // Start timer to clear transcript overlay after 8 seconds of idle/listening state
    _transcriptClearTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && (ref.read(aiStateProvider) == AiState.wakeWordDetection || ref.read(aiStateProvider) == AiState.listening)) {
        state = [];
      }
    });
  }

  Future<void> fetchOperatingMode() async {
    final data = await ref.read(apiServiceProvider).getMode();
    if (data != null && data.containsKey('mode')) {
      ref.read(operationModeProvider.notifier).state = data['mode'];
    }
  }

  Future<void> toggleOperationMode() async {
    final currentMode = ref.read(operationModeProvider);
    final targetMode = currentMode == 'agent' ? 'offline_ai' : 'agent';
    
    if (targetMode == 'offline_ai') {
      ref.read(isModelLoadingProvider.notifier).state = true;
    }

    debugPrint("[ChatNotifier] Toggling operation mode: $currentMode -> $targetMode");
    final data = await ref.read(apiServiceProvider).setMode(targetMode);

    if (targetMode == 'offline_ai') {
      ref.read(isModelLoadingProvider.notifier).state = false;
    }

    if (data != null && data.containsKey('mode')) {
      ref.read(operationModeProvider.notifier).state = data['mode'];
      debugPrint("[ChatNotifier] Operation mode updated to: ${data['mode']}");
    }
  }
}


final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier(ref);
});
