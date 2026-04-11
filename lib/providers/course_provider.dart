/// Course Provider
///
/// Manages course list state, loading, filtering, and caching
/// using Provider state management pattern.
library;

import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../services/api_service.dart';

/// Course Provider
///
/// Manages course data and provides methods for:
/// - Fetching enrolled courses
/// - Filtering by status
/// - Pull-to-refresh
/// - Loading states
class CourseProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// List of all courses
  List<Course> _courses = [];

  /// Loading state flag
  bool _isLoading = false;

  /// Error message (if any)
  String? _errorMessage;

  /// Current filter
  String _filter = 'all'; // all, not_started, in_progress, completed

  /// Last fetch timestamp (for cache)
  DateTime? _lastFetchedAt;

  // ==================== GETTERS ====================

  /// Get all courses
  List<Course> get courses => _courses;

  /// Get loading state
  bool get isLoading => _isLoading;

  /// Get error message
  String? get errorMessage => _errorMessage;

  /// Get current filter
  String get filter => _filter;

  /// Get last fetched timestamp
  DateTime? get lastFetchedAt => _lastFetchedAt;

  /// Get filtered courses
  ///
  /// Returns courses filtered by current filter
  List<Course> get filteredCourses {
    if (_filter == 'all') {
      return _courses;
    }

    return _courses.where((course) {
      return course.scheduleStatus == _filter;
    }).toList();
  }

  /// Check if there's an error
  bool get hasError => _errorMessage != null;

  /// Check if courses are loaded
  bool get isLoaded => _courses.isNotEmpty && !_isLoading;

  /// Get course count
  int get courseCount => _courses.length;

  /// Get in-progress course count
  int get inProgressCount =>
      _courses.where((c) => c.scheduleStatus == CourseStatus.inProgress).length;

  /// Get completed course count
  int get completedCount =>
      _courses.where((c) => c.scheduleStatus == CourseStatus.completed).length;

  /// Get not started course count
  int get notStartedCount =>
      _courses.where((c) => c.scheduleStatus == CourseStatus.notStarted).length;

  // ==================== METHODS ====================

  /// Fetch all enrolled courses
  ///
  /// [forceRefresh] - If true, ignores cache and fetches fresh data
  /// Returns true on success, false on failure
  Future<bool> fetchCourses({bool forceRefresh = false}) async {
    // Check cache (don't fetch if data is less than 5 minutes old)
    if (!forceRefresh &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) <
            const Duration(minutes: 5)) {
      debugPrint('💾 Using cached course data');
      return true;
    }

    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final courses = await _apiService.getCourses();
      _courses = courses;
      _lastFetchedAt = DateTime.now();
      _isLoading = false;

      debugPrint('✅ Fetched ${courses.length} courses');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Fetch courses error: $e');
      _setError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set filter for courses
  ///
  /// [filter] - Filter value: 'all', 'not_started', 'in_progress', 'completed'
  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  /// Get course by ID
  ///
  /// [courseId] - The course ID to find
  /// Returns Course or null if not found
  Course? getCourseById(String courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  /// Refresh courses (pull-to-refresh)
  ///
  /// Forces fresh data from server
  Future<void> refresh() async {
    await fetchCourses(forceRefresh: true);
  }

  /// Clear courses data
  ///
  /// Called on logout
  void clear() {
    _courses = [];
    _isLoading = false;
    _errorMessage = null;
    _filter = 'all';
    _lastFetchedAt = null;
    notifyListeners();
  }

  // ==================== PRIVATE METHODS ====================

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
  }
// ==================== LECTURE STATS ====================

  /// Get total completed lectures count across all courses
  int get completedLecturesCount =>
      _courses.fold(0, (sum, course) => sum + course.completedLectures);

  /// Get total remaining lectures count across all courses
  int get remainingLecturesCount =>
      _courses.fold(0, (sum, course) => sum + course.remainingLectures);

  /// Get overall progress (0.0 to 1.0) across all courses
  double get overallProgress {
    if (_courses.isEmpty) return 0.0;
    final total = _courses.fold(0, (sum, course) => sum + course.totalLectures);
    if (total == 0) return 0.0;
    return completedLecturesCount / total;
  }

  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
  void clearData() {
    _courses = [];
    _errorMessage = null;
    _lastFetchedAt = null;
    notifyListeners();
  }
}
