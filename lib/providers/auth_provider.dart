/// Authentication Provider
///
/// Manages authentication state, login, logout, and profile data
/// using Provider state management pattern.
library;

import 'package:flutter/foundation.dart';

import '../models/student.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';

/// Authentication state enum
/// Represents different states of authentication
enum AuthStatus {
  /// Initial state - checking authentication
  checking,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// Error occurred during authentication
  error,
}

/// Authentication Provider
///
/// Manages authentication state and provides methods for:
/// - Login/logout
/// - Profile management
/// - Token validation
/// - Auto-logout on 401 errors
class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final SecureStorage _secureStorage = SecureStorage();

  /// Current authentication status
  AuthStatus _status = AuthStatus.checking;

  /// Logged in student data
  Student? _student;

  /// Error message (if any)
  String? _errorMessage;

  // ==================== GETTERS ====================

  /// Get authentication status
  AuthStatus get status => _status;

  /// Get current student
  Student? get student => _student;

  /// Get error message
  String? get errorMessage => _errorMessage;

  /// Check if user is authenticated
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Check if checking authentication
  bool get isChecking => _status == AuthStatus.checking;

  /// Check if there's an error
  bool get hasError => _status == AuthStatus.error;

  /// Get student name (safe access)
  String get studentName => _student?.name ?? 'Student';

  /// Get student email (safe access)
  String get studentEmail => _student?.email ?? '';

  // ==================== METHODS ====================

  /// Initialize auth state
  ///
  /// Called on app startup to check if user has valid token
  /// Validates token by fetching profile
  Future<void> init() async {
    _status = AuthStatus.checking;
    notifyListeners();

    try {
      // Check if token exists
      final token = await _secureStorage.getAuthToken();

      if (token == null || token.isEmpty) {
        // No token - user needs to login
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }

      // Validate token by fetching profile
      await _fetchProfile();
    } catch (e) {
      debugPrint('❌ Auth init error: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Login student
  ///
  /// [email] - Student email
  /// [password] - Student password
  /// Returns true on success, false on failure
  ///
  /// On success:
  /// - Saves token to secure storage
  /// - Fetches profile
  /// - Updates status to authenticated
  Future<bool> login({required String email, required String password}) async {
    _clearError();
    notifyListeners();

    try {
      // Call login API
      await _apiService.login(email: email, password: password);

      // Fetch profile with new token
      await _fetchProfile();

      debugPrint('✅ Login successful: ${_student?.name}');
      return true;
    } catch (e) {
      debugPrint('❌ Login error: $e');
      _setError(e.toString());
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Logout student
  ///
  /// Clears token and resets state to unauthenticated
  Future<void> logout() async {
    try {
      await _apiService.logout();
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    } finally {
      // Always reset state
      _reset();
      notifyListeners();
    }
  }

  /// Refresh student profile
  ///
  /// Fetches latest profile data from server
  Future<void> refreshProfile() async {
    try {
      await _fetchProfile();
    } catch (e) {
      debugPrint('❌ Profile refresh error: $e');
      _setError(e.toString());
      notifyListeners();
    }
  }

  /// Change password
  ///
  /// [currentPassword] - Current password
  /// [newPassword] - New password
  /// Returns success message
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _clearError();
    notifyListeners();

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
  /// Send forgot password OTP
  Future<void> sendForgotPasswordOtp({required String email}) async {
    try {
      // TODO: Backend endpoint milal ki uncomment kar
      // await _apiService.sendForgotPasswordOtp(email: email);
      await Future.delayed(const Duration(seconds: 1)); // MOCK
      debugPrint('📧 OTP sent to $email (MOCK)');
    } catch (e) {
      debugPrint('❌ Send OTP error: $e');
      rethrow;
    }
  }

  /// Verify forgot password OTP
  Future<void> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    try {
      // TODO: Backend endpoint milal ki uncomment kar
      // await _apiService.verifyForgotPasswordOtp(email: email, otp: otp);
      await Future.delayed(const Duration(seconds: 1)); // MOCK
      debugPrint('✅ OTP verified (MOCK)');
    } catch (e) {
      debugPrint('❌ Verify OTP error: $e');
      rethrow;
    }
  }

  /// Reset password with verified OTP
  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      // TODO: Backend endpoint milal ki uncomment kar
      // await _apiService.resetPassword(
      //   email: email,
      //   otp: otp,
      //   newPassword: newPassword,
      // );
      await Future.delayed(const Duration(seconds: 1)); // MOCK
      debugPrint('🔑 Password reset for $email (MOCK)');
    } catch (e) {
      debugPrint('❌ Reset password error: $e');
      rethrow;
    }
  }

  /// Handle 401 unauthorized error
  ///
  /// Called automatically by API service when 401 is received
  /// Triggers auto-logout
  void handleUnauthorized() {
    debugPrint('🚨 Unauthorized - triggering logout');
    _reset();
    notifyListeners();
  }

  // ==================== PRIVATE METHODS ====================

  /// Fetch student profile from API
  ///
  /// Updates _student and sets status to authenticated
  Future<void> _fetchProfile() async {
    try {
      _student = await _apiService.getProfile();
      _status = AuthStatus.authenticated;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Profile fetch error: $e');

      // If 401, token is invalid
      if (e.toString().contains('401') ||
          e.toString().contains('Session expired')) {
        await _secureStorage.clearAuthToken();
        _status = AuthStatus.unauthenticated;
      } else {
        _status = AuthStatus.error;
        _errorMessage = e.toString();
      }

      notifyListeners();
    }
  }

  /// Reset auth state to unauthenticated
  void _reset() {
    _status = AuthStatus.unauthenticated;
    _student = null;
    _errorMessage = null;
  }

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
