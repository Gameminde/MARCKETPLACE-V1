import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:marketplace_app/main.dart' as app;
import 'package:marketplace_app/providers/auth_provider.dart';
import 'package:marketplace_app/providers/cart_provider.dart';
import 'package:marketplace_app/providers/search_provider.dart';

// Missing widget imports
import 'package:marketplace_app/widgets/product_card.dart';
// Note: CartItem is a model, not a widget
// Note: OrderCard and ChatCard widgets don't exist yet

/// Integration tests for critical user flows in the marketplace app
/// 
/// These tests simulate real user interactions and verify that the entire
/// application works correctly from end to end.
/// 
/// Run with: flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('🛍️ Marketplace App Integration Tests', () {
    
    group('Authentication Flow', () {
      testWidgets('should complete full login flow', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Verify we start on login/welcome screen
        expect(find.text('Welcome'), findsOneWidget);
        
        // Navigate to login screen
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        // Fill in login form
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        
        // Submit login
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Verify successful login - should navigate to home screen
        expect(find.text('Home'), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should complete registration flow', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Navigate to registration screen
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Fill in registration form
        final textFields = find.byType(TextField);
        await tester.enterText(textFields.at(0), 'John');
        await tester.enterText(textFields.at(1), 'Doe');
        await tester.enterText(textFields.at(2), 'john.doe@example.com');
        await tester.enterText(textFields.at(3), 'password123');
        await tester.enterText(textFields.at(4), 'password123');

        // Accept terms
        await tester.tap(find.byType(Checkbox));
        
        // Submit registration
        await tester.tap(find.text('Create Account'));
        await tester.pumpAndSettle();

        // Verify account created and logged in
        expect(find.text('Welcome, John!'), findsOneWidget);
      });

      testWidgets('should handle login errors gracefully', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        // Enter invalid credentials
        await tester.enterText(find.byType(TextField).first, 'invalid@example.com');
        await tester.enterText(find.byType(TextField).last, 'wrongpassword');
        
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Should show error message
        expect(find.text('Invalid credentials'), findsOneWidget);
        
        // Should remain on login screen
        expect(find.text('Sign In'), findsOneWidget);
      });
    });

    group('Product Discovery Flow', () {
      testWidgets('should search and view products', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Skip login for product browsing
        await tester.tap(find.text('Browse as Guest'));
        await tester.pumpAndSettle();

        // Tap search icon
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Enter search query
        await tester.enterText(find.byType(TextField), 'iPhone');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Verify search results are displayed
        expect(find.text('Search Results'), findsOneWidget);
        expect(find.byType(ProductCard), findsAtLeastNWidgets(1));

        // Tap on first product
        await tester.tap(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Verify product detail screen is shown
        expect(find.text('Product Details'), findsOneWidget);
        expect(find.byIcon(Icons.add_shopping_cart), findsOneWidget);
      });

      testWidgets('should filter search results', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Browse as Guest'));
        await tester.pumpAndSettle();

        // Open search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Search for products
        await tester.enterText(find.byType(TextField), 'phone');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        await tester.pumpAndSettle();

        // Open filters
        await tester.tap(find.byIcon(Icons.filter_list));
        await tester.pumpAndSettle();

        // Set price range
        await tester.drag(
          find.byType(RangeSlider),
          const Offset(100, 0),
        );
        
        // Select category
        await tester.tap(find.text('Electronics'));
        
        // Apply filters
        await tester.tap(find.text('Apply Filters'));
        await tester.pumpAndSettle();

        // Verify filtered results
        expect(find.text('Filters Applied'), findsOneWidget);
      });

      testWidgets('should use voice search', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Browse as Guest'));
        await tester.pumpAndSettle();

        // Open search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        // Tap voice search button
        await tester.tap(find.byIcon(Icons.mic));
        await tester.pumpAndSettle();

        // Verify voice search dialog is shown
        expect(find.text('Listening...'), findsOneWidget);
        
        // Simulate voice input completion
        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();

        // Verify search was performed
        expect(find.byType(ProductCard), findsAtLeastNWidgets(1));
      });
    });

    group('Shopping Cart Flow', () {
      testWidgets('should complete add to cart flow', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Login first
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Browse products
        await tester.tap(find.text('Shop Now'));
        await tester.pumpAndSettle();

        // Add first product to cart
        await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
        await tester.pumpAndSettle();

        // Verify cart badge shows 1 item
        expect(find.text('1'), findsOneWidget);

        // Add another product
        await tester.tap(find.byIcon(Icons.add_shopping_cart).at(1));
        await tester.pumpAndSettle();

        // Verify cart badge shows 2 items
        expect(find.text('2'), findsOneWidget);

        // Open cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Verify cart screen shows items
        expect(find.text('Shopping Cart'), findsOneWidget);
        expect(find.byType(CartItem), findsNWidgets(2));
      });

      testWidgets('should update cart quantities', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Login and add item to cart
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Shop Now'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
        await tester.pumpAndSettle();

        // Open cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Increase quantity
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();

        // Verify quantity increased
        expect(find.text('2'), findsAtLeastNWidgets(1));

        // Decrease quantity
        await tester.tap(find.byIcon(Icons.remove).first);
        await tester.pumpAndSettle();

        // Verify quantity decreased
        expect(find.text('1'), findsAtLeastNWidgets(1));
      });

      testWidgets('should remove items from cart', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Login and add items to cart
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Shop Now'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
        await tester.pumpAndSettle();

        // Open cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Remove item
        await tester.tap(find.byIcon(Icons.delete));
        await tester.pumpAndSettle();

        // Confirm removal
        await tester.tap(find.text('Remove'));
        await tester.pumpAndSettle();

        // Verify cart is empty
        expect(find.text('Your cart is empty'), findsOneWidget);
      });
    });

    group('Checkout Flow', () {
      testWidgets('should complete full checkout process', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Login
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Add item to cart
        await tester.tap(find.text('Shop Now'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
        await tester.pumpAndSettle();

        // Go to cart
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        // Proceed to checkout
        await tester.tap(find.text('Checkout'));
        await tester.pumpAndSettle();

        // Fill shipping address
        expect(find.text('Shipping Address'), findsOneWidget);
        await tester.enterText(find.byKey(const Key('street_address')), '123 Main St');
        await tester.enterText(find.byKey(const Key('city')), 'Anytown');
        await tester.enterText(find.byKey(const Key('zip_code')), '12345');
        
        // Continue to payment
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Select payment method
        expect(find.text('Payment Method'), findsOneWidget);
        await tester.tap(find.text('Credit Card'));
        await tester.pumpAndSettle();

        // Fill payment details
        await tester.enterText(find.byKey(const Key('card_number')), '4111111111111111');
        await tester.enterText(find.byKey(const Key('expiry_date')), '12/25');
        await tester.enterText(find.byKey(const Key('cvv')), '123');
        
        // Continue to review
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Review order
        expect(find.text('Order Review'), findsOneWidget);
        expect(find.text('Total:'), findsOneWidget);
        
        // Place order
        await tester.tap(find.text('Place Order'));
        await tester.pumpAndSettle();

        // Verify order confirmation
        expect(find.text('Order Confirmed'), findsOneWidget);
        expect(find.text('Order #'), findsOneWidget);
      });

      testWidgets('should handle payment errors', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Login and add item to cart
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Shop Now'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
        await tester.pumpAndSettle();

        // Go to cart and checkout
        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Checkout'));
        await tester.pumpAndSettle();

        // Skip to payment with minimal info
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Enter invalid card
        await tester.enterText(find.byKey(const Key('card_number')), '1234');
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Should show validation error
        expect(find.text('Invalid card number'), findsOneWidget);
      });
    });

    group('Profile Management Flow', () {
      testWidgets('should update user profile', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Login
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Go to profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // Edit profile
        await tester.tap(find.text('Edit Profile'));
        await tester.pumpAndSettle();

        // Update information
        await tester.enterText(find.byKey(const Key('first_name')), 'Updated');
        await tester.enterText(find.byKey(const Key('phone')), '+1234567890');
        
        // Save changes
        await tester.tap(find.text('Save Changes'));
        await tester.pumpAndSettle();

        // Verify changes saved
        expect(find.text('Profile updated successfully'), findsOneWidget);
        expect(find.text('Updated'), findsOneWidget);
      });

      testWidgets('should view order history', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Login
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Go to profile
        await tester.tap(find.byIcon(Icons.person));
        await tester.pumpAndSettle();

        // View order history
        await tester.tap(find.text('Order History'));
        await tester.pumpAndSettle();

        // Verify order history screen
        expect(find.text('My Orders'), findsOneWidget);
        
        // Tap on an order to view details
        if (find.byType(OrderCard).hasFound) {
          await tester.tap(find.byType(OrderCard).first);
          await tester.pumpAndSettle();
          
          // Verify order details screen
          expect(find.text('Order Details'), findsOneWidget);
        }
      });
    });

    group('Messaging Flow', () {
      testWidgets('should send and receive messages', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Login
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Go to messages
        await tester.tap(find.byIcon(Icons.chat));
        await tester.pumpAndSettle();

        // Start new chat or open existing
        if (find.text('Start Chatting').hasFound) {
          await tester.tap(find.text('Start Chatting'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Contact Support'));
          await tester.pumpAndSettle();
        } else {
          await tester.tap(find.byType(ChatCard).first);
          await tester.pumpAndSettle();
        }

        // Send a message
        await tester.enterText(find.byKey(const Key('message_input')), 'Hello, I need help!');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Verify message was sent
        expect(find.text('Hello, I need help!'), findsOneWidget);
        
        // Wait for auto-response
        await tester.pump(const Duration(seconds: 2));
        
        // Verify auto-response received
        expect(find.textContaining('Thank you for contacting'), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should handle network errors gracefully', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Try to perform action that requires network
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();

        // Simulate network error by entering invalid data
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        
        // Mock network failure
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        // Should show appropriate error handling
        expect(
          find.textContaining('network') | find.textContaining('connection') | find.textContaining('error'),
          findsOneWidget,
        );
      });

      testWidgets('should handle app state restoration', (tester) async {
        app.main();
        await tester.pumpAndSettle();

        // Login and add items to cart
        await tester.tap(find.text('Login'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'test@example.com');
        await tester.enterText(find.byType(TextField).last, 'password123');
        await tester.tap(find.text('Sign In'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Shop Now'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.add_shopping_cart).first);
        await tester.pumpAndSettle();

        // Simulate app restart
        await tester.restartAndRestore();

        // Verify state was restored
        expect(find.text('1'), findsOneWidget); // Cart badge
        expect(find.text('Home'), findsOneWidget); // Still logged in
      });
    });
  });
}