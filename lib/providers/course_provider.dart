/// Course Provider
library;

import 'package:flutter/foundation.dart';

import '../models/course.dart';
import '../services/api_service.dart';

class CourseProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filter = 'all';
  DateTime? _lastFetchedAt;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filter => _filter;
  DateTime? get lastFetchedAt => _lastFetchedAt;

  List<Course> get filteredCourses {
    if (_filter == 'all') return _courses;
    return _courses.where((course) => course.scheduleStatus == _filter).toList();
  }

  bool get hasError => _errorMessage != null;
  bool get isLoaded => _courses.isNotEmpty && !_isLoading;
  int get courseCount => _courses.length;

  int get inProgressCount =>
      _courses.where((c) => c.scheduleStatus == CourseStatus.inProgress).length;
  int get completedCount =>
      _courses.where((c) => c.scheduleStatus == CourseStatus.completed).length;
  int get notStartedCount =>
      _courses.where((c) => c.scheduleStatus == CourseStatus.notStarted).length;

  Future<bool> fetchCourses({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < const Duration(minutes: 5)) {
      if (kDebugMode) debugPrint('💾 Using cached course data');
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
      if (kDebugMode) debugPrint('✅ Fetched ${courses.length} courses');
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Fetch courses error: $e');
      _setError(e); // ✅ Fixed: e instead of e.toString()
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void setFilter(String filter) {
    _filter = filter;
    notifyListeners();
  }

  Course? getCourseById(String courseId) {
    try {
      return _courses.firstWhere((course) => course.id == courseId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refresh() async {
    await fetchCourses(forceRefresh: true);
  }

  void clear() {
    _courses = [];
    _isLoading = false;
    _errorMessage = null;
    _filter = 'all';
    _lastFetchedAt = null;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  // ✅ Fixed: dynamic type, ApiException check
  void _setError(dynamic error) {
    if (error is ApiException) {
      _errorMessage = error.message;
    } else {
      _errorMessage = 'Something went wrong. Please try again.';
    }
  }

  int get completedLecturesCount =>
      _courses.fold(0, (sum, course) => sum + course.completedLectures);

  int get remainingLecturesCount =>
      _courses.fold(0, (sum, course) => sum + course.remainingLectures);

  double get overallProgress {
    if (_courses.isEmpty) return 0.0;
    final total = _courses.fold(0, (sum, course) => sum + course.totalLectures);
    if (total == 0) return 0.0;
    return completedLecturesCount / total;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void clearData() {
    _courses = [];
    _errorMessage = null;
    _lastFetchedAt = null;
    notifyListeners();
  }
}