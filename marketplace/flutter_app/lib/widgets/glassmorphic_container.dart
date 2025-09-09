import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/config/app_constants.dart';
import '../core/theme/app_theme.dart';

/// Comprehensive glassmorphic container widget with advanced effects,
/// multiple styles, and theme integration
class GlassmorphicContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double? blur;
  final double? opacity;
  final Color? borderColor;
  final double? borderWidth;
  final List<BoxShadow>? boxShadow;
  final GlassmorphicStyle style;
  final bool enableBorder;
  final bool enableShadow;
  final AlignmentGeometry? alignment;
  final Gradient? gradient;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool animateOnTap;
  final Duration animationDuration;
  
  const GlassmorphicContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur,
    this.opacity,
    this.borderColor,
    this.borderWidth,
    this.boxShadow,
    this.style = GlassmorphicStyle.standard,
    this.enableBorder = true,
    this.enableShadow = true,
    this.alignment,
    this.gradient,
    this.backgroundColor,
    this.onTap,
    this.animateOnTap = false,
    this.animationDuration = const Duration(milliseconds: 150),
  });

  /// Factory constructor for card style
  factory GlassmorphicContainer.card({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    VoidCallback? onTap,
  }) {
    return GlassmorphicContainer(
      key: key,
      style: GlassmorphicStyle.card,
      padding: padding ?? const EdgeInsets.all(AppConstants.spacingM),
      margin: margin,
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      onTap: onTap,
      animateOnTap: onTap != null,
      child: child,
    );
  }

  /// Factory constructor for dialog style
  factory GlassmorphicContainer.dialog({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassmorphicContainer(
      key: key,
      style: GlassmorphicStyle.dialog,
      padding: padding ?? const EdgeInsets.all(AppConstants.spacingL),
      borderRadius: BorderRadius.circular(AppConstants.dialogBorderRadius),
      child: child,
    );
  }

  /// Factory constructor for button style
  factory GlassmorphicContainer.button({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassmorphicContainer(
      key: key,
      style: GlassmorphicStyle.button,
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingL,
        vertical: AppConstants.spacingM,
      ),
      borderRadius: BorderRadius.circular(AppConstants.buttonBorderRadius),
      onTap: onTap,
      animateOnTap: true,
      child: child,
    );
  }

  /// Factory constructor for navigation bar style
  factory GlassmorphicContainer.navigation({
    Key? key,
    required Widget child,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassmorphicContainer(
      key: key,
      style: GlassmorphicStyle.navigation,
      padding: padding,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppConstants.navBarBorderRadius),
        topRight: Radius.circular(AppConstants.navBarBorderRadius),
      ),
      child: child,
    );
  }

  /// Factory constructor for chip/tag style
  factory GlassmorphicContainer.chip({
    Key? key,
    required Widget child,
    required VoidCallback onTap,
    bool isSelected = false,
    EdgeInsetsGeometry? padding,
  }) {
    return GlassmorphicContainer(
      key: key,
      style: GlassmorphicStyle.chip,
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      borderRadius: BorderRadius.circular(AppConstants.chipBorderRadius),
      onTap: onTap,
      animateOnTap: true,
      backgroundColor: isSelected ? null : null, // Will be handled by style
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassExtension = theme.extension<GlassmorphicThemeExtension>();
    final isDark = theme.brightness == Brightness.dark;
    
    // Get style-specific properties
    final styleProps = _getStyleProperties(context, isDark);
    
    // Final values with fallbacks
    final finalBlur = blur ?? styleProps['blur'] ?? glassExtension?.blurRadius ?? AppConstants.glassBlurRadius;
    final finalOpacity = opacity ?? styleProps['opacity'] ?? glassExtension?.opacity ?? AppConstants.glassOpacity;
    final finalBorderRadius = borderRadius ?? styleProps['borderRadius'] ?? BorderRadius.circular(AppConstants.cardBorderRadius);
    final finalBorderColor = borderColor ?? styleProps['borderColor'] ?? glassExtension?.borderColor ?? Colors.white.withOpacity(0.2);
    final finalBorderWidth = borderWidth ?? styleProps['borderWidth'] ?? 1.0;
    final finalBackgroundColor = backgroundColor ?? styleProps['backgroundColor'] ?? Colors.white.withOpacity(finalOpacity);
    final finalBoxShadow = boxShadow ?? styleProps['boxShadow'] ?? _getDefaultShadow(isDark);
    
    Widget container = Container(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      alignment: alignment,
      decoration: BoxDecoration(
        color: gradient != null ? null : finalBackgroundColor,
        gradient: gradient,
        borderRadius: finalBorderRadius,
        border: enableBorder ? Border.all(
          color: finalBorderColor,
          width: finalBorderWidth,
        ) : null,
        boxShadow: enableShadow ? finalBoxShadow : null,
      ),
      child: child,
    );

    // Wrap with backdrop filter for blur effect
    container = ClipRRect(
      borderRadius: finalBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: finalBlur,
          sigmaY: finalBlur,
        ),
        child: container,
      ),
    );

    // Add tap functionality if provided
    if (onTap != null) {
      container = animateOnTap
          ? _AnimatedTapContainer(
              onTap: onTap!,
              duration: animationDuration,
              child: container,
            )
          : GestureDetector(
              onTap: onTap,
              child: container,
            );
    }

    return container;
  }

  /// Get style-specific properties
  Map<String, dynamic> _getStyleProperties(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    
    switch (style) {
      case GlassmorphicStyle.card:
        return {
          'blur': AppConstants.glassBlurRadius,
          'opacity': isDark ? 0.1 : 0.15,
          'borderRadius': BorderRadius.circular(AppConstants.cardBorderRadius),
          'borderColor': isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
          'borderWidth': 1.0,
          'backgroundColor': isDark 
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.2),
          'boxShadow': [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        };
        
      case GlassmorphicStyle.dialog:
        return {
          'blur': AppConstants.glassBlurRadius * 1.5,
          'opacity': isDark ? 0.15 : 0.25,
          'borderRadius': BorderRadius.circular(AppConstants.dialogBorderRadius),
          'borderColor': isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.3),
          'borderWidth': 1.5,
          'backgroundColor': isDark 
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.3),
          'boxShadow': [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.15),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        };
        
      case GlassmorphicStyle.button:
        return {
          'blur': AppConstants.glassBlurRadius * 0.8,
          'opacity': isDark ? 0.12 : 0.18,
          'borderRadius': BorderRadius.circular(AppConstants.buttonBorderRadius),
          'borderColor': theme.colorScheme.primary.withOpacity(0.3),
          'borderWidth': 1.0,
          'backgroundColor': theme.colorScheme.primary.withOpacity(0.1),
          'boxShadow': [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        };
        
      case GlassmorphicStyle.navigation:
        return {
          'blur': AppConstants.glassBlurRadius * 1.2,
          'opacity': isDark ? 0.2 : 0.3,
          'borderRadius': const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.navBarBorderRadius),
            topRight: Radius.circular(AppConstants.navBarBorderRadius),
          ),
          'borderColor': isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
          'borderWidth': 1.0,
          'backgroundColor': isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.white.withOpacity(0.4),
          'boxShadow': [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.1),
              blurRadius: 25,
              offset: const Offset(0, -5),
            ),
          ],
        };
        
      case GlassmorphicStyle.chip:
        return {
          'blur': AppConstants.glassBlurRadius * 0.6,
          'opacity': isDark ? 0.08 : 0.12,
          'borderRadius': BorderRadius.circular(AppConstants.chipBorderRadius),
          'borderColor': theme.colorScheme.outline.withOpacity(0.3),
          'borderWidth': 1.0,
          'backgroundColor': isDark 
              ? Colors.white.withOpacity(0.03)
              : Colors.white.withOpacity(0.15),
          'boxShadow': [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        };
        
      case GlassmorphicStyle.standard:
      default:
        return {
          'blur': AppConstants.glassBlurRadius,
          'opacity': isDark ? 0.1 : 0.2,
          'borderRadius': BorderRadius.circular(AppConstants.cardBorderRadius),
          'borderColor': isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.2),
          'borderWidth': 1.0,
          'backgroundColor': isDark 
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.2),
          'boxShadow': _getDefaultShadow(isDark),
        };
    }
  }

  /// Get default shadow
  List<BoxShadow> _getDefaultShadow(bool isDark) {
    return [
      BoxShadow(
        color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ];
  }
}

/// Glassmorphic container styles
enum GlassmorphicStyle {
  standard,
  card,
  dialog,
  button,
  navigation,
  chip,
}

/// Animated tap container for glass buttons
class _AnimatedTapContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final Duration duration;
  
  const _AnimatedTapContainer({
    required this.child,
    required this.onTap,
    required this.duration,
  });
  
  @override
  State<_AnimatedTapContainer> createState() => _AnimatedTapContainerState();
}

class _AnimatedTapContainerState extends State<_AnimatedTapContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }
  
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }
  
  void _onTapCancel() {
    _controller.reverse();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
