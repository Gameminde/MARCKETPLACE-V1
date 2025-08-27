import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../lib/providers/auth_provider.dart';
import '../lib/providers/api_provider.dart';
import '../lib/services/app_router.dart';
import '../lib/screens/splash_screen.dart';
import '../lib/screens/auth/login_screen.dart';
import '../lib/screens/auth/register_screen.dart';
import '../lib/screens/home/home_screen.dart';
import '../lib/screens/shop/shop_detail_screen.dart';
import '../lib/screens/shop/create_shop_screen.dart';
import '../lib/screens/product/product_detail_screen.dart';
import '../lib/screens/product/product_form_screen.dart';
import '../lib/screens/profile/profile_screen.dart';
import '../lib/screens/profile/settings_screen.dart';
import '../lib/screens/upload/upload_screen.dart';

void main() {
  group('Phase 3 Validation Tests', () {
    group('AppRouter Tests', () {
      testWidgets('Router configuration test', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => ApiProvider()),
            ],
            child: MaterialApp.router(
              routerConfig: AppRouter.router,
              title: 'Marketplace Test',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Vérifier que l'écran de démarrage s'affiche
        expect(find.text('MARKETPLACE'), findsOneWidget);
      });

      testWidgets('Route redirection test', (tester) async {
        final authProvider = AuthProvider();
        
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: authProvider),
              ChangeNotifierProvider(create: (_) => ApiProvider()),
            ],
            child: MaterialApp.router(
              routerConfig: AppRouter.router,
              title: 'Marketplace Test',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Vérifier la redirection initiale vers splash
        expect(find.text('MARKETPLACE'), findsOneWidget);
      });
    });

    group('SplashScreen Tests', () {
      testWidgets('Splash screen content test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SplashScreen(),
          ),
        );

        // Vérifier le contenu de l'écran de démarrage
        expect(find.text('MARKETPLACE'), findsOneWidget);
        expect(find.text('Votre destination shopping'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.byIcon(Icons.store), findsOneWidget);
      });

      testWidgets('Splash screen navigation test', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: const SplashScreen(),
            routes: {
              '/auth': (context) => const LoginScreen(),
            },
          ),
        );

        // Attendre que la navigation automatique se déclenche
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Vérifier que la navigation vers l'authentification fonctionne
        expect(find.text('Bienvenue !'), findsOneWidget);
      });
    });

    group('LoginScreen Tests', () {
      testWidgets('Login form validation test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: LoginScreen(),
          ),
        );

        // Vérifier que le formulaire s'affiche
        expect(find.text('Bienvenue !'), findsOneWidget);
        expect(find.text('Connectez-vous à votre compte'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2));
        expect(find.text('Se connecter'), findsOneWidget);
        expect(find.text('Créer un compte'), findsOneWidget);
      });

      testWidgets('Login form submission test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: LoginScreen(),
          ),
        );

        // Tester la soumission du formulaire vide
        await tester.tap(find.text('Se connecter'));
        await tester.pumpAndSettle();

        // Vérifier que les erreurs de validation s'affichent
        expect(find.text('L\'email est requis'), findsOneWidget);
        expect(find.text('Le mot de passe est requis'), findsOneWidget);
      });

      testWidgets('Login navigation test', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: const LoginScreen(),
            routes: {
              '/auth/register': (context) => const RegisterScreen(),
            },
          ),
        );

        // Tester la navigation vers l'inscription
        await tester.tap(find.text('Créer un compte'));
        await tester.pumpAndSettle();

        // Vérifier que l'écran d'inscription s'affiche
        expect(find.text('Rejoignez-nous !'), findsOneWidget);
      });
    });

    group('RegisterScreen Tests', () {
      testWidgets('Register form validation test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: RegisterScreen(),
          ),
        );

        // Vérifier que le formulaire s'affiche
        expect(find.text('Rejoignez-nous !'), findsOneWidget);
        expect(find.text('Créez votre compte et commencez à vendre'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(5));
        expect(find.text('Créer mon compte'), findsOneWidget);
        expect(find.text('Se connecter'), findsOneWidget);
      });

      testWidgets('Register form submission test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: RegisterScreen(),
          ),
        );

        // Tester la soumission du formulaire vide
        await tester.tap(find.text('Créer mon compte'));
        await tester.pumpAndSettle();

        // Vérifier que les erreurs de validation s'affichent
        expect(find.text('Le prénom est requis'), findsOneWidget);
        expect(find.text('Le nom est requis'), findsOneWidget);
        expect(find.text('Le nom d\'utilisateur est requis'), findsOneWidget);
        expect(find.text('L\'email est requis'), findsOneWidget);
        expect(find.text('Le mot de passe est requis'), findsOneWidget);
      });
    });

    group('HomeScreen Tests', () {
      testWidgets('Home screen content test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomeScreen(),
          ),
        );

        // Vérifier que l'écran d'accueil s'affiche
        expect(find.text('Accueil'), findsOneWidget);
        expect(find.text('Bienvenue sur la page d\'accueil !'), findsOneWidget);
      });
    });

    group('ShopDetailScreen Tests', () {
      testWidgets('Shop detail screen test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ShopDetailScreen(shopId: 'test-shop'),
          ),
        );

        // Vérifier que l'écran de détail de boutique s'affiche
        expect(find.byType(ShopDetailScreen), findsOneWidget);
      });
    });

    group('CreateShopScreen Tests', () {
      testWidgets('Create shop screen test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: CreateShopScreen(),
          ),
        );

        // Vérifier que l'écran de création de boutique s'affiche
        expect(find.byType(CreateShopScreen), findsOneWidget);
      });
    });

    group('ProductDetailScreen Tests', () {
      testWidgets('Product detail screen test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ProductDetailScreen(productId: 'test-product'),
          ),
        );

        // Vérifier que l'écran de détail de produit s'affiche
        expect(find.byType(ProductDetailScreen), findsOneWidget);
      });
    });

    group('ProductFormScreen Tests', () {
      testWidgets('Product form screen test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ProductFormScreen(),
          ),
        );

        // Vérifier que l'écran de formulaire de produit s'affiche
        expect(find.byType(ProductFormScreen), findsOneWidget);
      });
    });

    group('ProfileScreen Tests', () {
      testWidgets('Profile screen test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: ProfileScreen(),
          ),
        );

        // Vérifier que l'écran de profil s'affiche
        expect(find.byType(ProfileScreen), findsOneWidget);
      });
    });

    group('SettingsScreen Tests', () {
      testWidgets('Settings screen test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SettingsScreen(),
          ),
        );

        // Vérifier que l'écran de paramètres s'affiche
        expect(find.byType(SettingsScreen), findsOneWidget);
      });
    });

    group('UploadScreen Tests', () {
      testWidgets('Upload screen test', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: UploadScreen(),
          ),
        );

        // Vérifier que l'écran d'upload s'affiche
        expect(find.byType(UploadScreen), findsOneWidget);
      });
    });

    group('Provider Tests', () {
      testWidgets('AuthProvider test', (tester) async {
        final authProvider = AuthProvider();
        
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => authProvider,
            child: const MaterialApp(
              home: Scaffold(
                body: Text('Test'),
              ),
            ),
          ),
        );

        // Vérifier que le provider fonctionne
        expect(authProvider.isAuthenticated, false);
      });

      testWidgets('ApiProvider test', (tester) async {
        final apiProvider = ApiProvider();
        
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => apiProvider,
            child: const MaterialApp(
              home: Scaffold(
                body: Text('Test'),
              ),
            ),
          ),
        );

        // Vérifier que le provider fonctionne
        expect(apiProvider.isLoading, false);
        expect(apiProvider.error, null);
      });
    });

    group('Integration Tests', () {
      testWidgets('Complete navigation flow test', (tester) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => AuthProvider()),
              ChangeNotifierProvider(create: (_) => ApiProvider()),
            ],
            child: MaterialApp.router(
              routerConfig: AppRouter.router,
              title: 'Marketplace Test',
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Vérifier l'écran de démarrage
        expect(find.text('MARKETPLACE'), findsOneWidget);

        // Attendre la navigation automatique
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Vérifier l'écran d'authentification
        expect(find.text('Bienvenue !'), findsOneWidget);

        // Tester la navigation vers l'inscription
        await tester.tap(find.text('Créer un compte'));
        await tester.pumpAndSettle();

        // Vérifier l'écran d'inscription
        expect(find.text('Rejoignez-nous !'), findsOneWidget);

        // Retourner à la connexion
        await tester.tap(find.text('Se connecter'));
        await tester.pumpAndSettle();

        // Vérifier l'écran de connexion
        expect(find.text('Bienvenue !'), findsOneWidget);
      });
    });
  });
}

// Widget de test pour les écrans qui nécessitent des providers
class TestWrapper extends StatelessWidget {
  final Widget child;
  final List<ChangeNotifierProvider> providers;

  const TestWrapper({
    super.key,
    required this.child,
    this.providers = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return MaterialApp(home: child);
    }

    return MultiProvider(
      providers: providers,
      child: MaterialApp(home: child),
    );
  }
}
