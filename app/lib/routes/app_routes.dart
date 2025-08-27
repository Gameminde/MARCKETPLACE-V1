import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/shop/shop_screen.dart';
import '../screens/product/product_screen.dart';
import '../screens/upload/upload_screen.dart';
import '../screens/ai_demo/ai_demo_screen.dart';
import '../screens/profile/profile_screen.dart';

/// 🗺️ Configuration des routes de l'application Flutter
/// 
/// Utilise GoRouter pour une navigation avancée avec :
/// - Routes nommées
/// - Paramètres de route
/// - Navigation imbriquée
/// - Gestion des erreurs 404
class AppRoutes {
  // Routes nommées
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String shop = '/shop';
  static const String product = '/product';
  static const String upload = '/upload';
  static const String aiDemo = '/ai-demo';
  static const String profile = '/profile';
  static const String notFound = '/404';

  /// Configuration principale du routeur
  static final GoRouter router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,
    routes: [
      // Route d'accueil
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          // Sous-routes de l'accueil
          GoRoute(
            path: 'featured',
            name: 'featured',
            builder: (context, state) => const HomeScreen(initialTab: 1),
          ),
          GoRoute(
            path: 'trending',
            name: 'trending',
            builder: (context, state) => const HomeScreen(initialTab: 2),
          ),
        ],
      ),

      // Route d'authentification
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      GoRoute(
        path: register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Route de boutique
      GoRoute(
        path: shop,
        name: 'shop',
        builder: (context, state) {
          final shopId = state.queryParameters['id'];
          final shopName = state.queryParameters['name'];
          return ShopScreen(
            shopId: shopId ?? '',
            shopName: shopName ?? 'Boutique',
          );
        },
        routes: [
          // Sous-routes de la boutique
          GoRoute(
            path: 'products',
            name: 'shop-products',
            builder: (context, state) {
              final shopId = state.queryParameters['id'];
              return ShopScreen(
                shopId: shopId ?? '',
                shopName: 'Produits',
                initialTab: 1,
              );
            },
          ),
          GoRoute(
            path: 'about',
            name: 'shop-about',
            builder: (context, state) {
              final shopId = state.queryParameters['id'];
              return ShopScreen(
                shopId: shopId ?? '',
                shopName: 'À propos',
                initialTab: 2,
              );
            },
          ),
        ],
      ),

      // Route de produit
      GoRoute(
        path: product,
        name: 'product',
        builder: (context, state) {
          final productId = state.queryParameters['id'];
          final productName = state.queryParameters['name'];
          return ProductScreen(
            productId: productId ?? '',
            productName: productName ?? 'Produit',
          );
        },
      ),

      // Route d'upload
      GoRoute(
        path: upload,
        name: 'upload',
        builder: (context, state) => const UploadScreen(),
      ),

      // Route de démonstration IA
      GoRoute(
        path: aiDemo,
        name: 'ai-demo',
        builder: (context, state) => const AIDemoScreen(),
      ),

      // Route de profil
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          // Sous-routes du profil
          GoRoute(
            path: 'settings',
            name: 'profile-settings',
            builder: (context, state) => const ProfileScreen(initialTab: 1),
          ),
          GoRoute(
            path: 'orders',
            name: 'profile-orders',
            builder: (context, state) => const ProfileScreen(initialTab: 2),
          ),
          GoRoute(
            path: 'favorites',
            name: 'profile-favorites',
            builder: (context, state) => const ProfileScreen(initialTab: 3),
          ),
        ],
      ),

      // Route 404 (page non trouvée)
      GoRoute(
        path: notFound,
        name: 'not-found',
        builder: (context, state) => const NotFoundScreen(),
      ),
    ],

    // Gestion des erreurs 404
    errorBuilder: (context, state) => const NotFoundScreen(),

    // Redirections automatiques
    redirect: (context, state) {
      // Logique de redirection basée sur l'authentification
      // À implémenter selon vos besoins
      return null;
    },
  );

  /// Navigation vers une route nommée
  static void goTo(BuildContext context, String routeName, {Map<String, String>? queryParameters}) {
    if (queryParameters != null) {
      context.goNamed(routeName, queryParameters: queryParameters);
    } else {
      context.goNamed(routeName);
    }
  }

  /// Navigation vers une route avec remplacement de l'historique
  static void goToReplace(BuildContext context, String routeName, {Map<String, String>? queryParameters}) {
    if (queryParameters != null) {
      context.goNamed(routeName, queryParameters: queryParameters);
    } else {
      context.goNamed(routeName);
    }
  }

  /// Navigation vers une route avec push (ajout à l'historique)
  static void pushTo(BuildContext context, String routeName, {Map<String, String>? queryParameters}) {
    if (queryParameters != null) {
      context.pushNamed(routeName, queryParameters: queryParameters);
    } else {
      context.pushNamed(routeName);
    }
  }

  /// Retour en arrière
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed('home');
    }
  }

  /// Navigation vers l'écran de démonstration IA
  static void goToAIDemo(BuildContext context) {
    context.goNamed('ai-demo');
  }

  /// Navigation vers l'écran d'upload avec pré-remplissage
  static void goToUpload(BuildContext context, {String? category, String? template}) {
    final queryParams = <String, String>{};
    if (category != null) queryParams['category'] = category;
    if (template != null) queryParams['template'] = template;
    
    context.goNamed('upload', queryParameters: queryParams);
  }

  /// Navigation vers un produit spécifique
  static void goToProduct(BuildContext context, String productId, {String? productName}) {
    final queryParams = <String, String>{'id': productId};
    if (productName != null) queryParams['name'] = productName;
    
    context.goNamed('product', queryParameters: queryParams);
  }

  /// Navigation vers une boutique spécifique
  static void goToShop(BuildContext context, String shopId, {String? shopName}) {
    final queryParams = <String, String>{'id': shopId};
    if (shopName != null) queryParams['name'] = shopName;
    
    context.goNamed('shop', queryParameters: queryParams);
  }
}

/// 🚫 Écran 404 (page non trouvée)
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page non trouvée'),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 100,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              '404',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.red[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Page non trouvée',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'La page que vous recherchez n\'existe pas ou a été déplacée.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => AppRoutes.goBack(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => AppRoutes.goTo(context, 'home'),
              icon: const Icon(Icons.home),
              label: const Text('Accueil'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
