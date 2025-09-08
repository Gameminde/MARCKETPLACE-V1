/// Application constants used throughout the app
/// Contains UI constants, business rules, and configuration values

class AppConstants {
  // App Information
  static const String appName = 'Marketplace';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  static const int loadMoreThreshold = 5;

  // Image Sizes
  static const int thumbnailSize = 150;
  static const int mediumImageSize = 300;
  static const int largeImageSize = 600;
  static const int maxImageUploadSize = 5 * 1024 * 1024; // 5MB

  // Animation Durations (in milliseconds)
  static const int shortAnimationDuration = 200;
  static const int mediumAnimationDuration = 300;
  static const int longAnimationDuration = 500;
  static const int pageTransitionDuration = 250;

  // UI Dimensions
  static const double borderRadius = 12.0;
  static const double cardBorderRadius = 16.0;
  static const double buttonBorderRadius = 8.0;
  static const double inputBorderRadius = 10.0;
  static const double dialogBorderRadius = 20.0;
  static const double navBarBorderRadius = 20.0;
  static const double chipBorderRadius = 20.0;

  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Icon Sizes
  static const double iconSizeXS = 16.0;
  static const double iconSizeS = 20.0;
  static const double iconSizeM = 24.0;
  static const double iconSizeL = 32.0;
  static const double iconSizeXL = 48.0;

  // Text Sizes
  static const double textSizeXS = 10.0;
  static const double textSizeS = 12.0;
  static const double textSizeM = 14.0;
  static const double textSizeL = 16.0;
  static const double textSizeXL = 18.0;
  static const double textSizeXXL = 24.0;

  // Button Heights
  static const double buttonHeightS = 32.0;
  static const double buttonHeightM = 44.0;
  static const double buttonHeightL = 56.0;

  // Input Field Heights
  static const double inputHeightS = 40.0;
  static const double inputHeightM = 48.0;
  static const double inputHeightL = 56.0;

  // Grid Configuration
  static const int gridCrossAxisCount = 2;
  static const double gridChildAspectRatio = 0.75;
  static const double gridSpacing = 12.0;

  // Product Card Dimensions
  static const double productCardHeight = 280.0;
  static const double productImageHeight = 180.0;
  static const double productCardPadding = 12.0;

  // Cart & Checkout
  static const double minimumOrderAmount = 10.0;
  static const double freeShippingThreshold = 50.0;
  static const double standardShippingCost = 5.99;
  static const double expressShippingCost = 12.99;

  // Search Configuration
  static const int searchHistoryLimit = 10;
  static const int searchSuggestionLimit = 5;
  static const int minSearchLength = 2;
  static const int searchDebounceMs = 500;

  // Cache Configuration
  static const Duration cacheValidDuration = Duration(minutes: 15);
  static const Duration longCacheValidDuration = Duration(hours: 1);
  static const int maxCacheSize = 100;

  // Network Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Retry Configuration
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 1);

  // Validation Rules
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int maxReviewLength = 500;
  static const int maxMessageLength = 1000;

  // Rating System
  static const double minRating = 1.0;
  static const double maxRating = 5.0;
  static const double ratingStep = 0.5;

  // Gamification
  static const int baseXPPerAction = 10;
  static const int xpPerPurchase = 100;
  static const int xpPerReview = 50;
  static const int xpPerReferral = 200;
  static const int xpPerDailyLogin = 5;

  // Badge Thresholds
  static const int bronzeBadgeThreshold = 100;
  static const int silverBadgeThreshold = 500;
  static const int goldBadgeThreshold = 1000;
  static const int platinumBadgeThreshold = 5000;

  // Currency
  static const String defaultCurrency = 'USD';
  static const String currencySymbol = '\$';
  static const int decimalPlaces = 2;

  // Date Formats
  static const String dateFormatShort = 'MMM dd, yyyy';
  static const String dateFormatLong = 'MMMM dd, yyyy';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // File Types
  static const List<String> allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'gif'
  ];
  static const List<String> allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt'
  ];

  // Social Media
  static const String facebookUrl = 'https://facebook.com/marketplace';
  static const String twitterUrl = 'https://twitter.com/marketplace';
  static const String instagramUrl = 'https://instagram.com/marketplace';
  static const String linkedinUrl = 'https://linkedin.com/company/marketplace';

  // Legal
  static const String privacyPolicyUrl = 'https://marketplace.com/privacy';
  static const String termsOfServiceUrl = 'https://marketplace.com/terms';
  static const String supportEmail = 'support@marketplace.com';
  static const String contactPhone = '+1-800-123-4567';

  // Maps & Location
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;
  static const double locationAccuracyRadius = 1000.0; // meters
  static const int maxNearbyResults = 50;

  // Notification Types
  static const String notificationOrderUpdate = 'order_update';
  static const String notificationNewMessage = 'new_message';
  static const String notificationPromotion = 'promotion';
  static const String notificationReviewRequest = 'review_request';
  static const String notificationPaymentConfirmation = 'payment_confirmation';

  // Error Codes
  static const String errorCodeUnauthorized = 'UNAUTHORIZED';
  static const String errorCodeNotFound = 'NOT_FOUND';
  static const String errorCodeValidation = 'VALIDATION_ERROR';
  static const String errorCodeNetwork = 'NETWORK_ERROR';
  static const String errorCodeServer = 'SERVER_ERROR';

  // Feature Flags
  static const String featureFlagDarkMode = 'dark_mode';
  static const String featureFlagVoiceSearch = 'voice_search';
  static const String featureFlagArView = 'ar_view';
  static const String featureFlagSocialLogin = 'social_login';
  static const String featureFlagPayPal = 'paypal_payment';

  // Glassmorphism Effect
  static const double glassBlurRadius = 10.0;
  static const double glassOpacity = 0.1;
  static const double glassBorderOpacity = 0.2;

  // Particle Animation
  static const int particleCount = 50;
  static const double particleSpeed = 1.0;
  static const double particleSize = 3.0;

  // Theme Transitions
  static const Duration themeTransitionDuration = Duration(milliseconds: 300);

  // Onboarding
  static const int onboardingPages = 4;
  static const Duration onboardingAutoPlayDuration = Duration(seconds: 5);

  // Deep Links
  static const String deepLinkScheme = 'marketplace';
  static const String deepLinkHost = 'app.marketplace.com';

  // Analytics Events
  static const String eventAppStart = 'app_start';
  static const String eventProductView = 'product_view';
  static const String eventAddToCart = 'add_to_cart';
  static const String eventPurchase = 'purchase';
  static const String eventSearch = 'search';
  static const String eventShare = 'share';

  // Security
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration tokenRefreshBuffer = Duration(minutes: 5);
  static const int maxLoginAttempts = 5;
  static const Duration loginLockoutDuration = Duration(minutes: 30);

  // Performance
  static const int imageMemoryCacheSize = 100 * 1024 * 1024; // 100MB
  static const int imageDiskCacheSize = 200 * 1024 * 1024; // 200MB
  static const Duration imageCacheValidDuration = Duration(days: 7);

  // Accessibility
  static const Duration voiceOverDelay = Duration(milliseconds: 500);
  static const double minimumTapTargetSize = 44.0;
  static const double accessibleTextScale = 1.5;

  // Seasonal Themes
  static const List<String> seasonalThemes = [
    'spring',
    'summer',
    'autumn',
    'winter',
    'christmas',
    'halloween'
  ];

  // Shop Categories
  static const List<String> shopCategories = [
    'electronics',
    'fashion',
    'home_garden',
    'sports_outdoors',
    'books_media',
    'health_beauty',
    'toys_games',
    'automotive',
    'food_beverages',
    'services'
  ];

  // Order Status
  static const String orderStatusPending = 'pending';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusShipped = 'shipped';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';
  static const String orderStatusReturned = 'returned';

  // Payment Status
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusProcessing = 'processing';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';

  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';
  static const String messageTypeLocation = 'location';
  static const String messageTypeProduct = 'product';

  // User Roles
  static const String roleBuyer = 'buyer';
  static const String roleSeller = 'seller';
  static const String roleAdmin = 'admin';
  static const String roleModerator = 'moderator';

  // Review Status
  static const String reviewStatusPending = 'pending';
  static const String reviewStatusApproved = 'approved';
  static const String reviewStatusRejected = 'rejected';

  // Dispute Status
  static const String disputeStatusOpen = 'open';
  static const String disputeStatusInProgress = 'in_progress';
  static const String disputeStatusResolved = 'resolved';
  static const String disputeStatusClosed = 'closed';
}