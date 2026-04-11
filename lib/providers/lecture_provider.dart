/// Lecture Provider
///
/// Manages lecture list state for a specific course
/// including loading, fetching, and caching.
library;

import 'package:flutter/foundation.dart';

import '../models/lecture.dart';
import '../services/api_service.dart';

/// Lecture Provider
///
/// Manages lecture data for a specific course and provides methods for:
/// - Fetching lectures for a course
/// - Getting lecture details
/// - Loading states
/// - Pull-to-refresh
class LectureProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  /// Current course ID
  String? _courseId;

  /// List of lectures
  List<Lecture> _lectures = [];

  /// Currently selected lecture details
  Lecture? _selectedLecture;

  /// Loading state flag
  bool _isLoading = false;

  /// Error message (if any)
  String? _errorMessage;

  /// Last fetch timestamp (for cache)
  DateTime? _lastFetchedAt;

  // ==================== GETTERS ====================

  /// Get course ID
  String? get courseId => _courseId;

  /// Get all lectures
  List<Lecture> get lectures => _lectures;

  /// Get selected lecture details
  Lecture? get selectedLecture => _selectedLecture;

  /// Get loading state
  bool get isLoading => _isLoading;

  /// Get error message
  String? get errorMessage => _errorMessage;

  /// Get last fetched timestamp
  DateTime? get lastFetchedAt => _lastFetchedAt;

  /// Check if there's an error
  bool get hasError => _errorMessage != null;

  /// Check if lectures are loaded
  bool get isLoaded => _lectures.isNotEmpty && !_isLoading;

  /// Get lecture count
  int get lectureCount => _lectures.length;

  /// Get ready lecture count
  int get readyLectureCount =>
      _lectures.where((l) => l.videoStatus == VideoStatus.ready).length;

  // ==================== METHODS ====================

  /// Fetch lectures for a course
  ///
  /// [courseId] - The course ID to fetch lectures for
  /// [forceRefresh] - If true, ignores cache
  /// Returns true on success, false on failure
  Future<bool> fetchLectures({
    required String courseId,
    bool forceRefresh = false,
  }) async {
    // Check cache
    if (!forceRefresh &&
        _courseId == courseId &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) <
            const Duration(minutes: 5)) {
      debugPrint('💾 Using cached lecture data');
      return true;
    }

    _courseId = courseId;
    _isLoading = true;
    _clearError();
    notifyListeners();

    try {
      final lectures = await _apiService.getCourseLectures(courseId);
      _lectures = lectures;
      _lastFetchedAt = DateTime.now();
      _isLoading = false;

      debugPrint('✅ Fetched ${lectures.length} lectures for course $courseId');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Fetch lectures error: $e');
      _setError(e.toString());
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get lecture details
  ///
  /// [lectureId] - The lecture ID to fetch
  /// Returns Lecture model with video and notes data
  Future<Lecture> getLectureDetails(String lectureId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final lecture = await _apiService.getLectureDetails(lectureId);
      _selectedLecture = lecture;
      _isLoading = false;
      notifyListeners();
      return lecture;
    } catch (e) {
      debugPrint('❌ Get lecture details error: $e');
      _setError(e.toString());
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get lecture by ID from cached list
  ///
  /// [lectureId] - The lecture ID to find
  /// Returns Lecture or null if not found
  Lecture? getLectureFromList(String lectureId) {
    try {
      return _lectures.firstWhere((lecture) => lecture.id == lectureId);
    } catch (e) {
      return null;
    }
  }

  /// Refresh lectures (pull-to-refresh)
  ///
  /// Forces fresh data from server
  Future<void> refresh() async {
    if (_courseId != null) {
      await fetchLectures(courseId: _courseId!, forceRefresh: true);
    }
  }

  /// Clear lectures data
  ///
  /// Called when switching courses or on logout
  void clear() {
    _courseId = null;
    _lectures = [];
    _selectedLecture = null;
    _isLoading = false;
    _errorMessage = null;
    _lastFetchedAt = null;
    notifyListeners();
  }

  /// Clear selected lecture
  void clearSelectedLecture() {
    _selectedLecture = null;
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

  @override
  void dispose() {
    // Cleanup if needed
    super.dispose();
  }
}
