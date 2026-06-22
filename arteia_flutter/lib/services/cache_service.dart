import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String _boxName = 'arteia_cache';
  static const String _postsKey = 'cached_posts';
  static const String _categoriesKey = 'cached_categories';
  static const String _profilesKey = 'cached_profiles';
  static const String _lastSyncKey = 'last_sync';
  static const Duration _cacheDuration = Duration(hours: 1);

  static CacheService? _instance;
  Box? _box;

  CacheService._();

  static Future<CacheService> getInstance() async {
    if (_instance == null) {
      _instance = CacheService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // ==================== POSTS CACHE ====================

  Future<void> cachePosts(List<Map<String, dynamic>> posts) async {
    await _box?.put(_postsKey, jsonEncode(posts));
    await _box?.put('${_postsKey}_time', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedPosts() {
    final data = _box?.get(_postsKey);
    if (data == null) return null;
    
    final timeStr = _box?.get('${_postsKey}_time');
    if (timeStr != null) {
      final cacheTime = DateTime.parse(timeStr as String);
      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        return null; // Cache expired
      }
    }

    final List<dynamic> decoded = jsonDecode(data as String);
    return decoded.cast<Map<String, dynamic>>();
  }

  // ==================== CATEGORIES CACHE ====================

  Future<void> cacheCategories(List<Map<String, dynamic>> categories) async {
    await _box?.put(_categoriesKey, jsonEncode(categories));
    await _box?.put('${_categoriesKey}_time', DateTime.now().toIso8601String());
  }

  List<Map<String, dynamic>>? getCachedCategories() {
    final data = _box?.get(_categoriesKey);
    if (data == null) return null;

    final timeStr = _box?.get('${_categoriesKey}_time');
    if (timeStr != null) {
      final cacheTime = DateTime.parse(timeStr as String);
      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        return null;
      }
    }

    final List<dynamic> decoded = jsonDecode(data as String);
    return decoded.cast<Map<String, dynamic>>();
  }

  // ==================== PROFILES CACHE ====================

  Future<void> cacheProfile(String userId, Map<String, dynamic> profile) async {
    final profiles = _box?.get(_profilesKey) as Map? ?? {};
    profiles[userId] = profile;
    await _box?.put(_profilesKey, profiles);
  }

  Map<String, dynamic>? getCachedProfile(String userId) {
    final profiles = _box?.get(_profilesKey) as Map?;
    if (profiles == null) return null;
    return profiles[userId] as Map<String, dynamic>?;
  }

  // ==================== GENERIC CACHE ====================

  Future<void> put(String key, dynamic value) async {
    await _box?.put(key, value);
  }

  T? get<T>(String key) {
    return _box?.get(key) as T?;
  }

  // ==================== SYNC MANAGEMENT ====================

  Future<void> setLastSync() async {
    await _box?.put(_lastSyncKey, DateTime.now().toIso8601String());
  }

  DateTime? getLastSync() {
    final timeStr = _box?.get(_lastSyncKey) as String?;
    if (timeStr == null) return null;
    return DateTime.parse(timeStr);
  }

  bool get needsSync {
    final lastSync = getLastSync();
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > _cacheDuration;
  }

  // ==================== CLEAR CACHE ====================

  Future<void> clearAll() async {
    await _box?.clear();
  }

  Future<void> clearExpired() async {
    // Clear posts cache if expired
    final postsTime = _box?.get('${_postsKey}_time') as String?;
    if (postsTime != null) {
      final cacheTime = DateTime.parse(postsTime);
      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        await _box?.delete(_postsKey);
        await _box?.delete('${_postsKey}_time');
      }
    }

    // Clear categories cache if expired
    final catsTime = _box?.get('${_categoriesKey}_time') as String?;
    if (catsTime != null) {
      final cacheTime = DateTime.parse(catsTime);
      if (DateTime.now().difference(cacheTime) > _cacheDuration) {
        await _box?.delete(_categoriesKey);
        await _box?.delete('${_categoriesKey}_time');
      }
    }
  }

  /// Check if device is online by trying to reach Supabase
  Future<bool> isOnline() async {
    try {
      final result = await _box?.get('is_online');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Close the box
  Future<void> close() async {
    await _box?.close();
  }
}