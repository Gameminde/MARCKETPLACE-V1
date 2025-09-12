/// API Endpoints configuration
class ApiEndpoints {
  // Base paths
  static const String auth = '/auth';
  static const String users = '/users';
  static const String products = '/products';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String orders = '/orders';
  static const String payments = '/payments';
  static const String reviews = '/reviews';
  static const String wishlist = '/wishlist';
  static const String notifications = '/notifications';
  static const String messages = '/messages';
  static const String search = '/search';
  static const String recommendations = '/recommendations';
  static const String analytics = '/analytics';
  static const String vendors = '/vendors';
  static const String admin = '/admin';

  // Auth endpoints
  static const String login = '$auth/login';
  static const String register = '$auth/register';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  static const String forgotPassword = '$auth/forgot-password';
  static const String resetPassword = '$auth/reset-password';
  static const String verifyEmail = '$auth/verify-email';
  static const String resendVerification = '$auth/resend-verification';
  static const String changePassword = '$auth/change-password';
  static const String socialLogin = '$auth/social';
  static const String verifyMfa = '$auth/verify-mfa';
  static const String toggleMfa = '$auth/toggle-mfa';

  // User endpoints
  static const String profile = '$users/profile';
  static const String updateProfile = '$users/profile';
  static const String uploadAvatar = '$users/avatar';
  static const String userOrders = '$users/orders';
  static const String userAddresses = '$users/addresses';
  static const String userPaymentMethods = '$users/payment-methods';
  static const String userNotifications = '$users/notifications';
  static const String userPreferences = '$users/preferences';

  // Product endpoints
  static const String productList = products;
  static const String productDetail = '$products/:id';
  static const String productsByCategory = '$products/category/:categoryId';
  static const String productsByVendor = '$products/vendor/:vendorId';
  static const String featuredProducts = '$products/featured';
  static const String trendingProducts = '$products/trending';
  static const String newProducts = '$products/new';
  static const String saleProducts = '$products/sale';
  static const String relatedProducts = '$products/:id/related';

  // Cart endpoints
  static const String getCart = cart;
  static const String addToCart = '$cart/add';
  static const String updateCartItem = '$cart/update';
  static const String removeFromCart = '$cart/remove';
  static const String clearCart = '$cart/clear';
  static const String applyPromoCode = '$cart/promo';

  // Order endpoints
  static const String createOrder = orders;
  static const String getOrder = '$orders/:id';
  static const String getUserOrders = orders;
  static const String cancelOrder = '$orders/:id/cancel';
  static const String trackOrder = '$orders/:id/track';
  static const String orderInvoice = '$orders/:id/invoice';

  // Payment endpoints
  static const String processPayment = '$payments/process';
  static const String paymentMethods = '$payments/methods';
  static const String addPaymentMethod = '$payments/methods/add';
  static const String removePaymentMethod = '$payments/methods/:id/remove';
  static const String paymentHistory = '$payments/history';

  // Review endpoints
  static const String productReviews = '$reviews/product/:productId';
  static const String addReview = '$reviews/add';
  static const String updateReview = '$reviews/:id';
  static const String deleteReview = '$reviews/:id';
  static const String reviewHelpful = '$reviews/:id/helpful';

  // Wishlist endpoints
  static const String getWishlist = wishlist;
  static const String addToWishlist = '$wishlist/add';
  static const String removeFromWishlist = '$wishlist/remove/:productId';
  static const String clearWishlist = '$wishlist/clear';

  // Search endpoints
  static const String searchProducts = '$search/products';
  static const String searchVendors = '$search/vendors';
  static const String searchSuggestions = '$search/suggestions';
  static const String searchHistory = '$search/history';

  // Vendor endpoints
  static const String vendorProfile = '$vendors/:id';
  static const String vendorProducts = '$vendors/:id/products';
  static const String vendorReviews = '$vendors/:id/reviews';
  static const String becomeVendor = '$vendors/register';
  static const String vendorDashboard = '$vendors/dashboard';
  static const String vendorAnalytics = '$vendors/analytics';
  static const String vendorOrders = '$vendors/orders';
  static const String vendorPayouts = '$vendors/payouts';

  // Admin endpoints
  static const String adminDashboard = '$admin/dashboard';
  static const String adminUsers = '$admin/users';
  static const String adminProducts = '$admin/products';
  static const String adminOrders = '$admin/orders';
  static const String adminVendors = '$admin/vendors';
  static const String adminReports = '$admin/reports';
  static const String adminSettings = '$admin/settings';

  // Helper method to replace path parameters
  static String buildPath(String path, Map<String, dynamic> params) {
    String result = path;
    params.forEach((key, value) {
      result = result.replaceAll(':$key', value.toString());
    });
    return result;
  }

  // Helper method to add query parameters
  static String addQueryParams(String path, Map<String, dynamic> queryParams) {
    if (queryParams.isEmpty) return path;
    
    final queryString = queryParams.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value.toString())}')
        .join('&');
    
    return '$path?$queryString';
  }
}