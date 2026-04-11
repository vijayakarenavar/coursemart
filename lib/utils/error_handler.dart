/// Error handling utilities
///
/// Provides centralized error handling and display
/// for API errors, network errors, and validation.
library;

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/network_helper.dart';

/// Show error snackbar
///
/// Displays an error message as a snackbar
void showErrorSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red[700],
      behavior: SnackBarBehavior.floating,
      duration: duration,
      action: SnackBarAction(
        label: 'Dismiss',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    ),
  );
}

/// Show success snackbar
///
/// Displays a success message as a snackbar
void showSuccessSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.green[700],
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ),
  );
}

/// Show info snackbar
///
/// Displays an info message as a snackbar
void showInfoSnackBar(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 3),
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.blue[700],
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ),
  );
}

/// Extract user-friendly error message from exception
///
/// [error] - The exception or error object
/// Returns a user-friendly error message
String getErrorMessage(dynamic error) {
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

  // Generic error
  return error?.toString() ?? 'An unexpected error occurred';
}

/// Extract error message from DioException
///
/// [error] - The DioException
/// Returns user-friendly error message
String _getDioErrorMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
      return 'Connection timed out. Please check your internet connection.';
    case DioExceptionType.sendTimeout:
      return 'Request timed out. Please try again.';
    case DioExceptionType.receiveTimeout:
      return 'Server response timed out. Please try again.';
    case DioExceptionType.badResponse:
      // HTTP status code errors
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
          return 'Request failed (Status: ${error.response?.statusCode})';
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

/// Show error dialog
///
/// Displays an error message as a dialog
Future<void> showErrorDialog(
  BuildContext context,
  String title,
  String message,
) async {
  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Validation helpers
class ValidationHelper {
  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  static bool isStrongPassword(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    final passwordRegex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$',
    );
    return passwordRegex.hasMatch(password);
  }

  /// Get email validation error message
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Get password validation error message
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  /// Get confirm password validation error message
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
