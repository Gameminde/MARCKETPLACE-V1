import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math' as math;

import '../config/app_constants.dart';

/// Seasonal and contextual themes
enum SeasonalTheme { 
  defaultBlue, 
  spring, 
  summer, 
  autumn, 
  winter,
  christmas, 
  halloween,
  valentine,
  ramadan, 
  promo,
  midnight,
  ocean,
  sunset,
  forest
}

/// Theme modes
enum ThemeMode { light, dark, system }

/// Glassmorphic effects configuration
class GlassmorphicConfig {
  final double blurRadius;
  final double opacity;
  final double borderOpacity;
  final Color? borderColor;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;

  const GlassmorphicConfig({
    this.blurRadius = AppConstants.glassBlurRadius,
    this.opacity = AppConstants.glassOpacity,
    this.borderOpacity = AppConstants.glassBorderOpacity,
    this.borderColor,
    this.borderRadius,
    this.shadows,
  });

  GlassmorphicConfig copyWith({
    double? blurRadius,
    double? opacity,
    double? borderOpacity,
    Color? borderColor,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return GlassmorphicConfig(
      blurRadius: blurRadius ?? this.blurRadius,
      opacity: opacity ?? this.opacity,
      borderOpacity: borderOpacity ?? this.borderOpacity,
      borderColor: borderColor ?? this.borderColor,
      borderRadius: borderRadius ?? this.borderRadius,
      shadows: shadows ?? this.shadows,
    );
  }
}

/// Advanced Dynamic Theme Manager with seasonal themes, glassmorphic design,
/// custom color schemes, and persistent user preferences
class DynamicThemeManager extends ChangeNotifier {
  SeasonalTheme _currentSeasonal = SeasonalTheme.defaultBlue;
  ThemeMode _themeMode = ThemeMode.system;
  Map<String, Color> _customColors = {};
  GlassmorphicConfig _glassConfig = const GlassmorphicConfig();
  bool _isAutoSeasonalEnabled = true;
  bool _isPersistenceEnabled = true;
  String? _userId;
  DateTime? _lastThemeChange;
  
  // Animation properties
  bool _isTransitioning = false;
  Duration _transitionDuration = AppConstants.themeTransitionDuration;
  
  // Getters
  SeasonalTheme get currentSeasonal => _currentSeasonal;
  ThemeMode get themeMode => _themeMode;
  Map<String, Color> get customColors => Map.unmodifiable(_customColors);
  GlassmorphicConfig get glassConfig => _glassConfig;
  bool get isAutoSeasonalEnabled => _isAutoSeasonalEnabled;
  bool get isPersistenceEnabled => _isPersistenceEnabled;
  String? get userId => _userId;
  DateTime? get lastThemeChange => _lastThemeChange;
  bool get isTransitioning => _isTransitioning;
  Duration get transitionDuration => _transitionDuration;
  
  /// Check if current theme is dark based on theme mode and system settings
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  /// Set seasonal theme with animation and persistence
  Future<void> setSeasonalTheme(SeasonalTheme theme, {bool animate = true}) async {
    if (_currentSeasonal == theme) return;
    
    _isTransitioning = animate;
    notifyListeners();
    
    if (animate) {
      await Future.delayed(Duration(milliseconds: _transitionDuration.inMilliseconds ~/ 2));
    }
    
    _currentSeasonal = theme;
    _lastThemeChange = DateTime.now();
    
    if (_isPersistenceEnabled) {
      await _saveThemePreferences();
    }
    
    if (animate) {
      await Future.delayed(Duration(milliseconds: _transitionDuration.inMilliseconds ~/ 2));
      _isTransitioning = false;
    }
    
    notifyListeners();
  }
  
  /// Set theme mode (light/dark/system)
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    _lastThemeChange = DateTime.now();
    
    if (_isPersistenceEnabled) {
      await _saveThemePreferences();
    }
    
    notifyListeners();
  }
  
  /// Update custom colors
  Future<void> updateCustomColors(Map<String, Color> colors) async {
    _customColors = Map.from(colors);
    _lastThemeChange = DateTime.now();
    
    if (_isPersistenceEnabled) {
      await _saveThemePreferences();
    }
    
    notifyListeners();
  }
  
  /// Add or update a single custom color
  Future<void> setCustomColor(String key, Color color) async {
    _customColors[key] = color;
    _lastThemeChange = DateTime.now();
    
    if (_isPersistenceEnabled) {
      await _saveThemePreferences();
    }
    
    notifyListeners();
  }
  
  /// Remove a custom color
  Future<void> removeCustomColor(String key) async {
    _customColors.remove(key);
    _lastThemeChange = DateTime.now();
    
    if (_isPersistenceEnabled) {
      await _saveThemePreferences();
    }
    
    notifyListeners();
  }
  
  /// Update glassmorphic configuration
  void updateGlassmorphicConfig(GlassmorphicConfig config) {
    _glassConfig = config;
    notifyListeners();
  }
  
  /// Enable/disable automatic seasonal theme changes
  Future<void> setAutoSeasonalEnabled(bool enabled) async {
    _isAutoSeasonalEnabled = enabled;
    
    if (enabled) {
      await _applyAutoSeasonalTheme();
    }
    
    if (_isPersistenceEnabled) {
      await _saveThemePreferences();
    }
    
    notifyListeners();
  }
  
  /// Set user ID for personalized themes
  void setUserId(String? userId) {
    _userId = userId;
  }
  
  /// Set transition duration
  void setTransitionDuration(Duration duration) {
    _transitionDuration = duration;
  }

  /// Get comprehensive gradient for seasonal theme
  LinearGradient getGradientFor(SeasonalTheme theme, {bool? isDark}) {
    final useDark = isDark ?? this.isDarkMode;
    final baseColors = _getBaseColorsFor(theme);
    final adjustedColors = useDark 
        ? baseColors.map((c) => _darkenColor(c, 0.3)).toList()
        : baseColors.map((c) => _lightenColor(c, 0.1)).toList();
    
    final alignments = _getGradientAlignments(theme);
    
    return LinearGradient(
      colors: adjustedColors,
      begin: alignments['begin'] as AlignmentGeometry,
      end: alignments['end'] as AlignmentGeometry,
      stops: _getGradientStops(adjustedColors.length),
    );
  }
  
  /// Get base colors for theme
  List<Color> _getBaseColorsFor(SeasonalTheme theme) {
    switch (theme) {
      case SeasonalTheme.spring:
        return [const Color(0xFF4ECDC4), const Color(0xFF44A08D), const Color(0xFF90EE90)];
      case SeasonalTheme.summer:
        return [const Color(0xFF0A2342), const Color(0xFF00A8E8), const Color(0xFFFFC857)];
      case SeasonalTheme.autumn:
        return [const Color(0xFF8B4513), const Color(0xFFFF6347), const Color(0xFFFFD700)];
      case SeasonalTheme.winter:
        return [const Color(0xFF2C3E50), const Color(0xFF3498DB), const Color(0xFFECF0F1)];
      case SeasonalTheme.christmas:
        return [const Color(0xFF0D1F1E), const Color(0xFF145A32), const Color(0xFF922B21)];
      case SeasonalTheme.halloween:
        return [const Color(0xFF1C1C1C), const Color(0xFFFF6600), const Color(0xFF800080)];
      case SeasonalTheme.valentine:
        return [const Color(0xFF8E2DE2), const Color(0xFF4A00E0), const Color(0xFFFF6B9D)];
      case SeasonalTheme.ramadan:
        return [const Color(0xFF0B122B), const Color(0xFF1B2C56), const Color(0xFF8E44AD)];
      case SeasonalTheme.promo:
        return [const Color(0xFF1B1F3B), const Color(0xFF6C5CE7), const Color(0xFFFF6B81)];
      case SeasonalTheme.midnight:
        return [const Color(0xFF0C0C0C), const Color(0xFF1A1A2E), const Color(0xFF16213E)];
      case SeasonalTheme.ocean:
        return [const Color(0xFF667eea), const Color(0xFF764ba2), const Color(0xFF89CFF0)];
      case SeasonalTheme.sunset:
        return [const Color(0xFFFF512F), const Color(0xFFDD2476), const Color(0xFFF953C6)];
      case SeasonalTheme.forest:
        return [const Color(0xFF134E5E), const Color(0xFF71B280), const Color(0xFF228B22)];
      case SeasonalTheme.defaultBlue:
      default:
        return [const Color(0xFF0F2027), const Color(0xFF203A43), const Color(0xFF2C5364)];
    }
  }
  
  /// Get gradient alignments for theme
  Map<String, AlignmentGeometry> _getGradientAlignments(SeasonalTheme theme) {
    switch (theme) {
      case SeasonalTheme.christmas:
      case SeasonalTheme.promo:
        return {'begin': Alignment.topCenter, 'end': Alignment.bottomCenter};
      case SeasonalTheme.summer:
      case SeasonalTheme.autumn:
      case SeasonalTheme.defaultBlue:
        return {'begin': Alignment.topLeft, 'end': Alignment.bottomRight};
      default:
        return {'begin': Alignment.topLeft, 'end': Alignment.bottomRight};
    }
  }
  
  /// Get gradient stops
  List<double> _getGradientStops(int colorCount) {
    if (colorCount <= 1) return [0.0];
    return List.generate(colorCount, (index) => index / (colorCount - 1));
  }

  /// Enhanced background container with glassmorphic effects
  Widget backgroundContainer({
    required Widget child,
    SeasonalTheme? theme,
    GlassmorphicConfig? glassConfig,
    bool? useDarkMode,
  }) {
    final activeTheme = theme ?? _currentSeasonal;
    final activeGlassConfig = glassConfig ?? _glassConfig;
    final gradient = getGradientFor(activeTheme, isDark: useDarkMode);
    
    return AnimatedContainer(
      duration: _isTransitioning ? _transitionDuration : Duration.zero,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: gradient,
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: activeGlassConfig.blurRadius,
          sigmaY: activeGlassConfig.blurRadius,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(activeGlassConfig.opacity),
            borderRadius: activeGlassConfig.borderRadius ?? BorderRadius.circular(AppConstants.borderRadius),
            border: activeGlassConfig.borderColor != null
                ? Border.all(
                    color: activeGlassConfig.borderColor!.withOpacity(activeGlassConfig.borderOpacity),
                  )
                : null,
            boxShadow: activeGlassConfig.shadows,
          ),
          child: child,
        ),
      ),
    );
  }
  
  /// Create glassmorphic container widget
  Widget createGlassmorphicContainer({
    required Widget child,
    GlassmorphicConfig? config,
    double? width,
    double? height,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
  }) {
    final activeConfig = config ?? _glassConfig;
    
    return Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(activeConfig.opacity),
        borderRadius: activeConfig.borderRadius ?? BorderRadius.circular(AppConstants.borderRadius),
        border: activeConfig.borderColor != null
            ? Border.all(
                color: activeConfig.borderColor!.withOpacity(activeConfig.borderOpacity),
              )
            : null,
        boxShadow: activeConfig.shadows ?? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: activeConfig.borderRadius ?? BorderRadius.circular(AppConstants.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: activeConfig.blurRadius,
            sigmaY: activeConfig.blurRadius,
          ),
          child: child,
        ),
      ),
    );
  }
  
  /// Color manipulation helpers
  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }
  
  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }
  
  /// Get current primary color based on theme
  Color get primaryColor {
    final colors = _getBaseColorsFor(_currentSeasonal);
    return colors.isNotEmpty ? colors.first : Colors.blue;
  }
  
  /// Auto-apply seasonal theme based on current date
  Future<void> _applyAutoSeasonalTheme() async {
    if (!_isAutoSeasonalEnabled) return;
    
    final now = DateTime.now();
    SeasonalTheme autoTheme;
    
    if (now.month == 12) {
      autoTheme = SeasonalTheme.christmas;
    } else if (now.month >= 6 && now.month <= 8) {
      autoTheme = SeasonalTheme.summer;
    } else if (now.month >= 3 && now.month <= 5) {
      autoTheme = SeasonalTheme.spring;
    } else if (now.month >= 9 && now.month <= 11) {
      autoTheme = SeasonalTheme.autumn;
    } else {
      autoTheme = SeasonalTheme.winter;
    }
    
    if (autoTheme != _currentSeasonal) {
      await setSeasonalTheme(autoTheme, animate: true);
    }
  }
  
  /// Load theme preferences from storage
  Future<void> loadThemePreferences() async {
    if (!_isPersistenceEnabled) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final seasonalIndex = prefs.getInt('seasonal_theme_index');
      if (seasonalIndex != null && seasonalIndex < SeasonalTheme.values.length) {
        _currentSeasonal = SeasonalTheme.values[seasonalIndex];
      }
      
      _isAutoSeasonalEnabled = prefs.getBool('auto_seasonal_enabled') ?? true;
      
      if (_isAutoSeasonalEnabled) {
        await _applyAutoSeasonalTheme();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }
  
  /// Save theme preferences to storage
  Future<void> _saveThemePreferences() async {
    if (!_isPersistenceEnabled) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('seasonal_theme_index', _currentSeasonal.index);
      await prefs.setBool('auto_seasonal_enabled', _isAutoSeasonalEnabled);
    } catch (e) {
      debugPrint('Error saving theme preferences: $e');
    }
  }
}
