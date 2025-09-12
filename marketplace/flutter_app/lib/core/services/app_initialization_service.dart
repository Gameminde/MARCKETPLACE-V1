import 'package:flutter/foundation.dart';
import '../config/environment_secure.dart';
import '../di/injection_container.dart';

class AppInitializationService extends ChangeNotifier {
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _error;

  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    _error = null;
    notifyListeners();

    try {
      // Initialize environment in background
      const environment = String.fromEnvironment(
        'ENVIRONMENT',
        defaultValue: 'development',
      );

      await EnvironmentSecure.initialize(environment);

      // Configure dependency injection
      configureDependencies();

      _isInitialized = true;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('App initialization failed: $e');
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }
}