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

  // ✅ Helper — disposed असेल तर notifyListeners call करणार नाही
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
      _errorMessage = e.toString();
      _safeNotify();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _clearError();
    _safeNotify(); // ✅ safe

    try {
      await _apiService.login(email: email, password: password);
      await _fetchProfile();
      debugPrint('✅ Login successful: ${_student?.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _setError(e.toString());
      _status = AuthStatus.unauthenticated;
      _safeNotify(); // ✅ safe
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
      _safeNotify(); // ✅ safe
    }
  }

  Future<void> refreshProfile() async {
    try {
      await _fetchProfile();
    } catch (e) {
      debugPrint('❌ Profile refresh error: $e');
      _setError(e.toString());
      _safeNotify(); // ✅ safe
    }
  }

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _clearError();
    _safeNotify(); // ✅ safe

    try {
      final message = await _apiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return message;
    } catch (e) {
      debugPrint('❌ Change password error: $e');
      _setError(e.toString());
      rethrow;
    }
  }

  // जुने तीन methods (sendForgotPasswordOtp, verifyForgotPasswordOtp, resetPassword)
// हे तिन्ही DELETE करा आणि हे दोन add करा:

  /// Step 1 — Email पाठवा, resetToken परत येतो
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

  /// Step 2 — Token + नवीन password पाठवा
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
    _safeNotify(); // ✅ safe
  }

  Future<void> _fetchProfile() async {
    try {
      _student = await _apiService.getProfile();
      _status = AuthStatus.authenticated;
      _safeNotify(); // ✅ safe
    } catch (e) {
      debugPrint('❌ Profile fetch error: $e');
      if (e.toString().contains('401') ||
          e.toString().contains('Session expired')) {
        await _secureStorage.clearAuthToken();
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.error;
        _errorMessage = e.toString();
      }
      _safeNotify(); // ✅ safe
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

  void _setError(String message) {
    _errorMessage = message;
  }

}