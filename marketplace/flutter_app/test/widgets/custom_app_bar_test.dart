import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/widgets/custom_app_bar.dart';
import '../../lib/providers/cart_provider.dart';
import '../../lib/providers/search_provider.dart';

void main() {
  group('CustomAppBar Widget Tests', () {
    Widget createTestableWidget(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => SearchProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: child as PreferredSizeWidget,
            body: const Center(child: Text('Body')),
          ),
        ),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render app bar with title', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
            ),
          ),
        );

        expect(find.text('Test App Bar'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should show search icon when showSearch is true', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              showSearch: true,
            ),
          ),
        );

        expect(find.byIcon(Icons.search), findsOneWidget);
      });

      testWidgets('should show notifications icon when showNotifications is true', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              showNotifications: true,
            ),
          ),
        );

        expect(find.byIcon(Icons.notifications), findsOneWidget);
      });

      testWidgets('should show cart icon when showCart is true', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              showCart: true,
            ),
          ),
        );

        expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      });

      testWidgets('should show chat icon when showChat is true', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              showChat: true,
            ),
          ),
        );

        expect(find.byIcon(Icons.chat), findsOneWidget);
      });
    });

    group('Cart Badge', () {
      testWidgets('should show cart badge when cart has items', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              showCart: true,
            ),
          ),
        );

        // Add item to cart
        final cartProvider = tester.element(find.byType(CustomAppBar))
            .read<CartProvider>();
        
        await cartProvider.addItem(const Product(
          id: 'test_1',
          name: 'Test Product',
          description: 'Test',
          price: 29.99,
          category: 'Test',
        ));

        await tester.pumpAndSettle();

        // Should show badge with count
        expect(find.text('1'), findsOneWidget);
      });

      testWidgets('should not show cart badge when cart is empty', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              showCart: true,
            ),
          ),
        );

        // Cart should be empty by default
        expect(find.byType(Badge), findsNothing);
      });
    });

    group('Search Functionality', () {
      testWidgets('should open search when search icon is tapped', (tester) async {
        bool searchOpened = false;
        
        await tester.pumpWidget(
          createTestableWidget(
            CustomAppBar(
              title: 'Test App Bar',
              showSearch: true,
              onSearchTap: () => searchOpened = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.search));
        await tester.pumpAndSettle();

        expect(searchOpened, isTrue);
      });

      testWidgets('should show search field when in search mode', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              showSearch: true,
              isSearchMode: true,
            ),
          ),
        );

        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('should close search when close icon is tapped', (tester) async {
        bool searchClosed = false;
        
        await tester.pumpWidget(
          createTestableWidget(
            CustomAppBar(
              title: 'Test App Bar',
              showSearch: true,
              isSearchMode: true,
              onSearchClose: () => searchClosed = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();

        expect(searchClosed, isTrue);
      });
    });

    group('Navigation', () {
      testWidgets('should call onBackPressed when back button is tapped', (tester) async {
        bool backPressed = false;
        
        await tester.pumpWidget(
          createTestableWidget(
            CustomAppBar(
              title: 'Test App Bar',
              showBackButton: true,
              onBackPressed: () => backPressed = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();

        expect(backPressed, isTrue);
      });

      testWidgets('should navigate to cart when cart icon is tapped', (tester) async {
        bool cartOpened = false;
        
        await tester.pumpWidget(
          createTestableWidget(
            CustomAppBar(
              title: 'Test App Bar',
              showCart: true,
              onCartTap: () => cartOpened = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.shopping_cart));
        await tester.pumpAndSettle();

        expect(cartOpened, isTrue);
      });

      testWidgets('should navigate to notifications when notifications icon is tapped', (tester) async {
        bool notificationsOpened = false;
        
        await tester.pumpWidget(
          createTestableWidget(
            CustomAppBar(
              title: 'Test App Bar',
              showNotifications: true,
              onNotificationsTap: () => notificationsOpened = true,
            ),
          ),
        );

        await tester.tap(find.byIcon(Icons.notifications));
        await tester.pumpAndSettle();

        expect(notificationsOpened, isTrue);
      });
    });

    group('Custom Actions', () {
      testWidgets('should show custom actions when provided', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            CustomAppBar(
              title: 'Test App Bar',
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.help),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );

        expect(find.byIcon(Icons.settings), findsOneWidget);
        expect(find.byIcon(Icons.help), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              showSearch: true,
              showCart: true,
              showNotifications: true,
            ),
          ),
        );

        expect(find.bySemanticsLabel('Search'), findsOneWidget);
        expect(find.bySemanticsLabel('Shopping cart'), findsOneWidget);
        expect(find.bySemanticsLabel('Notifications'), findsOneWidget);
      });
    });

    group('Visual Customization', () {
      testWidgets('should apply custom background color', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              backgroundColor: Colors.red,
            ),
          ),
        );

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, equals(Colors.red));
      });

      testWidgets('should apply custom elevation', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              elevation: 10.0,
            ),
          ),
        );

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.elevation, equals(10.0));
      });

      testWidgets('should center title when specified', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              centerTitle: true,
            ),
          ),
        );

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.centerTitle, isTrue);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle empty title', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: '',
            ),
          ),
        );

        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should handle all icons enabled', (tester) async {
        await tester.pumpWidget(
          createTestableWidget(
            const CustomAppBar(
              title: 'Test App Bar',
              showSearch: true,
              showCart: true,
              showNotifications: true,
              showChat: true,
              showBackButton: true,
            ),
          ),
        );

        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
        expect(find.byIcon(Icons.notifications), findsOneWidget);
        expect(find.byIcon(Icons.chat), findsOneWidget);
      });
    });
  });
}