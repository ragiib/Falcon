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

  VoidCallback? onWakeWordDetected;
  Function(String)? onSpeechRecognized;
  Function(double)? onVolumeUpdated;

  Future<void> startListening() async {
    if (_isListening) return;

    try {
      const scriptPath = r'c:\falcon\scripts\stt_listener.ps1';
      final fileExists = await File(scriptPath).exists();

      if (!fileExists) {
        debugPrint("[STT Service] Error: stt_listener.ps1 script not found.");
        return;
      }

      _process = await Process.start('powershell', [
        '-ExecutionPolicy',
        'Bypass',
        '-NoProfile',
        '-File',
        scriptPath,
      ]);

      _isListening = true;
      debugPrint("[STT Service] Started native STT listener process.");

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
      });
    } catch (e) {
      debugPrint("[STT Service] Exception starting listener: $e");
      _isListening = false;
    }
  }

  void _handleLine(String line) {
    if (line.isEmpty) return;

    if (line == 'WAKE_WORD_DETECTED') {
      debugPrint("[STT Service] WAKE WORD DETECTED!");
      onWakeWordDetected?.call();
    } else if (line.startsWith('RECOGNIZED:')) {
      final text = line.substring(11).trim();
      if (text.isNotEmpty) {
        debugPrint("[STT Service] Recognized Speech: $text");
        onSpeechRecognized?.call(text);
      }
    } else if (line.startsWith('VOLUME:')) {
      final volStr = line.substring(7).trim();
      final vol = double.tryParse(volStr) ?? 0.0;
      // Normalize volume level (0-100) to 0.0-1.0
      final normalized = (vol / 100.0).clamp(0.0, 1.0);
      onVolumeUpdated?.call(normalized);
    }
  }

  Future<void> stopListening() async {
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
