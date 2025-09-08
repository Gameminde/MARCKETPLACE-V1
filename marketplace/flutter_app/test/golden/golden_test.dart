import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:marketplace/widgets/product_card.dart';
import 'package:marketplace/widgets/glassmorphic_container.dart';
import 'package:marketplace/widgets/custom_app_bar.dart';
import 'package:marketplace/widgets/loading_states.dart';
import 'package:marketplace/widgets/category_section.dart';
import 'package:marketplace/screens/login_screen.dart';
import 'package:marketplace/screens/cart_screen.dart';
import 'package:marketplace/providers/cart_provider.dart';
import 'package:marketplace/providers/auth_provider.dart';
import 'package:marketplace/providers/search_provider.dart';
import 'package:marketplace/models/product.dart';
import 'package:marketplace/core/theme/app_theme.dart';

/// Golden tests for visual regression testing
/// 
/// These tests capture widget screenshots and compare them against baseline
/// images to ensure UI consistency and prevent visual regressions.
/// 
/// To generate golden files: flutter test --update-goldens test/golden/golden_test.dart
/// To run golden tests: flutter test test/golden/golden_test.dart
void main() {
  group('🎨 Golden Tests - Visual Regression Testing', () {
    
    // Mock data for testing
    final mockProduct = const Product(
      id: 'test_1',
      name: 'Test Product',
      description: 'A beautiful test product with amazing features',
      price: 99.99,
      category: 'Electronics',
      rating: 4.8,
      reviewCount: 1250,
      imageUrl: 'https://example.com/product.jpg',
      inStock: true,
      availableColors: ['Black', 'White', 'Red'],
      availableSizes: ['S', 'M', 'L', 'XL'],
    );

    Widget createTestableWidget(Widget child, {ThemeData? theme}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
        ],
        child: MaterialApp(
          theme: theme ?? AppTheme.lightTheme,
          home: Scaffold(
            body: child,
          ),
          debugShowCheckedModeBanner: false,
        ),
      );
    }

    group('Product Components', () {
      testWidgets('ProductCard - light theme', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Center(
              child: SizedBox(
                width: 200,
                child: ProductCard(
                  product: mockProduct,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(ProductCard),
          matchesGoldenFile('goldens/product_card_light.png'),
        );
      });

      testWidgets('ProductCard - dark theme', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Center(
              child: SizedBox(
                width: 200,
                child: ProductCard(
                  product: mockProduct,
                  onTap: () {},
                ),
              ),
            ),
            theme: AppTheme.darkTheme,
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(ProductCard),
          matchesGoldenFile('goldens/product_card_dark.png'),
        );
      });

      testWidgets('ProductCard - out of stock', (tester) async {
        final outOfStockProduct = mockProduct.copyWith(inStock: false);
        
        await tester.pumpWidget(
          createTestableWidget(
            Center(
              child: SizedBox(
                width: 200,
                child: ProductCard(
                  product: outOfStockProduct,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(ProductCard),
          matchesGoldenFile('goldens/product_card_out_of_stock.png'),
        );
      });

      testWidgets('ProductCard - sale badge', (tester) async {
        final saleProduct = mockProduct.copyWith(
          originalPrice: 149.99,
          isOnSale: true,
        );
        
        await tester.pumpWidget(
          createTestableWidget(
            Center(
              child: SizedBox(
                width: 200,
                child: ProductCard(
                  product: saleProduct,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(ProductCard),
          matchesGoldenFile('goldens/product_card_sale.png'),
        );
      });
    });

    group('UI Components', () {
      testWidgets('GlassmorphicContainer - card style', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: GlassmorphicContainer.card(
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star, size: 48, color: Colors.amber),
                        SizedBox(height: 8),
                        Text(
                          'Glassmorphic Card',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Beautiful glass effect'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(GlassmorphicContainer),
          matchesGoldenFile('goldens/glassmorphic_container_card.png'),
        );
      });

      testWidgets('GlassmorphicContainer - elevated style', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: GlassmorphicContainer.elevated(
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, size: 48, color: Colors.blue),
                        SizedBox(height: 8),
                        Text(
                          'Elevated Card',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Enhanced elevation effect'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(GlassmorphicContainer),
          matchesGoldenFile('goldens/glassmorphic_container_elevated.png'),
        );
      });

      testWidgets('CustomAppBar - basic configuration', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Marketplace',
              showSearch: true,
              showCart: true,
              showNotifications: true,
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(CustomAppBar),
          matchesGoldenFile('goldens/custom_app_bar_basic.png'),
        );
      });

      testWidgets('CustomAppBar - search mode', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Search',
              showSearch: true,
              isSearchMode: true,
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(CustomAppBar),
          matchesGoldenFile('goldens/custom_app_bar_search.png'),
        );
      });
    });

    group('Loading States', () {
      testWidgets('LoadingStates - skeleton loader', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const Center(
              child: SizedBox(
                width: 300,
                height: 400,
                child: LoadingStates.skeleton(),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(LoadingStates),
          matchesGoldenFile('goldens/loading_states_skeleton.png'),
        );
      });

      testWidgets('LoadingStates - spinner', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: LoadingStates.spinner(
                  message: 'Loading products...',
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(LoadingStates),
          matchesGoldenFile('goldens/loading_states_spinner.png'),
        );
      });

      testWidgets('LoadingStates - shimmer effect', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const Center(
              child: SizedBox(
                width: 300,
                height: 150,
                child: LoadingStates.shimmer(
                  child: Column(
                    children: [
                      LoadingStates.shimmerBox(width: 280, height: 20),
                      SizedBox(height: 8),
                      LoadingStates.shimmerBox(width: 200, height: 16),
                      SizedBox(height: 8),
                      LoadingStates.shimmerBox(width: 250, height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(LoadingStates),
          matchesGoldenFile('goldens/loading_states_shimmer.png'),
        );
      });
    });

    group('Category Components', () {
      testWidgets('CategorySection - horizontal scroll', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const SizedBox(
              height: 120,
              child: CategorySection(),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(CategorySection),
          matchesGoldenFile('goldens/category_section.png'),
        );
      });
    });

    group('Screen Layouts', () {
      testWidgets('LoginScreen - complete layout', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(const LoginScreen()),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(LoginScreen),
          matchesGoldenFile('goldens/login_screen.png'),
        );
      });

      testWidgets('CartScreen - empty cart', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(const CartScreen()),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(CartScreen),
          matchesGoldenFile('goldens/cart_screen_empty.png'),
        );
      });

      testWidgets('CartScreen - with items', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(const CartScreen()),
        );

        // Add items to cart
        final cartProvider = tester.element(find.byType(CartScreen))
            .read<CartProvider>();
        await cartProvider.addItem(mockProduct);
        await cartProvider.addItem(mockProduct.copyWith(
          id: 'test_2',
          name: 'Another Product',
          price: 149.99,
        ));

        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(CartScreen),
          matchesGoldenFile('goldens/cart_screen_with_items.png'),
        );
      });
    });

    group('Responsive Design', () {
      testWidgets('ProductCard - mobile size', (tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(375, 667); // iPhone SE
        tester.binding.window.devicePixelRatioTestValue = 2.0;
        
        await tester.pumpWidget(
          createTestableWidget(
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ProductCard(
                product: mockProduct,
                onTap: () {},
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(ProductCard),
          matchesGoldenFile('goldens/product_card_mobile.png'),
        );
        
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });

      testWidgets('ProductCard - tablet size', (tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(768, 1024); // iPad
        tester.binding.window.devicePixelRatioTestValue = 2.0;
        
        await tester.pumpWidget(
          createTestableWidget(
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ProductCard(
                product: mockProduct,
                onTap: () {},
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(ProductCard),
          matchesGoldenFile('goldens/product_card_tablet.png'),
        );
        
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });
    });

    group('Theme Variations', () {
      testWidgets('GlassmorphicContainer - light theme variations', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 250,
                  height: 80,
                  child: GlassmorphicContainer.card(
                    child: const Center(child: Text('Card Style')),
                  ),
                ),
                SizedBox(
                  width: 250,
                  height: 80,
                  child: GlassmorphicContainer.elevated(
                    child: const Center(child: Text('Elevated Style')),
                  ),
                ),
                SizedBox(
                  width: 250,
                  height: 80,
                  child: GlassmorphicContainer.frosted(
                    child: const Center(child: Text('Frosted Style')),
                  ),
                ),
              ],
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(Column),
          matchesGoldenFile('goldens/glassmorphic_variations_light.png'),
        );
      });

      testWidgets('GlassmorphicContainer - dark theme variations', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 250,
                  height: 80,
                  child: GlassmorphicContainer.card(
                    child: const Center(child: Text('Card Style')),
                  ),
                ),
                SizedBox(
                  width: 250,
                  height: 80,
                  child: GlassmorphicContainer.elevated(
                    child: const Center(child: Text('Elevated Style')),
                  ),
                ),
                SizedBox(
                  width: 250,
                  height: 80,
                  child: GlassmorphicContainer.frosted(
                    child: const Center(child: Text('Frosted Style')),
                  ),
                ),
              ],
            ),
            theme: AppTheme.darkTheme,
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(Column),
          matchesGoldenFile('goldens/glassmorphic_variations_dark.png'),
        );
      });
    });

    group('Complex Layouts', () {
      testWidgets('Product grid layout', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            SizedBox(
              height: 600,
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => ProductCard(
                  product: mockProduct.copyWith(
                    id: 'product_$index',
                    name: 'Product ${index + 1}',
                    price: 99.99 + (index * 10),
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(GridView),
          matchesGoldenFile('goldens/product_grid_layout.png'),
        );
      });

      testWidgets('Mixed component layout', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomAppBar(
                    title: 'Featured Products',
                    showSearch: true,
                    showCart: true,
                  ),
                  const SizedBox(height: 16),
                  const CategorySection(),
                  const SizedBox(height: 24),
                  const Text(
                    'Trending Products',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ProductCard(
                          product: mockProduct,
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ProductCard(
                          product: mockProduct.copyWith(
                            id: 'product_2',
                            name: 'Another Product',
                            price: 149.99,
                          ),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(SingleChildScrollView),
          matchesGoldenFile('goldens/mixed_component_layout.png'),
        );
      });
    });

    group('State Variations', () {
      testWidgets('ProductCard - loading state', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Center(
              child: SizedBox(
                width: 200,
                child: ProductCard(
                  product: mockProduct.copyWith(imageUrl: null),
                  onTap: () {},
                  isLoading: true,
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(ProductCard),
          matchesGoldenFile('goldens/product_card_loading.png'),
        );
      });

      testWidgets('ProductCard - error state', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            Center(
              child: SizedBox(
                width: 200,
                child: ProductCard(
                  product: mockProduct.copyWith(imageUrl: 'invalid_url'),
                  onTap: () {},
                  hasError: true,
                ),
              ),
            ),
          ),
        );
        
        await tester.pumpAndSettle();
        
        await expectLater(
          find.byType(ProductCard),
          matchesGoldenFile('goldens/product_card_error.png'),
        );
      });
    });
  });
}