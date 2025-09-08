import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:marketplace/services/api_service.dart';
import 'package:marketplace/models/product.dart';
import 'package:marketplace/models/user.dart';

// Generate mocks using build_runner
@GenerateMocks([http.Client])
void main() {
  group('ApiService Tests', () {
    late ApiService apiService;
    late MockClient mockHttpClient;

    setUp(() {
      mockHttpClient = MockClient();
      apiService = ApiService(httpClient: mockHttpClient);
    });

    group('Authentication API Tests', () {
      test('should login successfully with valid credentials', () async {
        // Mock successful login response
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "token": "fake_jwt_token", "user": {"id": "1", "email": "test@example.com"}}',
          200,
        ));

        final result = await apiService.login('test@example.com', 'password123');

        expect(result.isSuccess, isTrue);
        expect(result.data['token'], equals('fake_jwt_token'));
        expect(result.data['user']['email'], equals('test@example.com'));
      });

      test('should handle login failure with invalid credentials', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success": false, "error": "Invalid credentials"}',
          401,
        ));

        final result = await apiService.login('test@example.com', 'wrongpassword');

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid credentials'));
      });

      test('should register new user successfully', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "user": {"id": "2", "email": "newuser@example.com"}}',
          201,
        ));

        final result = await apiService.register(
          email: 'newuser@example.com',
          password: 'password123',
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(result.isSuccess, isTrue);
        expect(result.data['user']['email'], equals('newuser@example.com'));
      });

      test('should handle registration failure with existing email', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success": false, "error": "Email already exists"}',
          409,
        ));

        final result = await apiService.register(
          email: 'existing@example.com',
          password: 'password123',
          firstName: 'John',
          lastName: 'Doe',
        );

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Email already exists'));
      });
    });

    group('Product API Tests', () {
      test('should fetch products successfully', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "products": [{"id": "1", "name": "Product 1", "price": 29.99}]}',
          200,
        ));

        final result = await apiService.getProducts();

        expect(result.isSuccess, isTrue);
        expect(result.data['products'], isA<List>());
        expect(result.data['products'].length, equals(1));
      });

      test('should fetch single product by ID', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "product": {"id": "1", "name": "Product 1", "price": 29.99}}',
          200,
        ));

        final result = await apiService.getProduct('1');

        expect(result.isSuccess, isTrue);
        expect(result.data['product']['id'], equals('1'));
        expect(result.data['product']['name'], equals('Product 1'));
      });

      test('should handle product not found', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"success": false, "error": "Product not found"}',
          404,
        ));

        final result = await apiService.getProduct('999');

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Product not found'));
      });

      test('should search products with query', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "products": [{"id": "1", "name": "iPhone 14"}]}',
          200,
        ));

        final result = await apiService.searchProducts('iPhone');

        expect(result.isSuccess, isTrue);
        expect(result.data['products'].length, equals(1));
        expect(result.data['products'][0]['name'], contains('iPhone'));
      });
    });

    group('Order API Tests', () {
      test('should create order successfully', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "order": {"id": "order_123", "status": "pending", "total": 99.99}}',
          201,
        ));

        final orderData = {
          'items': [{'productId': '1', 'quantity': 2}],
          'total': 99.99,
          'shippingAddress': 'Test Address'
        };

        final result = await apiService.createOrder(orderData);

        expect(result.isSuccess, isTrue);
        expect(result.data['order']['id'], equals('order_123'));
        expect(result.data['order']['status'], equals('pending'));
      });

      test('should fetch user orders', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "orders": [{"id": "order_1", "status": "delivered"}]}',
          200,
        ));

        final result = await apiService.getUserOrders();

        expect(result.isSuccess, isTrue);
        expect(result.data['orders'], isA<List>());
        expect(result.data['orders'].length, equals(1));
      });

      test('should update order status', () async {
        when(mockHttpClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "message": "Order status updated"}',
          200,
        ));

        final result = await apiService.updateOrderStatus('order_123', 'shipped');

        expect(result.isSuccess, isTrue);
        expect(result.message, contains('updated'));
      });
    });

    group('User Profile API Tests', () {
      test('should get user profile', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "user": {"id": "1", "firstName": "John", "lastName": "Doe"}}',
          200,
        ));

        final result = await apiService.getUserProfile();

        expect(result.isSuccess, isTrue);
        expect(result.data['user']['firstName'], equals('John'));
        expect(result.data['user']['lastName'], equals('Doe'));
      });

      test('should update user profile', () async {
        when(mockHttpClient.put(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "user": {"id": "1", "firstName": "Updated"}}',
          200,
        ));

        final updateData = {
          'firstName': 'Updated',
          'lastName': 'Name',
        };

        final result = await apiService.updateUserProfile(updateData);

        expect(result.isSuccess, isTrue);
        expect(result.data['user']['firstName'], equals('Updated'));
      });
    });

    group('Review API Tests', () {
      test('should submit product review', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "review": {"id": "review_1", "rating": 5}}',
          201,
        ));

        final reviewData = {
          'productId': '1',
          'rating': 5,
          'comment': 'Great product!',
        };

        final result = await apiService.submitReview(reviewData);

        expect(result.isSuccess, isTrue);
        expect(result.data['review']['rating'], equals(5));
      });

      test('should get product reviews', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "reviews": [{"id": "1", "rating": 5, "comment": "Excellent"}]}',
          200,
        ));

        final result = await apiService.getProductReviews('1');

        expect(result.isSuccess, isTrue);
        expect(result.data['reviews'], isA<List>());
        expect(result.data['reviews'].length, equals(1));
      });
    });

    group('Wishlist API Tests', () {
      test('should add item to wishlist', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "message": "Item added to wishlist"}',
          200,
        ));

        final result = await apiService.addToWishlist('product_1');

        expect(result.isSuccess, isTrue);
        expect(result.message, contains('added to wishlist'));
      });

      test('should remove item from wishlist', () async {
        when(mockHttpClient.delete(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "message": "Item removed from wishlist"}',
          200,
        ));

        final result = await apiService.removeFromWishlist('product_1');

        expect(result.isSuccess, isTrue);
        expect(result.message, contains('removed from wishlist'));
      });

      test('should get user wishlist', () async {
        when(mockHttpClient.get(
          any,
          headers: anyNamed('headers'),
        )).thenAnswer((_) async => http.Response(
          '{"success": true, "wishlist": [{"id": "1", "name": "Product 1"}]}',
          200,
        ));

        final result = await apiService.getUserWishlist();

        expect(result.isSuccess, isTrue);
        expect(result.data['wishlist'], isA<List>());
      });
    });

    group('Error Handling Tests', () {
      test('should handle network timeout', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(http.ClientException('Connection timeout'));

        final result = await apiService.getProducts();

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('timeout'));
      });

      test('should handle server error (500)', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
          '{"success": false, "error": "Internal server error"}',
          500,
        ));

        final result = await apiService.getProducts();

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('server error'));
      });

      test('should handle malformed JSON response', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('Invalid JSON', 200));

        final result = await apiService.getProducts();

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Invalid response format'));
      });

      test('should handle unauthorized access (401)', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(
          '{"success": false, "error": "Unauthorized"}',
          401,
        ));

        final result = await apiService.getUserProfile();

        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Unauthorized'));
      });
    });

    group('Request Configuration Tests', () {
      test('should include authorization header when token is set', () async {
        apiService.setAuthToken('fake_token_123');

        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('{"success": true}', 200));

        await apiService.getProducts();

        verify(mockHttpClient.get(
          any,
          headers: argThat(
            contains('Authorization'),
            named: 'headers',
          ),
        ));
      });

      test('should set correct content type for POST requests', () async {
        when(mockHttpClient.post(
          any,
          headers: anyNamed('headers'),
          body: anyNamed('body'),
        )).thenAnswer((_) async => http.Response('{"success": true}', 200));

        await apiService.login('test@example.com', 'password');

        verify(mockHttpClient.post(
          any,
          headers: argThat(
            allOf([
              containsPair('Content-Type', 'application/json'),
              containsPair('Accept', 'application/json'),
            ]),
            named: 'headers',
          ),
          body: anyNamed('body'),
        ));
      });

      test('should handle request retries on failure', () async {
        // First call fails, second succeeds
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenThrow(http.ClientException('Network error'))
            .thenAnswer((_) async => http.Response('{"success": true}', 200));

        final result = await apiService.getProducts(retryCount: 1);

        expect(result.isSuccess, isTrue);
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(2);
      });
    });

    group('Caching Tests', () {
      test('should cache GET requests when enabled', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('{"success": true, "data": "cached"}', 200));

        // First call
        final result1 = await apiService.getProducts(useCache: true);
        // Second call should use cache
        final result2 = await apiService.getProducts(useCache: true);

        expect(result1.isSuccess, isTrue);
        expect(result2.isSuccess, isTrue);
        
        // Should only make one actual HTTP request
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(1);
      });

      test('should clear cache when requested', () async {
        when(mockHttpClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response('{"success": true}', 200));

        await apiService.getProducts(useCache: true);
        apiService.clearCache();
        await apiService.getProducts(useCache: true);

        // Should make two HTTP requests after cache clear
        verify(mockHttpClient.get(any, headers: anyNamed('headers'))).called(2);
      });
    });
  });
}

// Mock client class for testing
class MockClient extends Mock implements http.Client {}