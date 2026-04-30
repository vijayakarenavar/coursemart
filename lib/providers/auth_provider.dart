/// Authentication Provider
library;

import 'package:flutter/foundation.dart';

import '../models/student.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';

enum AuthStatus {
  checking,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SecureStorage _secureStorage = SecureStorage();

  AuthStatus _status = AuthStatus.checking;
  Student? _student;
  String? _errorMessage;

  AuthStatus get status => _status;
  Student? get student => _student;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isChecking => _status == AuthStatus.checking;
  bool get hasError => _status == AuthStatus.error;
  String get studentName => _student?.name ?? 'Student';
  String get studentEmail => _student?.email ?? '';
  String get studentUsername => _student?.username ?? '';
  String get studentCreatedAt => _student?.createdAt ?? '';
  String get studentRollNumber => _student?.rollNumber ?? '';
  String get studentCollege => _student?.collegeName ?? '';
  int get enrolledCoursesCount => _student?.enrolledCourses.length ?? 0;
  List<EnrolledCourse> get enrolledCourses => _student?.enrolledCourses ?? [];

  void _safeNotify() {
    if (hasListeners) notifyListeners();
  }

  Future<void> init() async {
    _status = AuthStatus.checking;
    _safeNotify();

    try {
      final token = await _secureStorage.getAuthToken();
      if (token == null || token.isEmpty) {
        _status = AuthStatus.unauthenticated;
        _safeNotify();
        return;
      }
      await _fetchProfile();
    } catch (e) {
      debugPrint('❌ Auth init error: $e');
      _status = AuthStatus.unauthenticated;
      _setError(e); // ✅ Fixed: e instead of e.toString()
      _safeNotify();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _clearError();
    _safeNotify();

    try {
      await _apiService.login(email: email, password: password);
      await _fetchProfile();
      debugPrint('✅ Login successful: ${_student?.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _setError(e); // ✅ Fixed: e instead of e.toString()
      _status = AuthStatus.unauthenticated;
      _safeNotify();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    } finally {
      _reset();
      _safeNotify();
    }
  }

  Future<void> refreshProfile() async {
    try {
      await _fetchProfile();
    } catch (e) {
      debugPrint('❌ Profile refresh error: $e');
      _setError(e); // ✅ Fixed: e instead of e.toString()
      _safeNotify();
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _clearError();
    _safeNotify();

    try {
      final message = await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return message;
    } catch (e) {
      debugPrint('❌ Change password error: $e');
      _setError(e); // ✅ Fixed: e instead of e.toString()
      rethrow;
    }
  }

  Future<String> forgotPassword({required String email}) async {
    try {
      final token = await _apiService.forgotPassword(email: email);
      debugPrint('✅ Reset token received');
      return token;
    } catch (e) {
      debugPrint('❌ Forgot password error: $e');
      rethrow;
    }
  }

  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiService.resetPasswordWithToken(
        token: token,
        newPassword: newPassword,
      );
      debugPrint('✅ Password reset successfully');
    } catch (e) {
      debugPrint('❌ Reset password error: $e');
      rethrow;
    }
  }

  void handleUnauthorized() {
    debugPrint('🚨 Unauthorized - triggering logout');
    _reset();
    _safeNotify();
  }

  Future<void> _fetchProfile() async {
    try {
      _student = await _apiService.getProfile();
      _status = AuthStatus.authenticated;
      _safeNotify();
    } catch (e) {
      debugPrint('❌ Profile fetch error: $e');
      // ✅ Fixed: e is ApiException check instead of e.toString().contains()
      if (e is ApiException && e.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.error;
        _setError(e); // ✅ Fixed: e instead of e.toString()
      }
      _safeNotify();
    }
  }

  void _reset() {
    _status = AuthStatus.unauthenticated;
    _student = null;
    _errorMessage = null;
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
}