import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:marketplace/core/services/currency_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('CurrencyService', () {
    late CurrencyService currencyService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      SharedPreferences.setMockInitialValues({});
      currencyService = CurrencyService();
    });

    test('should default to DZD currency', () {
      expect(currencyService.currentCurrency, 'DZD');
      expect(currencyService.currencySymbol, 'د.ج');
    });

    test('should support multiple currencies', () {
      expect(CurrencyService.supportedCurrencies.length, 3);
      expect(CurrencyService.supportedCurrencies['DZD'], 'د.ج');
      expect(CurrencyService.supportedCurrencies['EUR'], '€');
      expect(CurrencyService.supportedCurrencies['USD'], '\$');
    });

    test('should format prices correctly for DZD', () {
      // Test DZD formatting
      final formatted = currencyService.formatPrice(1234.56);
      // Should format as "1 234,56 د.ج" or similar
      expect(formatted.contains('د.ج'), true);
    });

    test('should convert prices between currencies', () {
      // Test conversion from DZD to EUR
      final converted = currencyService.convertPrice(1000, 'EUR');
      expect(converted > 0, true);
      
      // Test conversion from DZD to USD
      final converted2 = currencyService.convertPrice(1000, 'USD');
      expect(converted2 > 0, true);
    });
  });
}