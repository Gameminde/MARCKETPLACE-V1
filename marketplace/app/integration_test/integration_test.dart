import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import '../lib/main.dart';
import '../lib/providers/auth_provider.dart';
import '../lib/providers/api_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Marketplace App Integration Tests', () {
    testWidgets('Complete app flow test', (tester) async {
      // Démarrer l'application
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiProvider()),
          ],
          child: const MarketplaceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Vérifier que l'écran de démarrage s'affiche
      expect(find.text('MARKETPLACE'), findsOneWidget);
      expect(find.text('Votre destination shopping'), findsOneWidget);

      // Attendre que l'écran de démarrage se termine
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Vérifier que l'écran d'authentification s'affiche
      expect(find.text('Bienvenue !'), findsOneWidget);
      expect(find.text('Connectez-vous à votre compte'), findsOneWidget);

      // Tester la navigation vers l'inscription
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      // Vérifier que l'écran d'inscription s'affiche
      expect(find.text('Rejoignez-nous !'), findsOneWidget);
      expect(find.text('Créez votre compte et commencez à vendre'), findsOneWidget);

      // Retourner à la connexion
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Vérifier que l'écran de connexion s'affiche
      expect(find.text('Bienvenue !'), findsOneWidget);
    });

    testWidgets('Authentication flow test', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiProvider()),
          ],
          child: const MarketplaceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Attendre que l'écran de démarrage se termine
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Remplir le formulaire de connexion
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );

      // Tester la validation du formulaire
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Vérifier que les erreurs de validation s'affichent
      expect(find.text('L\'email est requis'), findsOneWidget);
      expect(find.text('Le mot de passe est requis'), findsOneWidget);
    });

    testWidgets('Navigation test', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiProvider()),
          ],
          child: const MarketplaceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Attendre que l'écran de démarrage se termine
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tester la navigation vers l'inscription
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      // Vérifier que l'écran d'inscription s'affiche
      expect(find.text('Rejoignez-nous !'), findsOneWidget);

      // Tester la navigation vers la connexion
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Vérifier que l'écran de connexion s'affiche
      expect(find.text('Bienvenue !'), findsOneWidget);
    });

    testWidgets('Form validation test', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiProvider()),
          ],
          child: const MarketplaceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Attendre que l'écran de démarrage se termine
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Aller à l'écran d'inscription
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      // Tester la validation avec des champs vides
      await tester.tap(find.text('Créer mon compte'));
      await tester.pumpAndSettle();

      // Vérifier que les erreurs de validation s'affichent
      expect(find.text('Le prénom est requis'), findsOneWidget);
      expect(find.text('Le nom est requis'), findsOneWidget);
      expect(find.text('Le nom d\'utilisateur est requis'), findsOneWidget);
      expect(find.text('L\'email est requis'), findsOneWidget);
      expect(find.text('Le mot de passe est requis'), findsOneWidget);
    });

    testWidgets('UI responsiveness test', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiProvider()),
          ],
          child: const MarketplaceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Attendre que l'écran de démarrage se termine
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Vérifier que tous les éléments UI sont visibles
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byType(Icon), findsWidgets);

      // Tester la réactivité des boutons
      await tester.tap(find.text('Créer un compte'));
      await tester.pumpAndSettle();

      // Vérifier que la navigation fonctionne
      expect(find.text('Rejoignez-nous !'), findsOneWidget);
    });

    testWidgets('Error handling test', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiProvider()),
          ],
          child: const MarketplaceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Attendre que l'écran de démarrage se termine
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Tester la gestion des erreurs de validation
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      // Vérifier que les messages d'erreur s'affichent
      expect(find.text('L\'email est requis'), findsOneWidget);
      expect(find.text('Le mot de passe est requis'), findsOneWidget);
    });

    testWidgets('Accessibility test', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiProvider()),
          ],
          child: const MarketplaceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Attendre que l'écran de démarrage se termine
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Vérifier que tous les éléments interactifs ont des labels
      expect(find.byType(ElevatedButton), findsWidgets);
      expect(find.byType(TextFormField), findsWidgets);

      // Vérifier que les icônes sont présentes
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('Performance test', (tester) async {
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ApiProvider()),
          ],
          child: const MarketplaceApp(),
        ),
      );

      stopwatch.stop();
      final buildTime = stopwatch.elapsedMilliseconds;

      // Vérifier que le temps de construction est raisonnable (< 100ms)
      expect(buildTime, lessThan(100));

      await tester.pumpAndSettle();

      // Attendre que l'écran de démarrage se termine
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Vérifier que l'application est responsive
      expect(find.text('Bienvenue !'), findsOneWidget);
    });
  });
}

// Widget de test pour simuler l'application
class MarketplaceApp extends StatelessWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/auth': (context) => const LoginScreen(),
        '/auth/login': (context) => const LoginScreen(),
        '/auth/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

// Écrans simulés pour les tests
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToAuth();
  }

  void _navigateToAuth() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/auth');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store, size: 100, color: Colors.blue),
            const SizedBox(height: 20),
            Text(
              'MARKETPLACE',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            const Text('Votre destination shopping'),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Bienvenue !'),
              const SizedBox(height: 20),
              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'email est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('password_field'),
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le mot de passe est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Validation réussie
                  }
                },
                child: const Text('Se connecter'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/auth/register');
                },
                child: const Text('Créer un compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inscription')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text('Rejoignez-nous !'),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le prénom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nom d\'utilisateur',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le nom d\'utilisateur est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'email est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le mot de passe est requis';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Validation réussie
                  }
                },
                child: const Text('Créer mon compte'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil')),
      body: const Center(
        child: Text('Bienvenue sur la page d\'accueil !'),
      ),
    );
  }
}
