import 'package:flutter/material.dart';

/// Modèle pour les catégories de produits
class Category {
  final String id;
  final String name;
  final String displayName;
  final String description;
  final String? imageUrl;
  final String? iconName;
  final Color? color;
  final int productCount;
  final bool isActive;
  final bool isFeatured;
  final int sortOrder;
  final String? parentCategoryId;
  final List<String> subcategoryIds;
  final Map<String, dynamic>? metadata;

  const Category({
    required this.id,
    required this.name,
    required this.displayName,
    this.description = '',
    this.imageUrl,
    this.iconName,
    this.color,
    this.productCount = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.sortOrder = 0,
    this.parentCategoryId,
    this.subcategoryIds = const [],
    this.metadata,
  });

  /// Icône pour la catégorie
  IconData get icon {
    if (iconName != null) {
      return _getIconFromName(iconName!);
    }
    return _getDefaultIcon(name);
  }

  /// Couleur de la catégorie ou couleur par défaut
  Color get categoryColor {
    if (color != null) return color!;
    return _getDefaultColor(name);
  }

  /// Vérifie si c'est une catégorie parente
  bool get isParentCategory => parentCategoryId == null;

  /// Vérifie si c'est une sous-catégorie
  bool get isSubcategory => parentCategoryId != null;

  /// Vérifie si la catégorie a des sous-catégories
  bool get hasSubcategories => subcategoryIds.isNotEmpty;

  /// Copie avec modifications
  Category copyWith({
    String? id,
    String? name,
    String? displayName,
    String? description,
    String? imageUrl,
    String? iconName,
    Color? color,
    int? productCount,
    bool? isActive,
    bool? isFeatured,
    int? sortOrder,
    String? parentCategoryId,
    List<String>? subcategoryIds,
    Map<String, dynamic>? metadata,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      iconName: iconName ?? this.iconName,
      color: color ?? this.color,
      productCount: productCount ?? this.productCount,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Conversion en Map pour sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayName': displayName,
      'description': description,
      'imageUrl': imageUrl,
      'iconName': iconName,
      'color': color?.value,
      'productCount': productCount,
      'isActive': isActive,
      'isFeatured': isFeatured,
      'sortOrder': sortOrder,
      'parentCategoryId': parentCategoryId,
      'subcategoryIds': subcategoryIds,
      'metadata': metadata,
    };
  }

  /// Création depuis Map
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      iconName: json['iconName'] as String?,
      color: json['color'] != null ? Color(json['color'] as int) : null,
      productCount: json['productCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
      sortOrder: json['sortOrder'] as int? ?? 0,
      parentCategoryId: json['parentCategoryId'] as String?,
      subcategoryIds: List<String>.from(json['subcategoryIds'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category{id: $id, name: $name, productCount: $productCount}';
  }

  /// Obtient l'icône depuis le nom
  static IconData _getIconFromName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'fashion':
      case 'checkroom':
        return Icons.checkroom;
      case 'electronics':
      case 'devices':
        return Icons.devices;
      case 'computers':
      case 'laptop':
        return Icons.laptop;
      case 'beauty':
      case 'palette':
        return Icons.palette;
      case 'sports':
        return Icons.sports;
      case 'home':
        return Icons.home;
      case 'books':
      case 'book':
        return Icons.book;
      case 'toys':
        return Icons.toys;
      case 'automotive':
      case 'car':
        return Icons.directions_car;
      case 'food':
      case 'restaurant':
        return Icons.restaurant;
      case 'health':
      case 'medical':
        return Icons.medical_services;
      case 'garden':
      case 'eco':
        return Icons.eco;
      case 'music':
        return Icons.music_note;
      case 'camera':
      case 'photo':
        return Icons.camera_alt;
      default:
        return Icons.category;
    }
  }

  /// Obtient l'icône par défaut selon le nom de catégorie
  static IconData _getDefaultIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'fashion':
      case 'clothing':
      case 'apparel':
        return Icons.checkroom;
      case 'electronics':
      case 'tech':
        return Icons.devices;
      case 'computers':
      case 'laptops':
        return Icons.laptop;
      case 'beauty':
      case 'cosmetics':
        return Icons.palette;
      case 'sports':
      case 'fitness':
        return Icons.sports;
      case 'home':
      case 'furniture':
        return Icons.home;
      case 'books':
      case 'literature':
        return Icons.book;
      case 'toys':
      case 'games':
        return Icons.toys;
      case 'automotive':
      case 'cars':
        return Icons.directions_car;
      case 'food':
      case 'grocery':
        return Icons.restaurant;
      default:
        return Icons.category;
    }
  }

  /// Obtient la couleur par défaut selon le nom de catégorie
  static Color _getDefaultColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'fashion':
      case 'clothing':
        return Colors.pink;
      case 'electronics':
      case 'tech':
        return Colors.blue;
      case 'computers':
        return Colors.indigo;
      case 'beauty':
        return Colors.purple;
      case 'sports':
        return Colors.orange;
      case 'home':
        return Colors.brown;
      case 'books':
        return Colors.green;
      case 'toys':
        return Colors.red;
      case 'automotive':
        return Colors.grey;
      case 'food':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }
}

/// Données de test pour les catégories
class MockCategories {
  static const List<Category> featuredCategories = [
    Category(
      id: 'fashion',
      name: 'fashion',
      displayName: 'Fashion',
      description: 'Clothing, shoes, and accessories',
      iconName: 'checkroom',
      productCount: 1250,
      isFeatured: true,
      sortOrder: 1,
    ),
    Category(
      id: 'electronics',
      name: 'electronics',
      displayName: 'Electronics',
      description: 'Phones, tablets, and gadgets',
      iconName: 'devices',
      productCount: 890,
      isFeatured: true,
      sortOrder: 2,
    ),
    Category(
      id: 'computers',
      name: 'computers',
      displayName: 'Computers',
      description: 'Laptops, desktops, and accessories',
      iconName: 'laptop',
      productCount: 567,
      isFeatured: true,
      sortOrder: 3,
    ),
    Category(
      id: 'beauty',
      name: 'beauty',
      displayName: 'Beauty',
      description: 'Cosmetics and skincare',
      iconName: 'palette',
      productCount: 432,
      isFeatured: true,
      sortOrder: 4,
    ),
    Category(
      id: 'sports',
      name: 'sports',
      displayName: 'Sports',
      description: 'Fitness and outdoor equipment',
      iconName: 'sports',
      productCount: 678,
      isFeatured: true,
      sortOrder: 5,
    ),
    Category(
      id: 'home',
      name: 'home',
      displayName: 'Home & Garden',
      description: 'Furniture and home decor',
      iconName: 'home',
      productCount: 923,
      isFeatured: true,
      sortOrder: 6,
    ),
    Category(
      id: 'books',
      name: 'books',
      displayName: 'Books',
      description: 'Literature and educational materials',
      iconName: 'book',
      productCount: 345,
      isFeatured: true,
      sortOrder: 7,
    ),
    Category(
      id: 'toys',
      name: 'toys',
      displayName: 'Toys & Games',
      description: 'Toys for all ages',
      iconName: 'toys',
      productCount: 456,
      isFeatured: true,
      sortOrder: 8,
    ),
  ];

  static const List<Category> allCategories = [
    ...featuredCategories,
    Category(
      id: 'automotive',
      name: 'automotive',
      displayName: 'Automotive',
      description: 'Car parts and accessories',
      iconName: 'car',
      productCount: 234,
      sortOrder: 9,
    ),
    Category(
      id: 'food',
      name: 'food',
      displayName: 'Food & Grocery',
      description: 'Fresh and packaged foods',
      iconName: 'restaurant',
      productCount: 567,
      sortOrder: 10,
    ),
    Category(
      id: 'health',
      name: 'health',
      displayName: 'Health & Wellness',
      description: 'Health and medical supplies',
      iconName: 'medical',
      productCount: 123,
      sortOrder: 11,
    ),
    Category(
      id: 'music',
      name: 'music',
      displayName: 'Music & Audio',
      description: 'Musical instruments and audio equipment',
      iconName: 'music',
      productCount: 189,
      sortOrder: 12,
    ),
  ];
}