import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

/// Real voice recording service using the `record` package
class VoiceRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _currentFilePath;
  DateTime? _startTime;
  final Uuid _uuid = const Uuid();

  bool get isRecording => _isRecording;
  String? get currentFilePath => _currentFilePath;

  /// Request microphone permission
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    if (kIsWeb) return false;
    return await Permission.microphone.isGranted;
  }

  /// Start recording audio
  Future<String?> startRecording() async {
    if (kIsWeb) {
      throw UnsupportedError('Recording not supported on web');
    }

    // Request permission first
    final hasMic = await requestPermission();
    if (!hasMic) {
      throw Exception('Permission microphone refusée');
    }

    try {
      final dir = await getTemporaryDirectory();
      final fileName = 'voice_${_uuid.v4()}.m4a';
      _currentFilePath = '${dir.path}/$fileName';
      _startTime = DateTime.now();

      // Start actual recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
          numChannels: 1,
        ),
        path: _currentFilePath!,
      );

      _isRecording = true;
      debugPrint('Recording started: $_currentFilePath');
      return _currentFilePath;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      _isRecording = false;
      _currentFilePath = null;
      rethrow;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;
      
      if (path != null) {
        _currentFilePath = path;
        final duration = getDuration();
        debugPrint('Recording stopped: $path (${duration.inSeconds}s)');
      }
      
      return _currentFilePath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      _isRecording = false;
      return _currentFilePath;
    }
  }

  /// Get recording duration
  Duration getDuration() {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }

  /// Delete the recorded file
  Future<void> deleteRecording() async {
    await _recorder.cancel(); // Cancel if recording
    _isRecording = false;
    
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
    _startTime = null;
  }

  /// Check if currently has a valid recording file
  Future<bool> hasRecordingFile() async {
    if (_currentFilePath == null) return false;
    try {
      return await File(_currentFilePath!).exists();
    } catch (e) {
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _recorder.dispose();
  }
}