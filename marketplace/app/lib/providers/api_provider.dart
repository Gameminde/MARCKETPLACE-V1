import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/product.dart';
import '../models/shop.dart';
import '../models/user.dart';

class ApiProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  // Products API
  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      _setLoading(true);
      final response = await _apiService.client.get('/products/featured', 
        queryParameters: {'limit': limit}
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> productsData = response.data['data'] ?? [];
        return productsData.map((json) => Product.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      _setError('Failed to load featured products: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Product> getProductById(String productId) async {
    try {
      _setLoading(true);
      final response = await _apiService.client.get('/products/$productId');
      
      if (response.data['success'] == true) {
        return Product.fromJson(response.data['data']);
      }
      
      throw Exception('Product not found');
    } catch (e) {
      _setError('Failed to load product: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Product>> searchProducts({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      _setLoading(true);
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (query != null) queryParams['q'] = query;
      if (category != null) queryParams['category'] = category;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      
      final response = await _apiService.client.get('/products/search', 
        queryParameters: queryParams
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> productsData = response.data['data'] ?? [];
        return productsData.map((json) => Product.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      _setError('Failed to search products: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Shops API
  Future<List<Shop>> getPopularShops({int limit = 10}) async {
    try {
      _setLoading(true);
      final response = await _apiService.client.get('/shops/popular', 
        queryParameters: {'limit': limit}
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> shopsData = response.data['data'] ?? [];
        return shopsData.map((json) => Shop.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      _setError('Failed to load popular shops: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  Future<Shop> getShopById(String shopId) async {
    try {
      _setLoading(true);
      final response = await _apiService.client.get('/shops/$shopId');
      
      if (response.data['success'] == true) {
        return Shop.fromJson(response.data['data']);
      }
      
      throw Exception('Shop not found');
    } catch (e) {
      _setError('Failed to load shop: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<List<Product>> getShopProducts(String shopId, {int page = 1, int limit = 20}) async {
    try {
      _setLoading(true);
      final response = await _apiService.client.get('/shops/$shopId/products', 
        queryParameters: {'page': page, 'limit': limit}
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> productsData = response.data['data'] ?? [];
        return productsData.map((json) => Product.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      _setError('Failed to load shop products: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // User interactions
  Future<bool> isFollowingShop(String shopId) async {
    try {
      final response = await _apiService.client.get('/shops/$shopId/following');
      return response.data['data']['isFollowing'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> followShop(String shopId) async {
    try {
      await _apiService.client.post('/shops/$shopId/follow');
    } catch (e) {
      _setError('Failed to follow shop: $e');
      rethrow;
    }
  }

  Future<void> unfollowShop(String shopId) async {
    try {
      await _apiService.client.delete('/shops/$shopId/follow');
    } catch (e) {
      _setError('Failed to unfollow shop: $e');
      rethrow;
    }
  }

  // Cart operations
  Future<bool> isProductInCart(String productId) async {
    try {
      final response = await _apiService.client.get('/cart/check/$productId');
      return response.data['data']['inCart'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> addToCart(String productId, int quantity) async {
    try {
      await _apiService.client.post('/cart/add', data: {
        'productId': productId,
        'quantity': quantity,
      });
    } catch (e) {
      _setError('Failed to add to cart: $e');
      rethrow;
    }
  }

  Future<void> removeFromCart(String productId) async {
    try {
      await _apiService.client.delete('/cart/remove/$productId');
    } catch (e) {
      _setError('Failed to remove from cart: $e');
      rethrow;
    }
  }

  // Favorites operations
  Future<bool> isProductFavorite(String productId) async {
    try {
      final response = await _apiService.client.get('/favorites/check/$productId');
      return response.data['data']['isFavorite'] ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> addToFavorites(String productId) async {
    try {
      await _apiService.client.post('/favorites/add', data: {
        'productId': productId,
      });
    } catch (e) {
      _setError('Failed to add to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String productId) async {
    try {
      await _apiService.client.delete('/favorites/remove/$productId');
    } catch (e) {
      _setError('Failed to remove from favorites: $e');
      rethrow;
    }
  }

  // Categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _apiService.client.get('/categories');
      
      if (response.data['success'] == true) {
        final List<dynamic> categoriesData = response.data['data'] ?? [];
        return categoriesData.map((item) => item.toString()).toList();
      }
      
      return [];
    } catch (e) {
      _setError('Failed to load categories: $e');
      return [];
    }
  }

  // Orders
  Future<List<Map<String, dynamic>>> getUserOrders({int page = 1, int limit = 20}) async {
    try {
      _setLoading(true);
      final response = await _apiService.client.get('/orders', 
        queryParameters: {'page': page, 'limit': limit}
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> ordersData = response.data['data'] ?? [];
        return ordersData.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      _setError('Failed to load orders: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Search suggestions
  Future<List<String>> getSearchSuggestions(String query) async {
    try {
      final response = await _apiService.client.get('/search/suggestions', 
        queryParameters: {'q': query}
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> suggestions = response.data['data'] ?? [];
        return suggestions.map((item) => item.toString()).toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications({int page = 1, int limit = 20}) async {
    try {
      final response = await _apiService.client.get('/notifications', 
        queryParameters: {'page': page, 'limit': limit}
      );
      
      if (response.data['success'] == true) {
        final List<dynamic> notificationsData = response.data['data'] ?? [];
        return notificationsData.cast<Map<String, dynamic>>();
      }
      
      return [];
    } catch (e) {
      _setError('Failed to load notifications: $e');
      return [];
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _apiService.client.put('/notifications/$notificationId/read');
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    if (error != null) {
      debugPrint('ApiProvider Error: $error');
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Upload file
  Future<String> uploadFile(String filePath, {String type = 'image'}) async {
    try {
      _setLoading(true);
      
      // TODO: Implement file upload logic
      // This would typically use FormData with the file
      
      throw UnimplementedError('File upload not implemented yet');
    } catch (e) {
      _setError('Failed to upload file: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Analytics
  Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {
    try {
      await _apiService.client.post('/analytics/track', data: {
        'event': eventName,
        'properties': properties,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Analytics failures should not affect user experience
      debugPrint('Analytics tracking failed: $e');
    }
  }
}