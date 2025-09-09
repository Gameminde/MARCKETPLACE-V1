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
      'apiKey': 'AIzaSyB_development_key_here',
      'authDomain': 'marketplace-dev.firebaseapp.com',
      'projectId': 'marketplace-dev',
      'storageBucket': 'marketplace-dev.appspot.com',
      'messagingSenderId': '123456789',
      'appId': '1:123456789:web:abcdef123456',
    },
    staging: {
      'apiKey': 'AIzaSyB_staging_key_here',
      'authDomain': 'marketplace-staging.firebaseapp.com',
      'projectId': 'marketplace-staging',
      'storageBucket': 'marketplace-staging.appspot.com',
      'messagingSenderId': '987654321',
      'appId': '1:987654321:web:fedcba654321',
    },
    production: {
      'apiKey': 'AIzaSyB_production_key_here',
      'authDomain': 'marketplace-prod.firebaseapp.com',
      'projectId': 'marketplace-prod',
      'storageBucket': 'marketplace-prod.appspot.com',
      'messagingSenderId': '112233445',
      'appId': '1:112233445:web:production123456',
    },
  };

  // App Configuration
  static const Map<String, Map<String, dynamic>> _appConfig = {
    development: {
      'debugMode': true,
      'logLevel': 'debug',
      'enableCrashlytics': false,
      'enableAnalytics': false,
      'enablePerformanceMonitoring': false,
      'cacheTimeout': 300, // 5 minutes
      'maxRetries': 3,
      'requestTimeout': 30000, // 30 seconds
    },
    staging: {
      'debugMode': true,
      'logLevel': 'info',
      'enableCrashlytics': true,
      'enableAnalytics': true,
      'enablePerformanceMonitoring': true,
      'cacheTimeout': 600, // 10 minutes
      'maxRetries': 5,
      'requestTimeout': 45000, // 45 seconds
    },
    production: {
      'debugMode': false,
      'logLevel': 'error',
      'enableCrashlytics': true,
      'enableAnalytics': true,
      'enablePerformanceMonitoring': true,
      'cacheTimeout': 1800, // 30 minutes
      'maxRetries': 3,
      'requestTimeout': 60000, // 60 seconds
    },
  };

  // Feature Flags
  static const Map<String, Map<String, bool>> _featureFlags = {
    development: {
      'enablePushNotifications': true,
      'enableBiometricAuth': true,
      'enableDarkMode': true,
      'enableOfflineMode': true,
      'enableSocialLogin': true,
      'enableGuestCheckout': true,
      'enableWishlist': true,
      'enableReviews': true,
      'enableChat': true,
      'enableLiveChat': true,
      'enableVideoCalls': false,
      'enableARView': false,
      'enableVoiceSearch': false,
      'enableBarcodeScanner': true,
      'enableLocationServices': true,
      'enableCamera': true,
      'enableFileUpload': true,
      'enableAdvancedSearch': true,
      'enableRecommendations': true,
      'enablePersonalization': true,
    },
    staging: {
      'enablePushNotifications': true,
      'enableBiometricAuth': true,
      'enableDarkMode': true,
      'enableOfflineMode': true,
      'enableSocialLogin': true,
      'enableGuestCheckout': true,
      'enableWishlist': true,
      'enableReviews': true,
      'enableChat': true,
      'enableLiveChat': true,
      'enableVideoCalls': false,
      'enableARView': false,
      'enableVoiceSearch': false,
      'enableBarcodeScanner': true,
      'enableLocationServices': true,
      'enableCamera': true,
      'enableFileUpload': true,
      'enableAdvancedSearch': true,
      'enableRecommendations': true,
      'enablePersonalization': true,
    },
    production: {
      'enablePushNotifications': true,
      'enableBiometricAuth': true,
      'enableDarkMode': true,
      'enableOfflineMode': true,
      'enableSocialLogin': true,
      'enableGuestCheckout': true,
      'enableWishlist': true,
      'enableReviews': true,
      'enableChat': true,
      'enableLiveChat': true,
      'enableVideoCalls': false,
      'enableARView': false,
      'enableVoiceSearch': false,
      'enableBarcodeScanner': true,
      'enableLocationServices': true,
      'enableCamera': true,
      'enableFileUpload': true,
      'enableAdvancedSearch': true,
      'enableRecommendations': true,
      'enablePersonalization': true,
    },
  };

  // Getters for current environment values
  static String get baseUrl => _baseUrls[current]!;
  static String get wsUrl => _wsUrls[current]!;
  static String get cdnUrl => _cdnUrls[current]!;
  static Map<String, String> get stripeKeys => _stripeKeys[current]!;
  static Map<String, String> get firebaseConfig => _firebaseConfig[current]!;
  static Map<String, dynamic> get appConfig => _appConfig[current]!;
  static Map<String, bool> get featureFlags => _featureFlags[current]!;

  // Environment checks
  static bool get isDevelopment => current == development;
  static bool get isStaging => current == staging;
  static bool get isProduction => current == production;

  // API Endpoints
  static const Map<String, String> apiEndpoints = {
    // Authentication
    'login': '/auth/login',
    'register': '/auth/register',
    'refreshToken': '/auth/refresh',
    'forgotPassword': '/auth/forgot-password',
    'resetPassword': '/auth/reset-password',
    'verifyEmail': '/auth/verify-email',
    'logout': '/auth/logout',

    // User Profile
    'profile': '/user/profile',
    'updateProfile': '/user/profile',
    'uploadAvatar': '/user/avatar',
    'addresses': '/user/addresses',
    'paymentMethods': '/user/payment-methods',

    // Products
    'products': '/products',
    'productDetail': '/products',
    'searchProducts': '/products/search',
    'categories': '/products/categories',
    'brands': '/products/brands',
    'trending': '/products/trending',
    'recommendations': '/products/recommendations',
    'recentlyViewed': '/products/recently-viewed',

    // Cart & Orders
    'cart': '/cart',
    'addToCart': '/cart/add',
    'removeFromCart': '/cart/remove',
    'updateCartItem': '/cart/update',
    'clearCart': '/cart/clear',
    'orders': '/orders',
    'orderDetail': '/orders',
    'createOrder': '/orders',
    'cancelOrder': '/orders',

    // Wishlist
    'wishlist': '/wishlist',
    'addToWishlist': '/wishlist/add',
    'removeFromWishlist': '/wishlist/remove',

    // Reviews & Ratings
    'reviews': '/reviews',
    'createReview': '/reviews',
    'updateReview': '/reviews',
    'deleteReview': '/reviews',

    // Chat & Messaging
    'chatRooms': '/chat/rooms',
    'messages': '/chat/messages',
    'sendMessage': '/chat/send',
    'markAsRead': '/chat/mark-read',

    // Notifications
    'notifications': '/notifications',
    'markNotificationRead': '/notifications/read',
    'notificationSettings': '/notifications/settings',

    // Analytics
    'analytics': '/analytics',
    'trackEvent': '/analytics/track',
    'userBehavior': '/analytics/behavior',

    // File Upload
    'uploadImage': '/upload/image',
    'uploadFile': '/upload/file',
    'deleteFile': '/upload/delete',
  };

  // Cache Keys
  static const Map<String, String> cacheKeys = {
    'user': 'user_data',
    'cart': 'cart_data',
    'wishlist': 'wishlist_data',
    'recentSearches': 'recent_searches',
    'categories': 'categories_data',
    'brands': 'brands_data',
    'trendingProducts': 'trending_products',
    'recommendations': 'recommendations_data',
    'notifications': 'notifications_data',
    'settings': 'app_settings',
    'theme': 'theme_preference',
    'language': 'language_preference',
    'location': 'user_location',
    'paymentMethods': 'payment_methods',
    'addresses': 'user_addresses',
  };

  // Storage Keys
  static const Map<String, String> storageKeys = {
    'authToken': 'auth_token',
    'refreshToken': 'refresh_token',
    'userData': 'user_data',
    'cartData': 'cart_data',
    'wishlistData': 'wishlist_data',
    'appSettings': 'app_settings',
    'themeMode': 'theme_mode',
    'languageCode': 'language_code',
    'firstLaunch': 'first_launch',
    'onboardingCompleted': 'onboarding_completed',
    'biometricEnabled': 'biometric_enabled',
    'pushNotificationsEnabled': 'push_notifications_enabled',
    'locationPermissionGranted': 'location_permission_granted',
    'cameraPermissionGranted': 'camera_permission_granted',
  };
}

/// API Endpoints helper class
class ApiEndpoints {
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
  static const String productDetail = '/products';
  static const String searchProducts = '/products/search';
  static const String categories = '/products/categories';
  static const String brands = '/products/brands';
  static const String trending = '/products/trending';
  static const String recommendations = '/products/recommendations';
  static const String recentlyViewed = '/products/recently-viewed';

  // Cart & Orders
  static const String cart = '/cart';
  static const String addToCart = '/cart/add';
  static const String removeFromCart = '/cart/remove';
  static const String updateCartItem = '/cart/update';
  static const String clearCart = '/cart/clear';
  static const String orders = '/orders';
  static const String orderDetail = '/orders';
  static const String createOrder = '/orders';
  static const String cancelOrder = '/orders';

  // Wishlist
  static const String wishlist = '/wishlist';
  static const String addToWishlist = '/wishlist/add';
  static const String removeFromWishlist = '/wishlist/remove';

  // Reviews & Ratings
  static const String reviews = '/reviews';
  static const String createReview = '/reviews';
  static const String updateReview = '/reviews';
  static const String deleteReview = '/reviews';

  // Chat & Messaging
  static const String chatRooms = '/chat/rooms';
  static const String messages = '/chat/messages';
  static const String sendMessage = '/chat/send';
  static const String markAsRead = '/chat/mark-read';

  // Notifications
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/read';
  static const String notificationSettings = '/notifications/settings';

  // Analytics
  static const String analytics = '/analytics';
  static const String trackEvent = '/analytics/track';
  static const String userBehavior = '/analytics/behavior';

  // File Upload
  static const String uploadImage = '/upload/image';
  static const String uploadFile = '/upload/file';
  static const String deleteFile = '/upload/delete';
}

/// Cache Keys helper class
class CacheKeys {
  static const String user = 'user_data';
  static const String cart = 'cart_data';
  static const String wishlist = 'wishlist_data';
  static const String recentSearches = 'recent_searches';
  static const String categories = 'categories_data';
  static const String brands = 'brands_data';
  static const String trendingProducts = 'trending_products';
  static const String recommendations = 'recommendations_data';
  static const String notifications = 'notifications_data';
  static const String settings = 'app_settings';
  static const String theme = 'theme_preference';
  static const String language = 'language_preference';
  static const String location = 'user_location';
  static const String paymentMethods = 'payment_methods';
  static const String addresses = 'user_addresses';
}

/// Storage Keys helper class
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String cartData = 'cart_data';
  static const String wishlistData = 'wishlist_data';
  static const String appSettings = 'app_settings';
  static const String themeMode = 'theme_mode';
  static const String languageCode = 'language_code';
  static const String firstLaunch = 'first_launch';
  static const String onboardingCompleted = 'onboarding_completed';
  static const String biometricEnabled = 'biometric_enabled';
  static const String pushNotificationsEnabled = 'push_notifications_enabled';
  static const String locationPermissionGranted = 'location_permission_granted';
  static const String cameraPermissionGranted = 'camera_permission_granted';
}
