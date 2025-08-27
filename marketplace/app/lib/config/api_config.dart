/// API configuration with environment-specific settings
class ApiConfig {
  // Private constructor
  ApiConfig._();

  // Environment detection
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  // Base URLs for different environments
  static const Map<String, String> _baseUrls = {
    'development': 'http://localhost:3001/api/v1',
    'staging': 'https://staging-api.marketplace.com/api/v1',
    'production': 'https://api.marketplace.com/api/v1',
  };

  // API endpoints
  static const Map<String, String> _endpoints = {
    // Authentication
    'auth_register': '/auth/register',
    'auth_login': '/auth/login',
    'auth_logout': '/auth/logout',
    'auth_refresh': '/auth/refresh',
    'auth_me': '/auth/me',
    'auth_profile': '/auth/profile',
    'auth_forgot_password': '/auth/forgot-password',
    'auth_reset_password': '/auth/reset-password',
    'auth_verify_email': '/auth/verify-email',
    
    // Users
    'users': '/users',
    'user_profile': '/users/profile',
    'user_preferences': '/users/preferences',
    'user_avatar': '/users/avatar',
    
    // Shops
    'shops': '/shops',
    'shop_templates': '/shops/templates',
    'shop_analytics': '/shops/analytics',
    
    // Products
    'products': '/products',
    'product_search': '/products/search',
    'product_categories': '/products/categories',
    'product_upload': '/products/upload',
    'product_images': '/products/images',
    
    // Templates
    'templates': '/templates',
    'template_preview': '/templates/preview',
    'template_customize': '/templates/customize',
    
    // Payments
    'payments': '/payments',
    'payment_intent': '/payments/intent',
    'payment_methods': '/payments/methods',
    'payment_history': '/payments/history',
    
    // AI Services
    'ai_validate': '/ai/validate',
    'ai_generate': '/ai/generate',
    'ai_analyze': '/ai/analyze',
    
    // File Upload
    'upload_image': '/upload/image',
    'upload_document': '/upload/document',
    
    // Notifications
    'notifications': '/notifications',
    'notification_preferences': '/notifications/preferences',
    
    // Analytics
    'analytics': '/analytics',
    'analytics_events': '/analytics/events',
  };

  // Timeout configurations
  static const Map<String, int> _timeouts = {
    'connect': 30000, // 30 seconds
    'receive': 60000, // 60 seconds
    'send': 30000,    // 30 seconds
  };

  // Rate limiting configurations
  static const Map<String, int> _rateLimits = {
    'auth_attempts': 5,        // Max login attempts per minute
    'api_requests': 100,       // Max API requests per minute
    'upload_requests': 10,     // Max upload requests per minute
    'ai_requests': 20,         // Max AI requests per minute
  };

  // File upload configurations
  static const Map<String, dynamic> _uploadConfig = {
    'max_file_size': 10 * 1024 * 1024, // 10MB
    'allowed_image_types': ['jpg', 'jpeg', 'png', 'webp', 'gif'],
    'allowed_document_types': ['pdf', 'doc', 'docx', 'txt'],
    'max_images_per_product': 10,
  };

  // Security configurations
  static const Map<String, dynamic> _securityConfig = {
    'token_refresh_threshold': 300, // 5 minutes before expiry
    'max_retry_attempts': 3,
    'retry_delay_ms': 1000,
    'enable_certificate_pinning': true,
  };

  // Public getters
  static String get environment => _environment;
  
  static String get baseUrl => _baseUrls[_environment] ?? _baseUrls['development']!;
  
  static String endpoint(String key) {
    final endpoint = _endpoints[key];
    if (endpoint == null) {
      throw ArgumentError('Unknown endpoint key: $key');
    }
    return endpoint;
  }
  
  static String fullUrl(String endpointKey) {
    return baseUrl + endpoint(endpointKey);
  }
  
  static int timeout(String type) {
    return _timeouts[type] ?? _timeouts['connect']!;
  }
  
  static int rateLimit(String type) {
    return _rateLimits[type] ?? _rateLimits['api_requests']!;
  }
  
  static dynamic uploadConfig(String key) {
    return _uploadConfig[key];
  }
  
  static dynamic securityConfig(String key) {
    return _securityConfig[key];
  }

  // Environment checks
  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';

  // Feature flags based on environment
  static bool get enableLogging => isDevelopment || isStaging;
  static bool get enableDebugMode => isDevelopment;
  static bool get enableAnalytics => isStaging || isProduction;
  static bool get enableCrashReporting => isProduction;

  // API versioning
  static const String apiVersion = 'v1';
  static const String minSupportedVersion = 'v1';
  static const String maxSupportedVersion = 'v1';

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-API-Version': apiVersion,
    'X-Client-Platform': 'flutter',
    'X-Client-Version': '1.0.0',
  };

  // Custom headers for specific requests
  static Map<String, String> authHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };

  static Map<String, String> get uploadHeaders => {
    ...defaultHeaders,
    'Content-Type': 'multipart/form-data',
  };

  // Validation methods
  static bool isValidEndpoint(String endpointKey) {
    return _endpoints.containsKey(endpointKey);
  }

  static bool isValidEnvironment(String env) {
    return _baseUrls.containsKey(env);
  }

  // Error codes mapping
  static const Map<String, String> errorMessages = {
    'NETWORK_ERROR': 'Erreur de réseau. Vérifiez votre connexion.',
    'TIMEOUT_ERROR': 'Délai d\'attente dépassé. Réessayez.',
    'SERVER_ERROR': 'Erreur serveur. Réessayez plus tard.',
    'UNAUTHORIZED': 'Session expirée. Reconnectez-vous.',
    'FORBIDDEN': 'Accès refusé.',
    'NOT_FOUND': 'Ressource non trouvée.',
    'VALIDATION_ERROR': 'Données invalides.',
    'RATE_LIMITED': 'Trop de requêtes. Attendez avant de réessayer.',
    'MAINTENANCE': 'Service en maintenance. Réessayez plus tard.',
  };

  static String getErrorMessage(String code) {
    return errorMessages[code] ?? 'Une erreur inattendue s\'est produite.';
  }

  // Debug information
  static Map<String, dynamic> get debugInfo => {
    'environment': environment,
    'baseUrl': baseUrl,
    'apiVersion': apiVersion,
    'isDevelopment': isDevelopment,
    'isStaging': isStaging,
    'isProduction': isProduction,
    'enableLogging': enableLogging,
    'enableDebugMode': enableDebugMode,
    'timeouts': _timeouts,
    'rateLimits': _rateLimits,
  };

  // Configuration validation
  static bool validateConfiguration() {
    try {
      // Check if base URL is valid
      final uri = Uri.parse(baseUrl);
      if (!uri.hasScheme || !uri.hasAuthority) {
        return false;
      }

      // Check if all required endpoints are defined
      final requiredEndpoints = [
        'auth_login',
        'auth_register',
        'auth_logout',
        'products',
        'shops',
      ];

      for (final endpoint in requiredEndpoints) {
        if (!_endpoints.containsKey(endpoint)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}