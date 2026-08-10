import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';

class WakeListenerClient {
  static final WakeListenerClient _instance = WakeListenerClient._internal();
  factory WakeListenerClient() => _instance;
  WakeListenerClient._internal();

  Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  Timer? _reconnectTimer;
  VoidCallback? onWakeWordDetected;

  void start() {
    _connect();
  }

  void _connect() {
    _reconnectTimer?.cancel();
    if (_isConnected) return;

    try {
      Socket.connect('127.0.0.1', 8009, timeout: const Duration(seconds: 2)).then((socket) {
        _socket = socket;
        _isConnected = true;
        debugPrint("[WakeListenerClient] Connected to background wake listener service on port 8009.");

        _socket!.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
          _handleLine(line.trim());
        }, onError: (err) {
          debugPrint("[WakeListenerClient] Socket error: $err");
          _handleDisconnect();
        }, onDone: () {
          debugPrint("[WakeListenerClient] Socket closed by server.");
          _handleDisconnect();
        });
      }).catchError((err) {
        debugPrint("[WakeListenerClient] Connection failed: $err. Retrying in 3s...");
        _handleDisconnect();
      });
    } catch (e) {
      debugPrint("[WakeListenerClient] Connect exception: $e");
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _socket?.destroy();
    _socket = null;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _connect();
    });
  }

  void _handleLine(String line) {
    if (line.isEmpty) return;
    debugPrint("[COLD TRACE] 7 RAW IPC MESSAGE RECEIVED: $line");
    try {
      final jsonMap = json.decode(line);
      final event = jsonMap['event'];
      if (event == 'WAKE_WORD_DETECTED') {
        debugPrint("[COLD TRACE] 8 WAKE_WORD_DETECTED PARSED");
        final phrase = jsonMap['phrase'] ?? 'falcon wake up';
        debugPrint("[WAKE TRACE] Flutter received WAKE_WORD_DETECTED");
        debugPrint("[COLD WAKE 001] Flutter received WAKE_WORD_DETECTED: '$phrase'");

        // Bring Falcon UI to foreground
        doWhenWindowReady(() {
          appWindow.restore();
          appWindow.show();
        });

        debugPrint("[COLD TRACE] 9 Calling onWakeWordDetected");
        debugPrint("[WAKE TRACE] Calling onWakeWordDetected()");
        debugPrint("[COLD WAKE 001] Calling onWakeWordDetected()");
        onWakeWordDetected?.call();
      }
    } catch (e) {
      debugPrint("[WakeListenerClient] JSON parse error: $e for line: $line");
    }
  }

  void sendCommand(String command) {
    if (_socket != null && _isConnected) {
      try {
        _socket!.writeln(json.encode({'command': command}));
      } catch (e) {
        debugPrint("[WakeListenerClient] Send command failed: $e");
      }
    }
  }

  void pauseWakeListenerMic() {
    sendCommand("MIC_PAUSE");
  }

  void resumeWakeListenerMic() {
    sendCommand("MIC_RESUME");
  }
}
