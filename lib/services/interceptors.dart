/// Dio interceptors
///
/// Provides request/response interceptors for authentication,
/// logging, error handling, and retry logic.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import 'secure_storage.dart';

/// Authentication Interceptor
///
/// Automatically adds JWT token to request headers
/// Handles 401 Unauthorized errors with auto-logout
class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage;

  AuthInterceptor(this._secureStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get JWT token from secure storage
    final token = await _secureStorage.getAuthToken();

    // Add token to Authorization header if it exists
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Always set content type for JSON requests
    options.headers['Content-Type'] = 'application/json';

    // Add timestamp for cache busting
    options.queryParameters['_t'] = DateTime.now().millisecondsSinceEpoch;

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Log successful responses in debug mode
    if (kDebugMode) {
      if (kDebugMode) debugPrint('✅ [${response.statusCode}] ${response.requestOptions.uri}');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Handle 401 Unauthorized - token expired or invalid
    if (err.response?.statusCode == 401) {
      if (kDebugMode) debugPrint('❌ 401 Unauthorized - Token expired or invalid');

      // Clear token from secure storage
      _secureStorage.clearAuthToken();

      // Note: Navigation to login should be handled in the API service
      // or provider that catches this error
    }

    // Log errors in debug mode
    if (kDebugMode) {
      if (kDebugMode) debugPrint(
        '❌ [${err.response?.statusCode}] ${err.requestOptions.uri}\n'
        'Error: ${err.message}',
      );
    }

    handler.next(err);
  }
}

/// Logging Interceptor
///
/// Logs request/response details in debug mode for debugging
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      if (kDebugMode) debugPrint(
        '🌐 [REQUEST] ${options.method} ${options.uri}\n'
        'Headers: ${options.headers}\n'
        'Data: ${options.data}',
      );
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      if (kDebugMode) debugPrint(
        '📥 [RESPONSE] ${response.statusCode} ${response.requestOptions.uri}\n'
        'Data: ${response.data}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      if (kDebugMode) debugPrint(
        '⚠️ [ERROR] ${err.requestOptions.uri}\n'
        'Type: ${err.type}\n'
        'Message: ${err.message}\n'
        'Response: ${err.response?.data}',
      );
    }
    handler.next(err);
  }
}

/// Retry Interceptor
///
/// Automatically retries failed requests with exponential backoff
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryInterval;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = AppConstants.maxRetryAttempts,
    this.retryInterval = const Duration(seconds: 1),
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Only retry on network errors, not 4xx client errors (except 401)
    final shouldRetry = _shouldRetry(err);

    if (!shouldRetry || err.requestOptions.extra['retries'] != null) {
      handler.next(err);
      return;
    }

    int retries = err.requestOptions.extra['retries'] ?? 0;

    if (retries < maxRetries) {
      retries++;
      err.requestOptions.extra['retries'] = retries;

      // Exponential backoff: 1s, 2s, 4s, ...
      final delay = retryInterval * (1 << (retries - 1));

      if (kDebugMode) {
        if (kDebugMode) debugPrint(
          '🔄 Retrying request ($retries/$maxRetries) after ${delay.inSeconds}s',
        );
      }

      // Wait before retrying
      await Future.delayed(delay);

      try {
        // Clone and retry the request
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        // If retry failed, pass the error
        handler.next(err);
      }
    } else {
      // Max retries reached
      handler.next(err);
    }
  }

  /// Determine if request should be retried
  bool _shouldRetry(DioException err) {
    // Don't retry on client errors (4xx)
    if (err.response?.statusCode != null &&
        err.response!.statusCode! >= 400 &&
        err.response!.statusCode! < 500) {
      return false;
    }

    // Retry on network errors and server errors (5xx)
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError ||
        (err.response?.statusCode != null && err.response!.statusCode! >= 500);
  }
}
