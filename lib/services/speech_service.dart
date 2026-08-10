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
  bool _isStreamingActive = false;
  StringBuffer _tokenBuffer = StringBuffer();

  Future<void> init() async {
    debugPrint("[Native Windows Speech Engine] Initialized successfully.");
  }

  /// Immediately stops active speech playback and clears the speech queue (Interruption handling)
  Future<void> stop() async {
    _speechQueue.clear();
    _tokenBuffer.clear();
    _isProcessingQueue = false;
    _isStreamingActive = false;

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
    onSpeechCancel?.call();
  }

  /// Appends incoming streaming LLM token for low-latency sentence-level speech
  void handleStreamingToken(String token) {
    _isStreamingActive = true;
    _tokenBuffer.write(token);
    final text = _tokenBuffer.toString();

    // Sentence or clause boundary detection (. ! ? \n or comma/semicolon when chunk has >= 3 words)
    final RegExp boundaryRegex = RegExp(r'([^.!?\n,;]+[.!?\n,;]+)');
    final matches = boundaryRegex.allMatches(text);

    if (matches.isNotEmpty) {
      int lastMatchEnd = 0;
      for (final match in matches) {
        final chunk = match.group(0)?.trim();
        if (chunk != null && chunk.isNotEmpty) {
          // If chunk ends with a comma, require at least 3 words to avoid tiny fragments
          if (chunk.endsWith(',') && chunk.split(' ').length < 3) {
            continue;
          }
          enqueueSpeech(chunk);
          lastMatchEnd = match.end;
        }
      }
      if (lastMatchEnd > 0) {
        final remaining = text.substring(lastMatchEnd);
        _tokenBuffer = StringBuffer(remaining);
      }
    } else {
      // Fallback: If buffer has accumulated >= 10 words without any punctuation, chunk it at word boundary
      final words = text.trim().split(RegExp(r'\s+'));
      if (words.length >= 10) {
        final chunk = words.take(8).join(' ');
        enqueueSpeech(chunk);
        final remaining = words.skip(8).join(' ');
        _tokenBuffer = StringBuffer(remaining);
      }
    }
  }

  /// Flushes remaining text in token buffer when LLM generation completes
  void finalizeStreaming() {
    final remaining = _tokenBuffer.toString().trim();
    if (remaining.isNotEmpty) {
      enqueueSpeech(remaining);
    }
    _tokenBuffer.clear();
    _isStreamingActive = false;
    
    // Check if sentence queue is empty and process finished
    if (_speechQueue.isEmpty && _activeProcess == null && !_isProcessingQueue) {
      _onSegmentComplete();
    }
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
    _isStreamingActive = false;
    enqueueSpeech(text);
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _speechQueue.isEmpty) return;

    _isProcessingQueue = true;
    final nextText = _speechQueue.removeAt(0);

    debugPrint("ENTER: speak()");
    debugPrint("[TTS] Speaking response: $nextText");

    // Escape single quotes for PowerShell string literal
    final escapedText = nextText.replaceAll("'", "''");

    final psCommand =
        "Add-Type -AssemblyName System.Speech; \$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; \$s.Rate = 1; \$s.Speak('$escapedText')";

    final stage9Start = DateTime.now();
    debugPrint('[Voice] ENTER 9. TTS started: "$nextText"');

    try {
      _state = SpeechState.playing;
      onSpeechStart?.call();

      _activeProcess = await Process.start(
        'powershell',
        ['-NoProfile', '-Command', psCommand],
      );

      final exitCode = await _activeProcess!.exitCode;
      _activeProcess = null;

      final dt9 = DateTime.now().difference(stage9Start).inMilliseconds;
      debugPrint('[Voice] EXIT 9. TTS started (Duration: ${dt9}ms)');
      debugPrint("[Native TTS] Segment finished with exit code $exitCode");
      debugPrint("EXIT: speak()");
      _onSegmentComplete();
    } catch (e) {
      debugPrint("[Native TTS] Execution error: $e");
      _activeProcess = null;
      debugPrint("EXIT: speak()");
      _onSegmentComplete();
    }
  }

  DateTime? _ttsStartTime;

  void _onSegmentComplete() {
    _isProcessingQueue = false;
    if (_speechQueue.isNotEmpty) {
      _processQueue();
    } else if (!_isStreamingActive && _activeProcess == null) {
      _state = SpeechState.idle;
      final stage10Start = DateTime.now();
      debugPrint('[Voice] ENTER 10. TTS finished');
      debugPrint('[Voice] EXIT 10. TTS finished (Duration: 0 ms)');
      // 150ms acoustic decay tail buffer to absorb room echo reflections before unmuting mic
      Future.delayed(const Duration(milliseconds: 150), () {
        if (_state == SpeechState.idle && !_isStreamingActive && _speechQueue.isEmpty && _activeProcess == null) {
          onSpeechComplete?.call();
        }
      });
    }
  }
}

