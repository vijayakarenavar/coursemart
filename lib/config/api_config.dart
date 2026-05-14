/// API configuration and constants
///
/// This file contains all API endpoints and configuration constants
/// used throughout the application.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration class
///
/// Provides base URLs and endpoint paths for all API calls
class ApiConfig {
  // Private constructor to prevent instantiation
  ApiConfig._();

  /// Base URL for API requests
  /// Loaded from environment variable API_BASE_URL
  static String get baseUrl {
    return dotenv.get(
      'API_BASE_URL',
      fallback: 'https://course.mart.lemmecode.com/api/v1',
    );
  }

  /// Base URL for media files (images, videos, notes)
  /// Loaded from environment variable MEDIA_BASE_URL
  static String get mediaBaseUrl {
    return dotenv.get(
      'MEDIA_BASE_URL',
      fallback: 'https://course.mart.lemmecode.com',
    );
  }

  // ==================== AUTH ENDPOINTS ====================

  /// Login endpoint - POST
  static const String login = '/auth/login';

  /// Logout endpoint - POST
  static const String logout = '/auth/logout';

  /// Change password endpoint - POST
  static const String changePassword = '/auth/change-password';

  // ==================== STUDENT ENDPOINTS ====================

  /// Get student profile - GET
  static const String profile = '/student/profile';

  /// Get enrolled courses - GET
  static const String courses = '/student/courses';

  /// Get course lectures - GET (append courseId)
  /// Format: /student/courses/{courseId}/lectures
  static const String courseLectures = '/student/courses';

  /// Get lecture details - GET (append lectureId)
  /// Format: /student/lectures/{lectureId}
  static const String lectureDetails = '/student/lectures';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ==================== HELPER METHODS ====================

  /// Build full URL for an endpoint
  ///
  /// [endpoint] - The API endpoint path
  /// Returns complete URL string
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Build lecture list URL for a specific course
  ///
  /// [courseId] - The course ID
  /// Returns complete URL string
  static String buildCourseLecturesUrl(String courseId) {
    return '$baseUrl$courseLectures/$courseId/lectures';
  }

  /// Build lecture details URL for a specific lecture
  ///
  /// [lectureId] - The lecture ID
  /// Returns complete URL string
  static String buildLectureDetailsUrl(String lectureId) {
    return '$baseUrl$lectureDetails/$lectureId';
  }

  /// Build full media URL from relative path
  ///
  /// [relativePath] - The relative path from API response
  /// Returns complete URL string
  static String buildMediaUrl(String relativePath) {
    if (relativePath.startsWith('http')) {
      return relativePath; // Already a full URL
    }
    return '$mediaBaseUrl$relativePath';
  }
}

/// App-wide constants
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// Secure storage key for JWT token
  static String get authTokenKey =>
      dotenv.get('STORAGE_KEY_AUTH_TOKEN', fallback: 'auth_token');

  /// Request timeout duration
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Connection timeout duration
  static const Duration connectionTimeout = Duration(seconds: 15);

  /// Cache duration for courses (30 minutes)
  static const Duration courseCacheDuration = Duration(minutes: 30);

  /// Cache duration for lectures (15 minutes)
  static const Duration lectureCacheDuration = Duration(minutes: 15);

  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// App name
  static const String appName = 'CourseMart';

  /// App version
  static const String appVersion = '1.0.0';
}

/// Video status colors for lecture status badges
class StatusColors {
  /// Video is ready to watch
  static const int ready = 0xFF4CAF50; // Green

  /// Video is being processed
  static const int processing = 0xFFFF9800; // Orange

  /// Video upload failed
  static const int failed = 0xFFF44336; // Red

  /// Video is being uploaded
  static const int uploading = 0xFF2196F3; // Blue

  /// Default/unknown status
  static const int unknown = 0xFF9E9E9E; // Grey
}

/// Course schedule status values
class CourseStatus {
  static const String notStarted = 'not_started';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
}
