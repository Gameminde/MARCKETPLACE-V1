/// Enhanced model for cart items with vendor support and inventory tracking
class CartItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final String? imageUrl;
  final String? description;
  final Map<String, dynamic>? attributes; // color, size, etc.
  final String? vendorId;
  final String? vendorName;
  final bool isAvailable;
  final int maxQuantity;
  final int minQuantity;
  final String? sku;
  final double? weight;
  final String? category;
  final DateTime? addedAt;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.imageUrl,
    this.description,
    this.attributes,
    this.vendorId,
    this.vendorName,
    this.isAvailable = true,
    this.maxQuantity = 99,
    this.minQuantity = 1,
    this.sku,
    this.weight,
    this.category,
    this.addedAt,
  });

  /// Total price for this item (price * quantity)
  double get totalPrice => price * quantity;

  /// Check if item can be added to cart
  bool get canAddToCart => isAvailable && quantity < maxQuantity;

  /// Check if quantity can be increased
  bool get canIncreaseQuantity => quantity < maxQuantity;

  /// Check if quantity can be decreased  
  bool get canDecreaseQuantity => quantity > minQuantity;

  /// Get display name with vendor if available
  String get displayName {
    if (vendorName != null) {
      return '$name (by $vendorName)';
    }
    return name;
  }

  /// Copy with modifications
  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? imageUrl,
    String? description,
    Map<String, dynamic>? attributes,
    String? vendorId,
    String? vendorName,
    bool? isAvailable,
    int? maxQuantity,
    int? minQuantity,
    String? sku,
    double? weight,
    String? category,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      attributes: attributes ?? this.attributes,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      isAvailable: isAvailable ?? this.isAvailable,
      maxQuantity: maxQuantity ?? this.maxQuantity,
      minQuantity: minQuantity ?? this.minQuantity,
      sku: sku ?? this.sku,
      weight: weight ?? this.weight,
      category: category ?? this.category,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Convert to Map for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'description': description,
      'attributes': attributes,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'isAvailable': isAvailable,
      'maxQuantity': maxQuantity,
      'minQuantity': minQuantity,
      'sku': sku,
      'weight': weight,
      'category': category,
      'addedAt': addedAt?.toIso8601String(),
    };
  }

  /// Create from Map
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int? ?? 1,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
      attributes: json['attributes'] as Map<String, dynamic>?,
      vendorId: json['vendorId'] as String?,
      vendorName: json['vendorName'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      maxQuantity: json['maxQuantity'] as int? ?? 99,
      minQuantity: json['minQuantity'] as int? ?? 1,
      sku: json['sku'] as String?,
      weight: (json['weight'] as num?)?.toDouble(),
      category: json['category'] as String?,
      addedAt: json['addedAt'] != null 
          ? DateTime.tryParse(json['addedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CartItem{id: $id, name: $name, price: $price, quantity: $quantity}';
  }
}
