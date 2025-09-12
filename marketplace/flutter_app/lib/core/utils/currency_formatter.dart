import 'package:intl/intl.dart';

/// 🇩🇿 Algeria Currency Formatter for DZD (Dinar Algérien)
class CurrencyFormatter {
  static const String _currencyCode = 'DZD';
  static const String _currencySymbol = 'د.ج';
  static const String _currencyName = 'دينار جزائري';
  static const String _currencyNameFr = 'Dinar Algérien';
  
  // Number formatters for different locales
  static final NumberFormat _arabicFormatter = NumberFormat.currency(
    locale: 'ar_DZ',
    symbol: _currencySymbol,
    decimalDigits: 2,
  );
  
  static final NumberFormat _frenchFormatter = NumberFormat.currency(
    locale: 'fr_DZ',
    symbol: _currencySymbol,
    decimalDigits: 2,
  );
  
  static final NumberFormat _englishFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: _currencySymbol,
    decimalDigits: 2,
  );

  /// Format amount to DZD currency string
  static String formatDZD(
    double amount, {
    String locale = 'ar',
    bool showSymbol = true,
    bool showDecimals = true,
    bool compact = false,
  }) {
    if (amount.isNaN || amount.isInfinite) {
      return showSymbol ? '0.00 $_currencySymbol' : '0.00';
    }

    if (compact && amount >= 1000000) {
      return _formatCompact(amount, locale, showSymbol);
    }

    final formatter = _getFormatter(locale);
    
    if (!showDecimals) {
      final noDecimalFormatter = NumberFormat.currency(
        locale: _getLocaleString(locale),
        symbol: showSymbol ? _currencySymbol : '',
        decimalDigits: 0,
      );
      return noDecimalFormatter.format(amount);
    }
    
    if (!showSymbol) {
      final noSymbolFormatter = NumberFormat.currency(
        locale: _getLocaleString(locale),
        symbol: '',
        decimalDigits: showDecimals ? 2 : 0,
      );
      return noSymbolFormatter.format(amount).trim();
    }
    
    return formatter.format(amount);
  }

  /// Format amount with Arabic numerals
  static String formatDZDArabic(double amount, {bool showSymbol = true}) {
    final formatted = formatDZD(amount, locale: 'ar', showSymbol: showSymbol);
    return _convertToArabicNumerals(formatted);
  }

  /// Format amount in compact form (1.2M, 3.5K, etc.)
  static String _formatCompact(double amount, String locale, bool showSymbol) {
    String suffix = '';
    double compactAmount = amount;
    
    if (amount >= 1000000000) {
      compactAmount = amount / 1000000000;
      suffix = locale == 'ar' ? 'مليار' : 'Md';
    } else if (amount >= 1000000) {
      compactAmount = amount / 1000000;
      suffix = locale == 'ar' ? 'مليون' : 'M';
    } else if (amount >= 1000) {
      compactAmount = amount / 1000;
      suffix = locale == 'ar' ? 'ألف' : 'K';
    }
    
    final formattedAmount = compactAmount.toStringAsFixed(1);
    final symbol = showSymbol ? ' $_currencySymbol' : '';
    
    if (locale == 'ar') {
      return '${_convertToArabicNumerals(formattedAmount)} $suffix$symbol';
    } else {
      return '$formattedAmount$suffix$symbol';
    }
  }

  /// Parse DZD string to double
  static double parseDZD(String dzdString) {
    try {
      // Remove currency symbols and spaces
      String cleaned = dzdString
          .replaceAll(_currencySymbol, '')
          .replaceAll('د.ج', '')
          .replaceAll('DZD', '')
          .replaceAll(' ', '')
          .replaceAll(',', '');
      
      // Convert Arabic numerals to Western numerals
      cleaned = _convertToWesternNumerals(cleaned);
      
      return double.parse(cleaned);
    } catch (e) {
      return 0.0;
    }
  }

  /// Validate DZD amount format
  static bool isValidDZDAmount(String amount) {
    try {
      final parsed = parseDZD(amount);
      return parsed >= 0 && parsed <= 999999999999; // Max reasonable amount
    } catch (e) {
      return false;
    }
  }

  /// Get currency info
  static Map<String, String> getCurrencyInfo(String locale) {
    switch (locale) {
      case 'ar':
        return {
          'code': _currencyCode,
          'symbol': _currencySymbol,
          'name': _currencyName,
        };
      case 'fr':
        return {
          'code': _currencyCode,
          'symbol': _currencySymbol,
          'name': _currencyNameFr,
        };
      default:
        return {
          'code': _currencyCode,
          'symbol': _currencySymbol,
          'name': 'Algerian Dinar',
        };
    }
  }

  /// Format price range
  static String formatPriceRange(double minPrice, double maxPrice, {String locale = 'ar'}) {
    final min = formatDZD(minPrice, locale: locale);
    final max = formatDZD(maxPrice, locale: locale);
    
    switch (locale) {
      case 'ar':
        return 'من $min إلى $max';
      case 'fr':
        return 'De $min à $max';
      default:
        return 'From $min to $max';
    }
  }

  /// Format discount percentage
  static String formatDiscount(double originalPrice, double discountedPrice, {String locale = 'ar'}) {
    final discountAmount = originalPrice - discountedPrice;
    final discountPercentage = (discountAmount / originalPrice * 100).round();
    
    final originalFormatted = formatDZD(originalPrice, locale: locale);
    final discountedFormatted = formatDZD(discountedPrice, locale: locale);
    
    switch (locale) {
      case 'ar':
        return 'خصم $discountPercentage% - من $originalFormatted إلى $discountedFormatted';
      case 'fr':
        return 'Remise $discountPercentage% - De $originalFormatted à $discountedFormatted';
      default:
        return '$discountPercentage% off - From $originalFormatted to $discountedFormatted';
    }
  }

  // Private helper methods

  static NumberFormat _getFormatter(String locale) {
    switch (locale) {
      case 'ar':
        return _arabicFormatter;
      case 'fr':
        return _frenchFormatter;
      default:
        return _englishFormatter;
    }
  }

  static String _getLocaleString(String locale) {
    switch (locale) {
      case 'ar':
        return 'ar_DZ';
      case 'fr':
        return 'fr_DZ';
      default:
        return 'en_US';
    }
  }

  static String _convertToArabicNumerals(String text) {
    const westernToArabic = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    
    String result = text;
    westernToArabic.forEach((western, arabic) {
      result = result.replaceAll(western, arabic);
    });
    
    return result;
  }

  static String _convertToWesternNumerals(String text) {
    const arabicToWestern = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };
    
    String result = text;
    arabicToWestern.forEach((arabic, western) {
      result = result.replaceAll(arabic, western);
    });
    
    return result;
  }

  /// Common DZD amounts for quick selection
  static List<double> getCommonAmounts() {
    return [
      100.0,    // 100 DZD
      500.0,    // 500 DZD
      1000.0,   // 1,000 DZD
      2000.0,   // 2,000 DZD
      5000.0,   // 5,000 DZD
      10000.0,  // 10,000 DZD
      20000.0,  // 20,000 DZD
      50000.0,  // 50,000 DZD
      100000.0, // 100,000 DZD
    ];
  }

  /// Get minimum and maximum reasonable amounts for validation
  static double get minAmount => 1.0;
  static double get maxAmount => 999999999.0;
  
  /// Check if amount is within reasonable bounds
  static bool isReasonableAmount(double amount) {
    return amount >= minAmount && amount <= maxAmount;
  }
}