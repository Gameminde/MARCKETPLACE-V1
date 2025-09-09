import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureConfigService {
  static final SecureConfigService _instance = SecureConfigService._internal();
  factory SecureConfigService() => _instance;
  SecureConfigService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Keys for secure storage
  static const String _stripePublishableKey = 'stripe_publishable_key';
  static const String _firebaseApiKey = 'firebase_api_key';
  static const String _merchantId = 'merchant_id';

  // Initialize secure configuration
  Future<void> initialize() async {
    // In a real implementation, these values would be fetched from a secure backend
    // For now, we're just ensuring the structure is in place
    await _storage.write(key: _stripePublishableKey, value: '');
    await _storage.write(key: _firebaseApiKey, value: '');
    await _storage.write(key: _merchantId, value: '');
  }

  // Get secure values
  Future<String?> getStripePublishableKey() async {
    return await _storage.read(key: _stripePublishableKey);
  }

  Future<String?> getFirebaseApiKey() async {
    return await _storage.read(key: _firebaseApiKey);
  }

  Future<String?> getMerchantId() async {
    return await _storage.read(key: _merchantId);
  }

  // Set secure values (would be called after fetching from backend)
  Future<void> setStripePublishableKey(String key) async {
    await _storage.write(key: _stripePublishableKey, value: key);
  }

  Future<void> setFirebaseApiKey(String key) async {
    await _storage.write(key: _firebaseApiKey, value: key);
  }

  Future<void> setMerchantId(String id) async {
    await _storage.write(key: _merchantId, value: id);
  }

  // Clear all secure data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}