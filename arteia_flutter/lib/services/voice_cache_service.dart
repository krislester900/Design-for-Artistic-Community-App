import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VoiceCacheService {
  static final VoiceCacheService _instance = VoiceCacheService._internal();
  factory VoiceCacheService() => _instance;
  VoiceCacheService._internal();

  late Box _box;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) return;
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox('voice_cache');
      _initialized = true;
    } catch (e) {
      debugPrint('VoiceCacheService init failed: $e');
    }
  }

  Future<String?> getCachedPath(String voiceUrl) async {
    if (kIsWeb || !_initialized) return null;
    if (!_box.containsKey(voiceUrl)) return null;
    final cachedPath = _box.get(voiceUrl) as String?;
    if (cachedPath == null) return null;
    final file = File(cachedPath);
    if (await file.exists()) return cachedPath;
    await _box.delete(voiceUrl);
    return null;
  }

  Future<String?> cacheVoice(String voiceUrl) async {
    if (kIsWeb || !_initialized) return null;
    try {
      final cachedPath = await getCachedPath(voiceUrl);
      if (cachedPath != null) return cachedPath;

      final response = await http.get(Uri.parse(voiceUrl));
      if (response.statusCode != 200) return null;

      final dir = await getTemporaryDirectory();
      final fileName = 'voice_cache_${Uri.parse(voiceUrl).pathSegments.last}';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(response.bodyBytes);

      await _box.put(voiceUrl, file.path);
      return file.path;
    } catch (e) {
      debugPrint('VoiceCacheService cache failed: $e');
      return null;
    }
  }

  Future<void> clearCache() async {
    if (kIsWeb || !_initialized) return;
    try {
      await _box.clear();
      final dir = await getTemporaryDirectory();
      final cacheDir = Directory('${dir.path}/voice_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('VoiceCacheService clear failed: $e');
    }
  }
}
