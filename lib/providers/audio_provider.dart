import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'chat_provider.dart';

class AudioAmplitudeNotifier extends StateNotifier<double> {
  final Ref ref;
  Timer? _timer;
  final math.Random _random = math.Random();
  double _target = 0.0;

  AudioAmplitudeNotifier(this.ref) : super(0.0) {
    _startSimulation();
  }

  void _startSimulation() {
    _timer = Timer.periodic(const Duration(milliseconds: 32), (timer) {
      final aiState = ref.read(aiStateProvider);
      
      if (aiState == AiState.speaking) {
        // Simulate rapid amplitude changes for speech
        if (_random.nextDouble() > 0.7) {
          _target = _random.nextDouble() * 0.8 + 0.2;
        } else {
          _target = _target * 0.5; // decay
        }
      } else if (aiState == AiState.listening) {
        // Slow breathing wave
        _target = (math.sin(DateTime.now().millisecondsSinceEpoch / 500) + 1) / 2 * 0.3;
      } else {
        // Idle/Thinking decay to 0
        _target = 0.0;
      }

      // Interpolate for smoothness
      state = state + (_target - state) * 0.4;
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
