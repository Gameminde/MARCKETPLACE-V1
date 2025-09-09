import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';

/// Secure storage service for sensitive data
/// Uses Flutter Secure Storage with encryption
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false,
    ),
  );

  // Auth token storage
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<String?> getAuthToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: 'refresh_token', value: token);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
  }

  static Future<void> saveTokenExpiry(DateTime expiry) async {
    await _storage.write(key: 'token_expiry', value: expiry.toIso8601String());
  }

  static Future<DateTime?> getTokenExpiry() async {
    final expiryString = await _storage.read(key: 'token_expiry');
    if (expiryString != null) {
      return DateTime.tryParse(expiryString);
    }
    return null;
  }

  // User data storage
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: 'user_id', value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  static Future<void> saveUserEmail(String email) async {
    await _storage.write(key: 'user_email', value: email);
  }

  static Future<String?> getUserEmail() async {
    return await _storage.read(key: 'user_email');
  }

  // Password hashing for local validation
  static String hashPassword(String password, {String? salt}) {
    final actualSalt = salt ?? generateSalt();
    final bytes = utf8.encode(password + actualSalt);
    final digest = sha256.convert(bytes);
    return '$actualSalt:${digest.toString()}';
  }

  static String generateSalt() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(values);
  }

  static bool verifyPassword(String password, String hashedPassword) {
    final parts = hashedPassword.split(':');
    if (parts.length != 2) return false;

    final salt = parts[0];
    final hash = parts[1];
    final computedHash = hashPassword(password, salt: salt).split(':')[1];

    return hash == computedHash;
  }

  // Biometric authentication
  static Future<void> saveBiometricEnabled(bool enabled) async {
    await _storage.write(key: 'biometric_enabled', value: enabled.toString());
  }

  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: 'biometric_enabled');
    return value == 'true';
  }

  // MFA settings
  static Future<void> saveMfaSecret(String secret) async {
    await _storage.write(key: 'mfa_secret', value: secret);
  }

  static Future<String?> getMfaSecret() async {
    return await _storage.read(key: 'mfa_secret');
  }

  static Future<void> saveMfaEnabled(bool enabled) async {
    await _storage.write(key: 'mfa_enabled', value: enabled.toString());
  }

  static Future<bool> isMfaEnabled() async {
    final value = await _storage.read(key: 'mfa_enabled');
    return value == 'true';
  }

  // Payment methods (encrypted)
  static Future<void> savePaymentMethod(
      Map<String, dynamic> paymentMethod) async {
    final encrypted = await _encryptData(jsonEncode(paymentMethod));
    await _storage.write(key: 'payment_methods', value: encrypted);
  }

  static Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final encrypted = await _storage.read(key: 'payment_methods');
    if (encrypted == null) return [];

    try {
      final decrypted = await _decryptData(encrypted);
      final List<dynamic> methods = jsonDecode(decrypted);
      return methods.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // Addresses (encrypted)
  static Future<void> saveAddresses(
      List<Map<String, dynamic>> addresses) async {
    final encrypted = await _encryptData(jsonEncode(addresses));
    await _storage.write(key: 'addresses', value: encrypted);
  }

  static Future<List<Map<String, dynamic>>> getAddresses() async {
    final encrypted = await _storage.read(key: 'addresses');
    if (encrypted == null) return [];

    try {
      final decrypted = await _decryptData(encrypted);
      final List<dynamic> addresses = jsonDecode(decrypted);
      return addresses.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // App preferences
  static Future<void> saveThemeMode(String mode) async {
    await _storage.write(key: 'theme_mode', value: mode);
  }

  static Future<String?> getThemeMode() async {
    return await _storage.read(key: 'theme_mode');
  }

  static Future<void> saveLanguage(String language) async {
    await _storage.write(key: 'language', value: language);
  }

  static Future<String?> getLanguage() async {
    return await _storage.read(key: 'language');
  }

  static Future<void> saveNotificationSettings(
      Map<String, dynamic> settings) async {
    final encrypted = await _encryptData(jsonEncode(settings));
    await _storage.write(key: 'notification_settings', value: encrypted);
  }

  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final encrypted = await _storage.read(key: 'notification_settings');
    if (encrypted == null) return {};

    try {
      final decrypted = await _decryptData(encrypted);
      return Map<String, dynamic>.from(jsonDecode(decrypted));
    } catch (e) {
      return {};
    }
  }

  // Clear all sensitive data
  static Future<void> clearSecureData() async {
    await _storage.deleteAll();
  }

  static Future<void> clearAuthData() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'token_expiry');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_email');
  }

  // Encryption/Decryption helpers
  static Future<String> _encryptData(String data) async {
    // In a real app, use proper encryption like AES
    // For now, we'll use base64 encoding as a placeholder
    final bytes = utf8.encode(data);
    return base64.encode(bytes);
  }

  static Future<String> _decryptData(String encryptedData) async {
    // In a real app, use proper decryption
    // For now, we'll decode base64
    final bytes = base64.decode(encryptedData);
    return utf8.decode(bytes);
  }

  // Check if secure storage is available
  static Future<bool> isAvailable() async {
    try {
      await _storage.containsKey(key: 'test_key');
      return true;
    } catch (e) {
      return false;
    }
  }
}
