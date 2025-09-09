import '../core/services/base_api_service.dart';
import '../core/exceptions/api_exceptions.dart';
import '../models/product.dart';
import '../models/search_result.dart';

/// Specialized API service for product operations
class ProductApiService extends BaseApiService {
  @override
  String? _getAuthToken() {
    // This would be injected or retrieved from a service
    return null;
  }

  /// Get products with pagination and filters
  Future<List<Product>> getProducts({
    int page = 1,
    int limit = 20,
    String? category,
    String? brand,
    String? search,
    String? sortBy,
    String? sortOrder = 'asc',
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? inStock,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
        if (brand != null) 'brand': brand,
        if (search != null) 'search': search,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (minRating != null) 'minRating': minRating,
        if (inStock != null) 'inStock': inStock,
      };

      final response = await get<List<dynamic>>(
        '/products',
        queryParameters: queryParams,
      );

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch products: ${e.toString()}');
    }
  }

  /// Get product by ID
  Future<Product> getProductById(String productId) async {
    try {
      final response = await get<Map<String, dynamic>>('/products/$productId');
      return Product.fromJson(response);
    } on NotFoundException {
      throw const NotFoundException('Product not found');
    } catch (e) {
      throw ServerException('Failed to fetch product: ${e.toString()}');
    }
  }

  /// Search products
  Future<SearchResult> searchProducts({
    required String query,
    int page = 1,
    int limit = 20,
    String? category,
    String? brand,
    String? sortBy,
    String? sortOrder = 'asc',
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'q': query,
        'page': page,
        'limit': limit,
        if (category != null) 'category': category,
        if (brand != null) 'brand': brand,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (minRating != null) 'minRating': minRating,
      };

      final response = await get<Map<String, dynamic>>(
        '/products/search',
        queryParameters: queryParams,
      );

      return SearchResult.fromJson(response);
    } catch (e) {
      throw ServerException('Search failed: ${e.toString()}');
    }
  }

  /// Get product recommendations
  Future<List<Product>> getRecommendations({
    String? userId,
    String? productId,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (userId != null) 'userId': userId,
        if (productId != null) 'productId': productId,
      };

      final response = await get<List<dynamic>>(
        '/products/recommendations',
        queryParameters: queryParams,
      );

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch recommendations: ${e.toString()}');
    }
  }

  /// Get trending products
  Future<List<Product>> getTrendingProducts({
    int limit = 10,
    String? category,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (category != null) 'category': category,
      };

      final response = await get<List<dynamic>>(
        '/products/trending',
        queryParameters: queryParams,
      );

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ServerException(
          'Failed to fetch trending products: ${e.toString()}');
    }
  }

  /// Get recently viewed products
  Future<List<Product>> getRecentlyViewed({
    int limit = 10,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/products/recently-viewed',
        queryParameters: {'limit': limit},
      );

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ServerException(
          'Failed to fetch recently viewed products: ${e.toString()}');
    }
  }

  /// Get product categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await get<List<dynamic>>('/categories');
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ServerException('Failed to fetch categories: ${e.toString()}');
    }
  }

  /// Get product brands
  Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      final response = await get<List<dynamic>>('/brands');
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw ServerException('Failed to fetch brands: ${e.toString()}');
    }
  }

  /// Get product reviews
  Future<Map<String, dynamic>> getProductReviews({
    required String productId,
    int page = 1,
    int limit = 20,
    String? sortBy = 'date',
    String? sortOrder = 'desc',
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      final response = await get<Map<String, dynamic>>(
        '/products/$productId/reviews',
        queryParameters: queryParams,
      );

      return response;
    } catch (e) {
      throw ServerException('Failed to fetch reviews: ${e.toString()}');
    }
  }

  /// Create product review
  Future<bool> createReview({
    required String productId,
    required int rating,
    required String comment,
    List<String>? images,
  }) async {
    try {
      await post('/reviews', body: {
        'productId': productId,
        'rating': rating,
        'comment': comment,
        if (images != null) 'images': images,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Update product review
  Future<bool> updateReview({
    required String reviewId,
    int? rating,
    String? comment,
    List<String>? images,
  }) async {
    try {
      await put('/reviews/$reviewId', body: {
        if (rating != null) 'rating': rating,
        if (comment != null) 'comment': comment,
        if (images != null) 'images': images,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Delete product review
  Future<bool> deleteReview(String reviewId) async {
    try {
      await delete('/reviews/$reviewId');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add product to wishlist
  Future<bool> addToWishlist(String productId) async {
    try {
      await post('/wishlist/add', body: {'productId': productId});
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove product from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      await delete('/wishlist/remove/$productId');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get wishlist products
  Future<List<Product>> getWishlist() async {
    try {
      final response = await get<List<dynamic>>('/wishlist');
      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch wishlist: ${e.toString()}');
    }
  }

  /// Track product view
  Future<void> trackProductView(String productId) async {
    try {
      await post('/analytics/track-view', body: {'productId': productId});
    } catch (e) {
      // Don't throw error for analytics tracking
    }
  }

  /// Get product analytics
  Future<Map<String, dynamic>> getProductAnalytics(String productId) async {
    try {
      final response =
          await get<Map<String, dynamic>>('/products/$productId/analytics');
      return response;
    } catch (e) {
      throw ServerException(
          'Failed to fetch product analytics: ${e.toString()}');
    }
  }

  /// Get similar products
  Future<List<Product>> getSimilarProducts({
    required String productId,
    int limit = 5,
  }) async {
    try {
      final response = await get<List<dynamic>>(
        '/products/$productId/similar',
        queryParameters: {'limit': limit},
      );

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw ServerException(
          'Failed to fetch similar products: ${e.toString()}');
    }
  }

  /// Get product availability
  Future<Map<String, dynamic>> getProductAvailability(String productId) async {
    try {
      final response =
          await get<Map<String, dynamic>>('/products/$productId/availability');
      return response;
    } catch (e) {
      throw ServerException(
          'Failed to fetch product availability: ${e.toString()}');
    }
  }

  /// Check product stock
  Future<bool> checkProductStock(String productId, int quantity) async {
    try {
      final response = await get<Map<String, dynamic>>(
        '/products/$productId/stock',
        queryParameters: {'quantity': quantity},
      );
      return response['available'] ?? false;
    } catch (e) {
      return false;
    }
  }
}
