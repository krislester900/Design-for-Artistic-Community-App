import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Custom Exception Classes
class CacheException implements Exception {
  final String message;
  final dynamic originalError;
  
  CacheException(this.message, [this.originalError]);
  
  @override
  String toString() => 'CacheException: $message${originalError != null ? ' | $originalError' : ''}';
}

class CacheInitializationException extends CacheException {
  CacheInitializationException(String message, [dynamic error]) : super(message, error);
}

class CacheCorruptedException extends CacheException {
  CacheCorruptedException(String message, [dynamic error]) : super(message, error);
}

/// Improved Cache Service with Type Safety & Error Handling
class CacheService {
  static const String _boxName = 'arteia_cache';
  static const String _postsKey = 'cached_posts';
  static const String _categoriesKey = 'cached_categories';
  static const String _profilesKey = 'cached_profiles';
  static const String _lastSyncKey = 'last_sync';
  static const Duration _cacheDuration = Duration(hours: 1);

  static CacheService? _instance;
  Box<dynamic>? _box;
  bool _isInitialized = false;

  // Logging callback
  final Function(String message, [dynamic error])? onLog;

  CacheService._({this.onLog});

  static Future<CacheService> getInstance({
    Function(String message, [dynamic error])? onLog,
  }) async {
    if (_instance == null) {
      _instance = CacheService._(onLog: onLog);
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    try {
      if (_isInitialized) return;

      if (!kIsWeb) {
        try {
          await Hive.initFlutter();
        } catch (e) {
          _log('Hive already initialized', e);
        }
      }

      _box = await Hive.openBox<dynamic>(_boxName);
      _isInitialized = true;
      _log('✅ CacheService initialized successfully');
    } catch (e) {
      _log('❌ CacheService initialization failed', e);
      throw CacheInitializationException(
        'Failed to initialize cache service',
        e,
      );
    }
  }

  void _log(String message, [dynamic error]) {
    if (kDebugMode) {
      print('[CacheService] $message${error != null ? ' | $error' : ''}');
    }
    onLog?.call(message, error);
  }

  /// Verify box is initialized
  bool get _isReady {
    if (!_isInitialized || _box == null) {
      _log('⚠️ Cache not ready');
      return false;
    }
    return true;
  }

  // ==================== POSTS CACHE ====================

  Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    if (!_isReady) return;

    try {
      final jsonString = jsonEncode(posts);
      await _box!.put(_postsKey, jsonString);
      await _box!.put('${_postsKey}_time', DateTime.now().toIso8601String());
      _log('✅ Posts cached (${posts.length} items)');
    } catch (e) {
      _log('❌ Failed to cache posts', e);
      throw CacheException('Failed to cache posts', e);
    }
  }

  List<Map<String, dynamic>>? getCachedPosts() {
    if (!_isReady) return null;

    try {
      final data = _box!.get(_postsKey);
      if (data == null) return null;

      // Check expiration
      final timeStr = _box!.get('${_postsKey}_time') as String?;
      if (timeStr != null) {
        try {
          final cacheTime = DateTime.parse(timeStr);
          if (DateTime.now().difference(cacheTime) > _cacheDuration) {
            _log('⚠️ Posts cache expired');
            return null;
          }
        } catch (e) {
          _log('⚠️ Invalid cache timestamp', e);
          return null;
        }
      }

      // Safe JSON decoding
      try {
        final List<dynamic> decoded = jsonDecode(data as String);
        return List<Map<String, dynamic>>.from(
          decoded.map((item) {
            if (item is! Map) {
              throw CacheCorruptedException('Expected Map, got ${item.runtimeType}');
            }
            return Map<String, dynamic>.from(item as Map);
          }),
        );
      } catch (e) {
        _log('❌ Cache corrupted', e);
        throw CacheCorruptedException('Posts cache corrupted', e);
      }
    } catch (e) {
      _log('❌ Failed to retrieve cached posts', e);
      return null;
    }
  }

  // ==================== CATEGORIES CACHE ====================

  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    if (!_isReady) return;

    try {
      final jsonString = jsonEncode(categories);
      await _box!.put(_categoriesKey, jsonString);
      await _box!.put('${_categoriesKey}_time', DateTime.now().toIso8601String());
      _log('✅ Categories cached (${categories.length} items)');
    } catch (e) {
      _log('❌ Failed to cache categories', e);
      throw CacheException('Failed to cache categories', e);
    }
  }

  List<Map<String, dynamic>>? getCachedCategories() {
    if (!_isReady) return null;

    try {
      final data = _box!.get(_categoriesKey);
      if (data == null) return null;

      final timeStr = _box!.get('${_categoriesKey}_time') as String?;
      if (timeStr != null) {
        try {
          final cacheTime = DateTime.parse(timeStr);
          if (DateTime.now().difference(cacheTime) > _cacheDuration) {
            _log('⚠️ Categories cache expired');
            return null;
          }
        } catch (e) {
          _log('⚠️ Invalid cache timestamp', e);
          return null;
        }
      }

      try {
        final List<dynamic> decoded = jsonDecode(data as String);
        return List<Map<String, dynamic>>.from(
          decoded.map((item) {
            if (item is! Map) {
              throw CacheCorruptedException('Expected Map, got ${item.runtimeType}');
            }
            return Map<String, dynamic>.from(item as Map);
          }),
        );
      } catch (e) {
        _log('❌ Cache corrupted', e);
        throw CacheCorruptedException('Categories cache corrupted', e);
      }
    } catch (e) {
      _log('❌ Failed to retrieve cached categories', e);
      return null;
    }
  }

  // ==================== PROFILES CACHE ====================

  Future<void> cacheProfile(String userId, Map<String, dynamic> profile) async {
    if (!_isReady) return;
    if (userId.isEmpty) {
      _log('⚠️ Empty userId provided');
      return;
    }

    try {
      final profiles = Map<String, dynamic>.from(
        _box!.get(_profilesKey) as Map? ?? {},
      );
      profiles[userId] = profile;
      await _box!.put(_profilesKey, profiles);
      _log('✅ Profile cached for user: $userId');
    } catch (e) {
      _log('❌ Failed to cache profile', e);
      throw CacheException('Failed to cache profile', e);
    }
  }

  Map<String, dynamic>? getCachedProfile(String userId) {
    if (!_isReady) return null;
    if (userId.isEmpty) {
      _log('⚠️ Empty userId provided');
      return null;
    }

    try {
      final profiles = _box!.get(_profilesKey) as Map?;
      if (profiles == null) return null;

      final profile = profiles[userId];
      if (profile is! Map) {
        _log('⚠️ Invalid profile format for user: $userId');
        return null;
      }

      return Map<String, dynamic>.from(profile as Map);
    } catch (e) {
      _log('❌ Failed to retrieve cached profile', e);
      return null;
    }
  }

  // ==================== GENERIC CACHE ====================

  Future<void> put(String key, dynamic value) async {
    if (!_isReady) return;
    if (key.isEmpty) {
      _log('⚠️ Empty key provided');
      return;
    }

    try {
      await _box!.put(key, value);
      _log('✅ Value cached for key: $key');
    } catch (e) {
      _log('❌ Failed to cache value', e);
      throw CacheException('Failed to cache value for key: $key', e);
    }
  }

  T? get<T>(String key) {
    if (!_isReady) return null;
    if (key.isEmpty) {
      _log('⚠️ Empty key provided');
      return null;
    }

    try {
      final value = _box!.get(key);
      if (value is T) {
        return value;
      } else if (value != null) {
        _log('⚠️ Type mismatch for key: $key. Expected ${T.runtimeType}, got ${value.runtimeType}');
        return null;
      }
      return null;
    } catch (e) {
      _log('❌ Failed to retrieve value', e);
      return null;
    }
  }

  // ==================== SYNC MANAGEMENT ====================

  Future<void> setLastSync() async {
    if (!_isReady) return;

    try {
      await _box!.put(_lastSyncKey, DateTime.now().toIso8601String());
      _log('✅ Last sync time updated');
    } catch (e) {
      _log('❌ Failed to set last sync', e);
      throw CacheException('Failed to set last sync', e);
    }
  }

  DateTime? getLastSync() {
    if (!_isReady) return null;

    try {
      final timeStr = _box!.get(_lastSyncKey) as String?;
      if (timeStr == null) return null;

      return DateTime.parse(timeStr);
    } catch (e) {
      _log('❌ Failed to parse last sync time', e);
      return null;
    }
  }

  bool get needsSync {
    final lastSync = getLastSync();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > _cacheDuration;
  }

  // ==================== CLEAR CACHE ====================

  Future<void> clearAll() async {
    if (!_isReady) return;

    try {
      await _box!.clear();
      _log('✅ All cache cleared');
    } catch (e) {
      _log('❌ Failed to clear all cache', e);
      throw CacheException('Failed to clear all cache', e);
    }
  }

  Future<void> clearExpired() async {
    if (!_isReady) return;

    try {
      int clearedCount = 0;

      // Clear posts cache if expired
      final postsTime = _box!.get('${_postsKey}_time') as String?;
      if (postsTime != null) {
        try {
          final cacheTime = DateTime.parse(postsTime);
          if (DateTime.now().difference(cacheTime) > _cacheDuration) {
            await _box!.delete(_postsKey);
            await _box!.delete('${_postsKey}_time');
            clearedCount++;
          }
        } catch (e) {
          _log('⚠️ Error checking posts cache expiration', e);
        }
      }

      // Clear categories cache if expired
      final catsTime = _box!.get('${_categoriesKey}_time') as String?;
      if (catsTime != null) {
        try {
          final cacheTime = DateTime.parse(catsTime);
          if (DateTime.now().difference(cacheTime) > _cacheDuration) {
            await _box!.delete(_categoriesKey);
            await _box!.delete('${_categoriesKey}_time');
            clearedCount++;
          }
        } catch (e) {
          _log('⚠️ Error checking categories cache expiration', e);
        }
      }

      _log('✅ Cleared $clearedCount expired cache entries');
    } catch (e) {
      _log('❌ Failed to clear expired cache', e);
      throw CacheException('Failed to clear expired cache', e);
    }
  }

  /// Check if device is online (requires connectivity_plus package in production)
  Future<bool> isOnline() async {
    // This is a placeholder. In production, use:
    // import 'package:connectivity_plus/connectivity_plus.dart';
    // final connectivity = Connectivity();
    // final result = await connectivity.checkConnectivity();
    // return result != ConnectivityResult.none;
    
    try {
      // For now, assume online if cache is accessible
      return _isReady;
    } catch (e) {
      _log('⚠️ Failed to check connectivity', e);
      return false;
    }
  }

  /// Close the box
  Future<void> close() async {
    try {
      if (_box != null && _isInitialized) {
        await _box!.close();
        _isInitialized = false;
        _log('✅ Cache service closed');
      }
    } catch (e) {
      _log('❌ Failed to close cache service', e);
      throw CacheException('Failed to close cache service', e);
    }
  }

  /// Dispose (cleanup)
  void dispose() {
    _instance = null;
  }
}
