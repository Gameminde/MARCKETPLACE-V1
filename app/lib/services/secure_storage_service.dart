import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

/// Secure storage service with token integrity validation
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // Keys for secure storage
  static const String _authTokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _tokenHashKey = 'token_hash';

  /// Store authentication token with integrity check
  Future<void> storeAuthToken(String token) async {
    try {
      // Generate hash for integrity verification
      final tokenHash = _generateHash(token);
      
      await Future.wait([
        _storage.write(key: _authTokenKey, value: token),
        _storage.write(key: _tokenHashKey, value: tokenHash),
      ]);
    } catch (e) {
      throw SecureStorageException('Failed to store auth token: $e');
    }
  }

  /// Retrieve authentication token with integrity verification
  Future<String?> getAuthToken() async {
    try {
      final token = await _storage.read(key: _authTokenKey);
      final storedHash = await _storage.read(key: _tokenHashKey);
      
      if (token == null) return null;
      
      // Verify token integrity
      if (storedHash != null) {
        final currentHash = _generateHash(token);
        if (currentHash != storedHash) {
          // Token has been tampered with, clear it
          await clearAuthData();
          return null;
        }
      }
      
      return token;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve auth token: $e');
    }
  }

  /// Store refresh token
  Future<void> storeRefreshToken(String refreshToken) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } catch (e) {
      throw SecureStorageException('Failed to store refresh token: $e');
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve refresh token: $e');
    }
  }

  /// Store user data securely
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      final jsonString = jsonEncode(userData);
      await _storage.write(key: _userDataKey, value: jsonString);
    } catch (e) {
      throw SecureStorageException('Failed to store user data: $e');
    }
  }

  /// Retrieve user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final jsonString = await _storage.read(key: _userDataKey);
      if (jsonString == null) return null;
      
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve user data: $e');
    }
  }

  /// Check if user is authenticated (has valid token)
  Future<bool> isAuthenticated() async {
    try {
      final token = await getAuthToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    try {
      await Future.wait([
        _storage.delete(key: _authTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _userDataKey),
        _storage.delete(key: _tokenHashKey),
      ]);
    } catch (e) {
      throw SecureStorageException('Failed to clear auth data: $e');
    }
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to clear all data: $e');
    }
  }

  /// Store generic secure data
  Future<void> storeSecureData(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to store secure data: $e');
    }
  }

  /// Retrieve generic secure data
  Future<String?> getSecureData(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve secure data: $e');
    }
  }

  /// Delete specific secure data
  Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete secure data: $e');
    }
  }

  /// Generate SHA-256 hash for integrity verification
  String _generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if secure storage is available
  Future<bool> isAvailable() async {
    try {
      await _storage.containsKey(key: 'test_key');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all stored keys (for debugging purposes only)
  Future<Map<String, String>> getAllData() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw SecureStorageException('Failed to read all data: $e');
    }
  }
}

/// Custom exception for secure storage operations
class SecureStorageException implements Exception {
  final String message;
  
  SecureStorageException(this.message);
  
  @override
  String toString() => 'SecureStorageException: $message';
}