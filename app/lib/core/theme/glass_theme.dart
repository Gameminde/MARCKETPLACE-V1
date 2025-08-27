import 'package:flutter/material.dart';
import 'dart:ui';

/// Design System 3D avec Glassmorphisme et Psychology Colors
/// Basé sur l'analyse des interfaces glassify-forge et recherche psychologique
class GlassTheme {
  // ========================================
  // PSYCHOLOGY COLORS (Impact Scientifique)
  // ========================================
  
  /// Palette Luxury Experience (75% créativité trigger)
  static const Color luxuryPrimary = Color(0xFF7C3AED);
  
  /// Confiance et sécurité (90% confiance trigger)
  static const Color trustSecondary = Color(0xFF3B82F6);
  
  /// Action et conversion (85% action trigger)
  static const Color actionAccent = Color(0xFF10B981);
  
  /// Énergie et découverte (80% énergie trigger)
  static const Color energyWarning = Color(0xFFF59E0B);
  
  /// Urgence et promotions (85% urgence trigger)
  static const Color urgencyDanger = Color(0xFFEF4444);

  // ========================================
  // GLASSMORPHISME VARIABLES
  // ========================================
  
  /// Blur principal pour effets glassmorphisme
  static const double primaryBlur = 20.0;
  
  /// Blur secondaire pour éléments subtils
  static const double secondaryBlur = 10.0;
  
  /// Opacité des bordures glass
  static const double borderOpacity = 0.2;
  
  /// Opacité des arrière-plans glass
  static const double backgroundOpacity = 0.1;
  
  /// Intensité des ombres colorées
  static const double shadowIntensity = 0.3;

  // ========================================
  // PALETTES PSYCHOLOGIQUES
  // ========================================
  
  /// Palette complète pour effets luxury
  static const List<Color> luxuryPalette = [
    luxuryPrimary,
    Color(0xFF8B5CF6),
    Color(0xFFA78BFA),
    Color(0xFFC4B5FD),
  ];
  
  /// Palette pour effets de confiance
  static const List<Color> trustPalette = [
    trustSecondary,
    Color(0xFF60A5FA),
    Color(0xFF93C5FD),
    Color(0xFFDBEAFE),
  ];

  // ========================================
  // ANIMATIONS TIMING (Dopamine Triggers)
  // ========================================
  
  /// Feedback instantané (100ms)
  static const Duration instantFeedback = Duration(milliseconds: 100);
  
  /// Validation d'étape (300ms)
  static const Duration progressReward = Duration(milliseconds: 300);
  
  /// Accomplissement majeur (600ms)
  static const Duration achievementBurst = Duration(milliseconds: 600);
  
  /// Découverte guidée (200ms)
  static const Duration explorationHint = Duration(milliseconds: 200);

  // ========================================
  // COURBES D'ANIMATION ORGANIQUES
  // ========================================
  
  /// Courbe signature pour interactions premium
  static const Curve easeSignature = Cubic(0.4, 0.0, 0.2, 1);
  
  /// Courbe bounce pour effets ludiques
  static const Curve easeBounce = Cubic(0.68, -0.55, 0.265, 1.55);
  
  /// Courbe back pour effets élastiques
  static const Curve easeBack = Cubic(0.175, 0.885, 0.32, 1.275);
  
  /// Courbe elastic pour micro-interactions
  static const Curve easeElastic = Cubic(0.25, 0.46, 0.45, 0.94);

  // ========================================
  // FACTORY METHODS
  // ========================================
  
  /// Crée une décoration glassmorphisme standard
  static BoxDecoration createGlassDecoration({
    Color? color,
    double? blur,
    double? borderOpacity,
    double? backgroundOpacity,
    List<BoxShadow>? shadows,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: (color ?? Colors.white).withOpacity(backgroundOpacity ?? GlassTheme.backgroundOpacity),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(borderOpacity ?? GlassTheme.borderOpacity),
        width: 1,
      ),
      boxShadow: shadows ?? [
        BoxShadow(
          color: (color ?? luxuryPrimary).withOpacity(shadowIntensity),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
  
  /// Crée un BackdropFilter pour glassmorphisme
  static Widget createGlassFilter({
    required Widget child,
    double? blur,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blur ?? primaryBlur,
          sigmaY: blur ?? primaryBlur,
        ),
        child: child,
      ),
    );
  }
  
  /// Obtient la couleur psychologique selon la catégorie
  static Color getColorByCategory(ProductCategory category) {
    switch (category) {
      case ProductCategory.luxury:
        return luxuryPrimary;
      case ProductCategory.tech:
        return trustSecondary;
      case ProductCategory.fashion:
        return energyWarning;
      case ProductCategory.urgent:
        return urgencyDanger;
      case ProductCategory.action:
        return actionAccent;
      default:
        return luxuryPrimary;
    }
  }
  
  /// Crée un gradient psychologique
  static LinearGradient createPsychologyGradient(ProductCategory category) {
    final baseColor = getColorByCategory(category);
    return LinearGradient(
      colors: [
        baseColor,
        baseColor.withOpacity(0.8),
        baseColor.withOpacity(0.6),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // ========================================
  // THEME DATA COMPLET
  // ========================================
  
  /// Thème complet avec glassmorphisme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: luxuryPrimary,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  /// Thème sombre avec glassmorphisme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: luxuryPrimary,
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Énumération des catégories psychologiques
enum ProductCategory {
  luxury,
  tech,
  fashion,
  urgent,
  action,
  neutral,
}

/// Extension pour faciliter l'utilisation des couleurs
extension ColorPsychology on Color {
  /// Crée une version glassmorphisme de la couleur
  Color get glass => withOpacity(GlassTheme.backgroundOpacity);
  
  /// Crée une version border de la couleur
  Color get border => withOpacity(GlassTheme.borderOpacity);
  
  /// Crée une version shadow de la couleur
  Color get shadow => withOpacity(GlassTheme.shadowIntensity);
}