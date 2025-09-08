/// Modèle pour les produits
class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double? originalPrice;
  final String? imageUrl;
  final List<String> images;
  final String category;
  final double rating;
  final int reviewCount;
  final List<String> availableColors;
  final List<String> availableSizes;
  final bool inStock;
  final Map<String, dynamic>? metadata;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.imageUrl,
    this.images = const [],
    required this.category,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.availableColors = const [],
    this.availableSizes = const [],
    this.inStock = true,
    this.metadata,
  });

  /// Pourcentage de réduction si prix original disponible
  double? get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return null;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  /// Produit en promotion
  bool get isOnSale => originalPrice != null && originalPrice! > price;

  /// Note avec étoiles
  String get ratingStars {
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;
    
    String stars = '★' * fullStars;
    if (hasHalfStar) stars += '☆';
    
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);
    stars += '☆' * emptyStars;
    
    return stars;
  }

  /// Copie avec modifications
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? imageUrl,
    List<String>? images,
    String? category,
    double? rating,
    int? reviewCount,
    List<String>? availableColors,
    List<String>? availableSizes,
    bool? inStock,
    Map<String, dynamic>? metadata,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      availableColors: availableColors ?? this.availableColors,
      availableSizes: availableSizes ?? this.availableSizes,
      inStock: inStock ?? this.inStock,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Conversion en Map pour sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'images': images,
      'category': category,
      'rating': rating,
      'reviewCount': reviewCount,
      'availableColors': availableColors,
      'availableSizes': availableSizes,
      'inStock': inStock,
      'metadata': metadata,
    };
  }

  /// Création depuis Map
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      originalPrice: json['originalPrice'] != null 
          ? (json['originalPrice'] as num).toDouble() 
          : null,
      imageUrl: json['imageUrl'] as String?,
      images: List<String>.from(json['images'] ?? []),
      category: json['category'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      availableColors: List<String>.from(json['availableColors'] ?? []),
      availableSizes: List<String>.from(json['availableSizes'] ?? []),
      inStock: json['inStock'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
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
    return 'Product{id: $id, name: $name, price: $price, category: $category}';
  }
}

/// Données de test pour les produits
class MockProducts {
  static const List<Product> trendingProducts = [
    Product(
      id: '1',
      name: 'Fashion Shirt',
      description: 'Comfortable cotton shirt with modern design',
      price: 59.99,
      category: 'Fashion',
      rating: 4.0,
      reviewCount: 120,
      availableColors: ['blue', 'white', 'black'],
      availableSizes: ['S', 'M', 'L', 'XL'],
    ),
    Product(
      id: '2',
      name: 'Smart Tablet',
      description: 'High-performance tablet for work and entertainment',
      price: 59.99,
      category: 'Electronics',
      rating: 4.2,
      reviewCount: 89,
      availableColors: ['silver', 'black'],
    ),
    Product(
      id: '3',
      name: 'Gaming Laptop',
      description: 'Powerful laptop for gaming and professional work',
      price: 59.99,
      originalPrice: 79.99,
      category: 'Computers',
      rating: 4.5,
      reviewCount: 203,
      availableColors: ['black', 'silver'],
    ),
    Product(
      id: '4',
      name: 'Wireless Tablet',
      description: 'Lightweight tablet with long battery life',
      price: 59.99,
      category: 'Electronics',
      rating: 4.1,
      reviewCount: 156,
      availableColors: ['white', 'gold', 'rose-gold'],
    ),
  ];

  static const Product aeroRunShoe = Product(
    id: 'aero-run-2.0',
    name: 'AeroRun 2.0',
    description: 'Experience comfort and performance with our latest running shoe technology. Designed for athletes and everyday runners.',
    price: 199.99,
    category: 'Sports',
    rating: 4.8,
    reviewCount: 1200,
    availableColors: ['light-blue', 'grey', 'black', 'blue-grey'],
    availableSizes: ['US 8', 'US 9', 'US 10', 'US 11'],
    images: [
      'assets/images/aero-run-1.jpg',
      'assets/images/aero-run-2.jpg',
      'assets/images/aero-run-3.jpg',
      'assets/images/aero-run-4.jpg',
      'assets/images/aero-run-5.jpg',
    ],
  );
}
