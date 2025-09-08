import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../core/config/environment.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/address.dart';
import '../models/payment_method.dart';
import '../models/search_result.dart';

/// Comprehensive API service for all marketplace REST endpoints
/// Handles authentication, products, orders, users, search, and more
class ApiService {
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  
  // Base configurations
  final String _baseUrl = Environment.baseUrl;
  final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  String? _authToken;
  
  /// Set authentication token for API requests
  void setAuthToken(String? token) {
    _authToken = token;
  }
  
  /// Get headers with authentication
  Map<String, String> get _authenticatedHeaders {
    final headers = Map<String, String>.from(_defaultHeaders);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }
  
  // =============================================================================
  // AUTHENTICATION ENDPOINTS
  // =============================================================================
  
  /// Login with email and password
  Future<ApiResponse<AuthData>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    return _post<AuthData>(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
        'remember_me': rememberMe,
      },
      fromJson: (json) => AuthData.fromJson(json),
    );
  }
  
  /// Register new user
  Future<ApiResponse<AuthData>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    UserRole role = UserRole.buyer,
  }) async {
    return _post<AuthData>(
      '/auth/register',
      body: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'role': role.name,
      },
      fromJson: (json) => AuthData.fromJson(json),
    );
  }
  
  /// Send email verification code
  Future<ApiResponse<void>> sendEmailVerification(String email) async {
    return _post<void>(
      '/auth/send-verification',
      body: {'email': email},
    );
  }
  
  /// Verify email with code
  Future<ApiResponse<AuthData>> verifyEmail({
    required String email,
    required String verificationCode,
  }) async {
    return _post<AuthData>(
      '/auth/verify-email',
      body: {
        'email': email,
        'verification_code': verificationCode,
      },
      fromJson: (json) => AuthData.fromJson(json),
    );
  }
  
  /// Complete registration with email verification
  Future<ApiResponse<AuthData>> verifyEmailAndRegister({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    required String verificationCode,
    bool subscribeToNewsletter = false,
  }) async {
    return _post<AuthData>(
      '/auth/register-verify',
      body: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'verification_code': verificationCode,
        'subscribe_newsletter': subscribeToNewsletter,
      },
      fromJson: (json) => AuthData.fromJson(json),
    );
  }
  
  /// Social login (Google, Apple, Facebook)
  Future<ApiResponse<AuthData>> socialLogin({
    required String provider,
    required String token,
  }) async {
    return _post<AuthData>(
      '/auth/social/$provider',
      body: {'token': token},
      fromJson: (json) => AuthData.fromJson(json),
    );
  }
  
  /// Refresh authentication token
  Future<ApiResponse<AuthData>> refreshToken(String refreshToken) async {
    return _post<AuthData>(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
      fromJson: (json) => AuthData.fromJson(json),
    );
  }
  
  /// Logout
  Future<ApiResponse<void>> logout() async {
    return _post<void>('/auth/logout');
  }
  
  /// Forgot password
  Future<ApiResponse<void>> forgotPassword(String email) async {
    return _post<void>(
      '/auth/forgot-password',
      body: {'email': email},
    );
  }
  
  /// Reset password
  Future<ApiResponse<void>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    return _post<void>(
      '/auth/reset-password',
      body: {
        'token': token,
        'password': newPassword,
      },
    );
  }
  
  /// Change password
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return _post<void>(
      '/auth/change-password',
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }
  
  // =============================================================================
  // USER ENDPOINTS
  // =============================================================================
  
  /// Get current user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    return _get<User>(
      '/users/me',
      fromJson: (json) => User.fromJson(json),
    );
  }
  
  /// Update user profile
  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> updates) async {
    return _put<User>(
      '/users/me',
      body: updates,
      fromJson: (json) => User.fromJson(json),
    );
  }
  
  /// Upload profile picture
  Future<ApiResponse<String>> uploadProfilePicture(File imageFile) async {
    return _uploadFile<String>(
      '/users/me/avatar',
      file: imageFile,
      fieldName: 'avatar',
      fromJson: (json) => json['avatar_url'] as String,
    );
  }
  
  /// Get user addresses
  Future<ApiResponse<List<Address>>> getUserAddresses() async {
    return _get<List<Address>>(
      '/users/me/addresses',
      fromJson: (json) => (json as List).map((item) => Address.fromJson(item)).toList(),
    );
  }
  
  /// Add new address
  Future<ApiResponse<Address>> addAddress(Address address) async {
    return _post<Address>(
      '/users/me/addresses',
      body: address.toJson(),
      fromJson: (json) => Address.fromJson(json),
    );
  }
  
  /// Update address
  Future<ApiResponse<Address>> updateAddress(Address address) async {
    return _put<Address>(
      '/users/me/addresses/${address.id}',
      body: address.toJson(),
      fromJson: (json) => Address.fromJson(json),
    );
  }
  
  /// Delete address
  Future<ApiResponse<void>> deleteAddress(String addressId) async {
    return _delete('/users/me/addresses/$addressId');
  }
  
  /// Get user payment methods
  Future<ApiResponse<List<PaymentMethod>>> getPaymentMethods() async {
    return _get<List<PaymentMethod>>(
      '/users/me/payment-methods',
      fromJson: (json) => (json as List).map((item) => PaymentMethod.fromJson(item)).toList(),
    );
  }
  
  /// Add payment method
  Future<ApiResponse<PaymentMethod>> addPaymentMethod(Map<String, dynamic> paymentData) async {
    return _post<PaymentMethod>(
      '/users/me/payment-methods',
      body: paymentData,
      fromJson: (json) => PaymentMethod.fromJson(json),
    );
  }
  
  /// Delete payment method
  Future<ApiResponse<void>> deletePaymentMethod(String paymentMethodId) async {
    return _delete('/users/me/payment-methods/$paymentMethodId');
  }
  
  // =============================================================================
  // PRODUCT ENDPOINTS
  // =============================================================================
  
  /// Get products with pagination and filters
  Future<ApiResponse<ProductResponse>> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (category != null) queryParams['category'] = category;
    if (search != null) queryParams['search'] = search;
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (sortOrder != null) queryParams['sort_order'] = sortOrder;
    
    // Add custom filters
    if (filters != null) {
      filters.forEach((key, value) {
        queryParams['filter_$key'] = value.toString();
      });
    }
    
    return _get<ProductResponse>(
      '/products',
      queryParams: queryParams,
      fromJson: (json) => ProductResponse.fromJson(json),
    );
  }
  
  /// Get product by ID
  Future<ApiResponse<Product>> getProduct(String productId) async {
    return _get<Product>(
      '/products/$productId',
      fromJson: (json) => Product.fromJson(json),
    );
  }
  
  /// Get featured products
  Future<ApiResponse<List<Product>>> getFeaturedProducts({int limit = 10}) async {
    return _get<List<Product>>(
      '/products/featured',
      queryParams: {'limit': limit.toString()},
      fromJson: (json) => (json as List).map((item) => Product.fromJson(item)).toList(),
    );
  }
  
  /// Get product recommendations
  Future<ApiResponse<List<Product>>> getRecommendations({
    String? productId,
    String? userId,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (productId != null) queryParams['product_id'] = productId;
    if (userId != null) queryParams['user_id'] = userId;
    
    return _get<List<Product>>(
      '/products/recommendations',
      queryParams: queryParams,
      fromJson: (json) => (json as List).map((item) => Product.fromJson(item)).toList(),
    );
  }
  
  /// Get categories
  Future<ApiResponse<List<Category>>> getCategories() async {
    return _get<List<Category>>(
      '/categories',
      fromJson: (json) => (json as List).map((item) => Category.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
  
  /// Search products with AI-powered search
  Future<ApiResponse<SearchResponse>> searchProducts({
    required String query,
    int page = 1,
    int limit = 20,
    Map<String, dynamic>? filters,
    String? sortBy,
  }) async {
    final queryParams = <String, String>{
      'q': query,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    
    return _post<SearchResponse>(
      '/search/products',
      body: {
        'query': query,
        'page': page,
        'limit': limit,
        'filters': filters ?? {},
        'sort_by': sortBy,
      },
      fromJson: (json) => SearchResponse.fromJson(json),
    );
  }
  
  /// Visual search (image-based search)
  Future<ApiResponse<SearchResponse>> visualSearch(File imageFile) async {
    return _uploadFile<SearchResponse>(
      '/search/visual',
      file: imageFile,
      fieldName: 'image',
      fromJson: (json) => SearchResponse.fromJson(json),
    );
  }
  
  /// Barcode search
  Future<ApiResponse<Product?>> barcodeSearch(String barcode) async {
    return _get<Product?>(
      '/search/barcode/$barcode',
      fromJson: (json) => json != null ? Product.fromJson(json) : null,
    );
  }
  
  // =============================================================================
  // CART ENDPOINTS
  // =============================================================================
  
  /// Get user's cart
  Future<ApiResponse<List<CartItem>>> getCart() async {
    return _get<List<CartItem>>(
      '/cart',
      fromJson: (json) => (json as List).map((item) => CartItem.fromJson(item)).toList(),
    );
  }
  
  /// Add item to cart
  Future<ApiResponse<CartItem>> addToCart({
    required String productId,
    int quantity = 1,
    Map<String, dynamic>? attributes,
  }) async {
    return _post<CartItem>(
      '/cart/items',
      body: {
        'product_id': productId,
        'quantity': quantity,
        'attributes': attributes ?? {},
      },
      fromJson: (json) => CartItem.fromJson(json),
    );
  }
  
  /// Update cart item
  Future<ApiResponse<CartItem>> updateCartItem({
    required String itemId,
    required int quantity,
    Map<String, dynamic>? attributes,
  }) async {
    return _put<CartItem>(
      '/cart/items/$itemId',
      body: {
        'quantity': quantity,
        'attributes': attributes ?? {},
      },
      fromJson: (json) => CartItem.fromJson(json),
    );
  }
  
  /// Remove item from cart
  Future<ApiResponse<void>> removeFromCart(String itemId) async {
    return _delete('/cart/items/$itemId');
  }
  
  /// Clear cart
  Future<ApiResponse<void>> clearCart() async {
    return _delete('/cart');
  }
  
  /// Apply coupon/promo code
  Future<ApiResponse<CouponResult>> applyCoupon(String couponCode) async {
    return _post<CouponResult>(
      '/cart/coupon',
      body: {'coupon_code': couponCode},
      fromJson: (json) => CouponResult.fromJson(json),
    );
  }
  
  /// Remove coupon
  Future<ApiResponse<void>> removeCoupon() async {
    return _delete('/cart/coupon');
  }
  
  // =============================================================================
  // ORDER ENDPOINTS
  // =============================================================================
  
  /// Create order from cart
  Future<ApiResponse<Order>> createOrder({
    required String addressId,
    required String paymentMethodId,
    String? deliveryNotes,
    DateTime? preferredDeliveryDate,
  }) async {
    return _post<Order>(
      '/orders',
      body: {
        'address_id': addressId,
        'payment_method_id': paymentMethodId,
        'delivery_notes': deliveryNotes,
        'preferred_delivery_date': preferredDeliveryDate?.toIso8601String(),
      },
      fromJson: (json) => Order.fromJson(json),
    );
  }
  
  /// Get user orders
  Future<ApiResponse<List<Order>>> getOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (status != null) queryParams['status'] = status;
    
    return _get<List<Order>>(
      '/orders',
      queryParams: queryParams,
      fromJson: (json) => (json as List).map((item) => Order.fromJson(item)).toList(),
    );
  }
  
  /// Get order by ID
  Future<ApiResponse<Order>> getOrder(String orderId) async {
    return _get<Order>(
      '/orders/$orderId',
      fromJson: (json) => Order.fromJson(json),
    );
  }
  
  /// Cancel order
  Future<ApiResponse<Order>> cancelOrder(String orderId, {String? reason}) async {
    return _post<Order>(
      '/orders/$orderId/cancel',
      body: {'reason': reason},
      fromJson: (json) => Order.fromJson(json),
    );
  }
  
  /// Track order
  Future<ApiResponse<OrderTracking>> trackOrder(String orderId) async {
    return _get<OrderTracking>(
      '/orders/$orderId/tracking',
      fromJson: (json) => OrderTracking.fromJson(json),
    );
  }
  
  /// Request return/refund
  Future<ApiResponse<ReturnRequest>> requestReturn({
    required String orderId,
    required List<String> itemIds,
    required String reason,
    String? description,
    List<File>? images,
  }) async {
    final body = {
      'order_id': orderId,
      'item_ids': itemIds,
      'reason': reason,
      'description': description,
    };
    
    if (images != null && images.isNotEmpty) {
      return _uploadFiles<ReturnRequest>(
        '/orders/$orderId/return',
        files: images,
        fieldName: 'images',
        additionalFields: body,
        fromJson: (json) => ReturnRequest.fromJson(json),
      );
    } else {
      return _post<ReturnRequest>(
        '/orders/$orderId/return',
        body: body,
        fromJson: (json) => ReturnRequest.fromJson(json),
      );
    }
  }
  
  // =============================================================================
  // WISHLIST ENDPOINTS
  // =============================================================================
  
  /// Get user wishlist
  Future<ApiResponse<List<Product>>> getWishlist({
    int page = 1,
    int limit = 20,
  }) async {
    return _get<List<Product>>(
      '/wishlist',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      fromJson: (json) => (json as List).map((item) => Product.fromJson(item)).toList(),
    );
  }
  
  /// Add product to wishlist
  Future<ApiResponse<void>> addToWishlist(String productId) async {
    return _post<void>(
      '/wishlist',
      body: {'product_id': productId},
    );
  }
  
  /// Remove product from wishlist
  Future<ApiResponse<void>> removeFromWishlist(String productId) async {
    return _delete('/wishlist/$productId');
  }
  
  /// Check if product is in wishlist
  Future<ApiResponse<bool>> isInWishlist(String productId) async {
    return _get<bool>(
      '/wishlist/$productId/status',
      fromJson: (json) => json['is_in_wishlist'] as bool,
    );
  }
  
  // =============================================================================
  // REVIEW ENDPOINTS
  // =============================================================================
  
  /// Get product reviews
  Future<ApiResponse<ReviewResponse>> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 20,
    int? rating,
    String? sortBy,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (rating != null) queryParams['rating'] = rating.toString();
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    
    return _get<ReviewResponse>(
      '/products/$productId/reviews',
      queryParams: queryParams,
      fromJson: (json) => ReviewResponse.fromJson(json),
    );
  }
  
  /// Submit product review
  Future<ApiResponse<Review>> submitReview({
    required String productId,
    required int rating,
    required String comment,
    List<File>? images,
  }) async {
    final body = {
      'product_id': productId,
      'rating': rating,
      'comment': comment,
    };
    
    if (images != null && images.isNotEmpty) {
      return _uploadFiles<Review>(
        '/products/$productId/reviews',
        files: images,
        fieldName: 'images',
        additionalFields: body,
        fromJson: (json) => Review.fromJson(json),
      );
    } else {
      return _post<Review>(
        '/products/$productId/reviews',
        body: body,
        fromJson: (json) => Review.fromJson(json),
      );
    }
  }
  
  /// Update review
  Future<ApiResponse<Review>> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
    List<File>? newImages,
  }) async {
    final body = {
      'rating': rating,
      'comment': comment,
    };
    
    if (newImages != null && newImages.isNotEmpty) {
      return _uploadFiles<Review>(
        '/reviews/$reviewId',
        files: newImages,
        fieldName: 'images',
        additionalFields: body,
        method: 'PUT',
        fromJson: (json) => Review.fromJson(json),
      );
    } else {
      return _put<Review>(
        '/reviews/$reviewId',
        body: body,
        fromJson: (json) => Review.fromJson(json),
      );
    }
  }
  
  /// Delete review
  Future<ApiResponse<void>> deleteReview(String reviewId) async {
    return _delete('/reviews/$reviewId');
  }
  
  // =============================================================================
  // NOTIFICATION ENDPOINTS
  // =============================================================================
  
  /// Get user notifications
  Future<ApiResponse<List<Notification>>> getNotifications({
    int page = 1,
    int limit = 20,
    bool? unreadOnly,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (unreadOnly != null) queryParams['unread_only'] = unreadOnly.toString();
    
    return _get<List<Notification>>(
      '/notifications',
      queryParams: queryParams,
      fromJson: (json) => (json as List).map((item) => Notification.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
  
  /// Mark notification as read
  Future<ApiResponse<void>> markNotificationRead(String notificationId) async {
    return _put<void>('/notifications/$notificationId/read');
  }
  
  /// Mark all notifications as read
  Future<ApiResponse<void>> markAllNotificationsRead() async {
    return _put<void>('/notifications/mark-all-read');
  }
  
  /// Delete notification
  Future<ApiResponse<void>> deleteNotification(String notificationId) async {
    return _delete('/notifications/$notificationId');
  }
  
  /// Update notification preferences
  Future<ApiResponse<void>> updateNotificationPreferences(
    Map<String, bool> preferences,
  ) async {
    return _put<void>(
      '/notifications/preferences',
      body: preferences,
    );
  }
  
  // =============================================================================
  // VENDOR/SHOP ENDPOINTS
  // =============================================================================
  
  /// Get shops/vendors
  Future<ApiResponse<List<Shop>>> getShops({
    int page = 1,
    int limit = 20,
    String? search,
    String? category,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    
    if (search != null) queryParams['search'] = search;
    if (category != null) queryParams['category'] = category;
    
    return _get<List<Shop>>(
      '/shops',
      queryParams: queryParams,
      fromJson: (json) => (json as List).map((item) => Shop.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
  
  /// Get shop details
  Future<ApiResponse<Shop>> getShop(String shopId) async {
    return _get<Shop>(
      '/shops/$shopId',
      fromJson: (json) => Shop.fromJson(json),
    );
  }
  
  /// Get shop products
  Future<ApiResponse<List<Product>>> getShopProducts({
    required String shopId,
    int page = 1,
    int limit = 20,
  }) async {
    return _get<List<Product>>(
      '/shops/$shopId/products',
      queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
      fromJson: (json) => (json as List).map((item) => Product.fromJson(item)).toList(),
    );
  }
  
  // =============================================================================
  // ANALYTICS ENDPOINTS
  // =============================================================================
  
  /// Track user event
  Future<ApiResponse<void>> trackEvent({
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    return _post<void>(
      '/analytics/events',
      body: {
        'event_name': eventName,
        'properties': properties ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Track page view
  Future<ApiResponse<void>> trackPageView({
    required String pageName,
    String? referrer,
    Map<String, dynamic>? metadata,
  }) async {
    return _post<void>(
      '/analytics/page-views',
      body: {
        'page_name': pageName,
        'referrer': referrer,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
  
  // =============================================================================
  // UTILITY ENDPOINTS
  // =============================================================================
  
  /// Get app configuration
  Future<ApiResponse<AppConfig>> getAppConfig() async {
    return _get<AppConfig>(
      '/config',
      fromJson: (json) => AppConfig.fromJson(json),
    );
  }
  
  /// Check app version
  Future<ApiResponse<VersionInfo>> checkVersion(String currentVersion) async {
    return _get<VersionInfo>(
      '/version/$currentVersion',
      fromJson: (json) => VersionInfo.fromJson(json),
    );
  }
  
  /// Get currency exchange rates
  Future<ApiResponse<Map<String, double>>> getExchangeRates(String baseCurrency) async {
    return _get<Map<String, double>>(
      '/currency/rates/$baseCurrency',
      fromJson: (json) => Map<String, double>.from(json),
    );
  }
  
  /// Send feedback
  Future<ApiResponse<void>> sendFeedback({
    required String subject,
    required String message,
    String? category,
    List<File>? attachments,
  }) async {
    final body = {
      'subject': subject,
      'message': message,
      'category': category,
    };
    
    if (attachments != null && attachments.isNotEmpty) {
      return _uploadFiles<void>(
        '/feedback',
        files: attachments,
        fieldName: 'attachments',
        additionalFields: body,
      );
    } else {
      return _post<void>('/feedback', body: body);
    }
  }
  
  // =============================================================================
  // HTTP HELPER METHODS
  // =============================================================================
  
  /// Generic GET request
  Future<ApiResponse<T>> _get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    return _makeRequest<T>(
      'GET',
      endpoint,
      queryParams: queryParams,
      fromJson: fromJson,
    );
  }
  
  /// Generic POST request
  Future<ApiResponse<T>> _post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    return _makeRequest<T>(
      'POST',
      endpoint,
      body: body,
      fromJson: fromJson,
    );
  }
  
  /// Generic PUT request
  Future<ApiResponse<T>> _put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? fromJson,
  }) async {
    return _makeRequest<T>(
      'PUT',
      endpoint,
      body: body,
      fromJson: fromJson,
    );
  }
  
  /// Generic DELETE request
  Future<ApiResponse<T>> _delete<T>(String endpoint) async {
    return _makeRequest<T>('DELETE', endpoint);
  }
  
  /// Upload single file
  Future<ApiResponse<T>> _uploadFile<T>(
    String endpoint, {
    required File file,
    required String fieldName,
    Map<String, dynamic>? additionalFields,
    T Function(dynamic)? fromJson,
  }) async {
    return _uploadFiles<T>(
      endpoint,
      files: [file],
      fieldName: fieldName,
      additionalFields: additionalFields,
      fromJson: fromJson,
    );
  }
  
  /// Upload multiple files
  Future<ApiResponse<T>> _uploadFiles<T>(
    String endpoint, {
    required List<File> files,
    required String fieldName,
    Map<String, dynamic>? additionalFields,
    String method = 'POST',
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final request = http.MultipartRequest(method, uri);
      
      // Add headers
      request.headers.addAll(_authenticatedHeaders);
      
      // Add files
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final multipartFile = await http.MultipartFile.fromPath(
          files.length == 1 ? fieldName : '${fieldName}[$i]',
          file.path,
        );
        request.files.add(multipartFile);
      }
      
      // Add additional fields
      if (additionalFields != null) {
        additionalFields.forEach((key, value) {
          request.fields[key] = value?.toString() ?? '';
        });
      }
      
      final streamedResponse = await request.send().timeout(_defaultTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse<T>(response, fromJson: fromJson);
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Upload failed: $e',
        statusCode: 0,
      );
    }
  }
  
  /// Make HTTP request with retry logic
  Future<ApiResponse<T>> _makeRequest<T>(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    var uri = Uri.parse('$_baseUrl$endpoint');
    
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        http.Response response;
        
        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: _authenticatedHeaders)
                .timeout(_defaultTimeout);
            break;
          case 'POST':
            response = await http.post(
              uri,
              headers: _authenticatedHeaders,
              body: body != null ? json.encode(body) : null,
            ).timeout(_defaultTimeout);
            break;
          case 'PUT':
            response = await http.put(
              uri,
              headers: _authenticatedHeaders,
              body: body != null ? json.encode(body) : null,
            ).timeout(_defaultTimeout);
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: _authenticatedHeaders)
                .timeout(_defaultTimeout);
            break;
          default:
            throw ArgumentError('Unsupported HTTP method: $method');
        }
        
        return _handleResponse<T>(response, fromJson: fromJson);
        
      } catch (e) {
        if (attempt == _maxRetries - 1) {
          return ApiResponse<T>(
            success: false,
            message: 'Network error after $_maxRetries attempts: $e',
            statusCode: 0,
          );
        }
        
        // Wait before retrying
        await Future.delayed(Duration(seconds: attempt + 1));
      }
    }
    
    return ApiResponse<T>(
      success: false,
      message: 'Request failed after $_maxRetries attempts',
      statusCode: 0,
    );
  }
  
  /// Handle HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response, {
    T Function(dynamic)? fromJson,
  }) {
    try {
      final statusCode = response.statusCode;
      
      if (statusCode >= 200 && statusCode < 300) {
        // Success response
        if (response.body.isEmpty) {
          return ApiResponse<T>(
            success: true,
            statusCode: statusCode,
          );
        }
        
        final jsonData = json.decode(response.body);
        
        if (fromJson != null) {
          final data = fromJson(jsonData['data'] ?? jsonData);
          return ApiResponse<T>(
            success: true,
            data: data,
            message: jsonData['message'],
            statusCode: statusCode,
          );
        } else {
          return ApiResponse<T>(
            success: true,
            message: jsonData['message'],
            statusCode: statusCode,
          );
        }
        
      } else {
        // Error response
        final jsonData = json.decode(response.body);
        return ApiResponse<T>(
          success: false,
          message: jsonData['message'] ?? 'Request failed',
          errors: jsonData['errors'],
          statusCode: statusCode,
        );
      }
      
    } catch (e) {
      return ApiResponse<T>(
        success: false,
        message: 'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }
}

// =============================================================================
// RESPONSE MODELS
// =============================================================================

/// Generic API response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? errors;
  final int statusCode;
  
  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
    required this.statusCode,
  });
  
  bool get isSuccess => success && statusCode >= 200 && statusCode < 300;
  bool get isError => !success || statusCode >= 400;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode >= 500;
}

/// Authentication data model
class AuthData {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final User user;
  
  const AuthData({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });
  
  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

/// Product response with pagination
class ProductResponse {
  final List<Product> products;
  final int totalCount;
  final int page;
  final int limit;
  final bool hasMore;
  
  const ProductResponse({
    required this.products,
    required this.totalCount,
    required this.page,
    required this.limit,
    required this.hasMore,
  });
  
  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      products: (json['products'] as List)
          .map((item) => Product.fromJson(item))
          .toList(),
      totalCount: json['total_count'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      hasMore: json['has_more'] as bool,
    );
  }
}

/// Search response model
class SearchResponse {
  final List<Product> products;
  final int totalCount;
  final String query;
  final Map<String, dynamic> filters;
  final List<String> suggestions;
  
  const SearchResponse({
    required this.products,
    required this.totalCount,
    required this.query,
    required this.filters,
    required this.suggestions,
  });
  
  factory SearchResponse.fromJson(Map<String, dynamic> json) {
    return SearchResponse(
      products: (json['products'] as List)
          .map((item) => Product.fromJson(item))
          .toList(),
      totalCount: json['total_count'] as int,
      query: json['query'] as String,
      filters: json['filters'] as Map<String, dynamic>,
      suggestions: List<String>.from(json['suggestions'] as List),
    );
  }
}

// Placeholder models - would need proper implementation
class Category {
  const Category();
  factory Category.fromJson(Map<String, dynamic> json) => const Category();
}

class CouponResult {
  const CouponResult();
  factory CouponResult.fromJson(Map<String, dynamic> json) => const CouponResult();
}

class OrderTracking {
  const OrderTracking();
  factory OrderTracking.fromJson(Map<String, dynamic> json) => const OrderTracking();
}

class ReturnRequest {
  const ReturnRequest();
  factory ReturnRequest.fromJson(Map<String, dynamic> json) => const ReturnRequest();
}

class ReviewResponse {
  const ReviewResponse();
  factory ReviewResponse.fromJson(Map<String, dynamic> json) => const ReviewResponse();
}

class Review {
  const Review();
  factory Review.fromJson(Map<String, dynamic> json) => const Review();
}

class Notification {
  const Notification();
  factory Notification.fromJson(Map<String, dynamic> json) => const Notification();
}

class Shop {
  const Shop();
  factory Shop.fromJson(Map<String, dynamic> json) => const Shop();
}

class AppConfig {
  const AppConfig();
  factory AppConfig.fromJson(Map<String, dynamic> json) => const AppConfig();
}

class VersionInfo {
  const VersionInfo();
  factory VersionInfo.fromJson(Map<String, dynamic> json) => const VersionInfo();
}
