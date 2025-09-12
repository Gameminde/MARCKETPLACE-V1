import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🇩🇿 Algeria Official Theme with RTL Support
class AlgeriaTheme {
  // Official Algeria Color Palette
  static const Color algeriaGreen = Color(0xFF051F20);
  static const Color algeriaGreenLight = Color(0xFF0A3D40);
  static const Color algeriaGreenMedium = Color(0xFF1A5D60);
  static const Color algeriaGreenAccent = Color(0xFFDAFDE2);
  
  // Additional Algeria Colors
  static const Color algeriaRed = Color(0xFFD32F2F);
  static const Color algeriaWhite = Color(0xFFFFFFFF);
  static const Color algeriaGold = Color(0xFFFFD700);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF051F20);
  static const Color textSecondary = Color(0xFF0A3D40);
  static const Color textLight = Color(0xFF666666);
  static const Color textOnDark = Color(0xFFFFFFFF);
  
  // Background Colors
  static const Color backgroundPrimary = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color backgroundAccent = Color(0xFFDAFDE2);
  
  // Status Colors
  static const Color success = Color(0xFF1A5D60);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF2196F3);

  /// Get Algeria Light Theme
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: algeriaGreen,
        primaryContainer: algeriaGreenLight,
        secondary: algeriaGreenMedium,
        secondaryContainer: algeriaGreenAccent,
        surface: backgroundPrimary,
        surfaceContainerHighest: backgroundSecondary,
        onPrimary: algeriaWhite,
        onSecondary: algeriaWhite,
        onSurface: textPrimary,
        error: error,
        onError: algeriaWhite,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: algeriaGreen,
        foregroundColor: algeriaWhite,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: algeriaWhite,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
      ),
      
      // Text Theme with Arabic Support
      textTheme: _getTextTheme(),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: algeriaGreen,
          foregroundColor: algeriaWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: algeriaGreen,
          side: const BorderSide(color: algeriaGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: algeriaGreen,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: algeriaGreenLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: algeriaGreenLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: algeriaGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(
          color: textSecondary,
          fontFamily: 'Cairo',
        ),
        hintStyle: const TextStyle(
          color: textLight,
          fontFamily: 'Cairo',
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: backgroundPrimary,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundPrimary,
        selectedItemColor: algeriaGreen,
        unselectedItemColor: textLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: algeriaGreen,
        foregroundColor: algeriaWhite,
        elevation: 4,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: backgroundSecondary,
        selectedColor: algeriaGreenAccent,
        labelStyle: const TextStyle(
          color: textPrimary,
          fontFamily: 'Cairo',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: algeriaGreen,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: algeriaGreenLight,
        thickness: 1,
      ),
      
      // Font Family
      fontFamily: 'Cairo',
    );
  }

  /// Get Algeria Dark Theme
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: algeriaGreenAccent,
        primaryContainer: algeriaGreenMedium,
        secondary: algeriaGreenLight,
        secondaryContainer: algeriaGreen,
        surface: Color(0xFF121212),
        surfaceContainerHighest: Color(0xFF1E1E1E),
        onPrimary: algeriaGreen,
        onSecondary: algeriaWhite,
        onSurface: algeriaWhite,
        error: Color(0xFFFF6B6B),
        onError: algeriaWhite,
      ),
      
      fontFamily: 'Cairo',
    );
  }

  /// Get Text Theme with Arabic Support
  static TextTheme _getTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.2,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.3,
      ),
      headlineLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.3,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.3,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.4,
      ),
      titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.4,
      ),
      titleMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        fontFamily: 'Cairo',
        height: 1.4,
      ),
      titleSmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        fontFamily: 'Cairo',
        height: 1.4,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: textLight,
        fontFamily: 'Cairo',
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
        fontFamily: 'Cairo',
        height: 1.4,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        fontFamily: 'Cairo',
        height: 1.4,
      ),
      labelSmall: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: textLight,
        fontFamily: 'Cairo',
        height: 1.4,
      ),
    );
  }

  /// Get RTL Text Direction based on locale
  static TextDirection getTextDirection(String languageCode) {
    return languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }

  /// Get Algeria-specific gradients
  static LinearGradient get algeriaGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [algeriaGreen, algeriaGreenMedium],
  );

  static LinearGradient get algeriaAccentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [algeriaGreenAccent, algeriaGreenLight],
  );

  /// Get status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'completed':
      case 'approved':
        return success;
      case 'warning':
      case 'pending':
        return warning;
      case 'error':
      case 'failed':
      case 'rejected':
        return error;
      case 'info':
      case 'processing':
        return info;
      default:
        return textLight;
    }
  }
}