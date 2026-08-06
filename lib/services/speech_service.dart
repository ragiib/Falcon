import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

enum SpeechState { idle, playing, paused, stopped, error }

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  SpeechState _state = SpeechState.idle;
  SpeechState get state => _state;

  VoidCallback? onSpeechStart;
  VoidCallback? onSpeechComplete;
  VoidCallback? onSpeechCancel;
  Function(String)? onError;

  Process? _activeProcess;
  final List<String> _speechQueue = [];
  bool _isProcessingQueue = false;
  StringBuffer _tokenBuffer = StringBuffer();

  Future<void> init() async {
    debugPrint("[Native Windows Speech Engine] Initialized successfully.");
  }

  /// Immediately stops active speech playback and clears the speech queue (Interruption handling)
  Future<void> stop() async {
    _speechQueue.clear();
    _tokenBuffer.clear();
    _isProcessingQueue = false;

    if (_activeProcess != null) {
      try {
        _activeProcess!.kill(ProcessSignal.sigkill);
        _activeProcess = null;
      } catch (e) {
        debugPrint("[Native TTS] Kill error: $e");
      }
    }

    _state = SpeechState.stopped;
    debugPrint("[Native TTS] Speech stopped & queue cleared.");
    // Do NOT call onSpeechComplete here — stop() is an interruption,
    // not a natural completion. Firing it here causes false state transitions
    // (e.g., entering Listening mode before greeting even starts).
    onSpeechCancel?.call();
  }

  /// Appends incoming streaming LLM token for low-latency sentence-level speech
  void handleStreamingToken(String token) {
    _tokenBuffer.write(token);
    final text = _tokenBuffer.toString();

    // Sentence boundary detection (. ! ? or newline)
    final RegExp sentenceRegex = RegExp(r'([^.!?\n]+[.!?\n]+)');
    final matches = sentenceRegex.allMatches(text);

    if (matches.isNotEmpty) {
      int lastMatchEnd = 0;
      for (final match in matches) {
        final sentence = match.group(0)?.trim();
        if (sentence != null && sentence.isNotEmpty) {
          enqueueSpeech(sentence);
        }
        lastMatchEnd = match.end;
      }
      final remaining = text.substring(lastMatchEnd);
      _tokenBuffer = StringBuffer(remaining);
    }
  }

  /// Flushes remaining text in token buffer when LLM generation completes
  void finalizeStreaming() {
    final remaining = _tokenBuffer.toString().trim();
    if (remaining.isNotEmpty) {
      enqueueSpeech(remaining);
    }
    _tokenBuffer.clear();
  }

  /// Enqueues clean text segment for native TTS playback
  void enqueueSpeech(String text) {
    if (text.trim().isEmpty) return;
    // Strip markdown formatting symbols for clean spoken output (*, #, `, _, etc.)
    final cleanText = text
        .replaceAll(RegExp(r'[*#`_~>\[\]]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleanText.isEmpty) return;

    _speechQueue.add(cleanText);
    _processQueue();
  }

  /// Speaks text directly
  Future<void> speakDirect(String text) async {
    await stop();
    enqueueSpeech(text);
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _speechQueue.isEmpty) return;

    _isProcessingQueue = true;
    final nextText = _speechQueue.removeAt(0);

    // Escape single quotes for PowerShell string literal
    final escapedText = nextText.replaceAll("'", "''");

    final psCommand =
        "Add-Type -AssemblyName System.Speech; \$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; \$s.Rate = 1; \$s.Speak('$escapedText')";

    try {
      _state = SpeechState.playing;
      onSpeechStart?.call();

      _activeProcess = await Process.start(
        'powershell',
        ['-NoProfile', '-Command', psCommand],
      );

      final exitCode = await _activeProcess!.exitCode;
      _activeProcess = null;

      debugPrint("[Native TTS] Segment finished with exit code $exitCode");
      _onSegmentComplete();
    } catch (e) {
      debugPrint("[Native TTS] Execution error: $e");
      _activeProcess = null;
      _onSegmentComplete();
    }
  }

  void _onSegmentComplete() {
    _isProcessingQueue = false;
    if (_speechQueue.isNotEmpty) {
      _processQueue();
    } else {
      _state = SpeechState.idle;
      onSpeechComplete?.call();
    }
  }
}
