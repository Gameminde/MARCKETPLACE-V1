import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class LocalizationService extends ChangeNotifier {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage =
      'ar'; // Default to Arabic for Algeria market

  late Locale _currentLocale;
  late Map<String, String> _localizedStrings;

  // Supported locales
  static const List<Locale> supportedLocales = [
    Locale('ar', ''), // Arabic
    Locale('fr', ''), // French
    Locale('en', ''), // English
  ];

  // RTL languages
  static const List<String> rtlLanguages = ['ar'];

  Locale get currentLocale => _currentLocale;
  bool get isRtl => rtlLanguages.contains(_currentLocale.languageCode);

  LocalizationService() {
    _currentLocale = const Locale(_defaultLanguage, '');
    _localizedStrings = {};
    _loadSavedLanguage();
  }

  // Load saved language from shared preferences
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey) ?? _defaultLanguage;
      _currentLocale = Locale(savedLanguage, '');
    } catch (e) {
      _currentLocale = const Locale(_defaultLanguage, '');
    }
    await _loadLocalizedStrings();
  }

  // Change language
  Future<void> changeLanguage(Locale newLocale) async {
    if (supportedLocales.contains(newLocale)) {
      _currentLocale = newLocale;
      await _loadLocalizedStrings();

      // Save language preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, newLocale.languageCode);

      notifyListeners();
    }
  }

  // Load localized strings from JSON files
  Future<void> _loadLocalizedStrings() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/l10n/${_currentLocale.languageCode}.json',
      );
      final Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings =
          jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      // Fallback to empty map if file not found
      _localizedStrings = {};
    }
  }

  // Get translated string
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }

  // Static method for easy access
  static String of(BuildContext context, String key) {
    final localizationService = LocalizationService.ofProvider(context);
    return localizationService.translate(key);
  }

  // Get instance from provider
  static LocalizationService ofProvider(BuildContext context) {
    return Provider.of<LocalizationService>(context, listen: false);
  }
}
