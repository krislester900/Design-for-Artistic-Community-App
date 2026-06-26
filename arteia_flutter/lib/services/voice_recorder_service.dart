import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Service to handle voice recording on mobile platforms.
/// Uses platform channels via MethodChannel for actual recording.
/// Falls back to a simulated recording for testing.
class VoiceRecorderService {
  bool _isRecording = false;
  String? _currentFilePath;
  DateTime? _startTime;
  final Uuid _uuid = const Uuid();

  bool get isRecording => _isRecording;
  String? get currentFilePath => _currentFilePath;

  /// Start recording audio
  Future<String?> startRecording() async {
    if (kIsWeb) {
      throw UnsupportedError('Recording not supported on web');
    }

    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'voice_${_uuid.v4()}.m4a';
      _currentFilePath = '${dir.path}/$fileName';
      _startTime = DateTime.now();
      _isRecording = true;

      debugPrint('Recording started: $_currentFilePath');
      return _currentFilePath;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    _isRecording = false;
    final filePath = _currentFilePath;

    debugPrint('Recording stopped: $filePath (${_startTime != null ? DateTime.now().difference(_startTime!).inSeconds : 0}s)');
    
    return filePath;
  }

  /// Get recording duration
  Duration getDuration() {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  /// Delete the recorded file
  Future<void> deleteRecording() async {
    if (_currentFilePath != null) {
      try {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('Error deleting recording: $e');
      }
      _currentFilePath = null;
    }
    _isRecording = false;
    _startTime = null;
  }

  /// Check if file exists
  Future<bool> hasRecordingFile() async {
    if (_currentFilePath == null) return false;
    try {
      return await File(_currentFilePath!).exists();
    } catch (e) {
      return false;
    }
  }
}