import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8000/api/v1',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 25),
    sendTimeout: const Duration(seconds: 10),
  ));
  String? _sessionId;

  Future<void> initSession() async {
    try {
      final response = await _dio.post('/session');
      if (response.data['success'] == true) {
        _sessionId = response.data['data']['session_id'];
        debugPrint("Session initialized: $_sessionId");
      }
    } catch (e) {
      debugPrint("Failed to init session: $e");
    }
  }

  Stream<String> sendChatMessage(String message) async* {
    if (_sessionId == null) await initSession();
    if (_sessionId == null) {
      yield "Error: Could not connect to backend.";
      return;
    }

    try {
      final response = await _dio.post(
        '/chat/stream',
        data: {'session_id': _sessionId, 'message': message},
        options: Options(responseType: ResponseType.stream),
      );

      final stream = response.data.stream as Stream<Uint8List>;
      
      await for (final chunk in stream.timeout(
        const Duration(seconds: 20),
        onTimeout: (sink) {
          debugPrint("[ApiService] TIMEOUT: Stream response timed out after 20s at api_service.dart:sendChatMessage");
          sink.add(utf8.encode('data: {"token": " [Response timed out. Re-arming assistant...] "}\n\n'));
          sink.add(utf8.encode('data: {"done": true}\n\n'));
          sink.close();
        },
      )) {
        final text = utf8.decode(chunk);
        final lines = text.split('\n');
        
        for (var line in lines) {
          if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();
            if (dataStr.isEmpty) continue;
            
            try {
              final data = jsonDecode(dataStr);
              if (data.containsKey('token')) {
                yield data['token'];
              } else if (data['done'] == true) {
                return;
              }
            } catch (e) {
              // Ignore malformed JSON in partial chunks if any
            }
          }
        }
      }
    } catch (e, st) {
      debugPrint("[ApiService Error] Exception in sendChatMessage: $e\n$st");
      yield "\n[Notice: Backend stream connection interrupted]";
    }
  }

  Future<Map<String, dynamic>?> getMode() async {
    try {
      final response = await _dio.get('/mode');
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint("Failed to get operating mode: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> setMode(String targetMode) async {
    try {
      final response = await _dio.post('/mode', data: {'mode': targetMode});
      if (response.data['success'] == true) {
        return Map<String, dynamic>.from(response.data['data']);
      }
    } catch (e) {
      debugPrint("Failed to set operating mode ($targetMode): $e");
    }
    return null;
  }
}
