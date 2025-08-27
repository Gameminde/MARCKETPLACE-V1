class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final String category;
  final List<String> tags;
  final String shopId;
  final String shopName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? stock;
  final double? rating;
  final int? reviewCount;
  final bool? isOnSale;
  final double? originalPrice;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.category,
    this.tags = const [],
    required this.shopId,
    required this.shopName,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.stock,
    this.rating,
    this.reviewCount,
    this.isOnSale,
    this.originalPrice,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      shopId: json['shopId'] ?? json['shop_id'] ?? '',
      shopName: json['shopName'] ?? json['shop_name'] ?? '',
      isActive: json['isActive'] ?? json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? json['updated_at'] ?? '') ?? DateTime.now(),
      stock: json['stock'],
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? json['review_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'tags': tags,
      'shopId': shopId,
      'shopName': shopName,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'stock': stock,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    List<String>? tags,
    String? shopId,
    String? shopName,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? stock,
    double? rating,
    int? reviewCount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, category: $category)';
  }
}