import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/cart_item.dart';
import '../core/config/app_constants.dart';
import '../core/config/environment.dart';
import '../services/currency_service.dart';

/// Enhanced Provider for comprehensive cart management with currency support,
/// persistence, promotions, and advanced cart features
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  final CurrencyService _currencyService = CurrencyService();
  
  // Enhanced cart state
  String _currency = AppConstants.defaultCurrency;
  double _exchangeRate = 1.0;
  bool _isGuestCheckout = false;
  DateTime? _lastUpdated;
  bool _isPersistenceEnabled = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<CartItem> get items => List.unmodifiable(_items);
  String get currency => _currency;
  double get exchangeRate => _exchangeRate;
  bool get isGuestCheckout => _isGuestCheckout;
  DateTime? get lastUpdated => _lastUpdated;
  bool get isPersistenceEnabled => _isPersistenceEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Enhanced item count calculation
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  /// Enhanced total price with currency conversion
  double get totalPrice {
    double baseTotal = 0.0;
    for (final item in _items) {
      baseTotal += item.totalPrice;
    }
    return baseTotal * _exchangeRate;
  }

  /// Subtotal before shipping, taxes, and discounts
  double get subtotal => totalPrice;

  /// Calculate shipping cost
  double get shippingCost {
    if (isEmpty) return 0.0;
    if (totalPrice >= AppConstants.freeShippingThreshold * _exchangeRate) return 0.0;
    return AppConstants.standardShippingCost * _exchangeRate;
  }

  /// Calculate tax amount (10% default)
  double get taxAmount => subtotal * 0.1;

  /// Final total including all fees
  double get finalTotal => subtotal + shippingCost + taxAmount;

  /// Check if eligible for free shipping
  bool get isEligibleForFreeShipping {
    final threshold = AppConstants.freeShippingThreshold * _exchangeRate;
    return totalPrice >= threshold;
  }

  /// Check if cart is empty
  bool get isEmpty => _items.isEmpty;

  /// Check if cart has items
  bool get isNotEmpty => _items.isNotEmpty;

  /// Check if cart meets minimum order requirements
  bool get meetsMinimumOrder {
    return totalPrice >= AppConstants.minimumOrderAmount * _exchangeRate;
  }

  /// Get unique vendor count
  int get vendorCount {
    final vendorIds = _items.map((item) => item.vendorId ?? 'unknown').toSet();
    return vendorIds.length;
  }

  /// Enhanced add item with validation
  Future<bool> addItem(CartItem item, {bool skipValidation = false}) async {
    try {
      _setLoading(true);
      _clearError();

      final existingIndex = _items.indexWhere((existingItem) => 
          existingItem.id == item.id && 
          _areAttributesEqual(existingItem.attributes, item.attributes)
      );

      if (existingIndex >= 0) {
        // Item exists, update quantity
        final existingItem = _items[existingIndex];
        final newQuantity = existingItem.quantity + item.quantity;
        _items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
      } else {
        // New item
        _items.add(item);
      }
      
      await _updateLastModified();
      await _persistCart();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error adding item to cart: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Enhanced remove item
  Future<bool> removeItem(String itemId) async {
    try {
      _setLoading(true);
      _clearError();

      final removedCount = _items.length;
      _items.removeWhere((item) => item.id == itemId);
      
      if (_items.length == removedCount) {
        _setError('Item not found in cart');
        return false;
      }

      await _updateLastModified();
      await _persistCart();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error removing item from cart: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Enhanced quantity update
  Future<bool> updateQuantity(String itemId, int newQuantity) async {
    try {
      _setLoading(true);
      _clearError();

      if (newQuantity <= 0) {
        return await removeItem(itemId);
      }

      final index = _items.indexWhere((item) => item.id == itemId);
      if (index < 0) {
        _setError('Item not found in cart');
        return false;
      }

      final item = _items[index];
      _items[index] = item.copyWith(quantity: newQuantity);
      
      await _updateLastModified();
      await _persistCart();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error updating quantity: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Increment item quantity
  Future<bool> incrementQuantity(String itemId) async {
    final item = getItem(itemId);
    if (item == null) return false;
    return await updateQuantity(itemId, item.quantity + 1);
  }

  /// Decrement item quantity  
  Future<bool> decrementQuantity(String itemId) async {
    final item = getItem(itemId);
    if (item == null) return false;
    return await updateQuantity(itemId, item.quantity - 1);
  }

  /// Clear entire cart
  Future<bool> clearCart({bool force = false}) async {
    try {
      _setLoading(true);
      _clearError();

      _items.clear();
      
      await _updateLastModified();
      await _persistCart();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error clearing cart: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get specific item by ID
  CartItem? getItem(String itemId) {
    try {
      return _items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  /// Check if item exists in cart
  bool containsItem(String itemId) {
    return _items.any((item) => item.id == itemId);
  }

  /// Get item quantity by ID
  int getItemQuantity(String itemId) {
    final item = getItem(itemId);
    return item?.quantity ?? 0;
  }

  /// Currency Management
  Future<bool> setCurrency(String newCurrency) async {
    try {
      if (newCurrency == _currency) return true;
      
      _setLoading(true);
      final rate = await _currencyService.getExchangeRate(_currency, newCurrency);
      
      _currency = newCurrency;
      _exchangeRate = rate;
      
      await _persistCart();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error updating currency: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Guest checkout management
  void setGuestCheckout(bool isGuest) {
    _isGuestCheckout = isGuest;
    notifyListeners();
  }

  /// Persistence Management
  Future<bool> loadCart() async {
    if (!_isPersistenceEnabled) return true;
    
    try {
      _setLoading(true);
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('cart_data');
      
      if (cartJson != null) {
        final data = json.decode(cartJson) as Map<String, dynamic>;
        await _fromJson(data);
      }
      
      return true;
    } catch (e) {
      _setError('Error loading cart: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _persistCart() async {
    if (!_isPersistenceEnabled) return true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(_toJson());
      return await prefs.setString('cart_data', cartJson);
    } catch (e) {
      debugPrint('Error persisting cart: $e');
      return false;
    }
  }

  /// Enable or disable cart persistence
  void setPersistenceEnabled(bool enabled) {
    _isPersistenceEnabled = enabled;
  }

  /// Private helper methods
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

  Future<void> _updateLastModified() async {
    _lastUpdated = DateTime.now();
  }

  /// Compare item attributes for equality
  bool _areAttributesEqual(Map<String, dynamic>? attr1, Map<String, dynamic>? attr2) {
    if (attr1 == null && attr2 == null) return true;
    if (attr1 == null || attr2 == null) return false;
    
    if (attr1.length != attr2.length) return false;
    
    for (final key in attr1.keys) {
      if (!attr2.containsKey(key) || attr1[key] != attr2[key]) {
        return false;
      }
    }
    
    return true;
  }

  /// Enhanced JSON serialization
  Map<String, dynamic> _toJson() {
    return {
      'items': _items.map((item) => item.toJson()).toList(),
      'currency': _currency,
      'exchangeRate': _exchangeRate,
      'isGuestCheckout': _isGuestCheckout,
      'lastUpdated': _lastUpdated?.toIso8601String(),
      'version': '2.0',
    };
  }

  /// Enhanced JSON deserialization
  Future<void> _fromJson(Map<String, dynamic> data) async {
    try {
      _items.clear();
      
      // Load items
      final itemsJson = data['items'] as List<dynamic>? ?? [];
      for (final itemJson in itemsJson) {
        try {
          _items.add(CartItem.fromJson(itemJson as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Error loading cart item: $e');
        }
      }
      
      // Load other properties
      _currency = data['currency'] as String? ?? AppConstants.defaultCurrency;
      _exchangeRate = (data['exchangeRate'] as num?)?.toDouble() ?? 1.0;
      _isGuestCheckout = data['isGuestCheckout'] as bool? ?? false;
      
      if (data['lastUpdated'] != null) {
        _lastUpdated = DateTime.tryParse(data['lastUpdated'] as String);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cart from JSON: $e');
      _setError('Error loading saved cart data');
    }
  }

  /// Public methods for external access
  Future<void> fromJson(Map<String, dynamic> json) async {
    await _fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return _toJson();
  }

  /// Cleanup when provider is disposed
  @override
  void dispose() {
    if (_isPersistenceEnabled && _items.isNotEmpty) {
      _persistCart();
    }
    super.dispose();
  }
}
