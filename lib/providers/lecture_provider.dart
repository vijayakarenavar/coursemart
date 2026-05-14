/// Lecture Provider
library;

import 'package:flutter/foundation.dart';

import '../models/lecture.dart';
import '../services/api_service.dart';

class LectureProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _courseId;
  List<Lecture> _lectures = [];
  Lecture? _selectedLecture;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetchedAt;

  String? get courseId => _courseId;
  List<Lecture> get lectures => _lectures;
  Lecture? get selectedLecture => _selectedLecture;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastFetchedAt => _lastFetchedAt;
  bool get hasError => _errorMessage != null;
  bool get isLoaded => _lectures.isNotEmpty && !_isLoading;
  int get lectureCount => _lectures.length;
  int get readyLectureCount =>
      _lectures.where((l) => l.videoStatus == VideoStatus.ready).length;

  Future<bool> fetchLectures({
    required String courseId,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _courseId == courseId &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < const Duration(minutes: 5)) {
      if (kDebugMode) debugPrint('💾 Using cached lecture data');
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
      if (kDebugMode) debugPrint('✅ Fetched ${lectures.length} lectures for course $courseId');
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Fetch lectures error: $e');
      _setError(e); // ✅ Fixed: e instead of e.toString()
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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
      if (kDebugMode) debugPrint('❌ Get lecture details error: $e');
      _setError(e); // ✅ Fixed: e instead of e.toString()
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Lecture? getLectureFromList(String lectureId) {
    try {
      return _lectures.firstWhere((lecture) => lecture.id == lectureId);
    } catch (e) {
      return null;
    }
  }

  Future<void> refresh() async {
    if (_courseId != null) {
      await fetchLectures(courseId: _courseId!, forceRefresh: true);
    }
  }

  void clear() {
    _courseId = null;
    _lectures = [];
    _selectedLecture = null;
    _isLoading = false;
    _errorMessage = null;
    _lastFetchedAt = null;
    notifyListeners();
  }

  void clearSelectedLecture() {
    _selectedLecture = null;
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

  @override
  void dispose() {
    super.dispose();
  }
}