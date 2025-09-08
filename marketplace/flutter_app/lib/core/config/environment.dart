/// Environment configuration for different build environments
/// This file manages API endpoints and configuration for Development, Staging, and Production

class Environment {
  static const String development = 'development';
  static const String staging = 'staging';
  static const String production = 'production';

  // Current environment (change for different builds)
  static const String current = development;

  // Base URLs for different environments
  static const Map<String, String> _baseUrls = {
    development: 'http://localhost:3001/api',
    staging: 'https://staging-api.marketplace.com/api',
    production: 'https://api.marketplace.com/api',
  };

  // WebSocket URLs
  static const Map<String, String> _wsUrls = {
    development: 'ws://localhost:3001/ws',
    staging: 'wss://staging-ws.marketplace.com/ws',
    production: 'wss://ws.marketplace.com/ws',
  };

  // CDN URLs for assets
  static const Map<String, String> _cdnUrls = {
    development: 'http://localhost:3001/uploads',
    staging: 'https://staging-cdn.marketplace.com',
    production: 'https://cdn.marketplace.com',
  };

  // Stripe Keys
  static const Map<String, Map<String, String>> _stripeKeys = {
    development: {
      'publishableKey': 'pk_test_development_key_here',
      'merchantId': 'merchant.com.marketplace.dev',
    },
    staging: {
      'publishableKey': 'pk_test_staging_key_here',
      'merchantId': 'merchant.com.marketplace.staging',
    },
    production: {
      'publishableKey': 'pk_live_production_key_here',
      'merchantId': 'merchant.com.marketplace',
    },
  };

  // Firebase Configuration
  static const Map<String, Map<String, String>> _firebaseConfig = {
    development: {
      'projectId': 'marketplace-dev',
      'messagingSenderId': '1234567890',
      'appId': '1:1234567890:web:dev',
    },
    staging: {
      'projectId': 'marketplace-staging',
      'messagingSenderId': '0987654321',
      'appId': '1:0987654321:web:staging',
    },
    production: {
      'projectId': 'marketplace-prod',
      'messagingSenderId': '1122334455',
      'appId': '1:1122334455:web:prod',
    },
  };

  // Analytics Configuration
  static const Map<String, Map<String, String>> _analyticsConfig = {
    development: {
      'googleAnalyticsId': 'GA-DEV-123456',
      'sentryDsn': 'https://dev-sentry-dsn@sentry.io/project-dev',
    },
    staging: {
      'googleAnalyticsId': 'GA-STAGING-789012',
      'sentryDsn': 'https://staging-sentry-dsn@sentry.io/project-staging',
    },
    production: {
      'googleAnalyticsId': 'GA-PROD-345678',
      'sentryDsn': 'https://prod-sentry-dsn@sentry.io/project-prod',
    },
  };

  // Feature Flags
  static const Map<String, Map<String, bool>> _featureFlags = {
    development: {
      'enableAnalytics': true,
      'enableCrashReporting': true,
      'enableDebugMode': true,
      'enableMockData': true,
      'enableExperimentalFeatures': true,
      'enableLogging': true,
    },
    staging: {
      'enableAnalytics': true,
      'enableCrashReporting': true,
      'enableDebugMode': true,
      'enableMockData': false,
      'enableExperimentalFeatures': true,
      'enableLogging': true,
    },
    production: {
      'enableAnalytics': true,
      'enableCrashReporting': true,
      'enableDebugMode': false,
      'enableMockData': false,
      'enableExperimentalFeatures': false,
      'enableLogging': false,
    },
  };

  // API Configuration
  static const Map<String, Map<String, dynamic>> _apiConfig = {
    development: {
      'timeout': 30000, // 30 seconds
      'retryAttempts': 3,
      'enableLogging': true,
      'cacheEnabled': true,
      'cacheDuration': 300000, // 5 minutes
    },
    staging: {
      'timeout': 20000, // 20 seconds
      'retryAttempts': 2,
      'enableLogging': true,
      'cacheEnabled': true,
      'cacheDuration': 600000, // 10 minutes
    },
    production: {
      'timeout': 15000, // 15 seconds
      'retryAttempts': 2,
      'enableLogging': false,
      'cacheEnabled': true,
      'cacheDuration': 900000, // 15 minutes
    },
  };

  // Getters for current environment configuration
  static String get baseUrl => _baseUrls[current] ?? _baseUrls[development]!;
  static String get wsUrl => _wsUrls[current] ?? _wsUrls[development]!;
  static String get cdnUrl => _cdnUrls[current] ?? _cdnUrls[development]!;

  static Map<String, String> get stripeConfig =>
      _stripeKeys[current] ?? _stripeKeys[development]!;

  static Map<String, String> get firebaseConfig =>
      _firebaseConfig[current] ?? _firebaseConfig[development]!;

  static Map<String, String> get analyticsConfig =>
      _analyticsConfig[current] ?? _analyticsConfig[development]!;

  static Map<String, bool> get featureFlags =>
      _featureFlags[current] ?? _featureFlags[development]!;

  static Map<String, dynamic> get apiConfig =>
      _apiConfig[current] ?? _apiConfig[development]!;

  // Utility methods
  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;

  // API Endpoints
  static class ApiEndpoints {
    // Authentication
    static const String login = '/auth/login';
    static const String register = '/auth/register';
    static const String refreshToken = '/auth/refresh';
    static const String forgotPassword = '/auth/forgot-password';
    static const String resetPassword = '/auth/reset-password';
    static const String verifyEmail = '/auth/verify-email';
    static const String logout = '/auth/logout';

    // User Profile
    static const String profile = '/user/profile';
    static const String updateProfile = '/user/profile';
    static const String uploadAvatar = '/user/avatar';
    static const String addresses = '/user/addresses';
    static const String paymentMethods = '/user/payment-methods';

    // Products
    static const String products = '/products';
    static const String productDetail = '/products/{id}';
    static const String productSearch = '/products/search';
    static const String productReviews = '/products/{id}/reviews';
    static const String categories = '/categories';
    static const String brands = '/brands';

    // Shopping Cart
    static const String cart = '/cart';
    static const String addToCart = '/cart/add';
    static const String updateCartItem = '/cart/update/{id}';
    static const String removeFromCart = '/cart/remove/{id}';
    static const String clearCart = '/cart/clear';

    // Wishlist
    static const String wishlist = '/wishlist';
    static const String addToWishlist = '/wishlist/add';
    static const String removeFromWishlist = '/wishlist/remove/{id}';

    // Orders
    static const String orders = '/orders';
    static const String createOrder = '/orders';
    static const String orderDetail = '/orders/{id}';
    static const String cancelOrder = '/orders/{id}/cancel';
    static const String trackOrder = '/orders/{id}/track';

    // Payments
    static const String createPaymentIntent = '/payments/create-intent';
    static const String confirmPayment = '/payments/confirm';
    static const String refundPayment = '/payments/refund';

    // Shops/Vendors
    static const String shops = '/shops';
    static const String shopDetail = '/shops/{id}';
    static const String shopProducts = '/shops/{id}/products';
    static const String createShop = '/shops';
    static const String updateShop = '/shops/{id}';

    // Reviews & Ratings
    static const String createReview = '/reviews';
    static const String updateReview = '/reviews/{id}';
    static const String deleteReview = '/reviews/{id}';

    // Messaging
    static const String conversations = '/messages/conversations';
    static const String messages = '/messages/conversations/{id}';
    static const String sendMessage = '/messages/send';

    // Notifications
    static const String notifications = '/notifications';
    static const String markAsRead = '/notifications/{id}/read';
    static const String notificationSettings = '/notifications/settings';

    // Search & Discovery
    static const String aiSearch = '/search/ai';
    static const String visualSearch = '/search/visual';
    static const String voiceSearch = '/search/voice';
    static const String recommendations = '/recommendations';

    // Gamification
    static const String userXP = '/gamification/xp';
    static const String badges = '/gamification/badges';
    static const String leaderboard = '/gamification/leaderboard';
    static const String achievements = '/gamification/achievements';

    // Analytics
    static const String trackEvent = '/analytics/track';
    static const String userBehavior = '/analytics/behavior';
  }

  // Error Messages
  static const Map<String, String> errorMessages = {
    'network_error': 'Network connection error. Please check your internet connection.',
    'server_error': 'Server error occurred. Please try again later.',
    'unauthorized': 'Session expired. Please login again.',
    'validation_error': 'Please check your input and try again.',
    'not_found': 'The requested resource was not found.',
    'timeout_error': 'Request timeout. Please try again.',
    'unknown_error': 'An unexpected error occurred. Please try again.',
  };

  // Cache Keys
  static class CacheKeys {
    static const String userProfile = 'user_profile';
    static const String categories = 'categories';
    static const String brands = 'brands';
    static const String cart = 'cart';
    static const String wishlist = 'wishlist';
    static const String recentSearches = 'recent_searches';
    static const String userPreferences = 'user_preferences';
    static const String appSettings = 'app_settings';
  }

  // Local Storage Keys
  static class StorageKeys {
    static const String accessToken = 'access_token';
    static const String refreshToken = 'refresh_token';
    static const String userId = 'user_id';
    static const String userEmail = 'user_email';
    static const String themeMode = 'theme_mode';
    static const String language = 'language';
    static const String onboardingCompleted = 'onboarding_completed';
    static const String notificationSettings = 'notification_settings';
    static const String searchHistory = 'search_history';
    static const String cartData = 'cart_data';
    static const String wishlistData = 'wishlist_data';
  }
}