import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/speech_service.dart';
import '../services/stt_service.dart';

enum VoiceMode {
  wakeWordDetection,
  activated,
  greeting,
  listening,
  recognizingSpeech,
  processingRequest,
  thinking,
  speaking,
  returningToSleep,
  error,
}

class VoiceController {
  static final VoiceController _instance = VoiceController._internal();
  factory VoiceController() => _instance;
  VoiceController._internal();

  final SpeechService _speechService = SpeechService();
  VoiceMode _mode = VoiceMode.wakeWordDetection;
  VoiceMode get mode => _mode;

  Timer? _continuousListeningTimer;
  VoidCallback? onModeChanged;

  /// Triggered when wake word "Falcon" is detected or activation key/button pressed
  Future<void> activate({String greeting = "Yes, sir."}) async {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.greeting;
    onModeChanged?.call();

    debugPrint("[WAKE TRACE] VoiceController.activate() ENTERED");
    debugPrint("[COLD WAKE 001] VoiceController.activate()");
    debugPrint("[WAKE TRACE] State transition: VoiceMode -> GREETING");
    debugPrint("[COLD WAKE 001] Greeting started: \"$greeting\"");
    debugPrint("[WAKE TRACE] Greeting TTS started: \"$greeting\"");
    _speechService.speakDirect(greeting);
  }

  /// Called when TTS finishes speaking (greeting or response)
  void notifySpeechFinished() {
    debugPrint("[WAKE TRACE] Function: VoiceController.notifySpeechFinished() | Current mode: $_mode");
    if (_mode == VoiceMode.greeting || _mode == VoiceMode.speaking) {
      debugPrint("[WAKE TRACE] Greeting/Response TTS finished. Transitioning to ACTIVE LISTENING mode.");
      _enterListeningMode();
    }
  }

  void _enterListeningMode() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.listening;
    onModeChanged?.call();

    debugPrint("[WAKE TRACE] VoiceController._enterListeningMode()");
    debugPrint("[COLD WAKE 001] ACTIVE_LISTENING");
    debugPrint("[WAKE TRACE] State transition: VoiceMode -> ACTIVE_LISTENING");
    debugPrint("[WAKE TRACE] Unpausing Whisper STT command listener (10s window open)");
    SttService().resumeListening();

    _continuousListeningTimer = Timer(const Duration(seconds: 10), () {
      if (_mode == VoiceMode.listening) {
        _returnToSleep();
      }
    });
  }

  void resetListeningTimer({int seconds = 6}) {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.listening;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: LISTENING TIMER RESET (${seconds}s window)");
    _continuousListeningTimer = Timer(Duration(seconds: seconds), () {
      if (_mode == VoiceMode.listening) {
        _returnToSleep();
      }
    });
  }

  void notifyRecognizingSpeech() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.recognizingSpeech;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: RECOGNIZING SPEECH (Continuous listening timer cancelled)");
  }

  void notifyProcessingRequest() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.processingRequest;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: PROCESSING REQUEST");
  }

  void notifyThinking() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.thinking;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: THINKING");
  }

  void notifySpeaking() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.speaking;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: SPEAKING");
  }

  void _returnToSleep() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.returningToSleep;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: RETURNING TO SLEEP");

    Timer(const Duration(milliseconds: 500), () {
      _mode = VoiceMode.wakeWordDetection;
      onModeChanged?.call();
      SttService().pauseListening();
      debugPrint("[VoiceController] STATUS: WAKE WORD DETECTION (Monitoring for 'Falcon wake up')");
    });
  }
}
