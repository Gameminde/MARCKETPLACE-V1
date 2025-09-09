import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class CurrencyService extends ChangeNotifier {
  static const String _currencyKey = 'selected_currency';
  static const String _defaultCurrency = 'DZD'; // Algerian Dinar
  
  late String _currentCurrency;
  late String _currencySymbol;
  
  // Supported currencies
  static const Map<String, String> supportedCurrencies = {
    'DZD': 'د.ج', // Algerian Dinar
    'EUR': '€',   // Euro
    'USD': '$',   // US Dollar
  };
  
  String get currentCurrency => _currentCurrency;
  String get currencySymbol => _currencySymbol;
  
  CurrencyService() {
    _loadSavedCurrency();
  }
  
  // Load saved currency from shared preferences
  void _loadSavedCurrency() {
    _currentCurrency = _defaultCurrency;
    _currencySymbol = supportedCurrencies[_defaultCurrency] ?? 'د.ج';
  }
  
  // Change currency
  Future<void> changeCurrency(String newCurrencyCode) async {
    if (supportedCurrencies.containsKey(newCurrencyCode)) {
      _currentCurrency = newCurrencyCode;
      _currencySymbol = supportedCurrencies[newCurrencyCode]!;
      
      // Save currency preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, newCurrencyCode);
      
      notifyListeners();
    }
  }
  
  // Format price with currency
  String formatPrice(double price) {
    // For DZD, we use Algerian format
    if (_currentCurrency == 'DZD') {
      return '${_formatNumber(price)} $_currencySymbol';
    }
    
    // For other currencies, use standard format
    return '$_currencySymbol${_formatNumber(price)}';
  }
  
  // Format number with thousands separator
  String _formatNumber(double number) {
    // For Algerian format, use comma as decimal separator and space as thousands separator
    if (_currentCurrency == 'DZD') {
      final formatter = NumberFormat("#,##0.00", "ar_DZ");
      return formatter.format(number);
    }
    
    // For other currencies, use standard formatting
    return NumberFormat.currency(symbol: '').format(number);
  }
  
  // Convert price to different currency (simplified)
  double convertPrice(double price, String targetCurrency) {
    // In a real implementation, this would use real exchange rates
    // For now, we'll use fixed conversion rates for demonstration
    final Map<String, Map<String, double>> exchangeRates = {
      'DZD': {
        'EUR': 0.0067, // 1 DZD = 0.0067 EUR
        'USD': 0.0073, // 1 DZD = 0.0073 USD
      },
      'EUR': {
        'DZD': 150.0,  // 1 EUR = 150 DZD
        'USD': 1.09,   // 1 EUR = 1.09 USD
      },
      'USD': {
        'DZD': 137.0,  // 1 USD = 137 DZD
        'EUR': 0.92,   // 1 USD = 0.92 EUR
      },
    };
    
    if (_currentCurrency == targetCurrency) {
      return price;
    }
    
    final rate = exchangeRates[_currentCurrency]?[targetCurrency] ?? 1.0;
    return price * rate;
  }
}