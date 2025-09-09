import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/config/environment_secure.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations_delegate.dart';
import 'core/services/localization_service.dart';
import 'core/services/currency_service.dart';
import 'core/services/payment_service.dart';
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
        ChangeNotifierProvider(
          create: (_) => LocalizationService(),
        ),
        ChangeNotifierProvider(
          create: (_) => CurrencyService(),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentService(),
        ),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, localizationService, child) {
          return MaterialApp(
            title: 'Marketplace App',
            locale: localizationService.currentLocale,
            supportedLocales: LocalizationService.supportedLocales,
            localizationsDelegates: const [
              AppLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              // Default to Arabic for Algeria market
              return const Locale('ar', '');
            },
            theme: AppTheme.getLightTheme(),
            darkTheme: AppTheme.getDarkTheme(),
            themeMode: ThemeMode.light,
            home: const HomeScreen(), // Direct to home screen for testing
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}