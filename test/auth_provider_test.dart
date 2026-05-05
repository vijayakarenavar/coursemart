/// AuthProvider Unit Tests
///
/// ApiService ani SecureStorage mock karun
/// AuthProvider che behavior test karto.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:coursemart_app/models/student.dart';
import 'package:coursemart_app/services/api_service.dart';

// ─────────────────────────────────────────────
// MOCK CLASSES
// ─────────────────────────────────────────────

/// Mock SecureStorage — actual device storage use karaycha nahi
class MockSecureStorage {
  String? _token;

  Future<String?> getAuthToken() async => _token;
  Future<void> saveAuthToken(String token) async => _token = token;
  Future<void> clearAuthToken() async => _token = null;

  // Test helpers
  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  bool get hasToken => _token != null && _token!.isNotEmpty;
}

/// Mock ApiService — real API call hot nahi
class MockApiService {
  // Control flags for tests
  bool shouldLoginSucceed = true;
  bool shouldProfileSucceed = true;
  bool shouldThrow401 = false;
  String loginErrorMessage = 'Invalid credentials';
  String profileErrorMessage = 'Profile fetch failed';

  Student mockStudent = Student(
    id: 'stu123',
    name: 'Rahul Sharma',
    rollNumber: 'CS2021001',
    email: 'rahul@example.com',
    collegeName: 'MIT College',
    username: 'rahul21',
    createdAt: '2024-01-01',
    enrolledCourses: [
      const EnrolledCourse(id: 'c1', title: 'Flutter Dev'),
      const EnrolledCourse(id: 'c2', title: 'React Native'),
    ],
  );

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    if (!shouldLoginSucceed) {
      throw ApiException(message: loginErrorMessage, statusCode: 401);
    }
    return {'token': 'mock_jwt_token_123', 'message': 'Login successful'};
  }

  Future<void> logout() async {
    // Mock logout - always succeeds
  }

  Future<Student> getProfile() async {
    if (shouldThrow401) {
      throw const ApiException(
        message: 'Your session has expired. Please login again.',
        statusCode: 401,
      );
    }
    if (!shouldProfileSucceed) {
      throw ApiException(message: profileErrorMessage, statusCode: 500);
    }
    return mockStudent;
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword == 'wrong_password') {
      throw const ApiException(
        message: 'Current password is incorrect',
        statusCode: 400,
      );
    }
    return 'Password changed successfully';
  }

  Future<String> forgotPassword({required String email}) async {
    if (email == 'notfound@example.com') {
      throw const ApiException(
        message: 'Email not found',
        statusCode: 404,
      );
    }
    return 'mock_reset_token_abc';
  }
}

// ─────────────────────────────────────────────
// SIMPLIFIED AUTH PROVIDER FOR TESTING
// (same logic, mock dependencies inject kele)
// ─────────────────────────────────────────────

enum AuthStatus { checking, authenticated, unauthenticated, error }

class TestableAuthProvider {
  final MockApiService _apiService;
  final MockSecureStorage _secureStorage;

  AuthStatus _status = AuthStatus.checking;
  Student? _student;
  String? _errorMessage;

  TestableAuthProvider(this._apiService, this._secureStorage);

  AuthStatus get status => _status;
  Student? get student => _student;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isChecking => _status == AuthStatus.checking;
  bool get hasError => _status == AuthStatus.error;
  String get studentName => _student?.name ?? 'Student';
  String get studentEmail => _student?.email ?? '';
  int get enrolledCoursesCount => _student?.enrolledCourses.length ?? 0;

  Future<void> init() async {
    _status = AuthStatus.checking;
    try {
      final token = await _secureStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
        return;
      }
      await _fetchProfile();
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _setError(e);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _clearError();
    try {
      await _apiService.login(email: email, password: password);
      await _fetchProfile();
      return true;
    } catch (e) {
      _setError(e);
      _status = AuthStatus.unauthenticated;
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } finally {
      _status = AuthStatus.unauthenticated;
      _student = null;
      _errorMessage = null;
      await _secureStorage.clearAuthToken();
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _clearError();
    try {
      return await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      _setError(e);
      rethrow;
    }
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      return await _apiService.forgotPassword(email: email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _fetchProfile() async {
    try {
      _student = await _apiService.getProfile();
      _status = AuthStatus.authenticated;
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.error;
        _setError(e);
      }
    }
  }

  void _clearError() => _errorMessage = null;

  void _setError(dynamic error) {
    if (error is ApiException) {
      _errorMessage = error.message;
    } else {
      _errorMessage = 'Something went wrong. Please try again.';
    }
  }
}

// ─────────────────────────────────────────────
// TESTS
// ─────────────────────────────────────────────

void main() {
  late MockApiService mockApi;
  late MockSecureStorage mockStorage;
  late TestableAuthProvider authProvider;

  setUp(() {
    mockApi = MockApiService();
    mockStorage = MockSecureStorage();
    authProvider = TestableAuthProvider(mockApi, mockStorage);
  });

  // ═══════════════════════════════════════════
  // INIT TESTS
  // ═══════════════════════════════════════════
  group('AuthProvider - init()', () {
    test('Token nasel tar unauthenticated hoto ka', () async {
      mockStorage.clearToken();
      await authProvider.init();
      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.isAuthenticated, false);
    });

    test('Valid token asel tar authenticated hoto ka', () async {
      mockStorage.setToken('valid_token');
      mockApi.shouldProfileSucceed = true;
      await authProvider.init();
      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.isAuthenticated, true);
    });

    test('Token ahe pan profile fail zala tar error status milto ka', () async {
      mockStorage.setToken('valid_token');
      mockApi.shouldProfileSucceed = false;
      await authProvider.init();
      expect(authProvider.status, AuthStatus.error);
    });

    test('Token ahe pan 401 aala tar unauthenticated hoto ka', () async {
      mockStorage.setToken('expired_token');
      mockApi.shouldThrow401 = true;
      await authProvider.init();
      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(mockStorage.hasToken, false); // token clear zala ka
    });
  });

  // ═══════════════════════════════════════════
  // LOGIN TESTS
  // ═══════════════════════════════════════════
  group('AuthProvider - login()', () {
    test('Successful login - authenticated hoto ka', () async {
      mockApi.shouldLoginSucceed = true;
      mockApi.shouldProfileSucceed = true;

      final result = await authProvider.login(
        email: 'rahul@example.com',
        password: 'correct_password',
      );

      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.status, AuthStatus.authenticated);
    });

    test('Successful login - student data set hoto ka', () async {
      mockApi.shouldLoginSucceed = true;
      mockApi.shouldProfileSucceed = true;

      await authProvider.login(
        email: 'rahul@example.com',
        password: 'correct_password',
      );

      expect(authProvider.student, isNotNull);
      expect(authProvider.studentName, 'Rahul Sharma');
      expect(authProvider.studentEmail, 'rahul@example.com');
    });

    test('Failed login - unauthenticated rahto ka', () async {
      mockApi.shouldLoginSucceed = false;
      mockApi.loginErrorMessage = 'Invalid credentials';

      final result = await authProvider.login(
        email: 'wrong@example.com',
        password: 'wrong_password',
      );

      expect(result, false);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.status, AuthStatus.unauthenticated);
    });

    test('Failed login - error message set hoto ka', () async {
      mockApi.shouldLoginSucceed = false;
      mockApi.loginErrorMessage = 'Invalid credentials';

      await authProvider.login(
        email: 'wrong@example.com',
        password: 'wrong_password',
      );

      expect(authProvider.errorMessage, 'Invalid credentials');
      expect(authProvider.hasError, false); // status error nahi, unauthenticated aahe
    });

    test('Login successful - enrolledCourses miltat ka', () async {
      mockApi.shouldLoginSucceed = true;
      mockApi.shouldProfileSucceed = true;

      await authProvider.login(
        email: 'rahul@example.com',
        password: 'correct_password',
      );

      expect(authProvider.enrolledCoursesCount, 2);
    });

    test('Empty email/password la login fail hoto ka', () async {
      mockApi.shouldLoginSucceed = false;
      mockApi.loginErrorMessage = 'Email and password required';

      final result = await authProvider.login(email: '', password: '');

      expect(result, false);
      expect(authProvider.isAuthenticated, false);
    });
  });

  // ═══════════════════════════════════════════
  // LOGOUT TESTS
  // ═══════════════════════════════════════════
  group('AuthProvider - logout()', () {
    test('Logout nanthar unauthenticated hoto ka', () async {
      // Aadhi login karo
      mockApi.shouldLoginSucceed = true;
      mockApi.shouldProfileSucceed = true;
      await authProvider.login(
        email: 'rahul@example.com',
        password: 'correct_password',
      );
      expect(authProvider.isAuthenticated, true);

      // Mag logout karo
      await authProvider.logout();
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.status, AuthStatus.unauthenticated);
    });

    test('Logout nanthar student null hoto ka', () async {
      mockApi.shouldLoginSucceed = true;
      mockApi.shouldProfileSucceed = true;
      await authProvider.login(
        email: 'rahul@example.com',
        password: 'correct_password',
      );

      await authProvider.logout();
      expect(authProvider.student, isNull);
      expect(authProvider.studentName, 'Student'); // default value
    });

    test('Logout nanthar token clear hoto ka', () async {
      mockStorage.setToken('some_token');
      await authProvider.logout();
      expect(mockStorage.hasToken, false);
    });

    test('Logout nanthar errorMessage clear hoto ka', () async {
      mockApi.shouldLoginSucceed = true;
      mockApi.shouldProfileSucceed = true;
      await authProvider.login(
        email: 'rahul@example.com',
        password: 'correct_password',
      );

      await authProvider.logout();
      expect(authProvider.errorMessage, isNull);
    });
  });

  // ═══════════════════════════════════════════
  // CHANGE PASSWORD TESTS
  // ═══════════════════════════════════════════
  group('AuthProvider - changePassword()', () {
    test('Correct password - successfully change hoto ka', () async {
      final message = await authProvider.changePassword(
        currentPassword: 'correct_password',
        newPassword: 'new_password123',
      );
      expect(message, 'Password changed successfully');
    });

    test('Wrong current password - exception throw hoto ka', () async {
      expect(
            () => authProvider.changePassword(
          currentPassword: 'wrong_password',
          newPassword: 'new_password123',
        ),
        throwsA(isA<ApiException>()),
      );
    });

    test('Wrong password - error message set hoto ka', () async {
      try {
        await authProvider.changePassword(
          currentPassword: 'wrong_password',
          newPassword: 'new_password123',
        );
      } catch (_) {}
      expect(authProvider.errorMessage, 'Current password is incorrect');
    });
  });

  // ═══════════════════════════════════════════
  // FORGOT PASSWORD TESTS
  // ═══════════════════════════════════════════
  group('AuthProvider - forgotPassword()', () {
    test('Valid email - reset token milto ka', () async {
      final token = await authProvider.forgotPassword(
        email: 'rahul@example.com',
      );
      expect(token, 'mock_reset_token_abc');
      expect(token.isNotEmpty, true);
    });

    test('Invalid email - exception throw hoto ka', () async {
      expect(
            () => authProvider.forgotPassword(email: 'notfound@example.com'),
        throwsA(isA<ApiException>()),
      );
    });
  });

  // ═══════════════════════════════════════════
  // GETTERS TESTS
  // ═══════════════════════════════════════════
  group('AuthProvider - Getters', () {
    test('Student nasel tar default values miltat ka', () {
      expect(authProvider.studentName, 'Student');
      expect(authProvider.studentEmail, '');
      expect(authProvider.enrolledCoursesCount, 0);
    });

    test('isChecking - initial state checking aahe ka', () {
      expect(authProvider.isChecking, true);
    });

    test('hasError - error status madhe true aahe ka', () async {
      mockStorage.setToken('token');
      mockApi.shouldProfileSucceed = false;
      await authProvider.init();
      expect(authProvider.hasError, true);
    });
  });

  // ═══════════════════════════════════════════
  // API EXCEPTION TESTS
  // ═══════════════════════════════════════════
  group('ApiException Tests', () {
    test('ApiException message correct aahe ka', () {
      const exception = ApiException(message: 'Test error', statusCode: 400);
      expect(exception.message, 'Test error');
      expect(exception.statusCode, 400);
    });

    test('ApiException toString correct aahe ka', () {
      const exception = ApiException(message: 'Not found', statusCode: 404);
      expect(exception.toString(), 'ApiException(404): Not found');
    });

    test('ApiException without statusCode - null aahe ka', () {
      const exception = ApiException(message: 'Unknown error');
      expect(exception.statusCode, isNull);
    });
  });
}