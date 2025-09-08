import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace/models/product.dart';

void main() {
  group('Product Model Tests', () {
    test('should create product with required fields', () {
      const product = Product(
        id: 'test_1',
        name: 'Test Product',
        description: 'A test product',
        price: 29.99,
        category: 'Test Category',
      );

      expect(product.id, equals('test_1'));
      expect(product.name, equals('Test Product'));
      expect(product.price, equals(29.99));
      expect(product.inStock, isTrue); // Default value
      expect(product.rating, equals(0.0)); // Default value
    });

    test('should calculate discount percentage correctly', () {
      const product = Product(
        id: 'test_1',
        name: 'Discounted Product',
        description: 'A discounted product',
        price: 50.0,
        originalPrice: 100.0,
        category: 'Test Category',
      );

      expect(product.discountPercentage, equals(50.0));
      expect(product.isOnSale, isTrue);
    });

    test('should return null discount when no original price', () {
      const product = Product(
        id: 'test_1',
        name: 'Regular Product',
        description: 'A regular priced product',
        price: 50.0,
        category: 'Test Category',
      );

      expect(product.discountPercentage, isNull);
      expect(product.isOnSale, isFalse);
    });

    test('should return null discount when original price is lower', () {
      const product = Product(
        id: 'test_1',
        name: 'Weird Product',
        description: 'A product with weird pricing',
        price: 100.0,
        originalPrice: 50.0,
        category: 'Test Category',
      );

      expect(product.discountPercentage, isNull);
      expect(product.isOnSale, isFalse);
    });

    test('should generate rating stars correctly', () {
      const product = Product(
        id: 'test_1',
        name: 'Rated Product',
        description: 'A product with rating',
        price: 50.0,
        category: 'Test Category',
        rating: 4.2,
      );

      final stars = product.ratingStars;
      expect(stars.split('★').length - 1, equals(4)); // 4 full stars
      expect(stars.contains('☆'), isTrue); // Contains half/empty stars
    });

    test('should copy product with modifications', () {
      const originalProduct = Product(
        id: 'test_1',
        name: 'Original Product',
        description: 'Original description',
        price: 50.0,
        category: 'Original Category',
      );

      final modifiedProduct = originalProduct.copyWith(
        name: 'Modified Product',
        price: 75.0,
      );

      expect(modifiedProduct.id, equals('test_1')); // Unchanged
      expect(modifiedProduct.name, equals('Modified Product')); // Changed
      expect(modifiedProduct.price, equals(75.0)); // Changed
      expect(modifiedProduct.description, equals('Original description')); // Unchanged
      expect(modifiedProduct.category, equals('Original Category')); // Unchanged
    });

    test('should serialize to JSON correctly', () {
      const product = Product(
        id: 'test_1',
        name: 'JSON Product',
        description: 'A product for JSON testing',
        price: 29.99,
        originalPrice: 39.99,
        category: 'JSON Category',
        rating: 4.5,
        reviewCount: 100,
        availableColors: ['Red', 'Blue'],
        availableSizes: ['S', 'M', 'L'],
        inStock: true,
      );

      final json = product.toJson();

      expect(json['id'], equals('test_1'));
      expect(json['name'], equals('JSON Product'));
      expect(json['price'], equals(29.99));
      expect(json['originalPrice'], equals(39.99));
      expect(json['availableColors'], equals(['Red', 'Blue']));
      expect(json['availableSizes'], equals(['S', 'M', 'L']));
      expect(json['inStock'], isTrue);
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': 'test_1',
        'name': 'JSON Product',
        'description': 'A product from JSON',
        'price': 29.99,
        'originalPrice': 39.99,
        'imageUrl': 'https://example.com/image.jpg',
        'images': ['https://example.com/image1.jpg', 'https://example.com/image2.jpg'],
        'category': 'JSON Category',
        'rating': 4.5,
        'reviewCount': 100,
        'availableColors': ['Red', 'Blue'],
        'availableSizes': ['S', 'M', 'L'],
        'inStock': true,
        'metadata': {'key': 'value'},
      };

      final product = Product.fromJson(json);

      expect(product.id, equals('test_1'));
      expect(product.name, equals('JSON Product'));
      expect(product.price, equals(29.99));
      expect(product.originalPrice, equals(39.99));
      expect(product.imageUrl, equals('https://example.com/image.jpg'));
      expect(product.images.length, equals(2));
      expect(product.availableColors, equals(['Red', 'Blue']));
      expect(product.availableSizes, equals(['S', 'M', 'L']));
      expect(product.inStock, isTrue);
      expect(product.metadata?['key'], equals('value'));
    });

    test('should handle equality correctly', () {
      const product1 = Product(
        id: 'test_1',
        name: 'Product 1',
        description: 'Description 1',
        price: 29.99,
        category: 'Category 1',
      );

      const product2 = Product(
        id: 'test_1',
        name: 'Product 1 Modified',
        description: 'Different description',
        price: 39.99,
        category: 'Different category',
      );

      const product3 = Product(
        id: 'test_2',
        name: 'Product 1',
        description: 'Description 1',
        price: 29.99,
        category: 'Category 1',
      );

      // Products with same ID should be equal
      expect(product1, equals(product2));
      expect(product1.hashCode, equals(product2.hashCode));

      // Products with different ID should not be equal
      expect(product1, isNot(equals(product3)));
      expect(product1.hashCode, isNot(equals(product3.hashCode)));
    });

    test('should convert to string correctly', () {
      const product = Product(
        id: 'test_1',
        name: 'String Product',
        description: 'A product for string testing',
        price: 29.99,
        category: 'String Category',
      );

      final productString = product.toString();
      expect(productString, contains('test_1'));
      expect(productString, contains('String Product'));
      expect(productString, contains('29.99'));
      expect(productString, contains('String Category'));
    });

    group('MockProducts Tests', () {
      test('should provide trending products', () {
        final trendingProducts = MockProducts.trendingProducts;
        
        expect(trendingProducts.isNotEmpty, isTrue);
        expect(trendingProducts.length, equals(4));
        expect(trendingProducts.every((p) => p.id.isNotEmpty), isTrue);
        expect(trendingProducts.every((p) => p.name.isNotEmpty), isTrue);
        expect(trendingProducts.every((p) => p.price > 0), isTrue);
      });

      test('should provide aero run shoe product', () {
        final aeroRunShoe = MockProducts.aeroRunShoe;
        
        expect(aeroRunShoe.id, equals('aero-run-2.0'));
        expect(aeroRunShoe.name, equals('AeroRun 2.0'));
        expect(aeroRunShoe.description.isNotEmpty, isTrue);
      });

      test('trending products should have consistent data', () {
        final products = MockProducts.trendingProducts;
        
        // All products should have valid categories
        expect(products.every((p) => p.category.isNotEmpty), isTrue);
        
        // All products should have reasonable ratings
        expect(products.every((p) => p.rating >= 0 && p.rating <= 5), isTrue);
        
        // All products should have reasonable review counts
        expect(products.every((p) => p.reviewCount >= 0), isTrue);
        
        // All products should have positive prices
        expect(products.every((p) => p.price > 0), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle zero price', () {
        const product = Product(
          id: 'free_1',
          name: 'Free Product',
          description: 'A free product',
          price: 0.0,
          category: 'Free Category',
        );

        expect(product.price, equals(0.0));
        expect(product.isOnSale, isFalse);
      });

      test('should handle very high rating', () {
        const product = Product(
          id: 'perfect_1',
          name: 'Perfect Product',
          description: 'A perfect product',
          price: 50.0,
          category: 'Perfect Category',
          rating: 5.0,
        );

        final stars = product.ratingStars;
        expect(stars.split('★').length - 1, equals(5)); // 5 full stars
        expect(stars.contains('☆'), isFalse); // No empty stars
      });

      test('should handle zero rating', () {
        const product = Product(
          id: 'unrated_1',
          name: 'Unrated Product',
          description: 'An unrated product',
          price: 50.0,
          category: 'Unrated Category',
          rating: 0.0,
        );

        final stars = product.ratingStars;
        expect(stars.split('★').length - 1, equals(0)); // No full stars
        expect(stars.split('☆').length - 1, equals(5)); // 5 empty stars
      });

      test('should handle empty collections', () {
        const product = Product(
          id: 'minimal_1',
          name: 'Minimal Product',
          description: 'A minimal product',
          price: 50.0,
          category: 'Minimal Category',
          availableColors: [],
          availableSizes: [],
        );

        expect(product.availableColors, isEmpty);
        expect(product.availableSizes, isEmpty);
      });

      test('should handle null values in JSON', () {
        final json = {
          'id': 'null_test',
          'name': 'Null Test Product',
          'description': 'A product with null values',
          'price': 29.99,
          'category': 'Test Category',
          'originalPrice': null,
          'imageUrl': null,
          'images': null,
          'availableColors': null,
          'availableSizes': null,
          'metadata': null,
        };

        final product = Product.fromJson(json);

        expect(product.originalPrice, isNull);
        expect(product.imageUrl, isNull);
        expect(product.images, isEmpty);
        expect(product.availableColors, isEmpty);
        expect(product.availableSizes, isEmpty);
        expect(product.metadata, isNull);
      });
    });
  });
}