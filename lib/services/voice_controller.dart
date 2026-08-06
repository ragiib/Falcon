import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/speech_service.dart';

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
  Future<void> activate({String greeting = "Yes, sir. How can I assist you today?"}) async {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.activated;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: ACTIVATED");

    await Future.delayed(const Duration(milliseconds: 200));
    _mode = VoiceMode.greeting;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: GREETING");

    // Speak natural greeting aloud
    _speechService.speakDirect(greeting);
  }

  /// Called when TTS finishes speaking (greeting or response)
  void notifySpeechFinished() {
    debugPrint("[VoiceController] Speech finished. Current mode: $_mode");
    if (_mode == VoiceMode.greeting || _mode == VoiceMode.speaking) {
      _enterListeningMode();
    }
  }

  void _enterListeningMode() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.listening;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: LISTENING (10s command & follow-up window active)");

    // Start 10-second continuous listening window timer
    _continuousListeningTimer = Timer(const Duration(seconds: 10), () {
      if (_mode == VoiceMode.listening) {
        _returnToSleep();
      }
    });
  }

  void notifyRecognizingSpeech() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.recognizingSpeech;
    onModeChanged?.call();
    debugPrint("[VoiceController] STATUS: RECOGNIZING SPEECH");
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
      debugPrint("[VoiceController] STATUS: WAKE WORD DETECTION (Monitoring for 'Falcon')");
    });
  }
}
