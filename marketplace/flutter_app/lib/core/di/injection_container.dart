import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:http/http.dart' as http;

import '../services/secure_storage_service.dart';
import '../../services/auth_api_service.dart';
import '../../services/product_api_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';

final getIt = GetIt.instance;

/// Configure dependency injection
void configureDependencies() {
  // Register services
  getIt.registerLazySingleton<SecureStorageService>(
    () => SecureStorageService(),
  );

  getIt.registerLazySingleton<http.Client>(
    () => http.Client(),
  );

  // Register API services
  getIt.registerLazySingleton<AuthApiService>(
    () => AuthApiService(),
  );

  getIt.registerLazySingleton<ProductApiService>(
    () => ProductApiService(),
  );

  // Register providers
  getIt.registerFactory<AuthProvider>(
    () => AuthProvider(),
  );

  getIt.registerFactory<CartProvider>(
    () => CartProvider(),
  );

  getIt.registerFactory<ProductProvider>(
    () => ProductProvider(
      productService: getIt<ProductApiService>(),
    ),
  );
}

/// Reset all dependencies (useful for testing)
void resetDependencies() {
  getIt.reset();
}
