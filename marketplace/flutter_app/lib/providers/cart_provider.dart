import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Cart Provider for managing shopping cart state
class CartProvider extends ChangeNotifier {
  // State
  final List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  bool get isEmpty => _cartItems.isEmpty;
  bool get isNotEmpty => _cartItems.isNotEmpty;

  /// Add item to cart
  void addItem(Product product, {int quantity = 1}) {
    final existingItemIndex = _cartItems.indexWhere(
      (item) => item.id == product.id,
    );

    if (existingItemIndex != -1) {
      // Update existing item
      _cartItems[existingItemIndex].quantity += quantity;
    } else {
      // Add new item
      _cartItems.add(CartItem(
        id: product.id,
        name: product.name,
        price: product.price,
        quantity: quantity,
        imageUrl: product.imageUrl,
        description: product.description,
        category: product.category,
        addedAt: DateTime.now(),
      ));
    }

    notifyListeners();
  }

  /// Remove item from cart
  void removeItem(String productId) {
    _cartItems.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final itemIndex = _cartItems.indexWhere(
      (item) => item.id == productId,
    );

    if (itemIndex != -1) {
      _cartItems[itemIndex].quantity = quantity;
      notifyListeners();
    }
  }

  /// Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  /// Get item by product ID
  CartItem? getItem(String productId) {
    try {
      return _cartItems.firstWhere((item) => item.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    return _cartItems.any((item) => item.id == productId);
  }

  /// Get total quantity for a product
  int getProductQuantity(String productId) {
    final item = getItem(productId);
    return item?.quantity ?? 0;
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
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
