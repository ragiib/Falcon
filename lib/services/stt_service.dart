import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'wake_listener_client.dart';

class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  Process? _process;
  bool _isListening = false;
  bool get isListening => _isListening;
  bool _shouldRestart = true;
  bool _permissionGranted = false;
  bool get permissionGranted => _permissionGranted;

  // Use callback LISTS instead of single callbacks so multiple consumers
  // (ChatNotifier, AudioAmplitudeNotifier) can register without overwriting.
  final List<VoidCallback> _wakeWordListeners = [];
  final List<Function(String)> _speechRecognizedListeners = [];
  final List<Function(double)> _volumeUpdatedListeners = [];

  Future<bool> checkAndRequestPermission() async {
    // Win32 applications on Windows access audio directly via WASAPI / PortAudio drivers.
    // Calling permission_handler on Windows desktop queries WinRT UWP capabilities,
    // which can alter Windows privacy settings when the application process terminates.
    if (Platform.isWindows) {
      _permissionGranted = true;
      return true;
    }

    try {
      var status = await Permission.microphone.status;
      debugPrint("[STT Service] Initial Microphone Permission Status: $status");
      if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
        debugPrint("[STT Service] Requesting Microphone Permission...");
        status = await Permission.microphone.request();
        debugPrint("[STT Service] Permission Request Result: $status");
      }

      if (status.isGranted || status.isLimited) {
        _permissionGranted = true;
        debugPrint("[STT Service] Microphone Permission VERIFIED & GRANTED.");
        return true;
      } else {
        debugPrint("[STT Service] Warning: Microphone Permission status $status. Proceeding to initialize STT stream.");
        _permissionGranted = true;
        return true;
      }
    } catch (e) {
      debugPrint("[STT Service] Permission check exception: $e. Proceeding.");
      _permissionGranted = true;
      return true;
    }
  }

  void addWakeWordListener(VoidCallback cb) {
    if (!_wakeWordListeners.contains(cb)) _wakeWordListeners.add(cb);
  }

  void addSpeechRecognizedListener(Function(String) cb) {
    if (!_speechRecognizedListeners.contains(cb)) _speechRecognizedListeners.add(cb);
  }

  void addVolumeUpdatedListener(Function(double) cb) {
    if (!_volumeUpdatedListeners.contains(cb)) _volumeUpdatedListeners.add(cb);
  }

  // Keep legacy setters for backward compatibility but they ADD to the list
  set onWakeWordDetected(VoidCallback? cb) {
    _wakeWordListeners.clear();
    if (cb != null) _wakeWordListeners.add(cb);
  }

  set onSpeechRecognized(Function(String)? cb) {
    _speechRecognizedListeners.clear();
    if (cb != null) _speechRecognizedListeners.add(cb);
  }

  set onVolumeUpdated(Function(double)? cb) {
    _volumeUpdatedListeners.clear();
    if (cb != null) _volumeUpdatedListeners.add(cb);
  }

  Future<void> startListening() async {
    if (_isListening) return;
    _shouldRestart = true;

    final hasPerm = await checkAndRequestPermission();
    if (!hasPerm) {
      debugPrint("[STT Service] Microphone permission denied. Speech listener not started.");
      return;
    }

    try {
      const scriptPath = r'c:\falcon\scripts\stt_listener.py';
      final fileExists = await File(scriptPath).exists();

      if (!fileExists) {
        debugPrint("[STT Service] Error: stt_listener.py script not found.");
        return;
      }

      _process = await Process.start('python', [
        '-u',
        scriptPath,
      ]);

      _isListening = true;
      debugPrint("[STT Service] Started Faster-Whisper Large-v3 STT listener process.");

      _process!.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        _handleLine(line.trim());
      });

      _process!.stderr.transform(utf8.decoder).listen((err) {
        if (err.trim().isNotEmpty) {
          debugPrint("[STT Service Log] $err");
        }
      });

      _process!.exitCode.then((code) {
        debugPrint("[STT Service] Process exited with code $code");
        _isListening = false;
        _process = null;

        // Auto-restart resilience if exited unexpectedly
        if (_shouldRestart) {
          debugPrint("[STT Service] Auto-restarting continuous listener...");
          Future.delayed(const Duration(seconds: 1), () => startListening());
        }
      });
    } catch (e) {
      debugPrint("[STT Service] Exception starting listener: $e");
      _isListening = false;
      if (_shouldRestart) {
        Future.delayed(const Duration(seconds: 2), () => startListening());
      }
    }
  }

  VoidCallback? onSpeechDetected;
  VoidCallback? onEndOfSpeech;
  VoidCallback? onSttStarted;
  VoidCallback? onSttEmpty;

  double lastInferenceMs = 0.0;
  double lastAudioMs = 0.0;
  int lastIpcTransportMs = 0;

  void _handleLine(String line) {
    if (line.isEmpty) return;

    if (line == 'WAKE_WORD_DETECTED' || line.startsWith('WAKE_WORD_DETECTED:')) {
      final matched = line.contains(':') ? line.substring(19) : 'Falcon';
      debugPrint('[Wake] Wake phrase matched: "$matched"');
      debugPrint('[Wake] Callback executed');
      for (final cb in List.from(_wakeWordListeners)) {
        cb();
      }
    } else if (line == 'TIMING:SPEECH_DETECTED') {
      debugPrint('[Wake] Audio received');
      onSpeechDetected?.call();
    } else if (line == 'TIMING:END_OF_SPEECH') {
      onEndOfSpeech?.call();
    } else if (line == 'TIMING:STT_STARTED') {
      onSttStarted?.call();
    } else if (line == 'TIMING:STT_EMPTY') {
      onSttEmpty?.call();
    } else if (line.startsWith('TIMING:METRICS:')) {
      final parts = line.split(':');
      if (parts.length >= 5) {
        final sendTs = int.tryParse(parts[2]) ?? DateTime.now().millisecondsSinceEpoch;
        lastInferenceMs = double.tryParse(parts[3]) ?? 0.0;
        lastAudioMs = double.tryParse(parts[4]) ?? 0.0;
        lastIpcTransportMs = (DateTime.now().millisecondsSinceEpoch - sendTs).clamp(0, 1000);
      }
    } else if (line.startsWith('RECOGNIZED:')) {
      final text = line.substring(11).trim();
      if (text.isNotEmpty) {
        debugPrint('[Wake] Transcript: "$text"');
        debugPrint("[STT Service] Recognized Speech: $text");
        for (final cb in List.from(_speechRecognizedListeners)) {
          cb(text);
        }
      }
    } else if (line.startsWith('VOLUME:')) {
      final volStr = line.substring(7).trim();
      final vol = double.tryParse(volStr) ?? 0.0;
      // Normalize volume level (0-100) to 0.0-1.0
      final normalized = (vol / 100.0).clamp(0.0, 1.0);
      for (final cb in List.from(_volumeUpdatedListeners)) {
        cb(normalized);
      }
    }
  }

  void pauseListening() {
    if (_process != null && _isListening) {
      debugPrint("[STT Service] Sending PAUSE to Python Whisper listener...");
      _process!.stdin.writeln('PAUSE');
    }
    // Resume standby wake listener mic ownership
    WakeListenerClient().resumeWakeListenerMic();
  }

  void resumeListening() {
    // Pause standby wake listener mic to handoff ownership to Whisper STT
    WakeListenerClient().pauseWakeListenerMic();
    if (_process != null && _isListening) {
      debugPrint("[STT Service] Sending RESUME to Python Whisper listener...");
      _process!.stdin.writeln('RESUME');
    }
  }

  Future<void> stopListening() async {
    _shouldRestart = false;
    if (_process != null) {
      try {
        _process!.kill(ProcessSignal.sigkill);
      } catch (e) {
        debugPrint("[STT Service] Kill error: $e");
      }
      _process = null;
    }
    _isListening = false;
    debugPrint("[STT Service] Listener stopped.");
  }
}
