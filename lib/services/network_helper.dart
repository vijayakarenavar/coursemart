/// Network helper utilities
///
/// Provides connectivity checking and network-related utilities
library;

import 'dart:io';

/// Network connectivity checker
///
/// Provides methods to check if device has internet connection
class NetworkHelper {
  /// Check if device is connected to internet
  ///
  /// Returns true if connected, false otherwise
  /// Uses DNS lookup to google.com as connectivity test
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Get network error message based on exception
  ///
  /// [error] - The exception caught
  /// Returns user-friendly error message
  static String getNetworkErrorMessage(dynamic error) {
    if (error is SocketException) {
      return 'No internet connection. Please check your network settings.';
    }
    if (error is HandshakeException) {
      return 'Secure connection failed. Please check your internet security settings.';
    }
    if (error is HttpException) {
      return 'HTTP error occurred. Please try again later.';
    }
    return 'Network error occurred. Please try again.';
  }

  /// Check if error is a network-related error
  ///
  /// [error] - The exception to check
  /// Returns true if it's a network error
  static bool isNetworkError(dynamic error) {
    return error is SocketException ||
        error is HandshakeException ||
        error is HttpException;
  }
}
