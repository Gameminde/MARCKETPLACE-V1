import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';

import '../core/config/app_constants.dart';
import '../services/xp_system.dart';
import '../services/api_service.dart';
import '../models/user.dart';

/// Review rating enumeration
enum ReviewRating { one, two, three, four, five }

extension ReviewRatingExtension on ReviewRating {
  int get value {
    switch (this) {
      case ReviewRating.one:
        return 1;
      case ReviewRating.two:
        return 2;
      case ReviewRating.three:
        return 3;
      case ReviewRating.four:
        return 4;
      case ReviewRating.five:
        return 5;
    }
  }
  
  static ReviewRating fromValue(int value) {
    switch (value) {
      case 1:
        return ReviewRating.one;
      case 2:
        return ReviewRating.two;
      case 3:
        return ReviewRating.three;
      case 4:
        return ReviewRating.four;
      case 5:
        return ReviewRating.five;
      default:
        return ReviewRating.five;
    }
  }
}

/// Review model with comprehensive data
class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final ReviewRating rating;
  final String title;
  final String comment;
  final List<String> imageUrls;
  final List<String> videoUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isVerifiedPurchase;
  final Map<String, dynamic>? metadata;
  final int helpfulCount;
  final int reportCount;
  final List<String> tags;
  final bool isOwnerResponse;
  final String? ownerResponseText;
  final DateTime? ownerResponseDate;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.rating,
    required this.title,
    required this.comment,
    this.imageUrls = const [],
    this.videoUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.isVerifiedPurchase = false,
    this.metadata,
    this.helpfulCount = 0,
    this.reportCount = 0,
    this.tags = const [],
    this.isOwnerResponse = false,
    this.ownerResponseText,
    this.ownerResponseDate,
  });

  ProductReview copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    String? userAvatarUrl,
    ReviewRating? rating,
    String? title,
    String? comment,
    List<String>? imageUrls,
    List<String>? videoUrls,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isVerifiedPurchase,
    Map<String, dynamic>? metadata,
    int? helpfulCount,
    int? reportCount,
    List<String>? tags,
    bool? isOwnerResponse,
    String? ownerResponseText,
    DateTime? ownerResponseDate,
  }) {
    return ProductReview(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      metadata: metadata ?? this.metadata,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      reportCount: reportCount ?? this.reportCount,
      tags: tags ?? this.tags,
      isOwnerResponse: isOwnerResponse ?? this.isOwnerResponse,
      ownerResponseText: ownerResponseText ?? this.ownerResponseText,
      ownerResponseDate: ownerResponseDate ?? this.ownerResponseDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'rating': rating.value,
      'title': title,
      'comment': comment,
      'image_urls': imageUrls,
      'video_urls': videoUrls,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_verified_purchase': isVerifiedPurchase,
      'metadata': metadata,
      'helpful_count': helpfulCount,
      'report_count': reportCount,
      'tags': tags,
      'is_owner_response': isOwnerResponse,
      'owner_response_text': ownerResponseText,
      'owner_response_date': ownerResponseDate?.toIso8601String(),
    };
  }

  static ProductReview fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'],
      productId: json['product_id'],
      userId: json['user_id'],
      userName: json['user_name'],
      userAvatarUrl: json['user_avatar_url'],
      rating: ReviewRatingExtension.fromValue(json['rating']),
      title: json['title'],
      comment: json['comment'],
      imageUrls: List<String>.from(json['image_urls'] ?? []),
      videoUrls: List<String>.from(json['video_urls'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isVerifiedPurchase: json['is_verified_purchase'] ?? false,
      metadata: json['metadata'],
      helpfulCount: json['helpful_count'] ?? 0,
      reportCount: json['report_count'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      isOwnerResponse: json['is_owner_response'] ?? false,
      ownerResponseText: json['owner_response_text'],
      ownerResponseDate: json['owner_response_date'] != null 
          ? DateTime.parse(json['owner_response_date']) 
          : null,
    );
  }

  bool get hasMedia => imageUrls.isNotEmpty || videoUrls.isNotEmpty;
  double get ratingValue => rating.value.toDouble();
}

/// Review statistics model
class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final int totalWithPhotos;
  final int totalVerifiedPurchases;
  final List<String> commonTags;

  const ReviewStats({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    required this.totalWithPhotos,
    required this.totalVerifiedPurchases,
    required this.commonTags,
  });

  static ReviewStats fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      averageRating: (json['average_rating'] as num).toDouble(),
      totalReviews: json['total_reviews'],
      ratingDistribution: Map<int, int>.from(json['rating_distribution']),
      totalWithPhotos: json['total_with_photos'] ?? 0,
      totalVerifiedPurchases: json['total_verified_purchases'] ?? 0,
      commonTags: List<String>.from(json['common_tags'] ?? []),
    );
  }

  double getRatingPercentage(int rating) {
    if (totalReviews == 0) return 0.0;
    return (ratingDistribution[rating] ?? 0) / totalReviews;
  }
}

/// Review filter options
class ReviewFilter {
  final List<ReviewRating>? ratings;
  final bool? withPhotosOnly;
  final bool? verifiedPurchasesOnly;
  final String? sortBy; // newest, oldest, helpful, rating_high, rating_low
  final List<String>? tags;

  const ReviewFilter({
    this.ratings,
    this.withPhotosOnly,
    this.verifiedPurchasesOnly,
    this.sortBy,
    this.tags,
  });

  ReviewFilter copyWith({
    List<ReviewRating>? ratings,
    bool? withPhotosOnly,
    bool? verifiedPurchasesOnly,
    String? sortBy,
    List<String>? tags,
  }) {
    return ReviewFilter(
      ratings: ratings ?? this.ratings,
      withPhotosOnly: withPhotosOnly ?? this.withPhotosOnly,
      verifiedPurchasesOnly: verifiedPurchasesOnly ?? this.verifiedPurchasesOnly,
      sortBy: sortBy ?? this.sortBy,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ratings': ratings?.map((r) => r.value).toList(),
      'with_photos_only': withPhotosOnly,
      'verified_purchases_only': verifiedPurchasesOnly,
      'sort_by': sortBy,
      'tags': tags,
    };
  }
}

/// Comprehensive review system provider
class ReviewSystem extends ChangeNotifier {
  static ReviewSystem? _instance;
  static ReviewSystem get instance => _instance ??= ReviewSystem._internal();
  
  ReviewSystem._internal();

  // Service dependencies
  final ApiService _apiService = ApiService();
  late XPSystem _xpSystem;

  // Review data
  final Map<String, List<ProductReview>> _productReviews = {};
  final Map<String, ReviewStats> _reviewStats = {};
  final Map<String, ProductReview> _userReviews = {};
  
  // Loading states
  final Map<String, bool> _loadingStates = {};
  bool _isSubmitting = false;

  // Error handling
  String? _errorMessage;

  // Getters
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  
  bool isLoading(String productId) => _loadingStates[productId] ?? false;
  List<ProductReview> getProductReviews(String productId) => 
      _productReviews[productId] ?? [];
  ReviewStats? getReviewStats(String productId) => _reviewStats[productId];
  ProductReview? getUserReview(String productId) => _userReviews[productId];

  /// Initialize the review system
  Future<void> initialize() async {
    try {
      _xpSystem = XPSystem.instance;
      await _loadCachedReviews();
      debugPrint('ReviewSystem initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ReviewSystem: $e');
      _setError('Failed to initialize review system');
    }
  }

  /// Load reviews for a product
  Future<void> loadProductReviews(
    String productId, {
    ReviewFilter? filter,
    int page = 1,
    int limit = 20,
  }) async {
    if (isLoading(productId)) return;

    _setLoading(productId, true);
    _clearError();

    try {
      // In a real app, this would call the API
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Mock API call
      final mockReviews = _generateMockReviews(productId, limit);
      final mockStats = _generateMockStats(productId);
      
      if (page == 1) {
        _productReviews[productId] = mockReviews;
      } else {
        _productReviews[productId] = [
          ...(_productReviews[productId] ?? []),
          ...mockReviews,
        ];
      }
      
      _reviewStats[productId] = mockStats;
      
      await _cacheReviews(productId);
      notifyListeners();
      
    } catch (e) {
      _setError('Failed to load reviews: $e');
      debugPrint('Error loading product reviews: $e');
    } finally {
      _setLoading(productId, false);
    }
  }

  /// Submit a new review
  Future<bool> submitReview({
    required String productId,
    required ReviewRating rating,
    required String title,
    required String comment,
    List<File>? images,
    List<File>? videos,
    List<String>? tags,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _clearError();
    notifyListeners();

    try {
      // Upload media files first
      List<String> imageUrls = [];
      List<String> videoUrls = [];
      
      if (images != null && images.isNotEmpty) {
        imageUrls = await _uploadImages(images);
      }
      
      if (videos != null && videos.isNotEmpty) {
        videoUrls = await _uploadVideos(videos);
      }

      // Create review object
      final review = ProductReview(
        id: 'review_${DateTime.now().millisecondsSinceEpoch}',
        productId: productId,
        userId: 'current_user', // In real app, get from auth
        userName: 'Current User', // In real app, get from auth
        userAvatarUrl: null,
        rating: rating,
        title: title,
        comment: comment,
        imageUrls: imageUrls,
        videoUrls: videoUrls,
        createdAt: DateTime.now(),
        isVerifiedPurchase: true, // Mock verified purchase
        tags: tags ?? [],
      );

      // Submit to API (mock)
      await Future.delayed(const Duration(seconds: 1));
      
      // Add to local cache
      if (_productReviews[productId] == null) {
        _productReviews[productId] = [];
      }
      _productReviews[productId]!.insert(0, review);
      _userReviews[productId] = review;
      
      // Update stats
      _updateReviewStats(productId, review);
      
      // Award XP
      if (imageUrls.isNotEmpty || videoUrls.isNotEmpty) {
        await _xpSystem.addXP(XPAction.photoReview,
          customDescription: 'Submitted review with photos for $title');
      } else {
        await _xpSystem.addXP(XPAction.review,
          customDescription: 'Submitted review for $title');
      }
      
      await _cacheReviews(productId);
      notifyListeners();
      
      return true;
      
    } catch (e) {
      _setError('Failed to submit review: $e');
      debugPrint('Error submitting review: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Update an existing review
  Future<bool> updateReview({
    required String reviewId,
    required String productId,
    ReviewRating? rating,
    String? title,
    String? comment,
    List<File>? newImages,
    List<File>? newVideos,
    List<String>? tags,
  }) async {
    if (_isSubmitting) return false;

    _isSubmitting = true;
    _clearError();
    notifyListeners();

    try {
      final existingReview = _userReviews[productId];
      if (existingReview == null) {
        throw Exception('Review not found');
      }

      // Upload new media files
      List<String> imageUrls = existingReview.imageUrls;
      List<String> videoUrls = existingReview.videoUrls;
      
      if (newImages != null && newImages.isNotEmpty) {
        imageUrls = await _uploadImages(newImages);
      }
      
      if (newVideos != null && newVideos.isNotEmpty) {
        videoUrls = await _uploadVideos(newVideos);
      }

      // Update review
      final updatedReview = existingReview.copyWith(
        rating: rating,
        title: title,
        comment: comment,
        imageUrls: imageUrls,
        videoUrls: videoUrls,
        tags: tags,
        updatedAt: DateTime.now(),
      );

      // Update API (mock)
      await Future.delayed(const Duration(seconds: 1));
      
      // Update local cache
      final reviewIndex = _productReviews[productId]!
          .indexWhere((r) => r.id == reviewId);
      if (reviewIndex >= 0) {
        _productReviews[productId]![reviewIndex] = updatedReview;
      }
      _userReviews[productId] = updatedReview;
      
      await _cacheReviews(productId);
      notifyListeners();
      
      return true;
      
    } catch (e) {
      _setError('Failed to update review: $e');
      debugPrint('Error updating review: $e');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Delete a review
  Future<bool> deleteReview(String reviewId, String productId) async {
    try {
      // Delete from API (mock)
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Remove from local cache
      _productReviews[productId]?.removeWhere((r) => r.id == reviewId);
      _userReviews.remove(productId);
      
      await _cacheReviews(productId);
      notifyListeners();
      
      return true;
      
    } catch (e) {
      _setError('Failed to delete review: $e');
      debugPrint('Error deleting review: $e');
      return false;
    }
  }

  /// Mark review as helpful
  Future<bool> markReviewHelpful(String reviewId, String productId) async {
    try {
      // Update API (mock)
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Update local cache
      final reviews = _productReviews[productId];
      if (reviews != null) {
        final reviewIndex = reviews.indexWhere((r) => r.id == reviewId);
        if (reviewIndex >= 0) {
          _productReviews[productId]![reviewIndex] = reviews[reviewIndex]
              .copyWith(helpfulCount: reviews[reviewIndex].helpfulCount + 1);
        }
      }
      
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('Error marking review as helpful: $e');
      return false;
    }
  }

  /// Report a review
  Future<bool> reportReview(String reviewId, String productId, String reason) async {
    try {
      // Report to API (mock)
      await Future.delayed(const Duration(milliseconds: 500));
      
      return true;
      
    } catch (e) {
      _setError('Failed to report review: $e');
      debugPrint('Error reporting review: $e');
      return false;
    }
  }

  /// Get user's review history
  Future<List<ProductReview>> getUserReviewHistory({int limit = 50}) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Return mock user reviews
      return _userReviews.values.toList();
      
    } catch (e) {
      _setError('Failed to load review history: $e');
      debugPrint('Error loading user review history: $e');
      return [];
    }
  }

  /// Clear all cached reviews
  Future<void> clearCache() async {
    _productReviews.clear();
    _reviewStats.clear();
    _userReviews.clear();
    
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('reviews_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
    
    notifyListeners();
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Upload images to server
  Future<List<String>> _uploadImages(List<File> images) async {
    // Mock upload process
    await Future.delayed(Duration(seconds: images.length));
    
    // Return mock URLs
    return images.map((file) => 
        'https://example.com/reviews/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}'
    ).toList();
  }

  /// Upload videos to server
  Future<List<String>> _uploadVideos(List<File> videos) async {
    // Mock upload process
    await Future.delayed(Duration(seconds: videos.length * 2));
    
    // Return mock URLs
    return videos.map((file) => 
        'https://example.com/reviews/videos/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}'
    ).toList();
  }

  /// Generate mock reviews for testing
  List<ProductReview> _generateMockReviews(String productId, int count) {
    final reviews = <ProductReview>[];
    final now = DateTime.now();
    
    for (int i = 0; i < count; i++) {
      reviews.add(ProductReview(
        id: 'review_${productId}_$i',
        productId: productId,
        userId: 'user_$i',
        userName: 'User ${i + 1}',
        userAvatarUrl: i % 3 == 0 ? 'https://example.com/avatar$i.jpg' : null,
        rating: ReviewRatingExtension.fromValue((i % 5) + 1),
        title: _getMockReviewTitle(i),
        comment: _getMockReviewComment(i),
        imageUrls: i % 4 == 0 ? ['https://example.com/review$i.jpg'] : [],
        createdAt: now.subtract(Duration(days: i)),
        isVerifiedPurchase: i % 3 == 0,
        helpfulCount: i % 7,
        tags: i % 5 == 0 ? ['quality', 'value'] : [],
      ));
    }
    
    return reviews;
  }

  /// Generate mock review statistics
  ReviewStats _generateMockStats(String productId) {
    return ReviewStats(
      averageRating: 4.2,
      totalReviews: 156,
      ratingDistribution: {
        5: 89,
        4: 34,
        3: 21,
        2: 8,
        1: 4,
      },
      totalWithPhotos: 45,
      totalVerifiedPurchases: 123,
      commonTags: ['quality', 'value', 'fast shipping', 'as described'],
    );
  }

  String _getMockReviewTitle(int index) {
    final titles = [
      'Great product!',
      'Excellent quality',
      'Good value for money',
      'Fast delivery',
      'As described',
      'Could be better',
      'Perfect!',
      'Highly recommended',
      'Not bad',
      'Love it!',
    ];
    return titles[index % titles.length];
  }

  String _getMockReviewComment(int index) {
    final comments = [
      'Really happy with this purchase. The quality is excellent and it arrived quickly.',
      'Good product overall. Does what it says and the price is reasonable.',
      'Great value for money. Would definitely buy again.',
      'The delivery was super fast and the product is exactly as described.',
      'Perfect quality and great customer service. Highly recommend!',
      'It\'s okay, but could be improved in some areas.',
      'Absolutely love this product! Exceeded my expectations.',
      'Good quality but took a while to arrive.',
      'Nice product, works as expected.',
      'Amazing quality and great price point!',
    ];
    return comments[index % comments.length];
  }

  /// Update review statistics
  void _updateReviewStats(String productId, ProductReview review) {
    final currentStats = _reviewStats[productId];
    if (currentStats != null) {
      final newDistribution = Map<int, int>.from(currentStats.ratingDistribution);
      newDistribution[review.rating.value] = 
          (newDistribution[review.rating.value] ?? 0) + 1;
      
      final totalReviews = currentStats.totalReviews + 1;
      final totalRating = currentStats.averageRating * currentStats.totalReviews + 
          review.rating.value;
      final newAverage = totalRating / totalReviews;
      
      _reviewStats[productId] = ReviewStats(
        averageRating: newAverage,
        totalReviews: totalReviews,
        ratingDistribution: newDistribution,
        totalWithPhotos: currentStats.totalWithPhotos + 
            (review.hasMedia ? 1 : 0),
        totalVerifiedPurchases: currentStats.totalVerifiedPurchases + 
            (review.isVerifiedPurchase ? 1 : 0),
        commonTags: currentStats.commonTags,
      );
    }
  }

  /// Cache reviews to local storage
  Future<void> _cacheReviews(String productId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Cache reviews
      final reviews = _productReviews[productId];
      if (reviews != null) {
        final reviewsJson = reviews.map((r) => r.toJson()).toList();
        await prefs.setString('reviews_$productId', jsonEncode(reviewsJson));
      }
      
      // Cache stats
      final stats = _reviewStats[productId];
      if (stats != null) {
        await prefs.setString('stats_$productId', jsonEncode({
          'average_rating': stats.averageRating,
          'total_reviews': stats.totalReviews,
          'rating_distribution': stats.ratingDistribution,
          'total_with_photos': stats.totalWithPhotos,
          'total_verified_purchases': stats.totalVerifiedPurchases,
          'common_tags': stats.commonTags,
        }));
      }
      
    } catch (e) {
      debugPrint('Error caching reviews: $e');
    }
  }

  /// Load cached reviews from local storage
  Future<void> _loadCachedReviews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('reviews_'));
      
      for (final key in keys) {
        final productId = key.substring(8); // Remove 'reviews_' prefix
        final reviewsJson = prefs.getString(key);
        
        if (reviewsJson != null) {
          final reviewsList = jsonDecode(reviewsJson) as List;
          _productReviews[productId] = reviewsList
              .map((json) => ProductReview.fromJson(json))
              .toList();
        }
        
        // Load stats
        final statsJson = prefs.getString('stats_$productId');
        if (statsJson != null) {
          final statsMap = jsonDecode(statsJson);
          _reviewStats[productId] = ReviewStats.fromJson(statsMap);
        }
      }
      
    } catch (e) {
      debugPrint('Error loading cached reviews: $e');
    }
  }

  /// Set loading state
  void _setLoading(String productId, bool loading) {
    _loadingStates[productId] = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }
}