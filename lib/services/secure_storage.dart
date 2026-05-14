/// Secure storage service
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class SecureStorage {
  late final FlutterSecureStorage _storage;

  SecureStorage() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
      mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
      wOptions: WindowsOptions(),
    );
  }

  // ==================== AUTH TOKEN ====================

  Future<String?> getAuthToken() async {
    try {
      return await _storage.read(key: AppConstants.authTokenKey);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: AppConstants.authTokenKey, value: token);
  }

  Future<void> clearAuthToken() async {
    await _storage.delete(key: AppConstants.authTokenKey);
  }

  // ==================== ✅ CREDENTIALS (WebView auto-login साठी) ====================

  Future<void> saveCredentials({required String email, required String password}) async {
    await _storage.write(key: 'user_email', value: email);
    await _storage.write(key: 'user_password', value: password);
  }

  Future<String?> getSavedEmail() async {
    try { return await _storage.read(key: 'user_email'); } catch (e) { return null; }
  }

  Future<String?> getSavedPassword() async {
    try { return await _storage.read(key: 'user_password'); } catch (e) { return null; }
  }

  Future<void> clearCredentials() async {
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_password');
  }

  // ==================== GENERIC STORAGE ====================

  Future<String?> read(String key) async {
    try { return await _storage.read(key: key); } catch (e) { return null; }
  }

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  Future<bool> containsKey(String key) async {
    final value = await _storage.read(key: key);
    return value != null;
  }
}