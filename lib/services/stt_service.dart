import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class SttService {
  static final SttService _instance = SttService._internal();
  factory SttService() => _instance;
  SttService._internal();

  Process? _process;
  bool _isListening = false;
  bool get isListening => _isListening;
  bool _shouldRestart = true;

  // Use callback LISTS instead of single callbacks so multiple consumers
  // (ChatNotifier, AudioAmplitudeNotifier) can register without overwriting.
  final List<VoidCallback> _wakeWordListeners = [];
  final List<Function(String)> _speechRecognizedListeners = [];
  final List<Function(double)> _volumeUpdatedListeners = [];

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

  void _handleLine(String line) {
    if (line.isEmpty) return;

    if (line == 'WAKE_WORD_DETECTED') {
      debugPrint("[STT Service] WAKE WORD DETECTED!");
      for (final cb in _wakeWordListeners) {
        cb();
      }
    } else if (line.startsWith('RECOGNIZED:')) {
      final text = line.substring(11).trim();
      if (text.isNotEmpty) {
        debugPrint("[STT Service] Recognized Speech: $text");
        for (final cb in _speechRecognizedListeners) {
          cb(text);
        }
      }
    } else if (line.startsWith('VOLUME:')) {
      final volStr = line.substring(7).trim();
      final vol = double.tryParse(volStr) ?? 0.0;
      // Normalize volume level (0-100) to 0.0-1.0
      final normalized = (vol / 100.0).clamp(0.0, 1.0);
      for (final cb in _volumeUpdatedListeners) {
        cb(normalized);
      }
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
