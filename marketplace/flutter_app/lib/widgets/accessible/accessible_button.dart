import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// 🇩🇿 Accessible Button Widget with Semantics support
class AccessibleButton extends StatelessWidget {
  final String text;
  final String? semanticLabel;
  final String? semanticHint;
  final VoidCallback? onPressed;
  final ButtonType type;
  final bool isLoading;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final bool enabled;

  const AccessibleButton({
    super.key,
    required this.text,
    this.semanticLabel,
    this.semanticHint,
    this.onPressed,
    this.type = ButtonType.elevated,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.padding,
    this.width,
    this.height,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget button = _buildButton(context, theme);
    
    // Wrap with Semantics for accessibility
    return Semantics(
      label: semanticLabel ?? text,
      hint: semanticHint ?? _getDefaultHint(),
      button: true,
      enabled: enabled && !isLoading,
      onTap: enabled && !isLoading ? onPressed : null,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: button,
      ),
    );
  }

  Widget _buildButton(BuildContext context, ThemeData theme) {
    final content = _buildButtonContent();
    
    switch (type) {
      case ButtonType.elevated:
        return ElevatedButton(
          onPressed: enabled && !isLoading ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            padding: padding,
          ),
          child: content,
        );
      
      case ButtonType.outlined:
        return OutlinedButton(
          onPressed: enabled && !isLoading ? onPressed : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? backgroundColor,
            padding: padding,
            side: backgroundColor != null 
                ? BorderSide(color: backgroundColor!)
                : null,
          ),
          child: content,
        );
      
      case ButtonType.text:
        return TextButton(
          onPressed: enabled && !isLoading ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? backgroundColor,
            padding: padding,
          ),
          child: content,
        );
      
      case ButtonType.icon:
        return IconButton(
          onPressed: enabled && !isLoading ? onPressed : null,
          icon: icon ?? const Icon(Icons.touch_app),
          color: textColor ?? backgroundColor,
          tooltip: text,
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('جاري التحميل...'), // Loading in Arabic
        ],
      );
    }

    if (icon != null && type != ButtonType.icon) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }

  String _getDefaultHint() {
    if (isLoading) return 'جاري التحميل، يرجى الانتظار';
    if (!enabled) return 'الزر غير متاح حالياً';
    
    switch (type) {
      case ButtonType.elevated:
        return 'اضغط لتنفيذ الإجراء';
      case ButtonType.outlined:
        return 'اضغط للاختيار';
      case ButtonType.text:
        return 'رابط قابل للنقر';
      case ButtonType.icon:
        return 'زر أيقونة';
    }
  }
}

enum ButtonType {
  elevated,
  outlined,
  text,
  icon,
}

/// Accessible Icon Button with enhanced semantics
class AccessibleIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;
  final bool enabled;

  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.onPressed,
    this.color,
    this.size,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint ?? 'اضغط لتنفيذ $label',
      button: true,
      enabled: enabled,
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        color: color,
        iconSize: size,
        tooltip: label,
      ),
    );
  }
}

/// Accessible Floating Action Button
class AccessibleFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hint;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool mini;

  const AccessibleFAB({
    super.key,
    required this.icon,
    required this.label,
    this.hint,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      hint: hint ?? 'زر عائم: $label',
      button: true,
      onTap: onPressed,
      excludeSemantics: true,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        mini: mini,
        tooltip: label,
        child: Icon(icon),
      ),
    );
  }
}