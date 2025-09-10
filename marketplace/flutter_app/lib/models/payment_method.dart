import 'package:flutter/material.dart';

/// Payment method model for checkout
class PaymentMethod {
  final String id;
  final String name;
  final PaymentType type;
  final String? last4Digits;
  final String? brand;
  final IconData icon;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.last4Digits,
    this.brand,
    required this.icon,
    this.isDefault = false,
  });

  String get displayName {
    switch (type) {
      case PaymentType.creditCard:
        if (brand != null && last4Digits != null) {
          return '$brand •••• $last4Digits';
        }
        return name;
      case PaymentType.applePay:
        return 'Apple Pay';
      case PaymentType.googlePay:
        return 'Google Pay';
      case PaymentType.paypal:
        return 'PayPal';
      default:
        return name;
    }
  }
  
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      name: json['name'] as String,
      type: PaymentType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PaymentType.other,
      ),
      last4Digits: json['last4_digits'] as String?,
      brand: json['brand'] as String?,
      icon: Icons.credit_card, // Default icon - would need proper mapping
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'last4_digits': last4Digits,
      'brand': brand,
      'is_default': isDefault,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentMethod && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

enum PaymentType {
  creditCard,
  applePay,
  googlePay,
  paypal,
  other,
}

/// Mock payment methods
class MockPaymentMethods {
  static final List<PaymentMethod> userPaymentMethods = [
    const PaymentMethod(
      id: 'pm_1',
      name: 'Visa Credit Card',
      type: PaymentType.creditCard,
      last4Digits: '4242',
      brand: 'Visa',
      icon: Icons.credit_card,
      isDefault: true,
    ),
    const PaymentMethod(
      id: 'pm_2',
      name: 'Apple Pay',
      type: PaymentType.applePay,
      icon: Icons.language,
    ),
    const PaymentMethod(
      id: 'pm_3',
      name: 'Google Pay',
      type: PaymentType.googlePay,
      icon: Icons.language,
    ),
  ];
}

/// Checkout step model
class CheckoutStep {
  final String title;
  final String subtitle;
  final IconData icon;

  const CheckoutStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}