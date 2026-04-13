/// Error handling utilities
///
/// Provides centralized error handling and display
/// for API errors, network errors, and validation.
///
/// ✅ Snackbars आता AppDialogs वापरतात — theme consistent राहतो.
/// बाकी files मध्ये काहीही बदल नाही करायला लागत.
library;

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/network_helper.dart';
import '../services/api_service.dart'; // ApiException साठी
import 'app_dialogs.dart'; // ⬅️ हे एकच import add केले

// ─────────────────────────────────────────────────────────────
// SNACKBAR HELPERS
// हे functions तसेच आहेत — आत फक्त AppDialogs वापरतो
// त्यामुळे login_screen, change_password_screen — सगळे
// आपोआप नवीन themed snackbars दाखवतील
// ─────────────────────────────────────────────────────────────

/// ❌ Error snackbar — persistent, X button ने dismiss
///
/// AppColors.red + light border
/// duration parameter आता ignore होतो (AppDialogs handle करतो)
void showErrorSnackBar(
    BuildContext context,
    String message, {
      Duration duration = const Duration(seconds: 4), // backward compat साठी ठेवला
    }) {
  AppDialogs.showError(context, message);
}

/// ✅ Success snackbar — 2.5s auto dismiss, no X button
///
/// AppColors.primary navy + cyan border
void showSuccessSnackBar(
    BuildContext context,
    String message, {
      Duration duration = const Duration(seconds: 3), // backward compat साठी ठेवला
    }) {
  AppDialogs.showSuccess(context, message);
}

/// ℹ️ Info snackbar — 3s auto dismiss
///
/// AppColors.primaryLight + cyan border
void showInfoSnackBar(
    BuildContext context,
    String message, {
      Duration duration = const Duration(seconds: 3), // backward compat साठी ठेवला
    }) {
  AppDialogs.showInfo(context, message);
}

// ─────────────────────────────────────────────────────────────
// ERROR MESSAGE EXTRACTOR — हे बदलले नाही
// ─────────────────────────────────────────────────────────────

/// Exception मधून user-friendly message काढा
///
/// [error] - Exception किंवा error object
/// Returns user-friendly string
String getErrorMessage(dynamic error) {
  // ApiException — clean message directly वापरा, raw toString() नको
  if (error is ApiException) {
    return error.message;
  }

  // Network errors
  if (NetworkHelper.isNetworkError(error)) {
    return NetworkHelper.getNetworkErrorMessage(error);
  }

  // Dio errors
  if (error is DioException) {
    return _getDioErrorMessage(error);
  }

  // String errors
  if (error is String) {
    return error;
  }

  // Generic
  return error?.toString() ?? 'An unexpected error occurred';
}

/// DioException मधून message काढा
String _getDioErrorMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return 'Connection timed out. Please check your internet connection.';
    case DioExceptionType.sendTimeout:
      return 'Request timed out. Please try again.';
    case DioExceptionType.receiveTimeout:
      return 'Server response timed out. Please try again.';
    case DioExceptionType.badResponse:
      switch (error.response?.statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 401:
          return 'Session expired. Please login again.';
        case 403:
          return 'You don\'t have permission to access this resource.';
        case 404:
          return 'Resource not found.';
        case 500:
          return 'Server error. Please try again later.';
        default:
          return 'Request failed (${error.response?.statusCode})';
      }
    case DioExceptionType.cancel:
      return 'Request was cancelled.';
    case DioExceptionType.connectionError:
      return 'No internet connection. Please check your network settings.';
    case DioExceptionType.unknown:
    default:
      return error.message ?? 'An unexpected error occurred';
  }
}

// ─────────────────────────────────────────────────────────────
// ERROR DIALOG — AppDialogs कडे redirect
// ─────────────────────────────────────────────────────────────

/// Error dialog दाखवा — AppDialogs थीम वापरतो
///
/// जुना signature तसाच ठेवला — कुठेही break होणार नाही
Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message,
    ) async {
  if (!context.mounted) return;
  await AppDialogs.showErrorDialog(
    context,
    title: title,
    message: message,
  );
}

// ─────────────────────────────────────────────────────────────
// VALIDATION HELPERS — हे बदलले नाहीत
// ─────────────────────────────────────────────────────────────

/// Form validation helpers
class ValidationHelper {
  /// Email format validate करा
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Password strength validate करा
  static bool isStrongPassword(String password) {
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  /// Email validation error message
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!isValidEmail(value)) return 'Please enter a valid email';
    return null;
  }

  /// Password validation error message
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  /// Confirm password validation error message
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }
}