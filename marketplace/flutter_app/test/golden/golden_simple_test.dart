import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:marketplace/widgets/product_card.dart';
import 'package:marketplace/widgets/glassmorphic_container.dart';
import 'package:marketplace/widgets/loading_states.dart';
import 'package:marketplace/providers/cart_provider.dart';
import 'package:marketplace/providers/auth_provider.dart';
import 'package:marketplace/providers/search_provider.dart';
import 'package:marketplace/models/product.dart';
import 'package:marketplace/core/theme/app_theme.dart';

/// Simplified Golden tests for visual regression testing
/// 
/// These tests capture widget screenshots and compare them against baseline
/// images to ensure UI consistency and prevent visual regressions.
/// 
/// To generate golden files: flutter test --update-goldens test/golden/golden_simple_test.dart
/// To run golden tests: flutter test test/golden/golden_simple_test.dart
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

    group('Responsive Design', () {
      testWidgets('ProductCard - mobile size', (tester) async {
        tester.binding.window.physicalSizeTestValue = const Size(375, 667); // iPhone SE
        tester.view.devicePixelRatio = 2.0;
        
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
        tester.view.devicePixelRatio = 2.0;
        
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
    });
  });
}