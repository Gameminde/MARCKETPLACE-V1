import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace/core/services/payment_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('PaymentService', () {
    late PaymentService paymentService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      SharedPreferences.setMockInitialValues({});
      paymentService = PaymentService();
    });

    test('should default to CIB payment method', () {
      expect(paymentService.currentPaymentMethod, 'CIB');
    });

    test('should support all Algerian payment methods', () {
      expect(PaymentService.supportedPaymentMethods.length, 7);
      
      // Check that all required payment methods are supported
      final methodIds = PaymentService.supportedPaymentMethods
          .map((method) => method['id'])
          .toList();
      
      expect(methodIds.contains('CIB'), true);
      expect(methodIds.contains('EDAHABIA'), true);
      expect(methodIds.contains('MOBILIS'), true);
      expect(methodIds.contains('DJAZZ'), true);
      expect(methodIds.contains('OOREDOO'), true);
      expect(methodIds.contains('COD'), true);
      expect(methodIds.contains('STRIPE'), true);
    });

    test('should get payment method details', () {
      final details = paymentService.getPaymentMethodDetails('CIB');
      expect(details, isNotNull);
      expect(details!['id'], 'CIB');
      expect(details['name'], 'بطاقة CIB');
    });

    test('should process payments', () async {
      // Test successful payment with CIB
      final result = await paymentService.processPayment(
        amount: 100.0,
        currency: 'DZD',
        paymentMethod: 'CIB',
        paymentDetails: {'cardNumber': '1234'},
      );
      
      expect(result['success'], true);
      expect(result['transactionId'], isNotNull);
    });
  });
}