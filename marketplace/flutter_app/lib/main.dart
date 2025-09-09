import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/config/environment_secure.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment
  const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  await EnvironmentSecure.initialize(environment);

  // Configure dependency injection
  configureDependencies();

  runApp(const MarketplaceApp());
}

class MarketplaceApp extends StatelessWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => getIt<AuthProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<CartProvider>(),
        ),
        ChangeNotifierProvider(
          create: (_) => getIt<ProductProvider>(),
        ),
      ],
      child: MaterialApp(
        title: 'Marketplace App',
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        themeMode: ThemeMode.light,
        home: const HomeScreen(), // Direct to home screen for testing
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


