/// Simple currency service for basic currency conversion
/// In a production app, this would integrate with a real currency API
class CurrencyService {
  // Mock exchange rates for demonstration
  static const Map<String, double> _mockExchangeRates = {
    'USD': 1.0,  // Base currency
    'EUR': 0.85,
    'GBP': 0.73,
    'CAD': 1.25,
    'AUD': 1.35,
    'JPY': 110.0,
  };

  /// Get exchange rate from base currency to target currency
  Future<double> getExchangeRate(String fromCurrency, String toCurrency) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (fromCurrency == toCurrency) return 1.0;
    
    final fromRate = _mockExchangeRates[fromCurrency] ?? 1.0;
    final toRate = _mockExchangeRates[toCurrency] ?? 1.0;
    
    // Convert from base currency to target currency
    return toRate / fromRate;
  }

  /// Get all supported currencies
  List<String> getSupportedCurrencies() {
    return _mockExchangeRates.keys.toList();
  }

  /// Format currency amount with proper symbol and formatting
  String formatCurrency(double amount, String currency) {
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'JPY': '¥',
    };

    final symbol = symbols[currency] ?? currency;
    
    // Format with 2 decimal places for most currencies, 0 for JPY
    final decimals = currency == 'JPY' ? 0 : 2;
    
    return '$symbol${amount.toStringAsFixed(decimals)}';
  }
}