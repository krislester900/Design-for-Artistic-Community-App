import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'supabase_service.dart';

/// Exceptions personnalisées pour le cache
class CacheException implements Exception {
  final String message;
  final dynamic originalError;
  CacheException(this.message, [this.originalError]);
  @override
  String toString() => 'CacheException: $message${originalError != null ? ' | $originalError' : ''}';
}

/// Cache Service amélioré avec type safety et gestion d'erreurs
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

  CacheService._();

  static Future<CacheService> getInstance() async {
    if (_instance == null) {
      _instance = CacheService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    if (_isInitialized) return;
    try {
      if (!kIsWeb) {
        try {
          await Hive.initFlutter();
        } catch (_) {
          // Hive déjà initialisé
        }
      }
      _box = await Hive.openBox<dynamic>(_boxName);
      _isInitialized = true;
      debugPrint('✅ CacheService initialized');
    } catch (e) {
      debugPrint('❌ CacheService init failed: $e');
    }
  }

  bool get _isReady => _isInitialized && _box != null;

  // ==================== POSTS CACHE ====================

  Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    if (!_isReady) return;
    try {
      await _box!.put(_postsKey, jsonEncode(posts));
      await _box!.put('${_postsKey}_time', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Failed to cache posts: $e');
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
          if (DateTime.now().difference(cacheTime) > _cacheDuration) return null;
        } catch (_) {
          return null;
        }
      }

      final List<dynamic> decoded = jsonDecode(data as String);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get cached posts: $e');
      return null;
    }
  }

  // ==================== CATEGORIES CACHE ====================

  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    if (!_isReady) return;
    try {
      await _box!.put(_categoriesKey, jsonEncode(categories));
      await _box!.put('${_categoriesKey}_time', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Failed to cache categories: $e');
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
          if (DateTime.now().difference(cacheTime) > _cacheDuration) return null;
        } catch (_) {
          return null;
        }
      }

      final List<dynamic> decoded = jsonDecode(data as String);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('❌ Failed to get cached categories: $e');
      return null;
    }
  }

  // ==================== PROFILES CACHE ====================

  Future<void> cacheProfile(String userId, Map<String, dynamic> profile) async {
    if (!_isReady || userId.isEmpty) return;
    try {
      final profiles = Map<String, dynamic>.from(
        (_box!.get(_profilesKey) as Map?) ?? {},
      );
      profiles[userId] = profile;
      await _box!.put(_profilesKey, profiles);
    } catch (e) {
      debugPrint('❌ Failed to cache profile: $e');
    }
  }

  Map<String, dynamic>? getCachedProfile(String userId) {
    if (!_isReady || userId.isEmpty) return null;
    try {
      final profiles = _box!.get(_profilesKey) as Map?;
      if (profiles == null) return null;
      final profile = profiles[userId];
      return profile is Map ? Map<String, dynamic>.from(profile as Map) : null;
    } catch (e) {
      debugPrint('❌ Failed to get cached profile: $e');
      return null;
    }
  }

  // ==================== GENERIC CACHE ====================

  Future<void> put(String key, dynamic value) async {
    if (!_isReady || key.isEmpty) return;
    try {
      await _box!.put(key, value);
    } catch (e) {
      debugPrint('❌ Failed to cache value: $e');
    }
  }

  T? get<T>(String key) {
    if (!_isReady || key.isEmpty) return null;
    try {
      final value = _box!.get(key);
      return value is T ? value : null;
    } catch (e) {
      debugPrint('❌ Failed to get value: $e');
      return null;
    }
  }

  // ==================== SYNC MANAGEMENT ====================

  Future<void> setLastSync() async {
    if (!_isReady) return;
    try {
      await _box!.put(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('❌ Failed to set last sync: $e');
    }
  }

  DateTime? getLastSync() {
    if (!_isReady) return null;
    try {
      final timeStr = _box!.get(_lastSyncKey) as String?;
      return timeStr != null ? DateTime.parse(timeStr) : null;
    } catch (e) {
      debugPrint('❌ Failed to parse last sync: $e');
      return null;
    }
  }

  bool get needsSync {
    final lastSync = getLastSync();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > _cacheDuration;
  }

  // ==================== CLEAR CACHE ====================

  Future<bool> isOnline() async {
    try {
      final result = await http.get(Uri.parse(SupabaseConfig.supabaseUrl)).timeout(const Duration(seconds: 3));
      return result.statusCode >= 200 && result.statusCode < 400;
    } on Exception catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAll() async {
    if (!_isReady) return;
    try {
      await _box!.clear();
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
    }
  }

  Future<void> close() async {
    try {
      if (_box != null && _isInitialized) {
        await _box!.close();
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('❌ Failed to close cache: $e');
    }
  }
}