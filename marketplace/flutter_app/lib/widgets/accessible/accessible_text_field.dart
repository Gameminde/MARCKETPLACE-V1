import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🇩🇿 Accessible Text Field with Semantics and RTL support
class AccessibleTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? semanticLabel;
  final String? semanticHint;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? maxLength;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  const AccessibleTextField({
    super.key,
    this.label,
    this.hint,
    this.semanticLabel,
    this.semanticHint,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.maxLength,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.validator,
    this.onChanged,
    this.onTap,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      hint: semanticHint ?? _getDefaultHint(),
      textField: true,
      enabled: enabled && !readOnly,
      readOnly: readOnly,
      obscured: obscureText,
      maxValueLength: maxLength,
      excludeSemantics: true,
      child: TextFormField(
        controller: controller,
        initialValue: initialValue,
        keyboardType: keyboardType,
        obscureText: obscureText,
        enabled: enabled,
        readOnly: readOnly,
        maxLines: maxLines,
        maxLength: maxLength,
        textDirection: textDirection ?? _getTextDirection(context),
        textAlign: textAlign,
        validator: validator,
        onChanged: onChanged,
        onTap: onTap,
        inputFormatters: inputFormatters,
        focusNode: focusNode,
        autofocus: autofocus,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          counterText: maxLength != null ? null : '',
        ),
      ),
    );
  }

  String _getDefaultHint() {
    if (readOnly) return 'حقل للقراءة فقط';
    if (!enabled) return 'حقل غير متاح';
    if (obscureText) return 'حقل كلمة مرور';
    return 'حقل إدخال نص';
  }

  TextDirection _getTextDirection(BuildContext context) {
    final locale = Localizations.of(context);
    return locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }
}

/// Accessible Search Field
class AccessibleSearchField extends StatelessWidget {
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const AccessibleSearchField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'حقل البحث',
      hint: 'اكتب للبحث في المنتجات',
      textField: true,
      excludeSemantics: true,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        autofocus: autofocus,
        textDirection: _getTextDirection(context),
        decoration: InputDecoration(
          hintText: hint ?? 'البحث...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller?.text.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                  tooltip: 'مسح البحث',
                )
              : null,
        ),
      ),
    );
  }

  TextDirection _getTextDirection(BuildContext context) {
    final locale = Localizations.of(context);
    return locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr;
  }
}

/// Accessible Price Input Field
class AccessiblePriceField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final double? minValue;
  final double? maxValue;

  const AccessiblePriceField({
    super.key,
    this.label,
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.minValue,
    this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label ?? 'حقل السعر',
      hint: 'أدخل السعر بالدينار الجزائري',
      textField: true,
      enabled: enabled,
      excludeSemantics: true,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: enabled,
        onChanged: onChanged,
        validator: validator ?? _defaultPriceValidator,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        decoration: InputDecoration(
          labelText: label ?? 'السعر',
          hintText: '0.00',
          suffixText: 'د.ج',
          prefixIcon: const Icon(Icons.attach_money),
        ),
      ),
    );
  }

  String? _defaultPriceValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال السعر';
    }
    
    final price = double.tryParse(value);
    if (price == null) {
      return 'يرجى إدخال رقم صحيح';
    }
    
    if (minValue != null && price < minValue!) {
      return 'السعر يجب أن يكون أكبر من ${minValue!}';
    }
    
    if (maxValue != null && price > maxValue!) {
      return 'السعر يجب أن يكون أقل من ${maxValue!}';
    }
    
    return null;
  }
}

/// Accessible Phone Number Field
class AccessiblePhoneField extends StatelessWidget {
  final String? label;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const AccessiblePhoneField({
    super.key,
    this.label,
    this.controller,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label ?? 'رقم الهاتف',
      hint: 'أدخل رقم الهاتف الجزائري',
      textField: true,
      enabled: enabled,
      excludeSemantics: true,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.phone,
        enabled: enabled,
        onChanged: onChanged,
        validator: validator ?? _defaultPhoneValidator,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        decoration: InputDecoration(
          labelText: label ?? 'رقم الهاتف',
          hintText: '0555123456',
          prefixText: '+213 ',
          prefixIcon: const Icon(Icons.phone),
        ),
      ),
    );
  }

  String? _defaultPhoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'يرجى إدخال رقم الهاتف';
    }
    
    if (value.length != 10) {
      return 'رقم الهاتف يجب أن يكون 10 أرقام';
    }
    
    if (!value.startsWith('0')) {
      return 'رقم الهاتف يجب أن يبدأ بـ 0';
    }
    
    return null;
  }
}