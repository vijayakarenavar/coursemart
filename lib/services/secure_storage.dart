/// Secure storage service
///
/// Handles secure storage of JWT token and other sensitive data
/// using flutter_secure_storage package.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

/// Secure Storage Service
///
/// Provides secure storage for JWT tokens and sensitive data
/// Uses platform-specific secure storage (Keychain for iOS,
/// KeyStore for Android, Credential Manager for Windows)
class SecureStorage {
  late final FlutterSecureStorage _storage;

  /// Initialize secure storage with platform-specific options
  SecureStorage() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true, // Use encrypted preferences
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
      wOptions: WindowsOptions(),
    );
  }

  // ==================== AUTH TOKEN ====================

  /// Get JWT authentication token from secure storage
  ///
  /// Returns null if token doesn't exist
  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: AppConstants.authTokenKey);
    } catch (e) {
      // Return null if reading fails
      return null;
    }
  }

  /// Save JWT authentication token to secure storage
  ///
  /// [token] - The JWT token to store
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: AppConstants.authTokenKey, value: token);
  }

  /// Clear authentication token from secure storage
  ///
  /// Called on logout or when token is invalid
  Future<void> clearAuthToken() async {
    await _storage.delete(key: AppConstants.authTokenKey);
  }

  // ==================== GENERIC STORAGE ====================

  /// Read a value from secure storage
  ///
  /// [key] - The key to read
  /// Returns value or null if not found
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      return null;
    }
  }

  /// Write a value to secure storage
  ///
  /// [key] - The key to store under
  /// [value] - The value to store
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Delete a value from secure storage
  ///
  /// [key] - The key to delete
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Delete all values from secure storage
  ///
  /// ⚠️ Use with caution - clears ALL stored data
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists in secure storage
  ///
  /// [key] - The key to check
  /// Returns true if key exists
  Future<bool> containsKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }
}
