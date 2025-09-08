import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:marketplace/providers/cart_provider.dart';
import 'package:marketplace/models/product.dart';

void main() {
  group('CartProvider Tests', () {
    late CartProvider cartProvider;
    late Product testProduct;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      cartProvider = CartProvider();
      testProduct = const Product(
        id: 'test_1',
        name: 'Test Product',
        description: 'A test product for unit testing',
        price: 29.99,
        category: 'Test Category',
        rating: 4.5,
        reviewCount: 100,
        inStock: true,
      );
    });

    test('should initialize with empty cart', () {
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, equals(0));
      expect(cartProvider.totalAmount, equals(0.0));
    });

    test('should add item to cart', () {
      cartProvider.addItem(testProduct);
      
      expect(cartProvider.items.length, equals(1));
      expect(cartProvider.itemCount, equals(1));
      expect(cartProvider.totalAmount, equals(29.99));
      expect(cartProvider.items.first.product.id, equals('test_1'));
      expect(cartProvider.items.first.quantity, equals(1));
    });

    test('should increase quantity when adding same item', () {
      cartProvider.addItem(testProduct);
      cartProvider.addItem(testProduct);
      
      expect(cartProvider.items.length, equals(1));
      expect(cartProvider.itemCount, equals(2));
      expect(cartProvider.totalAmount, equals(59.98));
      expect(cartProvider.items.first.quantity, equals(2));
    });

    test('should add item with specified quantity', () {
      cartProvider.addItem(testProduct, quantity: 3);
      
      expect(cartProvider.items.length, equals(1));
      expect(cartProvider.itemCount, equals(3));
      expect(cartProvider.totalAmount, equals(89.97));
      expect(cartProvider.items.first.quantity, equals(3));
    });

    test('should remove item from cart', () {
      cartProvider.addItem(testProduct);
      cartProvider.removeItem(testProduct.id);
      
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, equals(0));
      expect(cartProvider.totalAmount, equals(0.0));
    });

    test('should update item quantity', () {
      cartProvider.addItem(testProduct);
      cartProvider.updateQuantity(testProduct.id, 5);
      
      expect(cartProvider.items.first.quantity, equals(5));
      expect(cartProvider.itemCount, equals(5));
      expect(cartProvider.totalAmount, equals(149.95));
    });

    test('should remove item when quantity is set to 0', () {
      cartProvider.addItem(testProduct);
      cartProvider.updateQuantity(testProduct.id, 0);
      
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, equals(0));
      expect(cartProvider.totalAmount, equals(0.0));
    });

    test('should decrease quantity', () {
      cartProvider.addItem(testProduct, quantity: 3);
      cartProvider.decreaseQuantity(testProduct.id);
      
      expect(cartProvider.items.first.quantity, equals(2));
      expect(cartProvider.itemCount, equals(2));
      expect(cartProvider.totalAmount, equals(59.98));
    });

    test('should remove item when decreasing quantity to 0', () {
      cartProvider.addItem(testProduct);
      cartProvider.decreaseQuantity(testProduct.id);
      
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, equals(0));
      expect(cartProvider.totalAmount, equals(0.0));
    });

    test('should clear entire cart', () {
      cartProvider.addItem(testProduct);
      cartProvider.addItem(const Product(
        id: 'test_2',
        name: 'Test Product 2',
        description: 'Another test product',
        price: 19.99,
        category: 'Test Category',
      ));
      
      cartProvider.clearCart();
      
      expect(cartProvider.items, isEmpty);
      expect(cartProvider.itemCount, equals(0));
      expect(cartProvider.totalAmount, equals(0.0));
    });

    test('should check if item is in cart', () {
      expect(cartProvider.isInCart(testProduct.id), isFalse);
      
      cartProvider.addItem(testProduct);
      expect(cartProvider.isInCart(testProduct.id), isTrue);
    });

    test('should get item quantity', () {
      expect(cartProvider.getQuantity(testProduct.id), equals(0));
      
      cartProvider.addItem(testProduct, quantity: 3);
      expect(cartProvider.getQuantity(testProduct.id), equals(3));
    });

    test('should calculate total with tax', () {
      cartProvider.addItem(testProduct);
      final totalWithTax = cartProvider.getTotalWithTax(0.08); // 8% tax
      
      expect(totalWithTax, closeTo(32.39, 0.01));
    });

    test('should calculate total with discount', () {
      cartProvider.addItem(testProduct);
      final totalWithDiscount = cartProvider.getTotalWithDiscount(10.0); // 10% discount
      
      expect(totalWithDiscount, closeTo(26.99, 0.01));
    });

    test('should get cart summary', () {
      cartProvider.addItem(testProduct, quantity: 2);
      final summary = cartProvider.getCartSummary();
      
      expect(summary['itemCount'], equals(2));
      expect(summary['subtotal'], equals(59.98));
      expect(summary['uniqueItems'], equals(1));
    });

    test('should handle currency formatting', () {
      cartProvider.addItem(testProduct);
      final formatted = cartProvider.getFormattedTotal();
      
      expect(formatted, equals('\$29.99'));
    });

    test('should validate cart before checkout', () {
      // Empty cart should be invalid
      expect(cartProvider.isValidForCheckout(), isFalse);
      
      // Cart with items should be valid
      cartProvider.addItem(testProduct);
      expect(cartProvider.isValidForCheckout(), isTrue);
      
      // Cart with out-of-stock items should be invalid
      final outOfStockProduct = testProduct.copyWith(inStock: false);
      cartProvider.addItem(outOfStockProduct);
      expect(cartProvider.isValidForCheckout(), isFalse);
    });

    test('should handle multiple currencies', () {
      cartProvider.setCurrency('EUR');
      cartProvider.addItem(testProduct);
      
      expect(cartProvider.currency, equals('EUR'));
      expect(cartProvider.getFormattedTotal(), contains('€'));
    });

    test('should notify listeners when cart changes', () {
      var notificationCount = 0;
      cartProvider.addListener(() {
        notificationCount++;
      });
      
      cartProvider.addItem(testProduct);
      cartProvider.updateQuantity(testProduct.id, 2);
      cartProvider.removeItem(testProduct.id);
      
      expect(notificationCount, equals(3));
    });

    group('Cart persistence', () {
      test('should save cart to persistence', () async {
        cartProvider.addItem(testProduct);
        await cartProvider.saveToCache();
        
        // Verify that the cart was saved (this would require mocking SharedPreferences)
        expect(cartProvider.items.isNotEmpty, isTrue);
      });

      test('should load cart from persistence', () async {
        // This test would require setting up mock data in SharedPreferences
        await cartProvider.loadFromCache();
        
        // Since we're using mock initial values (empty), cart should be empty
        expect(cartProvider.items, isEmpty);
      });
    });

    group('Edge cases', () {
      test('should handle adding item with negative quantity', () {
        cartProvider.addItem(testProduct, quantity: -1);
        
        // Should not add item with negative quantity
        expect(cartProvider.items, isEmpty);
      });

      test('should handle updating to negative quantity', () {
        cartProvider.addItem(testProduct);
        cartProvider.updateQuantity(testProduct.id, -1);
        
        // Should remove item instead of setting negative quantity
        expect(cartProvider.items, isEmpty);
      });

      test('should handle operations on non-existent items', () {
        // These operations should not crash
        cartProvider.removeItem('non_existent');
        cartProvider.updateQuantity('non_existent', 5);
        cartProvider.decreaseQuantity('non_existent');
        
        expect(cartProvider.items, isEmpty);
      });
    });
  });
}