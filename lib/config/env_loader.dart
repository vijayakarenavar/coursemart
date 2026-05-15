/// Environment variable loader
/// This file handles loading and validating environment variables from .env file
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Loads environment variables from .env file
///
/// This function should be called before runApp() in main.dart
/// It will load the .env file and make variables available via dotenv.get()
Future<void> loadEnvironment() async {
  try {
    // Load .env file - filename defaults to '.env'
    await dotenv.load(fileName: '.env');

    // Log environment for debugging (only in debug mode)
    assert(() {
      print(
        '🔧 Environment loaded: ${dotenv.get('APP_ENV', fallback: 'development')}',
      );
      print(
        '🌐 API Base URL: ${dotenv.get('API_BASE_URL', fallback: 'http://localhost:8000/api/v1')}',
      );
      print(
        '📦 Media Base URL: ${dotenv.get('MEDIA_BASE_URL', fallback: 'http://localhost:8000')}',
      );
      return true;
    }());
  } catch (e) {
    if (kDebugMode) {
      print(
        '⚠️ Warning: .env file not found, using defaults. Create .env from .env.example',
      );
    }
  }
}



/// Get environment variable with fallback
///
/// [key] - The environment variable key
/// [fallback] - Default value if key is not found
String getEnvVar(String key, {String fallback = ''}) {
  return dotenv.get(key, fallback: fallback);
}

/// Check if app is in production mode
bool isProduction() {
  return dotenv.get('APP_ENV', fallback: 'development') == 'production';
}

/// Check if app is in development mode
bool isDevelopment() {
  return !isProduction();
}
