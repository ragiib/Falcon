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
  Future<void> activate({String greeting = "Yes, sir. How can I assist you today?"}) async {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.greeting;
    onModeChanged?.call();

    // STAGE 13: VoiceController state changed to GREETING
    debugPrint("ENTER: activate()");
    debugPrint("[Stage 13] VoiceController state changed to GREETING");
    debugPrint("[Wake] State changed to GREETING");
    debugPrint("[VoiceController] STATUS: GREETING");

    // STAGE 14: Greeting TTS started
    debugPrint("[Stage 14] Greeting TTS started: \"$greeting\"");
    debugPrint("[Wake] Greeting TTS started");
    _speechService.speakDirect(greeting);
    debugPrint("EXIT: activate()");
  }

  /// Called when TTS finishes speaking (greeting or response)
  void notifySpeechFinished() {
    debugPrint("[VoiceController] Speech finished. Current mode: $_mode");
    if (_mode == VoiceMode.greeting || _mode == VoiceMode.speaking) {
      // STAGE 15: Greeting TTS finished
      debugPrint("[Stage 15] Greeting TTS finished. Entering listening mode.");
      _enterListeningMode();
    }
  }

  void _enterListeningMode() {
    _continuousListeningTimer?.cancel();
    _mode = VoiceMode.listening;
    onModeChanged?.call();

    // STAGE 16: Listening mode entered
    debugPrint("ENTER: enterListeningMode()");
    debugPrint("[Stage 16] Listening mode entered — STT active, 10s command window open");
    debugPrint("[Wake] State changed to LISTENING");
    debugPrint("[Wake] STT enters Listening mode after greeting");
    debugPrint("[VoiceController] STATUS: LISTENING (10s command & follow-up window active)");
    SttService().resumeListening();
    debugPrint("EXIT: enterListeningMode()");

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
      SttService().resumeListening();
      debugPrint("[VoiceController] STATUS: WAKE WORD DETECTION (Monitoring for 'Falcon')");
    });
  }
}
