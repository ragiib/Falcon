import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/speech_service.dart';

enum VoiceMode {
  idle,
  wakeWordDetection,
  activated,
  greeting,
  listening,
  processing,
  speaking,
  continuousConversation,
  returningToIdle,
}

class VoiceController {
  static final VoiceController _instance = VoiceController._internal();
  factory VoiceController() => _instance;
  VoiceController._internal();

  final SpeechService _speechService = SpeechService();
  VoiceMode _mode = VoiceMode.idle;
  VoiceMode get mode => _mode;

  Timer? _continuousListeningTimer;
  VoidCallback? onModeChanged;
  Function(String)? onUserSpeechRecognized;

  /// Triggered when wake word "Falcon" is detected or activation key/button pressed
  Future<void> activate({String greeting = "Yes, sir. How can I assist you today?"}) async {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.activated;
    onModeChanged?.call();
    debugPrint("[VoiceController] Activated! Playing voice greeting...");

    _mode = VoiceMode.greeting;
    onModeChanged?.call();

    // Speak natural greeting aloud
    await _speechService.speakDirect(greeting);

    // After greeting completes, enter Listening mode automatically
    _enterListeningMode();
  }

  void _enterListeningMode() {
    _mode = VoiceMode.listening;
    onModeChanged?.call();
    debugPrint("[VoiceController] Transitioned to Listening mode.");

    // Start 7-second continuous listening window timer
    _continuousListeningTimer?.cancel();
    _continuousListeningTimer = Timer(const Duration(seconds: 7), () {
      if (_mode == VoiceMode.listening) {
        _returnToIdle();
      }
    });
  }

  /// Triggered when AI starts processing or generating response
  void notifyProcessing() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.processing;
    onModeChanged?.call();
  }

  /// Triggered when AI starts speaking response
  void notifySpeaking() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.speaking;
    onModeChanged?.call();
  }

  /// Triggered when AI finishes speaking response
  void notifySpeechFinished() {
    debugPrint("[VoiceController] AI response speech finished. Entering Continuous Conversation window.");
    _enterListeningMode();
  }

  void _returnToIdle() {
    _mode = VoiceMode.returningToIdle;
    onModeChanged?.call();
    debugPrint("[VoiceController] Returning to Idle state.");

    Timer(const Duration(milliseconds: 500), () {
      _mode = VoiceMode.idle;
      onModeChanged?.call();
      debugPrint("[VoiceController] Idle. Resumed ambient wake-word detection.");
    });
  }
}
