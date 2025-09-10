import 'package:flutter/material.dart';
import 'dart:ui';

import '../config/app_constants.dart';
import 'dynamic_theme_manager.dart';

/// Comprehensive app theme with glassmorphic design system,
/// dynamic theming, and Material Design 3 support
class AppTheme {
  // Marketplace Color Palette - Based on Reference Images
  static const Color primaryGreen = Color(0xFF235347); // Forest Green
  static const Color secondaryGreen = Color(0xFF8EB69B); // Sage Green
  static const Color backgroundMint = Color(0x0ffdafde); // Mint Light - Note: This seems incomplete, using mint green
  static const Color backgroundMintLight = Color(0xFFE8F5E8); // Light mint background
  static const Color surfaceWhite = Color(0xFFFFFFFF); // White surfaces
  static const Color darkForest = Color(0xFF051F20); // Dark text
  static const Color successGreen = Color(0xFF4CAF50); // Success states
  static const Color warningOrange = Color(0xFFFF9800); // Badges, alerts
  
  // Color Schemes
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryGreen,
    onPrimary: Colors.white,
    secondary: secondaryGreen,
    onSecondary: darkForest,
    tertiary: successGreen,
    onTertiary: Colors.white,
    error: Color(0xFFE57373),
    onError: Colors.white,
    surface: surfaceWhite,
    onSurface: darkForest,
    background: backgroundMintLight,
    onBackground: darkForest,
    outline: Color(0xFFE0E0E0),
    surfaceVariant: Color(0xFFF8F9FA),
    onSurfaceVariant: Color(0xFF6C757D),
  );
  
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: secondaryGreen,
    onPrimary: darkForest,
    secondary: primaryGreen,
    onSecondary: Colors.white,
    tertiary: successGreen,
    onTertiary: darkForest,
    error: Color(0xFFEF5350),
    onError: Color(0xFFB71C1C),
    surface: Color(0xFF1E1E1E),
    onSurface: Color(0xFFE0E0E0),
    background: Color(0xFF121212),
    onBackground: Color(0xFFE0E0E0),
    outline: Color(0xFF424242),
    surfaceVariant: Color(0xFF2C2C2C),
    onSurfaceVariant: Color(0xFFBDBDBD),
  );
  
  // Glassmorphic color extensions
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBlack = Color(0x1A000000);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassShadow = Color(0x1A000000);
  /// Get light theme with glassmorphic design
  static ThemeData getLightTheme({SeasonalTheme? seasonalTheme}) {
    final colorScheme = seasonalTheme != null 
        ? _getSeasonalColorScheme(seasonalTheme, false)
        : _lightColorScheme;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.light,
      // Typography with multiple font families
      fontFamily: 'Poppins',
      textTheme: _createTextTheme(colorScheme, false),
      // AppBar with glassmorphic design
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
        actionsIconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),
      // Enhanced button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: AppConstants.buttonHeightM / 2 - 12,
            horizontal: AppConstants.spacingL,
          ),
          textStyle: const TextStyle(
            fontSize: AppConstants.textSizeL,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
          ),
        ),
      ),
      // Glassmorphic card theme
      cardTheme: CardThemeData(
        color: colorScheme.surface.withValues(alpha: 0.8),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          side: const BorderSide(
            color: glassBorder,
            width: 1,
          ),
        ),
        margin: const EdgeInsets.all(AppConstants.spacingS),
      ),
      // Enhanced input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingM,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: AppConstants.textSizeM,
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: AppConstants.textSizeM,
        ),
      ),
      // Glassmorphic bottom navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontSize: AppConstants.textSizeXS,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: AppConstants.textSizeXS,
          fontWeight: FontWeight.w400,
          fontFamily: 'Poppins',
        ),
      ),
      
      // Navigation bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.1),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: colorScheme.onSurfaceVariant),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colorScheme.primary,
              fontSize: AppConstants.textSizeXS,
              fontWeight: FontWeight.w600,
            );
          }
          return TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: AppConstants.textSizeXS,
            fontWeight: FontWeight.w400,
          );
        }),
      ),
      
      // Additional component themes
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primary.withOpacity(0.2),
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: AppConstants.textSizeS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.2),
        thickness: 0.5,
        space: 1,
      ),
      
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary.withOpacity(0.5);
          }
          return colorScheme.surfaceVariant;
        }),
      ),
      // Visual density and accessibility
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      // Extensions
      extensions: const [
        GlassmorphicThemeExtension(
          blurRadius: AppConstants.glassBlurRadius,
          opacity: AppConstants.glassOpacity,
          borderColor: glassBorder,
          shadowColor: glassShadow,
        ),
      ],
    );
  }
  
  /// Get dark theme with glassmorphic design
  static ThemeData getDarkTheme({SeasonalTheme? seasonalTheme}) {
    final colorScheme = seasonalTheme != null 
        ? _getSeasonalColorScheme(seasonalTheme, true)
        : _darkColorScheme;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      fontFamily: 'Poppins',
      textTheme: _createTextTheme(colorScheme, true),
      
      // Dark theme specific configurations
      scaffoldBackgroundColor: colorScheme.background,
      
      // AppBar for dark theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
      
      // Dark glassmorphic cards
      cardTheme: CardThemeData(
        color: colorScheme.surface.withOpacity(0.3),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          side: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      
      // Other theme components with dark variants...
      visualDensity: VisualDensity.adaptivePlatformDensity,
      
      extensions: [
        GlassmorphicThemeExtension(
          blurRadius: AppConstants.glassBlurRadius * 1.5,
          opacity: AppConstants.glassOpacity * 0.7,
          borderColor: Colors.white.withOpacity(0.1),
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      ],
    );
  }
  
  /// Create comprehensive text theme
  static TextTheme _createTextTheme(ColorScheme colorScheme, bool isDark) {
    final baseColor = colorScheme.onSurface;
    final secondaryColor = colorScheme.onSurfaceVariant;
    
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: baseColor,
        fontFamily: 'Poppins',
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: baseColor,
        fontFamily: 'Poppins',
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: AppConstants.textSizeXXL,
        fontWeight: FontWeight.w600,
        color: baseColor,
        fontFamily: 'Poppins',
      ),
      
      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: baseColor,
        fontFamily: 'Poppins',
      ),
      headlineMedium: TextStyle(
        fontSize: AppConstants.textSizeXXL,
        fontWeight: FontWeight.w600,
        color: baseColor,
        fontFamily: 'Poppins',
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        fontFamily: 'Poppins',
      ),
      
      // Title styles
      titleLarge: TextStyle(
        fontSize: AppConstants.textSizeXL,
        fontWeight: FontWeight.w600,
        color: baseColor,
        fontFamily: 'Poppins',
      ),
      titleMedium: TextStyle(
        fontSize: AppConstants.textSizeL,
        fontWeight: FontWeight.w500,
        color: baseColor,
        fontFamily: 'Poppins',
      ),
      titleSmall: TextStyle(
        fontSize: AppConstants.textSizeM,
        fontWeight: FontWeight.w500,
        color: baseColor,
        fontFamily: 'Poppins',
      ),
      
      // Body styles
      bodyLarge: TextStyle(
        fontSize: AppConstants.textSizeL,
        fontWeight: FontWeight.w400,
        color: baseColor,
        fontFamily: 'Inter',
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: AppConstants.textSizeM,
        fontWeight: FontWeight.w400,
        color: baseColor,
        fontFamily: 'Inter',
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontSize: AppConstants.textSizeS,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
        fontFamily: 'Inter',
        height: 1.3,
      ),
      
      // Label styles
      labelLarge: TextStyle(
        fontSize: AppConstants.textSizeM,
        fontWeight: FontWeight.w600,
        color: baseColor,
        fontFamily: 'Poppins',
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: AppConstants.textSizeS,
        fontWeight: FontWeight.w500,
        color: baseColor,
        fontFamily: 'Poppins',
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: AppConstants.textSizeXS,
        fontWeight: FontWeight.w500,
        color: secondaryColor,
        fontFamily: 'Poppins',
        letterSpacing: 0.5,
      ),
    );
  }
  
  /// Get seasonal color scheme
  static ColorScheme _getSeasonalColorScheme(SeasonalTheme theme, bool isDark) {
    final baseScheme = isDark ? _darkColorScheme : _lightColorScheme;
    
    // Get seasonal colors from DynamicThemeManager
    final seasonalColors = _getSeasonalColors(theme);
    
    return baseScheme.copyWith(
      primary: seasonalColors['primary'],
      secondary: seasonalColors['secondary'],
      tertiary: seasonalColors['tertiary'],
    );
  }
  
  /// Get seasonal colors map
  static Map<String, Color> _getSeasonalColors(SeasonalTheme theme) {
    switch (theme) {
      case SeasonalTheme.spring:
        return {
          'primary': const Color(0xFF4ECDC4),
          'secondary': const Color(0xFF44A08D),
          'tertiary': const Color(0xFF90EE90),
        };
      case SeasonalTheme.summer:
        return {
          'primary': const Color(0xFF00A8E8),
          'secondary': const Color(0xFFFFC857),
          'tertiary': const Color(0xFF0A2342),
        };
      case SeasonalTheme.autumn:
        return {
          'primary': const Color(0xFFFF6347),
          'secondary': const Color(0xFFFFD700),
          'tertiary': const Color(0xFF8B4513),
        };
      case SeasonalTheme.winter:
        return {
          'primary': const Color(0xFF3498DB),
          'secondary': const Color(0xFFECF0F1),
          'tertiary': const Color(0xFF2C3E50),
        };
      case SeasonalTheme.christmas:
        return {
          'primary': const Color(0xFF145A32),
          'secondary': const Color(0xFF922B21),
          'tertiary': const Color(0xFF0D1F1E),
        };
      case SeasonalTheme.halloween:
        return {
          'primary': const Color(0xFFFF6600),
          'secondary': const Color(0xFF800080),
          'tertiary': const Color(0xFF1C1C1C),
        };
      default:
        return {
          'primary': const Color(0xFF1565C0),
          'secondary': const Color(0xFF42A5F5),
          'tertiary': const Color(0xFF29B6F6),
        };
    }
  }

}

/// Glassmorphic theme extension for consistent glass effects
class GlassmorphicThemeExtension extends ThemeExtension<GlassmorphicThemeExtension> {
  final double blurRadius;
  final double opacity;
  final Color borderColor;
  final Color shadowColor;
  final double borderOpacity;
  
  const GlassmorphicThemeExtension({
    required this.blurRadius,
    required this.opacity,
    required this.borderColor,
    required this.shadowColor,
    this.borderOpacity = 0.2,
  });

  @override
  GlassmorphicThemeExtension copyWith({
    double? blurRadius,
    double? opacity,
    Color? borderColor,
    Color? shadowColor,
    double? borderOpacity,
  }) {
    return GlassmorphicThemeExtension(
      blurRadius: blurRadius ?? this.blurRadius,
      opacity: opacity ?? this.opacity,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      borderOpacity: borderOpacity ?? this.borderOpacity,
    );
  }

  @override
  GlassmorphicThemeExtension lerp(
    covariant ThemeExtension<GlassmorphicThemeExtension>? other,
    double t,
  ) {
    if (other is! GlassmorphicThemeExtension) {
      return this;
    }
    return GlassmorphicThemeExtension(
      blurRadius: lerpDouble(blurRadius, other.blurRadius, t) ?? blurRadius,
      opacity: lerpDouble(opacity, other.opacity, t) ?? opacity,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t) ?? shadowColor,
      borderOpacity: lerpDouble(borderOpacity, other.borderOpacity, t) ?? borderOpacity,
    );
  }

  /// Create glass decoration
  BoxDecoration createGlassDecoration({
    BorderRadius? borderRadius,
    List<BoxShadow>? customShadows,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.cardBorderRadius),
      border: Border.all(
        color: borderColor.withOpacity(borderOpacity),
        width: 1,
      ),
      boxShadow: customShadows ?? [
        BoxShadow(
          color: shadowColor,
          blurRadius: blurRadius,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Create backdrop filter for blur effect
  Widget createBackdropFilter({
    required Widget child,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(AppConstants.cardBorderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurRadius,
          sigmaY: blurRadius,
        ),
        child: child,
      ),
    );
  }
}
