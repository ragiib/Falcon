import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_provider.dart';
import '../services/speech_service.dart';
import '../services/stt_service.dart';

class AudioAmplitudeNotifier extends StateNotifier<double> {
  final Ref ref;
  Timer? _timer;
  final math.Random _random = math.Random();
  final SpeechService _speechService = SpeechService();
  final SttService _sttService = SttService();
  double _target = 0.0;
  double _micVolumeInput = 0.0;

  AudioAmplitudeNotifier(this.ref) : super(0.0) {
    // Listen to live microphone volume updates from STT Service
    _sttService.addVolumeUpdatedListener((micVol) {
      _micVolumeInput = micVol;
    });

    _startAmplitudeLoop();
  }

  void _startAmplitudeLoop() {
    _timer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      final aiState = ref.read(aiStateProvider);
      final isTtsSpeaking = _speechService.state == SpeechState.playing;

      if (aiState == AiState.speaking || isTtsSpeaking) {
        // AI Speaking: Erupt dynamic amplitude spikes for reactor flares & waveform
        if (_random.nextDouble() > 0.6) {
          _target = _random.nextDouble() * 0.85 + 0.15;
        } else {
          _target = _target * 0.45; // Smooth audio decay
        }
      } else if (aiState == AiState.listening || aiState == AiState.recognizingSpeech || aiState == AiState.activated) {
        // User Speaking into Mic / Speech Recognition Active: Live mic volume + pulsing bounce animation!
        if (_micVolumeInput > 0.05) {
          _target = (_micVolumeInput * 1.5).clamp(0.2, 1.0);
        } else {
          // Energetic bouncing wave during speech capture & recognition
          _target = (math.sin(DateTime.now().millisecondsSinceEpoch / 180) + 1) / 2 * 0.5 + 0.15;
        }
      } else if (aiState == AiState.generating || aiState == AiState.thinking) {
        // Generating/Thinking: Pulsing core excitation
        _target = (math.sin(DateTime.now().millisecondsSinceEpoch / 250) + 1) / 2 * 0.4 + 0.1;
      } else {
        // Idle: Smooth decay to baseline
        _target = 0.0;
        _micVolumeInput = 0.0;
      }

      // Smooth interpolation for 60 FPS visual rendering
      state = state + (_target - state) * 0.35;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final audioAmplitudeProvider = StateNotifierProvider<AudioAmplitudeNotifier, double>((ref) {
  return AudioAmplitudeNotifier(ref);
});
