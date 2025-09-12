import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/core/services/localization_service.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('LocalizationService', () {
    late LocalizationService localizationService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      SharedPreferences.setMockInitialValues({});
      localizationService = LocalizationService();
    });

    test('should default to Arabic locale', () {
      expect(localizationService.currentLocale.languageCode, 'ar');
    });

    test('should detect RTL languages correctly', () {
      expect(localizationService.isRtl, true);
    });

    test('should support Arabic, French, and English', () {
      expect(LocalizationService.supportedLocales.length, 3);
      expect(LocalizationService.supportedLocales[0].languageCode, 'ar');
      expect(LocalizationService.supportedLocales[1].languageCode, 'fr');
      expect(LocalizationService.supportedLocales[2].languageCode, 'en');
    });

    test('should translate keys correctly', () {
      // Test that the translate method returns the key if no translation is found
      expect(localizationService.translate('nonexistent_key'), 'nonexistent_key');
    });
  });
}