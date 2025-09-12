import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme/algeria_theme.dart';
import 'core/localization/app_localizations_delegate.dart';
import 'core/services/app_initialization_service.dart';
import 'core/services/localization_service.dart';
import 'core/services/currency_service.dart';
import 'core/services/payment_service.dart';
import 'services/banking_auth_service.dart';
import 'providers/auth_provider_secure.dart';
import 'providers/cart_provider.dart';
import 'providers/product_provider.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start app immediately for fast cold start
  runApp(const MarketplaceApp());
}

class MarketplaceApp extends StatelessWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AppInitializationService(),
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
        Provider(
          create: (_) => BankingAuthService(),
        ),
        // Other providers will be initialized after app initialization
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
            theme: AlgeriaTheme.getLightTheme(),
            darkTheme: AlgeriaTheme.getDarkTheme(),
            themeMode: ThemeMode.light,
            home: const SplashScreen(), // Start with splash for fast cold start
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}