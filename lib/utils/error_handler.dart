/// Error handling utilities
///
/// Provides centralized error handling and display
/// for API errors, network errors, and validation.
///
/// ✅ Snackbars आता AppDialogs वापरतात — theme consistent राहतो.
/// ✅ ApiException(null) / raw exception strings user ला दिसत नाहीत.
library;

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/network_helper.dart';
import '../services/api_service.dart';
import 'app_dialogs.dart';

// ─────────────────────────────────────────────────────────────
// SNACKBAR HELPERS
// ─────────────────────────────────────────────────────────────

/// ❌ Error snackbar — persistent, X button ने dismiss
void showErrorSnackBar(
    BuildContext context,
    String message, {
      Duration duration = const Duration(seconds: 4),
    }) {
  AppDialogs.showError(context, message);
}

/// ✅ Success snackbar — 2.5s auto dismiss, no X button
void showSuccessSnackBar(
    BuildContext context,
    String message, {
      Duration duration = const Duration(seconds: 3),
    }) {
  AppDialogs.showSuccess(context, message);
}

/// ℹ️ Info snackbar — 3s auto dismiss
void showInfoSnackBar(
    BuildContext context,
    String message, {
      Duration duration = const Duration(seconds: 3),
    }) {
  AppDialogs.showInfo(context, message);
}

// ─────────────────────────────────────────────────────────────
// ERROR MESSAGE EXTRACTOR
// ─────────────────────────────────────────────────────────────

/// Exception मधून user-friendly message काढा.
/// कोणताही raw/technical string user ला दिसणार नाही.
String getErrorMessage(dynamic error) {
  // 1. ApiException — message null/empty/technical असू शकतो
  if (error is ApiException) {
    final msg = error.message.trim();

    // message रिकामा असेल तर status code वरून fallback द्या
    if (msg.isEmpty) {
      return _fallbackForStatusCode(error.statusCode);
    }

    final cleaned = _cleanApiMessage(msg);

    // cleaned message तरीपण technical असेल तर status code वापरा
    if (cleaned == msg && _isTechnicalString(msg)) {
      return _fallbackForStatusCode(error.statusCode);
    }

    return cleaned;
  }

  // 2. Network error (no internet)
  if (NetworkHelper.isNetworkError(error)) {
    return 'No internet connection. Please check your network.';
  }

  // 3. DioException
  if (error is DioException) {
    return _getDioErrorMessage(error);
  }

  // 4. Plain string — technical असेल तर clean करा
  if (error is String) {
    final trimmed = error.trim();
    if (trimmed.isEmpty) return 'Something went wrong. Please try again.';
    if (_isTechnicalString(trimmed)) return 'Something went wrong. Please try again.';
    return _cleanApiMessage(trimmed);
  }

  // 5. कोणताही unknown error — toString() कधीही user ला दाखवू नये
  return 'Something went wrong. Please try again.';
}

/// String technical/raw आहे का हे check करा
bool _isTechnicalString(String msg) {
  final lower = msg.toLowerCase();
  return lower.startsWith('apiexception') ||
      lower.startsWith('dioexception') ||
      lower.startsWith('socketexception') ||
      lower.contains('apiexception(') ||
      lower.contains('exception:') ||
      lower.contains('stack trace') ||
      lower.contains('null check') ||
      lower.contains('type \'') ||
      lower.contains('is not a subtype') ||
      lower.contains('_internal') ||
      lower.contains('package:');
}

/// Status code वरून user-friendly fallback message
String _fallbackForStatusCode(int? statusCode) {
  switch (statusCode) {
    case 400:
      return 'Invalid details. Please check and try again.';
    case 401:
      return 'Your session has expired. Please login again.';
    case 403:
      return 'You don\'t have permission to access this.';
    case 404:
      return 'Information not found.';
    case 408:
      return 'Request timed out. Please try again.';
    case 422:
      return 'Invalid data submitted. Please check and try again.';
    case 429:
      return 'Too many requests. Please wait and try again.';
    case 500:
    case 502:
    case 503:
    case 504:
      return 'Server issue. Please try again later.';
    default:
      return 'Something went wrong. Please try again.';
  }
}

/// API message clean करा — technical jargon काढा
String _cleanApiMessage(String message) {
  final lower = message.toLowerCase();

  // ── Raw exception strings ── कधीही user ला दाखवू नये
  if (lower.startsWith('apiexception') ||
      lower.startsWith('dioexception') ||
      lower.startsWith('socketexception') ||
      lower.contains('apiexception(') ||
      lower.contains('exception:') ||
      lower.contains('connection errored') ||
      lower.contains('failed host lookup') ||
      lower.contains('handshake') ||
      lower.contains('this indicates an error') ||
      lower.contains('null check operator')) {
    return 'Something went wrong. Please try again.';
  }

  // ── Network / connection errors ──
  if (lower.contains('no internet') ||
      lower.contains('network error') ||
      lower.contains('failed to load') ||
      lower.contains('could not connect')) {
    return 'No internet connection. Please check your network and try again.';
  }

  // ── Timeout ──
  if (lower.contains('timeout') || lower.contains('timed out')) {
    return 'Slow network. Please try again.';
  }

  // ── Session / auth ──
  if (lower.contains('session expired') ||
      lower.contains('login again') ||
      lower.contains('unauthorized') ||
      lower.contains('unauthenticated')) {
    return 'Your session has expired. Please login again.';
  }

  // ── Credentials ──
  if (lower.contains('invalid') && lower.contains('password')) {
    return 'Incorrect email or password. Please try again.';
  }
  if (lower.contains('invalid') && lower.contains('email')) {
    return 'Please enter a valid email address.';
  }
  if (lower.contains('invalid') &&
      (lower.contains('credential') || lower.contains('login'))) {
    return 'Incorrect email or password. Please try again.';
  }

  // ── Not found ──
  if (lower.contains('not found')) {
    return 'Information not found. Please try again.';
  }

  // ── Permission ──
  if (lower.contains('permission') ||
      lower.contains('access denied') ||
      lower.contains('forbidden')) {
    return 'You don\'t have permission to view this.';
  }

  // ── Server errors ──
  if (lower.contains('server error') ||
      lower.contains('internal server') ||
      lower.contains('service unavailable')) {
    return 'Server issue. Please try again later.';
  }

  // ── Server message clean असेल तर तसाच दाखवा ──
  return message;
}

/// DioException मधून user-friendly message काढा
String _getDioErrorMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Slow network. Please try again.';

    case DioExceptionType.connectionError:
      return 'No internet connection. Please check your network.';

    case DioExceptionType.badResponse:
    // Server कडून response आला — status code वापरा
      final serverMsg = _extractServerMessage(error.response?.data);
      if (serverMsg != null && serverMsg.isNotEmpty) {
        return _cleanApiMessage(serverMsg);
      }
      return _fallbackForStatusCode(error.response?.statusCode);

    case DioExceptionType.cancel:
      return 'Request cancelled. Please try again.';

    default:
      return 'Something went wrong. Please try again.';
  }
}

/// Response body मधून server message काढा
String? _extractServerMessage(dynamic data) {
  if (data is Map<String, dynamic>) {
    final msg = data['message'] ?? data['error'] ?? data['errorMessage'];
    if (msg is String && msg.trim().isNotEmpty) return msg.trim();
  }
  return null;
}

// ─────────────────────────────────────────────────────────────
// ERROR DIALOG
// ─────────────────────────────────────────────────────────────

/// Error dialog दाखवा — AppDialogs थीम वापरतो
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
// VALIDATION HELPERS
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
    if (!isValidEmail(value)) return 'Please enter a valid email address';
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