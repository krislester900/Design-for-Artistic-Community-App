import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class LocalImageCacheService extends ChangeNotifier {
  static const String _cacheKeyPrefix = 'cached_image_';
  static const int _maxCacheSize = 100; // Max 100 images
  static const int _maxCacheAgeDays = 7; // Cache expires after 7 days

  final Map<String, Uint8List> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  Directory? _cacheDir;

  static LocalImageCacheService? _instance;
  static Future<LocalImageCacheService> getInstance() async {
    _instance ??= LocalImageCacheService._();
    await _instance!._init();
    return _instance!;
  }

  LocalImageCacheService._();

  Future<void> _init() async {
    if (kIsWeb) return;
    _cacheDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(path.join(_cacheDir!.path, 'image_cache'));
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    _cacheDir = cacheDir;
    await _loadCacheIndex();
  }

  Future<void> _loadCacheIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix)).toList();
    
    for (final key in keys) {
      final timestamp = prefs.getInt(key);
      if (timestamp != null) {
        _cacheTimestamps[key.replaceFirst(_cacheKeyPrefix, '')] = 
            DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }
  }

  Future<void> _saveCacheIndex(String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getCacheKey(imageUrl);
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
    _cacheTimestamps[imageUrl] = DateTime.now();
  }

  String _getCacheKey(String imageUrl) {
    return _cacheKeyPrefix + imageUrl.hashCode.toString();
  }

  String _getFilePath(String imageUrl) {
    final fileName = '${imageUrl.hashCode}.jpg';
    return path.join(_cacheDir!.path, fileName);
  }

  Future<Uint8List?> getImage(String imageUrl) async {
    if (kIsWeb) return null;

    // Check memory cache first
    if (_memoryCache.containsKey(imageUrl)) {
      final timestamp = _cacheTimestamps[imageUrl];
      if (timestamp != null && DateTime.now().difference(timestamp).inDays < _maxCacheAgeDays) {
        return _memoryCache[imageUrl];
      } else {
        _memoryCache.remove(imageUrl);
        _cacheTimestamps.remove(imageUrl);
      }
    }

    // Check disk cache
    final file = File(_getFilePath(imageUrl));
    if (await file.exists()) {
      final timestamp = _cacheTimestamps[imageUrl];
      if (timestamp != null && DateTime.now().difference(timestamp).inDays < _maxCacheAgeDays) {
        final bytes = await file.readAsBytes();
        _memoryCache[imageUrl] = bytes;
        return bytes;
      } else {
        await file.delete();
        _cacheTimestamps.remove(imageUrl);
      }
    }

    return null;
  }

  Future<void> cacheImage(String imageUrl, Uint8List imageBytes) async {
    if (kIsWeb) return;
    if (_memoryCache.length >= _maxCacheSize) {
      _evictOldest();
    }

    _memoryCache[imageUrl] = imageBytes;
    await _saveCacheIndex(imageUrl);

    try {
      final file = File(_getFilePath(imageUrl));
      await file.writeAsBytes(imageBytes);
    } catch (e) {
      // Ignore write errors
    }

    notifyListeners();
  }

  void _evictOldest() {
    if (_cacheTimestamps.isEmpty) return;
    
    final sorted = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final oldest = sorted.first.key;
    _memoryCache.remove(oldest);
    _cacheTimestamps.remove(oldest);
    
    final file = File(_getFilePath(oldest));
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  Future<void> clearCache() async {
    if (kIsWeb) return;
    
    _memoryCache.clear();
    _cacheTimestamps.clear();

    if (_cacheDir != null) {
      final dir = Directory(_cacheDir!.path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await dir.create(recursive: true);
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith(_cacheKeyPrefix)).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }

    notifyListeners();
  }

  Future<void> clearOldCache() async {
    if (kIsWeb) return;

    final cutoff = DateTime.now().subtract(const Duration(days: _maxCacheAgeDays));
    final toRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (entry.value.isBefore(cutoff)) {
        toRemove.add(entry.key);
      }
    }

    for (final url in toRemove) {
      _memoryCache.remove(url);
      _cacheTimestamps.remove(url);
      final file = File(_getFilePath(url));
      if (await file.exists()) {
        await file.delete();
      }
    }

    if (toRemove.isNotEmpty) {
      notifyListeners();
    }
  }

  int get cachedImagesCount => _memoryCache.length;
  int get diskCacheSize => _cacheTimestamps.length;
}