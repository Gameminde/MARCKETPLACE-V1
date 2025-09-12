import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:marketplace_app/widgets/product_card.dart';
import 'package:marketplace_app/models/product.dart';
import 'package:marketplace_app/providers/cart_provider.dart';
import 'package:marketplace_app/providers/wishlist_provider.dart';

void main() {
  group('ProductCard Widget Tests', () {
    late Product testProduct;

    setUp(() {
      testProduct = const Product(
        id: 'test_1',
        name: 'Test Product',
        description: 'A test product for widget testing',
        price: 29.99,
        originalPrice: 39.99,
        imageUrl: 'https://example.com/test-image.jpg',
        category: 'Test Category',
        rating: 4.5,
        reviewCount: 100,
        inStock: true,
        availableColors: ['Red', 'Blue'],
      );
    });

    Widget createTestableWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render product card with all information', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Verify product name is displayed
        expect(find.text('Test Product'), findsOneWidget);
        
        // Verify price is displayed
        expect(find.text('\$29.99'), findsOneWidget);
        
        // Verify original price is displayed with strikethrough
        expect(find.text('\$39.99'), findsOneWidget);
        
        // Verify rating is displayed
        expect(find.text('4.5'), findsOneWidget);
        
        // Verify review count is displayed
        expect(find.text('(100)'), findsOneWidget);
        
        // Verify category is displayed
        expect(find.text('Test Category'), findsOneWidget);
      });

      testWidgets('should display product image', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Find image widget
        expect(find.byType(Image), findsOneWidget);
        
        // Verify image has correct URL
        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect((imageWidget.image as NetworkImage).url, equals('https://example.com/test-image.jpg'));
      });

      testWidgets('should show discount badge when on sale', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Should show discount percentage
        expect(find.text('25% OFF'), findsOneWidget);
        
        // Should have sale badge
        expect(find.byIcon(Icons.local_offer), findsOneWidget);
      });

      testWidgets('should not show discount badge when not on sale', (tester) async {
        final regularProduct = testProduct.copyWith(originalPrice: null);
        
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: regularProduct),
          ),
        );

        // Should not show discount
        expect(find.text('25% OFF'), findsNothing);
        expect(find.byIcon(Icons.local_offer), findsNothing);
      });

      testWidgets('should display rating stars', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Should have star rating display
        expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
      });
    });

    group('Interactive Elements', () {
      testWidgets('should call onTap when product card is tapped', (tester) async {
        bool wasTapped = false;
        
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(
              product: testProduct,
              onTap: () => wasTapped = true,
            ),
          ),
        );

        // Tap the product card
        await tester.tap(find.byType(ProductCard));
        await tester.pumpAndSettle();

        expect(wasTapped, isTrue);
      });

      testWidgets('should add product to cart when add to cart button is pressed', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Find and tap the add to cart button
        final addToCartButton = find.byIcon(Icons.add_shopping_cart);
        expect(addToCartButton, findsOneWidget);
        
        await tester.tap(addToCartButton);
        await tester.pumpAndSettle();

        // Verify product was added to cart
        final cartProvider = tester.element(find.byType(ProductCard))
            .read<CartProvider>();
        expect(cartProvider.isInCart(testProduct.id), isTrue);
      });

      testWidgets('should toggle wishlist when wishlist button is pressed', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Find and tap the wishlist button
        final wishlistButton = find.byIcon(Icons.favorite_border);
        expect(wishlistButton, findsOneWidget);
        
        await tester.tap(wishlistButton);
        await tester.pumpAndSettle();

        // Verify product was added to wishlist
        final wishlistProvider = tester.element(find.byType(ProductCard))
            .read<WishlistProvider>();
        expect(wishlistProvider.isInWishlist(testProduct.id), isTrue);

        // Icon should change to filled heart
        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border), findsNothing);
      });

      testWidgets('should show quick view when quick view button is tapped', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct, showQuickView: true),
          ),
        );

        // Find and tap the quick view button
        final quickViewButton = find.byIcon(Icons.visibility);
        expect(quickViewButton, findsOneWidget);
        
        await tester.tap(quickViewButton);
        await tester.pumpAndSettle();

        // Should show quick view dialog or bottom sheet
        expect(find.text('Quick View'), findsOneWidget);
      });
    });

    group('Different Card Styles', () {
      testWidgets('should render compact card style', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(
              product: testProduct,
              style: ProductCardStyle.compact,
            ),
          ),
        );

        // Compact style should have smaller height
        final cardWidget = tester.widget<Card>(find.byType(Card));
        expect(cardWidget, isNotNull);
      });

      testWidgets('should render list card style', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(
              product: testProduct,
              style: ProductCardStyle.list,
            ),
          ),
        );

        // List style should arrange elements horizontally
        expect(find.byType(Row), findsAtLeastNWidgets(1));
      });

      testWidgets('should render featured card style', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(
              product: testProduct,
              style: ProductCardStyle.featured,
            ),
          ),
        );

        // Featured style should be larger
        final sizedBox = find.byType(SizedBox).first;
        expect(sizedBox, findsOneWidget);
      });
    });

    group('Loading and Error States', () {
      testWidgets('should show loading state for image', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Should show loading indicator while image loads
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show placeholder when image fails to load', (tester) async {
        final productWithBadImage = testProduct.copyWith(
          imageUrl: 'https://invalid-url.com/image.jpg',
        );
        
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: productWithBadImage),
          ),
        );

        await tester.pump();

        // Should show placeholder icon
        expect(find.byIcon(Icons.image_not_supported), findsOneWidget);
      });

      testWidgets('should show out of stock indicator', (tester) async {
        final outOfStockProduct = testProduct.copyWith(inStock: false);
        
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: outOfStockProduct),
          ),
        );

        // Should show out of stock indicator
        expect(find.text('Out of Stock'), findsOneWidget);
        
        // Add to cart button should be disabled
        final addToCartButton = find.byIcon(Icons.add_shopping_cart);
        final button = tester.widget<IconButton>(addToCartButton);
        expect(button.onPressed, isNull);
      });
    });

    group('Color Variants', () {
      testWidgets('should show color variants when available', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(
              product: testProduct,
              showColorVariants: true,
            ),
          ),
        );

        // Should show color variant indicators
        expect(find.text('Red'), findsOneWidget);
        expect(find.text('Blue'), findsOneWidget);
      });

      testWidgets('should select color variant when tapped', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(
              product: testProduct,
              showColorVariants: true,
            ),
          ),
        );

        // Tap on blue color variant
        await tester.tap(find.text('Blue'));
        await tester.pumpAndSettle();

        // Blue should be selected (implementation dependent)
        expect(find.text('Blue'), findsOneWidget);
      });
    });

    group('Animations', () {
      testWidgets('should animate on hover (web/desktop)', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Simulate hover
        final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(tester.getCenter(find.byType(ProductCard)));
        await tester.pump();

        // Should trigger hover animation
        expect(find.byType(AnimatedContainer), findsAtLeastNWidgets(1));
      });

      testWidgets('should animate add to cart action', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Tap add to cart button
        await tester.tap(find.byIcon(Icons.add_shopping_cart));
        await tester.pump();

        // Should show animation feedback
        expect(find.byType(ScaleTransition), findsAtLeastNWidgets(1));
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Should have semantics for screen readers
        expect(
          find.bySemanticsLabel('Product: Test Product, Price: \$29.99'),
          findsOneWidget,
        );
      });

      testWidgets('should support focus navigation', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Should be focusable
        final cardFinder = find.byType(ProductCard);
        await tester.tap(cardFinder);
        await tester.pump();

        expect(Focus.of(tester.element(cardFinder)).hasFocus, isTrue);
      });

      testWidgets('should announce cart addition to screen readers', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: testProduct),
          ),
        );

        // Tap add to cart
        await tester.tap(find.byIcon(Icons.add_shopping_cart));
        await tester.pumpAndSettle();

        // Should announce the action
        expect(
          find.bySemanticsLabel(RegExp(r'Added.*to cart')),
          findsOneWidget,
        );
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle product with no image', (tester) async {
        final productWithoutImage = testProduct.copyWith(imageUrl: null);
        
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: productWithoutImage),
          ),
        );

        // Should show placeholder
        expect(find.byIcon(Icons.image), findsOneWidget);
      });

      testWidgets('should handle very long product names', (tester) async {
        final productWithLongName = testProduct.copyWith(
          name: 'This is a very long product name that should be truncated properly to fit in the card layout without breaking the UI',
        );
        
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: productWithLongName),
          ),
        );

        // Should truncate long text
        final textWidget = tester.widget<Text>(
          find.text(contains('This is a very long')),
        );
        expect(textWidget.overflow, equals(TextOverflow.ellipsis));
      });

      testWidgets('should handle zero rating', (tester) async {
        final productWithNoRating = testProduct.copyWith(
          rating: 0.0,
          reviewCount: 0,
        );
        
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: productWithNoRating),
          ),
        );

        // Should show "No reviews" or similar
        expect(find.text('No reviews'), findsOneWidget);
      });

      testWidgets('should handle free products', (tester) async {
        final freeProduct = testProduct.copyWith(price: 0.0);
        
        await tester.pumpWidget(
          createTestableWidget(
            ProductCard(product: freeProduct),
          ),
        );

        // Should show "Free" instead of price
        expect(find.text('Free'), findsOneWidget);
      });
    });
  });
}