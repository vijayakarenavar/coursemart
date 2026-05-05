/// LectureProvider, CacheManager & SecureStorage Tests
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:coursemart_app/models/lecture.dart';
import 'package:coursemart_app/services/api_service.dart';

// ─────────────────────────────────────────────
// MOCK CLASSES
// ─────────────────────────────────────────────

class MockLectureApiService {
  bool shouldSucceed = true;
  bool shouldThrow401 = false;
  String errorMessage = 'Could not load lectures. Please try again.';

  List<Lecture> mockLectures = [
    Lecture.fromJson({
      '_id': 'l1',
      'lectureNumber': 1,
      'topic': 'Intro to Flutter',
      'videoStatus': 'ready',
      'uploadedAt': '2026-03-01T10:00:00.000Z',
      'trainerName': 'John Doe',
      'youtubeVideoId': 'abc123',
      'notesUrl': 'https://example.com/notes1.pdf',
    }),
    Lecture.fromJson({
      '_id': 'l2',
      'lectureNumber': 2,
      'topic': 'Widgets Deep Dive',
      'videoStatus': 'processing',
      'uploadedAt': '2026-03-05T10:00:00.000Z',
      'trainerName': 'Jane Smith',
    }),
    Lecture.fromJson({
      '_id': 'l3',
      'lectureNumber': 3,
      'topic': 'State Management',
      'videoStatus': 'ready',
      'uploadedAt': '2026-03-10T10:00:00.000Z',
      'trainerName': 'John Doe',
      'youtubeVideoId': 'xyz789',
      'notesUrl': 'https://example.com/notes3.pdf',
    }),
    Lecture.fromJson({
      '_id': 'l4',
      'lectureNumber': 4,
      'topic': 'API Integration',
      'videoStatus': 'failed',
      'uploadedAt': '2026-03-15T10:00:00.000Z',
      'trainerName': 'Jane Smith',
    }),
  ];

  Lecture mockLectureDetail = Lecture.fromJson({
    '_id': 'l1',
    'lectureNumber': 1,
    'topic': 'Intro to Flutter',
    'videoStatus': 'ready',
    'uploadedAt': '2026-03-01T10:00:00.000Z',
    'trainerName': 'John Doe',
    'youtubeVideoId': 'abc123',
    'notesUrl': 'https://example.com/notes1.pdf',
    'courseTitle': 'Flutter Development',
  });

  Future<List<Lecture>> getCourseLectures(String courseId) async {
    if (shouldThrow401) {
      throw const ApiException(
        message: 'Your session has expired. Please login again.',
        statusCode: 401,
      );
    }
    if (!shouldSucceed) {
      throw ApiException(message: errorMessage, statusCode: 500);
    }
    return mockLectures;
  }

  Future<Lecture> getLectureDetails(String lectureId) async {
    if (!shouldSucceed) {
      throw ApiException(message: errorMessage, statusCode: 500);
    }
    return mockLectureDetail;
  }
}

/// Mock SecureStorage — device storage use karaycha nahi
class MockSecureStorage {
  final Map<String, String> _store = {};

  Future<String?> getAuthToken() async => _store['auth_token'];
  Future<void> saveAuthToken(String token) async => _store['auth_token'] = token;
  Future<void> clearAuthToken() async => _store.remove('auth_token');
  Future<String?> read(String key) async => _store[key];
  Future<void> write(String key, String value) async => _store[key] = value;
  Future<void> delete(String key) async => _store.remove(key);
  Future<void> deleteAll() async => _store.clear();
  Future<bool> containsKey(String key) async => _store.containsKey(key);
  bool get isEmpty => _store.isEmpty;
  int get length => _store.length;
}

/// Mock CacheManager — Hive use karaycha nahi
class MockCacheManager {
  Map<String, dynamic>? _profileData;
  int? _profileTimestamp;

  List<dynamic>? _coursesData;
  int? _coursesTimestamp;

  final Map<String, List<dynamic>> _lecturesData = {};
  final Map<String, int> _lecturesTimestamp = {};

  final Map<String, dynamic> _settings = {};

  static const Duration profileCacheDuration = Duration(minutes: 30);
  static const Duration coursesCacheDuration = Duration(minutes: 15);
  static const Duration lecturesCacheDuration = Duration(minutes: 10);

  // ── Profile ──
  Future<void> cacheProfile(Map<String, dynamic> data) async {
    _profileData = data;
    _profileTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  Map<String, dynamic>? getCachedProfile() {
    if (_profileTimestamp == null) return null;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(_profileTimestamp!);
    if (DateTime.now().difference(cacheTime) > profileCacheDuration) return null;
    return _profileData;
  }

  Future<void> clearCachedProfile() async {
    _profileData = null;
    _profileTimestamp = null;
  }

  // ── Courses ──
  Future<void> cacheCourses(List<dynamic> data) async {
    _coursesData = data;
    _coursesTimestamp = DateTime.now().millisecondsSinceEpoch;
  }

  List<dynamic>? getCachedCourses() {
    if (_coursesTimestamp == null) return null;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(_coursesTimestamp!);
    if (DateTime.now().difference(cacheTime) > coursesCacheDuration) return null;
    return _coursesData;
  }

  Future<void> clearCachedCourses() async {
    _coursesData = null;
    _coursesTimestamp = null;
  }

  // ── Lectures ──
  Future<void> cacheLectures(String courseId, List<dynamic> data) async {
    _lecturesData[courseId] = data;
    _lecturesTimestamp[courseId] = DateTime.now().millisecondsSinceEpoch;
  }

  List<dynamic>? getCachedLectures(String courseId) {
    final ts = _lecturesTimestamp[courseId];
    if (ts == null) return null;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(ts);
    if (DateTime.now().difference(cacheTime) > lecturesCacheDuration) return null;
    return _lecturesData[courseId];
  }

  Future<void> clearCachedLectures(String courseId) async {
    _lecturesData.remove(courseId);
    _lecturesTimestamp.remove(courseId);
  }

  // ── Settings ──
  Future<void> setSetting(String key, dynamic value) async => _settings[key] = value;
  T? getSetting<T>(String key, {T? defaultValue}) =>
      (_settings[key] as T?) ?? defaultValue;
  Future<void> deleteSetting(String key) async => _settings.remove(key);

  // ── General ──
  Future<void> clearAllCache() async {
    _profileData = null;
    _profileTimestamp = null;
    _coursesData = null;
    _coursesTimestamp = null;
    _lecturesData.clear();
    _lecturesTimestamp.clear();
  }

  int getCacheSize() {
    int size = 0;
    if (_profileData != null) size++;
    if (_profileTimestamp != null) size++;
    if (_coursesData != null) size++;
    if (_coursesTimestamp != null) size++;
    size += _lecturesData.length;
    size += _lecturesTimestamp.length;
    size += _settings.length;
    return size;
  }
}

// ─────────────────────────────────────────────
// TESTABLE LECTURE PROVIDER
// ─────────────────────────────────────────────

class TestableLectureProvider {
  final MockLectureApiService _apiService;

  String? _courseId;
  List<Lecture> _lectures = [];
  Lecture? _selectedLecture;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetchedAt;

  TestableLectureProvider(this._apiService);

  String? get courseId => _courseId;
  List<Lecture> get lectures => _lectures;
  Lecture? get selectedLecture => _selectedLecture;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
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
      return true;
    }

    _courseId = courseId;
    _isLoading = true;
    _errorMessage = null;

    try {
      _lectures = await _apiService.getCourseLectures(courseId);
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

  Future<Lecture> getLectureDetails(String lectureId) async {
    _isLoading = true;
    try {
      final lecture = await _apiService.getLectureDetails(lectureId);
      _selectedLecture = lecture;
      _isLoading = false;
      return lecture;
    } catch (e) {
      if (e is ApiException) {
        _errorMessage = e.message;
      } else {
        _errorMessage = 'Something went wrong. Please try again.';
      }
      _isLoading = false;
      rethrow;
    }
  }

  Lecture? getLectureFromList(String lectureId) {
    try {
      return _lectures.firstWhere((l) => l.id == lectureId);
    } catch (_) {
      return null;
    }
  }

  void clear() {
    _courseId = null;
    _lectures = [];
    _selectedLecture = null;
    _isLoading = false;
    _errorMessage = null;
    _lastFetchedAt = null;
  }

  void clearSelectedLecture() => _selectedLecture = null;
}

// ─────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────

void main() {
  // ═══════════════════════════════════════════
  // LECTURE PROVIDER TESTS
  // ═══════════════════════════════════════════
  group('LectureProvider - fetchLectures()', () {
    late MockLectureApiService mockApi;
    late TestableLectureProvider provider;

    setUp(() {
      mockApi = MockLectureApiService();
      provider = TestableLectureProvider(mockApi);
    });

    test('Successful fetch - lectures load hotat ka', () async {
      final result = await provider.fetchLectures(courseId: 'c1');
      expect(result, true);
      expect(provider.lectures.length, 4);
      expect(provider.isLoaded, true);
      expect(provider.hasError, false);
    });

    test('Failed fetch - error message set hoto ka', () async {
      mockApi.shouldSucceed = false;
      final result = await provider.fetchLectures(courseId: 'c1');
      expect(result, false);
      expect(provider.hasError, true);
      expect(provider.errorMessage, isNotEmpty);
    });

    test('401 error - session expired message milto ka', () async {
      mockApi.shouldThrow401 = true;
      final result = await provider.fetchLectures(courseId: 'c1');
      expect(result, false);
      expect(provider.errorMessage!.toLowerCase().contains('session'), true);
    });

    test('courseId correct set hoto ka', () async {
      await provider.fetchLectures(courseId: 'course123');
      expect(provider.courseId, 'course123');
    });

    test('Cache - same courseId 5 min madhe re-fetch hot nahi ka', () async {
      await provider.fetchLectures(courseId: 'c1');
      mockApi.shouldSucceed = false;
      final result = await provider.fetchLectures(courseId: 'c1');
      expect(result, true); // cache varun
    });

    test('forceRefresh - cache ignore karto ka', () async {
      await provider.fetchLectures(courseId: 'c1');
      mockApi.shouldSucceed = false;
      final result = await provider.fetchLectures(courseId: 'c1', forceRefresh: true);
      expect(result, false); // fresh fetch, fail zala
    });

    test('Different courseId - fresh fetch hoto ka', () async {
      await provider.fetchLectures(courseId: 'c1');
      mockApi.shouldSucceed = false;
      final result = await provider.fetchLectures(courseId: 'c2');
      expect(result, false); // different course, fresh fetch
    });

    test('Empty lectures - isLoaded false aahe ka', () async {
      mockApi.mockLectures = [];
      await provider.fetchLectures(courseId: 'c1');
      expect(provider.isLoaded, false);
      expect(provider.lectureCount, 0);
    });
  });

  group('LectureProvider - readyLectureCount Tests', () {
    late MockLectureApiService mockApi;
    late TestableLectureProvider provider;

    setUp(() async {
      mockApi = MockLectureApiService();
      provider = TestableLectureProvider(mockApi);
      await provider.fetchLectures(courseId: 'c1');
    });

    test('readyLectureCount correct aahe ka', () {
      // l1: ready, l2: processing, l3: ready, l4: failed => 2 ready
      expect(provider.readyLectureCount, 2);
    });

    test('lectureCount correct aahe ka', () {
      expect(provider.lectureCount, 4);
    });
  });

  group('LectureProvider - getLectureDetails()', () {
    late MockLectureApiService mockApi;
    late TestableLectureProvider provider;

    setUp(() {
      mockApi = MockLectureApiService();
      provider = TestableLectureProvider(mockApi);
    });

    test('Successful - lecture details miltat ka', () async {
      final lecture = await provider.getLectureDetails('l1');
      expect(lecture.id, 'l1');
      expect(lecture.topic, 'Intro to Flutter');
      expect(provider.selectedLecture, isNotNull);
    });

    test('Failed - exception throw hoto ka', () async {
      mockApi.shouldSucceed = false;
      expect(
            () => provider.getLectureDetails('l1'),
        throwsA(isA<ApiException>()),
      );
    });

    test('clearSelectedLecture - selected lecture null hoto ka', () async {
      await provider.getLectureDetails('l1');
      expect(provider.selectedLecture, isNotNull);
      provider.clearSelectedLecture();
      expect(provider.selectedLecture, isNull);
    });
  });

  group('LectureProvider - getLectureFromList()', () {
    late MockLectureApiService mockApi;
    late TestableLectureProvider provider;

    setUp(() async {
      mockApi = MockLectureApiService();
      provider = TestableLectureProvider(mockApi);
      await provider.fetchLectures(courseId: 'c1');
    });

    test('Valid id - lecture milto ka', () {
      final lecture = provider.getLectureFromList('l1');
      expect(lecture, isNotNull);
      expect(lecture!.topic, 'Intro to Flutter');
    });

    test('Invalid id - null milto ka', () {
      final lecture = provider.getLectureFromList('invalid_id');
      expect(lecture, isNull);
    });
  });

  group('LectureProvider - clear()', () {
    late MockLectureApiService mockApi;
    late TestableLectureProvider provider;

    setUp(() async {
      mockApi = MockLectureApiService();
      provider = TestableLectureProvider(mockApi);
      await provider.fetchLectures(courseId: 'c1');
    });

    test('clear() nanthar lectures empty hotat ka', () {
      provider.clear();
      expect(provider.lectures, isEmpty);
      expect(provider.courseId, isNull);
      expect(provider.hasError, false);
      expect(provider.selectedLecture, isNull);
    });
  });

  // ═══════════════════════════════════════════
  // CACHE MANAGER TESTS
  // ═══════════════════════════════════════════
  group('CacheManager - Profile Cache Tests', () {
    late MockCacheManager cache;

    setUp(() => cache = MockCacheManager());

    test('Profile cache karto ka', () async {
      final data = {'name': 'Rahul', 'email': 'rahul@example.com'};
      await cache.cacheProfile(data);
      final cached = cache.getCachedProfile();
      expect(cached, isNotNull);
      expect(cached!['name'], 'Rahul');
    });

    test('Profile cache nasel tar null milto ka', () {
      final cached = cache.getCachedProfile();
      expect(cached, isNull);
    });

    test('Profile cache clear hoto ka', () async {
      await cache.cacheProfile({'name': 'Test'});
      await cache.clearCachedProfile();
      expect(cache.getCachedProfile(), isNull);
    });
  });

  group('CacheManager - Courses Cache Tests', () {
    late MockCacheManager cache;

    setUp(() => cache = MockCacheManager());

    test('Courses cache karto ka', () async {
      final data = [
        {'_id': 'c1', 'title': 'Flutter'},
        {'_id': 'c2', 'title': 'React'},
      ];
      await cache.cacheCourses(data);
      final cached = cache.getCachedCourses();
      expect(cached, isNotNull);
      expect(cached!.length, 2);
    });

    test('Courses cache nasel tar null milto ka', () {
      expect(cache.getCachedCourses(), isNull);
    });

    test('Courses cache clear hoto ka', () async {
      await cache.cacheCourses([{'_id': 'c1'}]);
      await cache.clearCachedCourses();
      expect(cache.getCachedCourses(), isNull);
    });

    test('Empty courses list cache hoto ka', () async {
      await cache.cacheCourses([]);
      final cached = cache.getCachedCourses();
      expect(cached, isNotNull);
      expect(cached!.isEmpty, true);
    });
  });

  group('CacheManager - Lectures Cache Tests', () {
    late MockCacheManager cache;

    setUp(() => cache = MockCacheManager());

    test('Lectures cache karto ka', () async {
      final data = [
        {'_id': 'l1', 'topic': 'Intro'},
        {'_id': 'l2', 'topic': 'Widgets'},
      ];
      await cache.cacheLectures('c1', data);
      final cached = cache.getCachedLectures('c1');
      expect(cached, isNotNull);
      expect(cached!.length, 2);
    });

    test('Different courseId sathi alag cache aahe ka', () async {
      await cache.cacheLectures('c1', [{'_id': 'l1'}]);
      await cache.cacheLectures('c2', [{'_id': 'l2'}, {'_id': 'l3'}]);
      expect(cache.getCachedLectures('c1')!.length, 1);
      expect(cache.getCachedLectures('c2')!.length, 2);
    });

    test('Lectures cache nasel tar null milto ka', () {
      expect(cache.getCachedLectures('c1'), isNull);
    });

    test('Specific course lectures clear hoto ka', () async {
      await cache.cacheLectures('c1', [{'_id': 'l1'}]);
      await cache.cacheLectures('c2', [{'_id': 'l2'}]);
      await cache.clearCachedLectures('c1');
      expect(cache.getCachedLectures('c1'), isNull);
      expect(cache.getCachedLectures('c2'), isNotNull); // c2 still aahe
    });
  });

  group('CacheManager - Settings Tests', () {
    late MockCacheManager cache;

    setUp(() => cache = MockCacheManager());

    test('Setting save ani get hoto ka', () async {
      await cache.setSetting('theme', 'dark');
      expect(cache.getSetting<String>('theme'), 'dark');
    });

    test('Bool setting save ani get hoto ka', () async {
      await cache.setSetting('notifications', true);
      expect(cache.getSetting<bool>('notifications'), true);
    });

    test('Setting nasel tar default value milto ka', () {
      expect(cache.getSetting<String>('missing', defaultValue: 'light'), 'light');
    });

    test('Setting delete hoto ka', () async {
      await cache.setSetting('key', 'value');
      await cache.deleteSetting('key');
      expect(cache.getSetting<String>('key'), isNull);
    });
  });

  group('CacheManager - clearAllCache() Tests', () {
    late MockCacheManager cache;

    setUp(() => cache = MockCacheManager());

    test('clearAllCache - sagala data clear hoto ka', () async {
      await cache.cacheProfile({'name': 'Test'});
      await cache.cacheCourses([{'_id': 'c1'}]);
      await cache.cacheLectures('c1', [{'_id': 'l1'}]);

      await cache.clearAllCache();

      expect(cache.getCachedProfile(), isNull);
      expect(cache.getCachedCourses(), isNull);
      expect(cache.getCachedLectures('c1'), isNull);
    });

    test('getCacheSize - correct size milto ka', () async {
      expect(cache.getCacheSize(), 0);
      await cache.cacheProfile({'name': 'Test'});
      expect(cache.getCacheSize(), greaterThan(0));
    });
  });

  // ═══════════════════════════════════════════
  // SECURE STORAGE TESTS
  // ═══════════════════════════════════════════
  group('SecureStorage - Auth Token Tests', () {
    late MockSecureStorage storage;

    setUp(() => storage = MockSecureStorage());

    test('Token save hoto ka', () async {
      await storage.saveAuthToken('jwt_token_abc');
      final token = await storage.getAuthToken();
      expect(token, 'jwt_token_abc');
    });

    test('Token nasel tar null milto ka', () async {
      final token = await storage.getAuthToken();
      expect(token, isNull);
    });

    test('Token clear hoto ka', () async {
      await storage.saveAuthToken('jwt_token_abc');
      await storage.clearAuthToken();
      final token = await storage.getAuthToken();
      expect(token, isNull);
    });

    test('Token overwrite hoto ka', () async {
      await storage.saveAuthToken('old_token');
      await storage.saveAuthToken('new_token');
      final token = await storage.getAuthToken();
      expect(token, 'new_token');
    });
  });

  group('SecureStorage - Generic Storage Tests', () {
    late MockSecureStorage storage;

    setUp(() => storage = MockSecureStorage());

    test('Write ani read hoto ka', () async {
      await storage.write('user_pref', 'dark_mode');
      final value = await storage.read('user_pref');
      expect(value, 'dark_mode');
    });

    test('Key nasel tar null milto ka', () async {
      final value = await storage.read('missing_key');
      expect(value, isNull);
    });

    test('Delete - key remove hoto ka', () async {
      await storage.write('temp_key', 'temp_value');
      await storage.delete('temp_key');
      final value = await storage.read('temp_key');
      expect(value, isNull);
    });

    test('deleteAll - sagala data clear hoto ka', () async {
      await storage.write('key1', 'value1');
      await storage.write('key2', 'value2');
      await storage.saveAuthToken('token');
      await storage.deleteAll();
      expect(storage.isEmpty, true);
    });

    test('containsKey - existing key true milto ka', () async {
      await storage.write('exists', 'yes');
      expect(await storage.containsKey('exists'), true);
    });

    test('containsKey - missing key false milto ka', () async {
      expect(await storage.containsKey('not_exists'), false);
    });

    test('Multiple keys independently store hotat ka', () async {
      await storage.write('k1', 'v1');
      await storage.write('k2', 'v2');
      await storage.write('k3', 'v3');
      expect(storage.length, 3);
      expect(await storage.read('k1'), 'v1');
      expect(await storage.read('k2'), 'v2');
      expect(await storage.read('k3'), 'v3');
    });
  });
}