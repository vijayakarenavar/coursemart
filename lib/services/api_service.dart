/// Main API Service
///
/// Central service for all API calls including authentication,
/// student profile, courses, and lectures.
/// Uses Dio HTTP client with interceptors for auth, logging, and retry.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../models/certificate.dart';
import '../models/exam_history.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/lecture.dart';
import 'secure_storage.dart';
import 'interceptors.dart';

/// API Service class
class ApiService {
  ApiService._internal();

  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  late final Dio _dio;

  final SecureStorage _secureStorage = SecureStorage();

  Function()? onUnauthorized;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: AppConstants.connectionTimeout,
        receiveTimeout: AppConstants.requestTimeout,
        sendTimeout: AppConstants.requestTimeout,
        validateStatus: (status) {
          return status != null;
        },
      ),
    );

    _dio.interceptors.add(AuthInterceptor(_secureStorage));
    _dio.interceptors.add(LoggingInterceptor());
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
  }

  // ==================== AUTH APIs ====================

  /// Login student
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

        final token = data['token'] as String?;
        if (token != null) {
          await _secureStorage.saveAuthToken(token);
          debugPrint('✅ Token saved to secure storage');
        }

        return data;
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Login failed. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: 'Could not login. Please check your internet and try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Logout student
  Future<void> logout() async {
    try {
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
      await _secureStorage.clearAuthToken();
      debugPrint('🗑️ Token cleared from secure storage');
    }
  }

  /// Change student password
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
          message: message ?? 'Could not change password. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: 'Could not change password. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ==================== FORGOT PASSWORD APIs ====================

  /// Send forgot password request — returns reset token
  Future<String?> forgotPassword({required String email}) async {
    try {
      final response = await _dio.post(
        ApiConfig.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('🔍 Forgot Password Response: $data');

        final token = data['resetToken'];

        // Production: token null/undefined — email गेली
        if (token == null || token == 'undefined') return null;

        // Development: token directly मिळतो
        return token as String;
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Could not send reset link. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: 'Could not send reset link. Please check your internet.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Reset password using token from forgot password
  Future<void> resetPasswordWithToken({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '${ApiConfig.resetPassword}/$token',
        data: {'newPassword': newPassword},
      );

      if (response.statusCode == 200) {
        return;
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Could not reset password. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        message: 'Could not reset password. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }
  // ==================== STUDENT APIs ====================

  /// Get student profile
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
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Your session has expired. Please login again.',
          statusCode: 401,
        );
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Could not load profile. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Your session has expired. Please login again.',
          statusCode: 401,
        );
      }
      throw ApiException(
        message: 'Could not load profile. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get enrolled courses
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
          message: 'Your session has expired. Please login again.',
          statusCode: 401,
        );
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Could not load courses. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Your session has expired. Please login again.',
          statusCode: 401,
        );
      }
      throw ApiException(
        message: 'Could not load courses. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get lectures for a specific course
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
          message: 'Your session has expired. Please login again.',
          statusCode: 401,
        );
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Could not load lectures. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Your session has expired. Please login again.',
          statusCode: 401,
        );
      }
      throw ApiException(
        message: 'Could not load lectures. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get lecture details (video + notes)
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
          message: 'Your session has expired. Please login again.',
          statusCode: 401,
        );
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
          message: message ?? 'Could not load video. Please try again.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
          message: 'Your session has expired. Please login again.',
          statusCode: 401,
        );
      }
      throw ApiException(
        message: 'Could not load video. Please try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ==================== CERTIFICATE APIs ====================

  /// Get all certificates
  Future<List<Certificate>> getCertificates() async {
    try {
      final response = await _dio.get('/student/certificates');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final certsData = data['certificates'] as List<dynamic>?;
        return certsData
            ?.map((c) => Certificate.fromJson(c))
            .toList() ??
            [];
      } else if (response.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
            message: 'Your session has expired. Please login again.',
            statusCode: 401);
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
            message: message ?? 'Could not load certificates. Please try again.',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(
          message: 'Could not load certificates. Please try again.',
          statusCode: e.response?.statusCode);
    }
  }

  /// Get certificate by ID
  Future<Certificate> getCertificateById(String certId) async {
    try {
      final response = await _dio.get('/student/certificates/$certId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final certData = data['certificate'] as Map<String, dynamic>?;
        if (certData != null) return Certificate.fromJson(certData);
        throw const ApiException(message: 'Invalid certificate data');
      } else if (response.statusCode == 401) {
        await _secureStorage.clearAuthToken();
        onUnauthorized?.call();
        throw const ApiException(
            message: 'Your session has expired. Please login again.',
            statusCode: 401);
      } else {
        final message = _extractErrorMessage(response.data);
        throw ApiException(
            message: message ?? 'Could not load certificate. Please try again.',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      throw ApiException(
          message: 'Could not load certificate. Please try again.',
          statusCode: e.response?.statusCode);
    }
  }

  /// GET /api/v1/student/exam/history
  Future<List<ExamHistory>> getExamHistory() async {
    try {
      final response = await _dio.get('/student/exam/history');
      final data = response.data as Map<String, dynamic>;

      final rawList = data['attempts'] as List<dynamic>?;
      if (rawList == null || rawList.isEmpty) return [];

      return rawList
          .map((e) => ExamHistory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ getExamHistory: ${e.response?.statusCode} ${e.message}');
      throw Exception('Could not load exam history. Please try again.');
    } catch (e) {
      debugPrint('❌ getExamHistory unexpected: $e');
      throw Exception('Something went wrong. Please try again.');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Extract error message from API response
  String? _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] ?? data['error'] ?? data['errorMessage'];
    }
    return null;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _secureStorage.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Get Dio instance for custom requests
  Dio get dio => _dio;
}

/// Custom API Exception
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