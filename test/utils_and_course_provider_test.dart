/// Validation, DateHelper, ErrorHandler & CourseProvider Tests
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:coursemart_app/utils/error_handler.dart';
import 'package:coursemart_app/utils/date_helper.dart';
import 'package:coursemart_app/models/course.dart';
import 'package:coursemart_app/services/api_service.dart';

// ─────────────────────────────────────────────
// MOCK API SERVICE FOR COURSE PROVIDER
// ─────────────────────────────────────────────

class MockCourseApiService {
  bool shouldSucceed = true;
  bool shouldThrow401 = false;
  List<Course> mockCourses = [
    Course.fromJson({
      '_id': 'c1',
      'title': 'Flutter Dev',
      'description': 'Learn Flutter',
      'thumbnail': 'thumb1.jpg',
      'progress': 60,
      'totalLectures': 20,
      'completedLectures': 12,
      'scheduleStatus': 'in_progress',
    }),
    Course.fromJson({
      '_id': 'c2',
      'title': 'React Native',
      'description': 'Learn RN',
      'thumbnail': 'thumb2.jpg',
      'progress': 100,
      'totalLectures': 15,
      'completedLectures': 15,
      'scheduleStatus': 'completed',
    }),
    Course.fromJson({
      '_id': 'c3',
      'title': 'Django REST',
      'description': 'Learn Django',
      'thumbnail': 'thumb3.jpg',
      'progress': 0,
      'totalLectures': 10,
      'completedLectures': 0,
      'scheduleStatus': 'not_started',
    }),
  ];

  Future<List<Course>> getCourses() async {
    if (shouldThrow401) {
      throw const ApiException(
        message: 'Your session has expired. Please login again.',
        statusCode: 401,
      );
    }
    if (!shouldSucceed) {
      throw const ApiException(
        message: 'Could not load courses. Please try again.',
        statusCode: 500,
      );
    }
    return mockCourses;
  }
}

// ─────────────────────────────────────────────
// TESTABLE COURSE PROVIDER
// ─────────────────────────────────────────────

class TestableCourseProvider {
  final MockCourseApiService _apiService;

  List<Course> _courses = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _filter = 'all';
  DateTime? _lastFetchedAt;

  TestableCourseProvider(this._apiService);

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get filter => _filter;
  bool get hasError => _errorMessage != null;
  bool get isLoaded => _courses.isNotEmpty && !_isLoading;
  int get courseCount => _courses.length;

  List<Course> get filteredCourses {
    if (_filter == 'all') return _courses;
    return _courses.where((c) => c.scheduleStatus == _filter).toList();
  }

  int get inProgressCount =>
      _courses.where((c) => c.scheduleStatus == CourseStatus.inProgress).length;
  int get completedCount =>
      _courses.where((c) => c.scheduleStatus == CourseStatus.completed).length;
  int get notStartedCount =>
      _courses.where((c) => c.scheduleStatus == CourseStatus.notStarted).length;

  int get completedLecturesCount =>
      _courses.fold(0, (sum, c) => sum + c.completedLectures);
  int get remainingLecturesCount =>
      _courses.fold(0, (sum, c) => sum + c.remainingLectures);

  double get overallProgress {
    if (_courses.isEmpty) return 0.0;
    final total = _courses.fold(0, (sum, c) => sum + c.totalLectures);
    if (total == 0) return 0.0;
    return completedLecturesCount / total;
  }

  Future<bool> fetchCourses({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < const Duration(minutes: 5)) {
      return true;
    }
    _isLoading = true;
    _errorMessage = null;
    try {
      _courses = await _apiService.getCourses();
      _lastFetchedAt = DateTime.now();
      _isLoading = false;
      return true;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Something went wrong. Please try again.';
      }
      _isLoading = false;
      return false;
    }
  }

  void setFilter(String filter) => _filter = filter;

  Course? getCourseById(String id) {
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _courses = [];
    _isLoading = false;
    _errorMessage = null;
    _filter = 'all';
    _lastFetchedAt = null;
  }
}

// ─────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────

void main() {
  // ═══════════════════════════════════════════
  // VALIDATION HELPER TESTS
  // ═══════════════════════════════════════════
  group('ValidationHelper - Email Tests', () {
    test('Valid email accept hoto ka', () {
      expect(ValidationHelper.isValidEmail('rahul@example.com'), true);
      expect(ValidationHelper.isValidEmail('test.user@gmail.com'), true);
      expect(ValidationHelper.isValidEmail('user+tag@domain.co.in'), true);
    });

    test('Invalid email reject hoto ka', () {
      expect(ValidationHelper.isValidEmail('rahul@'), false);
      expect(ValidationHelper.isValidEmail('rahul'), false);
      expect(ValidationHelper.isValidEmail('@example.com'), false);
      expect(ValidationHelper.isValidEmail('rahul@example'), false);
      expect(ValidationHelper.isValidEmail(''), false);
    });

    test('validateEmail - empty asel tar error milto ka', () {
      expect(ValidationHelper.validateEmail(''), 'Email is required');
      expect(ValidationHelper.validateEmail(null), 'Email is required');
    });

    test('validateEmail - invalid format asel tar error milto ka', () {
      expect(
        ValidationHelper.validateEmail('rahul@'),
        'Please enter a valid email address',
      );
    });

    test('validateEmail - valid asel tar null milto ka', () {
      expect(ValidationHelper.validateEmail('rahul@example.com'), null);
    });
  });

  group('ValidationHelper - Password Tests', () {
    test('validatePassword - empty asel tar error milto ka', () {
      expect(ValidationHelper.validatePassword(''), 'Password is required');
      expect(ValidationHelper.validatePassword(null), 'Password is required');
    });

    test('validatePassword - 6 chars kam asel tar error milto ka', () {
      expect(
        ValidationHelper.validatePassword('abc'),
        'Password must be at least 6 characters',
      );
      expect(
        ValidationHelper.validatePassword('12345'),
        'Password must be at least 6 characters',
      );
    });

    test('validatePassword - 6+ chars asel tar null milto ka', () {
      expect(ValidationHelper.validatePassword('123456'), null);
      expect(ValidationHelper.validatePassword('password123'), null);
    });

    test('isStrongPassword - weak password reject hoto ka', () {
      expect(ValidationHelper.isStrongPassword('password'), false);
      expect(ValidationHelper.isStrongPassword('12345678'), false);
      expect(ValidationHelper.isStrongPassword('Password'), false);
    });

    test('isStrongPassword - strong password accept hoto ka', () {
      expect(ValidationHelper.isStrongPassword('Password1'), true);
      expect(ValidationHelper.isStrongPassword('Flutter2024'), true);
    });
  });

  group('ValidationHelper - Confirm Password Tests', () {
    test('Matching passwords - null milto ka', () {
      expect(
        ValidationHelper.validateConfirmPassword('pass123', 'pass123'),
        null,
      );
    });

    test('Non-matching passwords - error milto ka', () {
      expect(
        ValidationHelper.validateConfirmPassword('pass123', 'pass456'),
        'Passwords do not match',
      );
    });

    test('Empty confirm password - error milto ka', () {
      expect(
        ValidationHelper.validateConfirmPassword('', 'pass123'),
        'Please confirm your password',
      );
      expect(
        ValidationHelper.validateConfirmPassword(null, 'pass123'),
        'Please confirm your password',
      );
    });
  });

  // ═══════════════════════════════════════════
  // ERROR HANDLER TESTS
  // ═══════════════════════════════════════════
  group('getErrorMessage - ApiException Tests', () {
    test('ApiException message user-friendly aahe ka', () {
      final error = ApiException(message: 'Invalid credentials', statusCode: 401);
      final msg = getErrorMessage(error);
      expect(msg, isNotEmpty);
      expect(msg.toLowerCase().contains('apiexception'), false);
    });

    test('401 status - session expired message milto ka', () {
      final error = ApiException(
        message: 'Your session has expired. Please login again.',
        statusCode: 401,
      );
      final msg = getErrorMessage(error);
      expect(msg.toLowerCase().contains('session'), true);
    });

    test('500 status - server error message milto ka', () {
      final error = ApiException(message: '', statusCode: 500);
      final msg = getErrorMessage(error);
      expect(msg.toLowerCase().contains('server') || msg.toLowerCase().contains('wrong'), true);
    });

    test('400 status - invalid details message milto ka', () {
      final error = ApiException(message: '', statusCode: 400);
      final msg = getErrorMessage(error);
      expect(msg, 'Invalid details. Please check and try again.');
    });

    test('404 status - not found message milto ka', () {
      final error = ApiException(message: '', statusCode: 404);
      final msg = getErrorMessage(error);
      expect(msg, 'Information not found.');
    });

    test('Technical string user la disat nahi ka', () {
      final error = ApiException(
        message: 'ApiException(500): internal error',
        statusCode: 500,
      );
      final msg = getErrorMessage(error);
      expect(msg.toLowerCase().contains('apiexception'), false);
    });

    test('Invalid password message clean hoto ka', () {
      final error = ApiException(
        message: 'Invalid password provided',
        statusCode: 400,
      );
      final msg = getErrorMessage(error);
      expect(msg.toLowerCase().contains('incorrect') || msg.toLowerCase().contains('password'), true);
    });
  });

  group('getErrorMessage - String Tests', () {
    test('Empty string - fallback message milto ka', () {
      final msg = getErrorMessage('');
      expect(msg, 'Something went wrong. Please try again.');
    });

    test('Technical string - clean message milto ka', () {
      final msg = getErrorMessage('SocketException: connection refused');
      expect(msg, 'Something went wrong. Please try again.');
    });

    test('Clean server message - as-is milto ka', () {
      final msg = getErrorMessage('Email already registered');
      expect(msg, 'Email already registered');
    });
  });

  group('getErrorMessage - Unknown Error Tests', () {
    test('Unknown error - fallback message milto ka', () {
      final msg = getErrorMessage(Exception('Some random error'));
      expect(msg, 'Something went wrong. Please try again.');
    });

    test('Null-like error - fallback message milto ka', () {
      final msg = getErrorMessage(42);
      expect(msg, 'Something went wrong. Please try again.');
    });
  });

  // ═══════════════════════════════════════════
  // DATE HELPER TESTS
  // ═══════════════════════════════════════════
  group('DateHelper - Format Tests', () {
    final testDate = DateTime(2026, 3, 25, 10, 30);

    test('formatDate - correct format aahe ka', () {
      expect(DateHelper.formatDate(testDate), 'Mar 25, 2026');
    });

    test('formatShortDate - correct format aahe ka', () {
      expect(DateHelper.formatShortDate(testDate), 'Mar 25');
    });

    test('formatTime - correct format aahe ka', () {
      final result = DateHelper.formatTime(testDate);
      expect(result, contains('10:30'));
      expect(result, contains('AM'));
    });

    test('formatDateTime - correct format aahe ka', () {
      final result = DateHelper.formatDateTime(testDate);
      expect(result, contains('Mar 25, 2026'));
      expect(result, contains('10:30'));
    });

    test('toIsoString - correct ISO string milto ka', () {
      final result = DateHelper.toIsoString(testDate);
      expect(result, contains('2026-03-25'));
    });

    test('fromIsoString - correct DateTime milto ka', () {
      final result = DateHelper.fromIsoString('2026-03-25T10:30:00.000');
      expect(result.year, 2026);
      expect(result.month, 3);
      expect(result.day, 25);
    });
  });

  group('DateHelper - Relative Time Tests', () {
    test('Just now - seconds ago', () {
      final date = DateTime.now().subtract(const Duration(seconds: 30));
      expect(DateHelper.formatRelative(date), 'Just now');
    });

    test('Minutes ago - correct text milto ka', () {
      final date = DateTime.now().subtract(const Duration(minutes: 5));
      expect(DateHelper.formatRelative(date), '5 minutes ago');
    });

    test('1 minute ago - singular form correct aahe ka', () {
      final date = DateTime.now().subtract(const Duration(minutes: 1));
      expect(DateHelper.formatRelative(date), '1 minute ago');
    });

    test('Hours ago - correct text milto ka', () {
      final date = DateTime.now().subtract(const Duration(hours: 3));
      expect(DateHelper.formatRelative(date), '3 hours ago');
    });

    test('1 hour ago - singular form correct aahe ka', () {
      final date = DateTime.now().subtract(const Duration(hours: 1));
      expect(DateHelper.formatRelative(date), '1 hour ago');
    });

    test('Days ago - correct text milto ka', () {
      final date = DateTime.now().subtract(const Duration(days: 3));
      expect(DateHelper.formatRelative(date), '3 days ago');
    });

    test('1 day ago - singular form correct aahe ka', () {
      final date = DateTime.now().subtract(const Duration(days: 1));
      expect(DateHelper.formatRelative(date), '1 day ago');
    });

    test('Weeks ago - correct text milto ka', () {
      final date = DateTime.now().subtract(const Duration(days: 14));
      expect(DateHelper.formatRelative(date), '2 weeks ago');
    });

    test('Months ago - correct text milto ka', () {
      final date = DateTime.now().subtract(const Duration(days: 60));
      expect(DateHelper.formatRelative(date), '2 months ago');
    });

    test('Years ago - correct text milto ka', () {
      final date = DateTime.now().subtract(const Duration(days: 400));
      expect(DateHelper.formatRelative(date), '1 year ago');
    });
  });

  group('DateHelper - isToday / isYesterday Tests', () {
    test('Today - isToday true aahe ka', () {
      expect(DateHelper.isToday(DateTime.now()), true);
    });

    test('Yesterday - isYesterday true aahe ka', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(DateHelper.isYesterday(yesterday), true);
    });

    test('Old date - isToday false aahe ka', () {
      final oldDate = DateTime(2020, 1, 1);
      expect(DateHelper.isToday(oldDate), false);
    });

    test('Today - isYesterday false aahe ka', () {
      expect(DateHelper.isYesterday(DateTime.now()), false);
    });
  });

  group('DateHelper - Duration Tests', () {
    test('Hours ani minutes - correct format aahe ka', () {
      expect(DateHelper.formatDuration(const Duration(hours: 2, minutes: 30)), '2h 30m');
    });

    test('Only minutes - correct format aahe ka', () {
      expect(DateHelper.formatDuration(const Duration(minutes: 45)), '45m');
    });

    test('Zero duration - correct format aahe ka', () {
      expect(DateHelper.formatDuration(Duration.zero), '0m');
    });
  });

  // ═══════════════════════════════════════════
  // COURSE PROVIDER TESTS
  // ═══════════════════════════════════════════
  group('CourseProvider - fetchCourses()', () {
    late MockCourseApiService mockApi;
    late TestableCourseProvider provider;

    setUp(() {
      mockApi = MockCourseApiService();
      provider = TestableCourseProvider(mockApi);
    });

    test('Successful fetch - courses load hotat ka', () async {
      final result = await provider.fetchCourses();
      expect(result, true);
      expect(provider.courses.length, 3);
      expect(provider.isLoaded, true);
      expect(provider.hasError, false);
    });

    test('Failed fetch - error message set hoto ka', () async {
      mockApi.shouldSucceed = false;
      final result = await provider.fetchCourses();
      expect(result, false);
      expect(provider.hasError, true);
      expect(provider.errorMessage, isNotEmpty);
    });

    test('401 error - session expired message milto ka', () async {
      mockApi.shouldThrow401 = true;
      final result = await provider.fetchCourses();
      expect(result, false);
      expect(provider.errorMessage!.toLowerCase().contains('session'), true);
    });

    test('Cache - 5 min madhe re-fetch hot nahi ka', () async {
      await provider.fetchCourses();
      mockApi.shouldSucceed = false; // API fail hota, pan cache use hoto
      final result = await provider.fetchCourses();
      expect(result, true); // cache varun success
    });

    test('forceRefresh - cache ignore karto ka', () async {
      await provider.fetchCourses();
      mockApi.shouldSucceed = false;
      final result = await provider.fetchCourses(forceRefresh: true);
      expect(result, false); // fresh fetch kela ani fail zala
    });

    test('Empty courses - isLoaded false aahe ka', () async {
      mockApi.mockCourses = [];
      await provider.fetchCourses();
      expect(provider.isLoaded, false);
      expect(provider.courseCount, 0);
    });
  });

  group('CourseProvider - Filter Tests', () {
    late MockCourseApiService mockApi;
    late TestableCourseProvider provider;

    setUp(() async {
      mockApi = MockCourseApiService();
      provider = TestableCourseProvider(mockApi);
      await provider.fetchCourses();
    });

    test('Default filter all - sagale courses miltat ka', () {
      expect(provider.filteredCourses.length, 3);
    });

    test('in_progress filter - correct courses miltat ka', () {
      provider.setFilter('in_progress');
      expect(provider.filteredCourses.length, 1);
      expect(provider.filteredCourses[0].title, 'Flutter Dev');
    });

    test('completed filter - correct courses miltat ka', () {
      provider.setFilter('completed');
      expect(provider.filteredCourses.length, 1);
      expect(provider.filteredCourses[0].title, 'React Native');
    });

    test('not_started filter - correct courses miltat ka', () {
      provider.setFilter('not_started');
      expect(provider.filteredCourses.length, 1);
      expect(provider.filteredCourses[0].title, 'Django REST');
    });
  });

  group('CourseProvider - Count Tests', () {
    late MockCourseApiService mockApi;
    late TestableCourseProvider provider;

    setUp(() async {
      mockApi = MockCourseApiService();
      provider = TestableCourseProvider(mockApi);
      await provider.fetchCourses();
    });

    test('inProgressCount correct aahe ka', () {
      expect(provider.inProgressCount, 1);
    });

    test('completedCount correct aahe ka', () {
      expect(provider.completedCount, 1);
    });

    test('notStartedCount correct aahe ka', () {
      expect(provider.notStartedCount, 1);
    });

    test('completedLecturesCount correct aahe ka', () {
      // c1: 12, c2: 15, c3: 0 = 27
      expect(provider.completedLecturesCount, 27);
    });

    test('remainingLecturesCount correct aahe ka', () {
      // c1: 8, c2: 0, c3: 10 = 18
      expect(provider.remainingLecturesCount, 18);
    });

    test('overallProgress correct aahe ka', () {
      // total: 45, completed: 27 = 0.6
      expect(provider.overallProgress, closeTo(0.6, 0.01));
    });
  });

  group('CourseProvider - getCourseById Tests', () {
    late MockCourseApiService mockApi;
    late TestableCourseProvider provider;

    setUp(() async {
      mockApi = MockCourseApiService();
      provider = TestableCourseProvider(mockApi);
      await provider.fetchCourses();
    });

    test('Valid id - course milto ka', () {
      final course = provider.getCourseById('c1');
      expect(course, isNotNull);
      expect(course!.title, 'Flutter Dev');
    });

    test('Invalid id - null milto ka', () {
      final course = provider.getCourseById('invalid_id');
      expect(course, isNull);
    });
  });

  group('CourseProvider - clear() Tests', () {
    late MockCourseApiService mockApi;
    late TestableCourseProvider provider;

    setUp(() async {
      mockApi = MockCourseApiService();
      provider = TestableCourseProvider(mockApi);
      await provider.fetchCourses();
    });

    test('clear() nanthar courses empty hotat ka', () {
      provider.clear();
      expect(provider.courses, isEmpty);
      expect(provider.courseCount, 0);
      expect(provider.hasError, false);
      expect(provider.filter, 'all');
    });

    test('overallProgress - courses empty asel tar 0.0 milto ka', () {
      provider.clear();
      expect(provider.overallProgress, 0.0);
    });
  });
}