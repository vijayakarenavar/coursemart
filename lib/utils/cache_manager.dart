/// Cache manager utility
///
/// Provides local caching support using Hive for offline data access
/// and improved performance.
library;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Cache Manager
///
/// Provides caching for:
/// - Student profile data
/// - Course list
/// - Lecture lists
///
/// Uses Hive for fast, lightweight local storage
class CacheManager {
  /// Singleton instance
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  /// Hive box names
  static const String _profileBoxName = 'profile';
  static const String _coursesBoxName = 'courses';
  static const String _lecturesBoxName = 'lectures';
  static const String _settingsBoxName = 'settings';

  /// Hive boxes
  late Box _profileBox;
  late Box _coursesBox;
  late Box _lecturesBox;
  late Box _settingsBox;

  /// Cache expiry durations
  static const Duration profileCacheDuration = Duration(minutes: 30);
  static const Duration coursesCacheDuration = Duration(minutes: 15);
  static const Duration lecturesCacheDuration = Duration(minutes: 10);

  /// Initialize Hive and open boxes
  ///
  /// Call this once during app initialization
  Future<void> init() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Open boxes
      _profileBox = await Hive.openBox(_profileBoxName);
      _coursesBox = await Hive.openBox(_coursesBoxName);
      _lecturesBox = await Hive.openBox(_lecturesBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);

      if (kDebugMode) debugPrint('✅ Cache manager initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Cache manager initialization error: $e');
    }
  }

  // ==================== PROFILE CACHE ====================

  /// Cache student profile data
  ///
  /// [data] - Profile data map to cache
  Future<void> cacheProfile(Map<String, dynamic> data) async {
    try {
      await _profileBox.put('data', data);
      await _profileBox.put('timestamp', DateTime.now().millisecondsSinceEpoch);
      if (kDebugMode) debugPrint('💾 Profile cached');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error caching profile: $e');
    }
  }

  /// Get cached profile data
  ///
  /// Returns profile data if cache is valid, null otherwise
  Map<String, dynamic>? getCachedProfile() {
    try {
      final timestamp = _profileBox.get('timestamp') as int?;
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > profileCacheDuration) {
        if (kDebugMode) debugPrint('⏰ Profile cache expired');
        return null;
      }

      final data = _profileBox.get('data') as Map<String, dynamic>?;
      if (kDebugMode) debugPrint('💾 Using cached profile');
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting cached profile: $e');
      return null;
    }
  }

  /// Clear cached profile
  Future<void> clearCachedProfile() async {
    await _profileBox.clear();
    if (kDebugMode) debugPrint('🗑️ Profile cache cleared');
  }

  // ==================== COURSES CACHE ====================

  /// Cache courses data
  ///
  /// [data] - Courses data list to cache
  Future<void> cacheCourses(List<dynamic> data) async {
    try {
      await _coursesBox.put('data', data);
      await _coursesBox.put('timestamp', DateTime.now().millisecondsSinceEpoch);
      if (kDebugMode) debugPrint('💾 Courses cached');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error caching courses: $e');
    }
  }

  /// Get cached courses data
  ///
  /// Returns courses data if cache is valid, null otherwise
  List<dynamic>? getCachedCourses() {
    try {
      final timestamp = _coursesBox.get('timestamp') as int?;
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > coursesCacheDuration) {
        if (kDebugMode) debugPrint('⏰ Courses cache expired');
        return null;
      }

      final data = _coursesBox.get('data') as List<dynamic>?;
      if (kDebugMode) debugPrint('💾 Using cached courses (${data?.length ?? 0} courses)');
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting cached courses: $e');
      return null;
    }
  }

  /// Clear cached courses
  Future<void> clearCachedCourses() async {
    await _coursesBox.clear();
    if (kDebugMode) debugPrint('🗑️ Courses cache cleared');
  }

  // ==================== LECTURES CACHE ====================

  /// Cache lectures data for a course
  ///
  /// [courseId] - Course ID
  /// [data] - Lectures data list to cache
  Future<void> cacheLectures(String courseId, List<dynamic> data) async {
    try {
      await _lecturesBox.put('course_$courseId', data);
      await _lecturesBox.put(
        'course_${courseId}_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
      if (kDebugMode) debugPrint('💾 Lectures cached for course $courseId');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error caching lectures: $e');
    }
  }

  /// Get cached lectures data for a course
  ///
  /// [courseId] - Course ID
  /// Returns lectures data if cache is valid, null otherwise
  List<dynamic>? getCachedLectures(String courseId) {
    try {
      final timestamp =
          _lecturesBox.get('course_${courseId}_timestamp') as int?;
      if (timestamp == null) return null;

      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();

      // Check if cache is expired
      if (now.difference(cacheTime) > lecturesCacheDuration) {
        if (kDebugMode) debugPrint('⏰ Lectures cache expired for course $courseId');
        return null;
      }

      final data = _lecturesBox.get('course_$courseId') as List<dynamic>?;
      if (kDebugMode) debugPrint('💾 Using cached lectures for course $courseId');
      return data;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting cached lectures: $e');
      return null;
    }
  }

  /// Clear cached lectures for a course
  Future<void> clearCachedLectures(String courseId) async {
    await _lecturesBox.delete('course_$courseId');
    await _lecturesBox.delete('course_${courseId}_timestamp');
    if (kDebugMode) debugPrint('🗑️ Lectures cache cleared for course $courseId');
  }

  // ==================== SETTINGS CACHE ====================

  /// Save a setting value
  ///
  /// [key] - Setting key
  /// [value] - Setting value
  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  /// Get a setting value
  ///
  /// [key] - Setting key
  /// [defaultValue] - Default value if not found
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  /// Delete a setting
  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  // ==================== GENERAL CACHE ====================

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _profileBox.clear();
    await _coursesBox.clear();
    await _lecturesBox.clear();
    if (kDebugMode) debugPrint('🗑️ All cache cleared');
  }

  /// Get cache size (approximate)
  Future<int> getCacheSize() async {
    int size = 0;
    size += _profileBox.length;
    size += _coursesBox.length;
    size += _lecturesBox.length;
    size += _settingsBox.length;
    return size;
  }

  /// Close all Hive boxes
  Future<void> dispose() async {
    await _profileBox.close();
    await _coursesBox.close();
    await _lecturesBox.close();
    await _settingsBox.close();
    if (kDebugMode) debugPrint('🔒 Cache manager disposed');
  }
}
