import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

/// Cart Provider for managing shopping cart state
class CartProvider extends ChangeNotifier {
  // State
  final List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isGuestCheckout = false;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  List<CartItem> get items => _cartItems; // Alias for compatibility
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount =>
      _cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get totalPrice => totalAmount; // Alias for compatibility
  bool get isEmpty => _cartItems.isEmpty;
  bool get isNotEmpty => _cartItems.isNotEmpty;
  bool get isGuestCheckout => _isGuestCheckout;

  /// Calculate shipping cost (Algeria-specific)
  double get shippingCost {
    if (isEmpty) return 0.0;
    if (totalPrice >= 5000.0) return 0.0; // Free shipping over 5000 DZD
    return 500.0; // Standard shipping cost in DZD
  }

  /// Calculate tax amount (19% VAT for Algeria)
  double get taxAmount {
    return totalPrice * 0.19;
  }

  /// Calculate final total including shipping and tax
  double get finalTotal {
    return totalPrice + shippingCost + taxAmount;
  }

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
        productId: product.id,
        product: product,
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

  /// Increment quantity of a product
  void incrementQuantity(String productId) {
    final itemIndex = _cartItems.indexWhere((item) => item.id == productId);
    if (itemIndex != -1) {
      _cartItems[itemIndex].quantity++;
      notifyListeners();
    }
  }

  /// Decrement quantity of a product
  void decrementQuantity(String productId) {
    final itemIndex = _cartItems.indexWhere((item) => item.id == productId);
    if (itemIndex != -1) {
      if (_cartItems[itemIndex].quantity > 1) {
        _cartItems[itemIndex].quantity--;
      } else {
        _cartItems.removeAt(itemIndex);
      }
      notifyListeners();
    }
  }

  /// Set guest checkout mode
  void setGuestCheckout(bool isGuest) {
    _isGuestCheckout = isGuest;
    notifyListeners();
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
