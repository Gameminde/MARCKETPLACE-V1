import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../models/address.dart';
import '../models/payment_method.dart';

/// Order status enumeration
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

/// Order model for marketplace orders
class Order {
  final String id;
  final String userId;
  final List<CartItem> items;
  final Address shippingAddress;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double tax;
  final double shipping;
  final double discount;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? deliveredAt;
  final String? trackingNumber;
  final String? deliveryNotes;

  const Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.shippingAddress,
    required this.paymentMethod,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.status,
    required this.createdAt,
    this.deliveredAt,
    this.trackingNumber,
    this.deliveryNotes,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      shippingAddress: Address.fromJson(json['shipping_address'] as Map<String, dynamic>),
      paymentMethod: PaymentMethod.fromJson(json['payment_method'] as Map<String, dynamic>),
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      shipping: (json['shipping'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      deliveredAt: json['delivered_at'] != null
          ? DateTime.parse(json['delivered_at'] as String)
          : null,
      trackingNumber: json['tracking_number'] as String?,
      deliveryNotes: json['delivery_notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'shipping_address': shippingAddress.toJson(),
      'payment_method': paymentMethod.toJson(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'tracking_number': trackingNumber,
      'delivery_notes': deliveryNotes,
    };
  }

  Order copyWith({
    String? id,
    String? userId,
    List<CartItem>? items,
    Address? shippingAddress,
    PaymentMethod? paymentMethod,
    double? subtotal,
    double? tax,
    double? shipping,
    double? discount,
    double? total,
    OrderStatus? status,
    DateTime? createdAt,
    DateTime? deliveredAt,
    String? trackingNumber,
    String? deliveryNotes,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      shipping: shipping ?? this.shipping,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Order{id: $id, status: $status, total: $total}';
}

/// Mock orders for development
class MockOrders {
  static final List<Order> userOrders = [
    Order(
      id: 'order_1',
      userId: 'user_1',
      items: [
        const CartItem(
          id: 'cart_1',
          productId: 'prod_1',
          name: 'Wireless Headphones',
          price: 99.99,
          quantity: 1,
          imageUrl: 'https://example.com/headphones.jpg',
        ),
      ],
      shippingAddress: const Address(
        id: 'addr_1',
        firstName: 'John',
        lastName: 'Doe',
        street: '123 Main St',
        city: 'New York',
        state: 'NY',
        zipCode: '10001',
        country: 'United States',
        isDefault: true,
      ),
      paymentMethod: const PaymentMethod(
        id: 'pm_1',
        name: 'Visa Card',
        type: PaymentType.creditCard,
        last4Digits: '4242',
        icon: Icons.credit_card,
        isDefault: true,
      ),
      subtotal: 99.99,
      tax: 8.00,
      shipping: 5.99,
      discount: 0.0,
      total: 113.98,
      status: OrderStatus.delivered,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      deliveredAt: DateTime.now().subtract(const Duration(days: 2)),
      trackingNumber: 'TRK123456789',
    ),
  ];
}