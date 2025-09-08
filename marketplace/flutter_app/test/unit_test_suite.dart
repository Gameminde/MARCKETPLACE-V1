import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'providers/cart_provider_test.dart' as cart_provider_tests;
import 'providers/auth_provider_test.dart' as auth_provider_tests;
import 'providers/search_provider_test.dart' as search_provider_tests;
import 'services/api_service_test.dart' as api_service_tests;
import 'services/notification_service_test.dart' as notification_service_tests;
import 'services/messaging_service_test.dart' as messaging_service_tests;

/// Comprehensive test suite for all providers and business logic
/// 
/// This file runs all unit tests for the marketplace application including:
/// - Provider tests (Cart, Auth, Search)
/// - Service tests (API, Notification, Messaging)
/// - Business logic validation
/// - Error handling scenarios
/// 
/// Run with: flutter test test/unit_test_suite.dart
void main() {
  group('🧪 Marketplace Unit Tests Suite', () {
    group('🔄 Provider Tests', () {
      group('🛒 Cart Provider', cart_provider_tests.main);
      group('🔐 Auth Provider', auth_provider_tests.main);
      group('🔍 Search Provider', search_provider_tests.main);
    });

    group('🌐 Service Tests', () {
      group('📡 API Service', api_service_tests.main);
      group('🔔 Notification Service', notification_service_tests.main);
      group('💬 Messaging Service', messaging_service_tests.main);
    });
  });
}