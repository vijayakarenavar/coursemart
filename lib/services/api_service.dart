/// Main API Service
///
/// Central service for all API calls including authentication,
/// student profile, courses, and lectures.
/// Uses Dio HTTP client with interceptors for auth, logging, and retry.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/lecture.dart';
import 'secure_storage.dart';
import 'interceptors.dart';

/// API Service class
///
/// Provides all API methods for the CourseMart app
/// Uses singleton pattern to maintain single Dio instance
class ApiService {
  // Private constructor for singleton
  ApiService._internal();

  /// Singleton instance
  static final ApiService _instance = ApiService._internal();

  /// Get singleton instance
  factory ApiService() => _instance;

  /// Dio HTTP client
  late final Dio _dio;

  /// Secure storage for token management
  final SecureStorage _secureStorage = SecureStorage();

  /// Callback for 401 unauthorized errors
  /// Used to trigger auto-logout
  Function()? onUnauthorized;

  /// Initialize Dio with interceptors
  ///
  /// Call this in app initialization or before first API call
  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        sendTimeout: AppConstants.requestTimeout,
        validateStatus: (status) {
          // Accept all status codes to handle them manually
          return status != null;
        },
      ),
    );

    // Add interceptors
    _dio.interceptors.add(AuthInterceptor(_secureStorage)); // Auth headers
    _dio.interceptors.add(LoggingInterceptor()); // Debug logging

    // Add retry interceptor (must be last to retry after other interceptors)
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }

  // ==================== AUTH APIs ====================

  /// Login student
  ///
  /// [email] - Student email
  /// [password] - Student password
  /// Returns map with token and user data
  ///
  /// Example response:
  /// {
  ///   "token": "eyJhbGci...",
  ///   "user": { "id": "...", "name": "...", "email": "..." }
  /// }
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Save token to secure storage
        final token = data['token'] as String?;
        if (token != null) {
          await _secureStorage.saveAuthToken(token);
          debugPrint('✅ Token saved to secure storage');
        }

        return data;
      } else {
        // Handle error response
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Login failed',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error during login',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Logout student
  ///
  /// Clears token from secure storage
  /// Calls server logout endpoint if token exists
  Future<void> logout() async {
    try {
      // Check if token exists before calling server
      final token = await _secureStorage.getAuthToken();
      if (token != null) {
        final response = await _dio.post(ApiConfig.logout);

        if (response.statusCode != 200) {
          debugPrint('⚠️ Server logout failed, but clearing local token');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    } finally {
      // Always clear local token
      await _secureStorage.clearAuthToken();
      debugPrint('🗑️ Token cleared from secure storage');
    }
  }

  /// Change student password
  ///
  /// [currentPassword] - Current password
  /// [newPassword] - New password
  /// Returns success message
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiConfig.changePassword,
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['message'] ?? 'Password changed successfully';
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Failed to change password',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: e.message ?? 'Network error during password change',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ==================== STUDENT APIs ====================

  /// Get student profile
  ///
  /// Returns Student model with profile information
  /// Used to validate token and display user info
  Future<Student> getProfile() async {
    try {
      final response = await _dio.get(ApiConfig.profile);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final studentData = data['student'] as Map<String, dynamic>?;

        if (studentData != null) {
          return Student.fromJson(studentData);
        } else {
          throw const ApiException(message: 'Invalid profile data from server');
        }
      } else if (response.statusCode == 401) {
        // Token invalid - trigger logout
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Failed to load profile',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      }
      throw ApiException(
        message: e.message ?? 'Network error during profile fetch',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get enrolled courses
  ///
  /// Returns list of Course models
  /// Shows all courses the student is enrolled in
  Future<List<Course>> getCourses() async {
    try {
      final response = await _dio.get(ApiConfig.courses);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final coursesData = data['courses'] as List<dynamic>?;

        if (coursesData != null) {
          return coursesData
              .map((courseJson) => Course.fromJson(courseJson))
              .toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Failed to load courses',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      }
      throw ApiException(
        message: e.message ?? 'Network error during course fetch',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get lectures for a specific course
  ///
  /// [courseId] - The course ID
  /// Returns list of Lecture models
  Future<List<Lecture>> getCourseLectures(String courseId) async {
    try {
      final url = ApiConfig.buildCourseLecturesUrl(courseId);
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final lecturesData = data['lectures'] as List<dynamic>?;

        if (lecturesData != null) {
          return lecturesData
              .map((lectureJson) => Lecture.fromJson(lectureJson))
              .toList();
        } else {
          return [];
        }
      } else if (response.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Failed to load lectures',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      }
      throw ApiException(
        message: e.message ?? 'Network error during lecture fetch',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get lecture details (video + notes)
  ///
  /// [lectureId] - The lecture ID
  /// Returns Lecture model with video and notes data
  Future<Lecture> getLectureDetails(String lectureId) async {
    try {
      final url = ApiConfig.buildLectureDetailsUrl(lectureId);
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final lectureData = data['lecture'] as Map<String, dynamic>?;

        if (lectureData != null) {
          return Lecture.fromJson(lectureData);
        } else {
          throw const ApiException(message: 'Invalid lecture data from server');
        }
      } else if (response.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Failed to load lecture details',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Session expired. Please login again.',
          statusCode: 401,
        );
      }
      throw ApiException(
        message: e.message ?? 'Network error during lecture details fetch',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Extract error message from API response
  ///
  /// [data] - Response data (may be Map or other types)
  /// Returns error message or null
  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Try common error message fields
      return data['message'] ?? data['error'] ?? data['errorMessage'];
    }
    return null;
  }

  /// Check if user is authenticated (has valid token)
  ///
  /// Returns true if token exists in secure storage
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Get Dio instance for custom requests
  ///
  /// Useful for file downloads or special requests
  Dio get dio => _dio;
}

/// Custom API Exception
///
/// Provides detailed error information for API failures
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final StackTrace? stackTrace;

  const ApiException({required this.message, this.statusCode, this.stackTrace});

  @override
  String toString() {
    return 'ApiException($statusCode): $message';
  }
}
