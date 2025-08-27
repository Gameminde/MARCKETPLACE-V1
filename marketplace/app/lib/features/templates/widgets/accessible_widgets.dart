import 'package:flutter/material.dart';
import '../services/accessibility_service.dart';

/// 🎯 Collection de Widgets Accessibles - WCAG 2.1 AA
/// 
/// Cette collection fournit des widgets prêts à l'emploi qui respectent
/// automatiquement les standards d'accessibilité les plus élevés.
class AccessibleWidgets {
  static final AccessibilityService _accessibilityService = AccessibilityService();

  /// Bouton accessible avec support complet des lecteurs d'écran
  static Widget button({
    required String label,
    String? hint,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
    bool isEnabled = true,
    Widget? icon,
    ButtonStyle? style,
    Size? minimumSize,
    EdgeInsetsGeometry? padding,
    Widget? child,
  }) {
    final button = ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      onLongPress: onLongPress,
      style: style?.copyWith(
        minimumSize: MaterialStateProperty.all(minimumSize ?? const Size(44, 44)),
        padding: MaterialStateProperty.all(padding ?? const EdgeInsets.all(12)),
      ),
      child: child ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );

    return _accessibilityService.makeAccessibleButton(
      button,
      label: label,
      hint: hint,
      onPressed: onPressed,
      onLongPress: onLongPress,
      isEnabled: isEnabled,
    );
  }

  /// Bouton de texte accessible
  static Widget textButton({
    required String label,
    String? hint,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
    bool isEnabled = true,
    Widget? icon,
    ButtonStyle? style,
    Widget? child,
  }) {
    final button = TextButton(
      onPressed: isEnabled ? onPressed : null,
      onLongPress: onLongPress,
      style: style?.copyWith(
        minimumSize: MaterialStateProperty.all(const Size(44, 44)),
        padding: MaterialStateProperty.all(const EdgeInsets.all(12)),
      ),
      child: child ?? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ),
    );

    return _accessibilityService.makeAccessibleButton(
      button,
      label: label,
      hint: hint,
      onPressed: onPressed,
      onLongPress: onLongPress,
      isEnabled: isEnabled,
    );
  }

  /// Bouton d'icône accessible
  static Widget iconButton({
    required String label,
    String? hint,
    required IconData icon,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
    bool isEnabled = true,
    double? iconSize,
    Color? iconColor,
    ButtonStyle? style,
    Size? minimumSize,
  }) {
    final button = IconButton(
      onPressed: isEnabled ? onPressed : null,
      onLongPress: onLongPress,
      icon: Icon(icon, size: iconSize, color: iconColor),
      style: style?.copyWith(
        minimumSize: MaterialStateProperty.all(minimumSize ?? const Size(44, 44)),
      ),
    );

    return _accessibilityService.makeAccessibleButton(
      button,
      label: label,
      hint: hint,
      onPressed: onPressed,
      onLongPress: onLongPress,
      isEnabled: isEnabled,
    );
  }

  /// Champ de texte accessible
  static Widget textField({
    required String label,
    String? hint,
    String? value,
    bool isRequired = false,
    String? errorText,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    int? maxLines,
    int? maxLength,
    bool enabled = true,
    InputDecoration? decoration,
    FocusNode? focusNode,
  }) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onTap: onTap,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      focusNode: focusNode,
      decoration: decoration?.copyWith(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        counterText: '', // Masquer le compteur par défaut
      ) ?? InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
      ),
    );

    return _accessibilityService.makeAccessibleTextField(
      field,
      label: label,
      hint: hint,
      value: value,
      isRequired: isRequired,
      errorText: errorText,
    );
  }

  /// Image accessible avec description
  static Widget image({
    required String imageUrl,
    required String description,
    String? label,
    bool isDecorative = false,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    Widget imageWidget;
    
    if (isDecorative) {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const CircularProgressIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.error);
        },
      );
    } else {
      imageWidget = Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? const CircularProgressIndicator();
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? const Icon(Icons.error);
        },
      );
    }

    return _accessibilityService.makeAccessibleImage(
      imageWidget,
      description: description,
      label: label,
      isDecorative: isDecorative,
    );
  }

  /// Titre accessible avec niveau approprié
  static Widget heading({
    required String text,
    required int level,
    String? label,
    TextStyle? style,
    TextAlign? textAlign,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
  }) {
    final headingStyle = style ?? TextStyle(
      fontSize: fontSize ?? _getDefaultFontSize(level),
      fontWeight: fontWeight ?? _getDefaultFontWeight(level),
      color: color,
    );

    final heading = Text(
      text,
      style: headingStyle,
      textAlign: textAlign,
    );

    return _accessibilityService.makeAccessibleHeading(
      heading,
      level: level,
      label: label,
    );
  }

  /// Carte accessible avec support des actions
  static Widget card({
    required String label,
    String? hint,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isInteractive = false,
    Color? color,
    double? elevation,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    ShapeBorder? shape,
  }) {
    final card = Card(
      color: color,
      elevation: elevation,
      margin: margin,
      shape: shape,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    Widget accessibleCard = card;
    
    if (isInteractive) {
      accessibleCard = InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: card,
      );
    }

    return _accessibilityService.makeAccessible(
      accessibleCard,
      label: label,
      hint: hint,
      isInteractive: isInteractive,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  /// Liste accessible avec support de la navigation
  static Widget listTile({
    required String label,
    String? hint,
    String? value,
    Widget? leading,
    Widget? title,
    Widget? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool isEnabled = true,
    bool isSelected = false,
    Color? selectedColor,
  }) {
    final tile = ListTile(
      leading: leading,
      title: title ?? Text(label),
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
      onLongPress: onLongPress,
      enabled: isEnabled,
      selected: isSelected,
      selectedTileColor: selectedColor,
    );

    return _accessibilityService.makeAccessible(
      tile,
      label: label,
      hint: hint,
      value: value,
      isInteractive: onTap != null || onLongPress != null,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }

  /// Switch accessible avec label descriptif
  static Widget switchTile({
    required String label,
    String? hint,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isEnabled = true,
    Widget? secondary,
    Color? activeColor,
    Color? activeTrackColor,
    Color? inactiveThumbColor,
    Color? inactiveTrackColor,
  }) {
    final switchTile = SwitchListTile(
      title: Text(label),
      subtitle: secondary,
      value: value,
      onChanged: isEnabled ? onChanged : null,
      activeColor: activeColor,
      activeTrackColor: activeTrackColor,
      inactiveThumbColor: inactiveThumbColor,
      inactiveTrackColor: inactiveTrackColor,
    );

    return _accessibilityService.makeAccessible(
      switchTile,
      label: label,
      hint: hint,
      value: value ? 'Activé' : 'Désactivé',
      isInteractive: isEnabled,
    );
  }

  /// Checkbox accessible avec label descriptif
  static Widget checkbox({
    required String label,
    String? hint,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool isEnabled = true,
    Color? activeColor,
    Color? checkColor,
    Widget? secondary,
  }) {
    final checkbox = CheckboxListTile(
      title: Text(label),
      subtitle: secondary,
      value: value,
      onChanged: isEnabled ? onChanged : null,
      activeColor: activeColor,
      checkColor: checkColor,
    );

    return _accessibilityService.makeAccessible(
      checkbox,
      label: label,
      hint: hint,
      value: value ? 'Coché' : 'Non coché',
      isInteractive: isEnabled,
    );
  }

  /// Radio accessible avec groupe
  static Widget radio<T>({
    required String label,
    String? hint,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
    bool isEnabled = true,
    Color? activeColor,
    Widget? secondary,
  }) {
    final radio = RadioListTile<T>(
      title: Text(label),
      subtitle: secondary,
      value: value,
      groupValue: groupValue,
      onChanged: isEnabled ? onChanged : null,
      activeColor: activeColor,
    );

    return _accessibilityService.makeAccessible(
      radio,
      label: label,
      hint: hint,
      value: value == groupValue ? 'Sélectionné' : 'Non sélectionné',
      isInteractive: isEnabled,
    );
  }

  /// Slider accessible avec valeurs descriptives
  static Widget slider({
    required String label,
    String? hint,
    required double value,
    required ValueChanged<double> onChanged,
    double? min,
    double? max,
    int? divisions,
    bool isEnabled = true,
    Color? activeColor,
    Color? inactiveColor,
    Color? thumbColor,
  }) {
    final slider = Slider(
      value: value,
      onChanged: isEnabled ? onChanged : null,
      min: min ?? 0.0,
      max: max ?? 100.0,
      divisions: divisions,
      activeColor: activeColor,
      inactiveColor: inactiveColor,
      thumbColor: thumbColor,
    );

    return _accessibilityService.makeAccessible(
      slider,
      label: label,
      hint: hint,
      value: '${value.toStringAsFixed(1)} sur ${max ?? 100.0}',
      isInteractive: isEnabled,
    );
  }

  /// Progress indicator accessible
  static Widget progressIndicator({
    required String label,
    String? hint,
    double? value,
    Color? backgroundColor,
    Color? valueColor,
    double? strokeWidth,
    Widget? child,
  }) {
    final progress = value != null
        ? LinearProgressIndicator(
            value: value,
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(valueColor ?? Colors.blue),
            strokeWidth: strokeWidth,
          )
        : LinearProgressIndicator(
            backgroundColor: backgroundColor,
            valueColor: AlwaysStoppedAnimation<Color>(valueColor ?? Colors.blue),
            strokeWidth: strokeWidth,
          );

    return _accessibilityService.makeAccessible(
      progress,
      label: label,
      hint: hint,
      value: value != null ? '${(value * 100).toStringAsFixed(0)}%' : 'En cours...',
    );
  }

  /// Chip accessible avec support des actions
  static Widget chip({
    required String label,
    String? hint,
    Widget? avatar,
    Widget? deleteIcon,
    VoidCallback? onDeleted,
    VoidCallback? onTap,
    bool isEnabled = true,
    Color? backgroundColor,
    Color? deleteIconColor,
    EdgeInsetsGeometry? padding,
  }) {
    final chip = Chip(
      label: Text(label),
      avatar: avatar,
      deleteIcon: deleteIcon,
      onDeleted: onDeleted,
      backgroundColor: backgroundColor,
      deleteIconColor: deleteIconColor,
      padding: padding,
    );

    Widget accessibleChip = chip;
    
    if (onTap != null) {
      accessibleChip = InkWell(
        onTap: onTap,
        child: chip,
      );
    }

    return _accessibilityService.makeAccessible(
      accessibleChip,
      label: label,
      hint: hint,
      isInteractive: onTap != null || onDeleted != null,
      onTap: onTap,
    );
  }

  /// Divider accessible avec label
  static Widget divider({
    String? label,
    String? hint,
    Color? color,
    double? thickness,
    double? indent,
    double? endIndent,
  }) {
    final divider = label != null
        ? Row(
            children: [
              Expanded(
                child: Divider(
                  color: color,
                  thickness: thickness,
                  indent: indent,
                  endIndent: endIndent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(label),
              ),
              Expanded(
                child: Divider(
                  color: color,
                  thickness: thickness,
                  indent: indent,
                  endIndent: endIndent,
                ),
              ),
            ],
          )
        : Divider(
            color: color,
            thickness: thickness,
            indent: indent,
            endIndent: endIndent,
          );

    return _accessibilityService.makeAccessible(
      divider,
      label: label ?? 'Séparateur',
      hint: hint,
    );
  }

  /// Spacer accessible avec description
  static Widget spacer({
    String? label,
    String? hint,
    double? width,
    double? height,
  }) {
    final spacer = SizedBox(
      width: width,
      height: height,
    );

    return _accessibilityService.makeAccessible(
      spacer,
      label: label ?? 'Espace',
      hint: hint,
    );
  }

  // Méthodes utilitaires privées

  static double _getDefaultFontSize(int level) {
    switch (level) {
      case 1:
        return 32.0;
      case 2:
        return 28.0;
      case 3:
        return 24.0;
      case 4:
        return 20.0;
      case 5:
        return 18.0;
      case 6:
        return 16.0;
      default:
        return 20.0;
    }
  }

  static FontWeight _getDefaultFontWeight(int level) {
    switch (level) {
      case 1:
      case 2:
        return FontWeight.bold;
      case 3:
      case 4:
        return FontWeight.w600;
      case 5:
      case 6:
        return FontWeight.w500;
      default:
        return FontWeight.w600;
    }
  }
}
