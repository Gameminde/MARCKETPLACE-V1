import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../features/modern_home/modern_home_screen.dart';
import '../screens/shop/shop_detail_screen.dart';
import '../screens/shop/create_shop_screen.dart';
import '../screens/product/product_detail_screen.dart';
import '../screens/product/product_form_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/upload/upload_screen.dart';
import '../screens/splash_screen.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/home', // BYPASS: Aller directement à l'accueil
    redirect: (context, state) {
      // BYPASS AUTHENTIFICATION - Accès direct à toutes les routes
      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'login',
            name: 'login',
            builder: (context, state) => const LoginScreen(),
          ),
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
        ],
      ),

      // Main App Routes (Protected)
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const Modern3DHomeScreen(),
      ),
      
      // Classic Home (for comparison)
      GoRoute(
        path: '/home-classic',
        name: 'home-classic',
        builder: (context, state) => const HomeScreen(),
      ),

      // Shop Routes
      GoRoute(
        path: '/shop/create',
        name: 'create-shop',
        builder: (context, state) => const CreateShopScreen(),
      ),
      GoRoute(
        path: '/shop/:shopId',
        name: 'shop-detail',
        builder: (context, state) {
          final shopId = state.pathParameters['shopId']!;
          return ShopDetailScreen(shopId: shopId);
        },
      ),

      // Product Routes
      GoRoute(
        path: '/product/create',
        name: 'create-product',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/product/:productId',
        name: 'product-detail',
        builder: (context, state) {
          final productId = state.pathParameters['productId']!;
          return ProductDetailScreen(productId: productId);
        },
      ),

      // Upload Routes
      GoRoute(
        path: '/upload',
        name: 'upload',
        builder: (context, state) => const UploadScreen(),
      ),

      // Profile Routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        routes: [
          GoRoute(
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) => _ErrorScreen(error: state.error),
  );

  // Navigation helpers
  static void goToHome(BuildContext context) => context.go('/home');
  static void goToAuth(BuildContext context) => context.go('/auth');
  static void goToShopDetail(BuildContext context, String shopId) => context.go('/shop/$shopId');
  static void goToProductDetail(BuildContext context, String productId) => context.go('/product/$productId');
  static void goToCreateShop(BuildContext context) => context.go('/shop/create');
  static void goToCreateProduct(BuildContext context) => context.go('/product/create');
  static void goToUpload(BuildContext context) => context.go('/upload');
  static void goToProfile(BuildContext context) => context.go('/profile');
  static void goToSettings(BuildContext context) => context.go('/profile/settings');
}

class _ErrorScreen extends StatelessWidget {
  final Exception? error;

  const _ErrorScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Une erreur est survenue',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }
}
