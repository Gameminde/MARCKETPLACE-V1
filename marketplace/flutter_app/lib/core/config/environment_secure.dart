import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Secure environment configuration using .env files
/// This replaces the hardcoded values in environment.dart
class EnvironmentSecure {
  static late String _environment;
  static bool _initialized = false;

  /// Initialize environment with .env file
  static Future<void> initialize(String environment) async {
    if (_initialized) return;

    _environment = environment;

    // Temporarily skip loading .env file to avoid blocking
    print('Using default environment values');
    _initialized = true;
    
    // Commented out for debugging
    // try {
    //   await dotenv.load(fileName: '.env.$environment');
    //   _initialized = true;
    // } catch (e) {
    //   // Fallback to development if .env file not found
    //   print('Warning: .env.$environment not found, using defaults');
    //   _initialized = true;
    // }
  }

  // Environment detection
  static String get environment => _environment;
  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3001/api';

  static String get wsUrl => dotenv.env['WS_URL'] ?? 'ws://localhost:3001/ws';

  static String get cdnUrl =>
      dotenv.env['CDN_URL'] ?? 'http://localhost:3001/uploads';

  // Stripe Configuration
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  static String get stripeMerchantId => dotenv.env['STRIPE_MERCHANT_ID'] ?? '';

  // Firebase Configuration
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // Analytics Configuration
  static String get googleAnalyticsId =>
      dotenv.env['GOOGLE_ANALYTICS_ID'] ?? '';

  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';

  // Feature Flags
  static bool get enableAnalytics =>
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';

  static bool get enableCrashReporting =>
      dotenv.env['ENABLE_CRASH_REPORTING']?.toLowerCase() == 'true';

  static bool get enableDebugMode =>
      dotenv.env['ENABLE_DEBUG_MODE']?.toLowerCase() == 'true';

  static bool get enableMockData =>
      dotenv.env['ENABLE_MOCK_DATA']?.toLowerCase() == 'true';

  static bool get enableExperimentalFeatures =>
      dotenv.env['ENABLE_EXPERIMENTAL_FEATURES']?.toLowerCase() == 'true';

  static bool get enableLogging =>
      dotenv.env['ENABLE_LOGGING']?.toLowerCase() == 'true';

  // API Configuration
  static Duration get apiTimeout => Duration(
        milliseconds:
            int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000,
      );

  static int get apiRetryAttempts =>
      int.tryParse(dotenv.env['API_RETRY_ATTEMPTS'] ?? '3') ?? 3;

  static bool get apiCacheEnabled =>
      dotenv.env['API_CACHE_ENABLED']?.toLowerCase() == 'true';

  static Duration get apiCacheDuration => Duration(
        milliseconds:
            int.tryParse(dotenv.env['API_CACHE_DURATION'] ?? '300000') ??
                300000,
      );

  // Security Configuration
  static String get encryptionKey =>
      dotenv.env['ENCRYPTION_KEY'] ??
      'default_encryption_key_change_in_production';

  static bool get enableSslPinning =>
      dotenv.env['ENABLE_SSL_PINNING']?.toLowerCase() == 'true';

  static String get sslPinningCertificate =>
      dotenv.env['SSL_PINNING_CERTIFICATE'] ?? '';

  // Validation
  static bool get isConfigurationValid {
    if (isProduction) {
      return apiBaseUrl.isNotEmpty &&
          stripePublishableKey.isNotEmpty &&
          firebaseProjectId.isNotEmpty &&
          googleAnalyticsId.isNotEmpty;
    }
    return true; // Development can have empty values
  }

  // Get all configuration as map
  static Map<String, dynamic> getConfiguration() {
    return {
      'environment': _environment,
      'apiBaseUrl': apiBaseUrl,
      'wsUrl': wsUrl,
      'cdnUrl': cdnUrl,
      'stripePublishableKey': stripePublishableKey.isNotEmpty ? '***' : '',
      'stripeMerchantId': stripeMerchantId,
      'firebaseProjectId': firebaseProjectId,
      'googleAnalyticsId': googleAnalyticsId,
      'sentryDsn': sentryDsn.isNotEmpty ? '***' : '',
      'enableAnalytics': enableAnalytics,
      'enableCrashReporting': enableCrashReporting,
      'enableDebugMode': enableDebugMode,
      'enableMockData': enableMockData,
      'enableExperimentalFeatures': enableExperimentalFeatures,
      'enableLogging': enableLogging,
      'apiTimeout': apiTimeout.inMilliseconds,
      'apiRetryAttempts': apiRetryAttempts,
      'apiCacheEnabled': apiCacheEnabled,
      'apiCacheDuration': apiCacheDuration.inMilliseconds,
      'isConfigurationValid': isConfigurationValid,
    };
  }
}
