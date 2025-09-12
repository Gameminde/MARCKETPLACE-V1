import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/product.dart';

/// Wishlist Provider for managing user's wishlist
class WishlistProvider extends ChangeNotifier {
  final List<Product> _wishlistItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<Product> get wishlistItems => List.unmodifiable(_wishlistItems);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _wishlistItems.isEmpty;
  int get itemCount => _wishlistItems.length;

  /// Initialize wishlist provider
  Future<void> initialize() async {
    await loadWishlist();
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlistItems.any((item) => item.id == productId);
  }

  /// Add product to wishlist
  Future<void> addToWishlist(Product product) async {
    if (isInWishlist(product.id)) return;

    _wishlistItems.add(product);
    await _saveWishlist();
    notifyListeners();
  }

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String productId) async {
    _wishlistItems.removeWhere((item) => item.id == productId);
    await _saveWishlist();
    notifyListeners();
  }

  /// Toggle product in wishlist
  Future<void> toggleWishlist(Product product) async {
    if (isInWishlist(product.id)) {
      await removeFromWishlist(product.id);
    } else {
      await addToWishlist(product);
    }
  }

  /// Clear all wishlist items
  Future<void> clearWishlist() async {
    _wishlistItems.clear();
    await _saveWishlist();
    notifyListeners();
  }

  /// Load wishlist from storage
  Future<void> loadWishlist() async {
    _setLoading(true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistJson = prefs.getString('wishlist_items');
      
      if (wishlistJson != null) {
        final wishlistData = json.decode(wishlistJson) as List<dynamic>;
        _wishlistItems.clear();
        
        for (final item in wishlistData) {
          try {
            final product = Product.fromJson(item as Map<String, dynamic>);
            _wishlistItems.add(product);
          } catch (e) {
            debugPrint('Error parsing wishlist item: $e');
          }
        }
      }
      
      _clearError();
    } catch (e) {
      _setError('Failed to load wishlist: $e');
    } finally {
      _setLoading(false);
    }
    
    notifyListeners();
  }

  /// Save wishlist to storage
  Future<void> _saveWishlist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final wishlistData = _wishlistItems.map((item) => item.toJson()).toList();
      final wishlistJson = json.encode(wishlistData);
      await prefs.setString('wishlist_items', wishlistJson);
    } catch (e) {
      debugPrint('Error saving wishlist: $e');
    }
  }

  /// Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
  }

  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
  }

  void _clearError() {
    _errorMessage = null;
  }
}