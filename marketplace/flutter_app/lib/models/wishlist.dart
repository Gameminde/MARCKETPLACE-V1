import '../models/product.dart';

/// Modèle pour les éléments de la liste de souhaits
class WishlistItem {
  final String id;
  final String userId;
  final Product product;
  final DateTime addedAt;
  final Map<String, dynamic>? metadata;

  const WishlistItem({
    required this.id,
    required this.userId,
    required this.product,
    required this.addedAt,
    this.metadata,
  });

  /// Durée depuis l'ajout
  Duration get timeSinceAdded => DateTime.now().difference(addedAt);

  /// Format d'affichage de la date d'ajout
  String get addedDateFormatted {
    final duration = timeSinceAdded;
    if (duration.inDays > 7) {
      return '${(duration.inDays / 7).floor()} week${duration.inDays > 14 ? 's' : ''} ago';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just added';
    }
  }

  /// Copie avec modifications
  WishlistItem copyWith({
    String? id,
    String? userId,
    Product? product,
    DateTime? addedAt,
    Map<String, dynamic>? metadata,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      product: product ?? this.product,
      addedAt: addedAt ?? this.addedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Conversion en Map pour sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'product': product.toJson(),
      'addedAt': addedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Création depuis Map
  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    return WishlistItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      product: Product.fromJson(json['product'] as Map<String, dynamic>),
      addedAt: DateTime.parse(json['addedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WishlistItem && 
           other.id == id && 
           other.product.id == product.id;
  }

  @override
  int get hashCode => id.hashCode ^ product.id.hashCode;

  @override
  String toString() {
    return 'WishlistItem{id: $id, productId: ${product.id}, addedAt: $addedAt}';
  }
}

/// Modèle pour la liste de souhaits complète
class Wishlist {
  final String id;
  final String userId;
  final List<WishlistItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? description;
  final bool isPublic;
  final bool isDefault;
  final Map<String, dynamic>? metadata;

  const Wishlist({
    required this.id,
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.name = 'My Wishlist',
    this.description,
    this.isPublic = false,
    this.isDefault = true,
    this.metadata,
  });

  /// Nombre total d'articles
  int get itemCount => items.length;

  /// Produits dans la liste
  List<Product> get products => items.map((item) => item.product).toList();

  /// Valeur totale de la liste de souhaits
  double get totalValue => items.fold(0.0, (sum, item) => sum + item.product.price);

  /// Articles ajoutés récemment (dernières 24h)
  List<WishlistItem> get recentItems {
    final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
    return items.where((item) => item.addedAt.isAfter(oneDayAgo)).toList();
  }

  /// Articles en promotion
  List<WishlistItem> get itemsOnSale {
    return items.where((item) => item.product.isOnSale).toList();
  }

  /// Articles en stock
  List<WishlistItem> get itemsInStock {
    return items.where((item) => item.product.inStock).toList();
  }

  /// Articles hors stock
  List<WishlistItem> get itemsOutOfStock {
    return items.where((item) => !item.product.inStock).toList();
  }

  /// Vérifie si un produit est dans la liste
  bool containsProduct(String productId) {
    return items.any((item) => item.product.id == productId);
  }

  /// Obtient un article par ID de produit
  WishlistItem? getItemByProductId(String productId) {
    try {
      return items.firstWhere((item) => item.product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Copie avec modifications
  Wishlist copyWith({
    String? id,
    String? userId,
    List<WishlistItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? description,
    bool? isPublic,
    bool? isDefault,
    Map<String, dynamic>? metadata,
  }) {
    return Wishlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      description: description ?? this.description,
      isPublic: isPublic ?? this.isPublic,
      isDefault: isDefault ?? this.isDefault,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Ajoute un article
  Wishlist addItem(WishlistItem item) {
    if (containsProduct(item.product.id)) {
      return this; // Déjà présent
    }
    
    final newItems = List<WishlistItem>.from(items)..add(item);
    return copyWith(
      items: newItems,
      updatedAt: DateTime.now(),
    );
  }

  /// Supprime un article par ID de produit
  Wishlist removeProduct(String productId) {
    final newItems = items.where((item) => item.product.id != productId).toList();
    return copyWith(
      items: newItems,
      updatedAt: DateTime.now(),
    );
  }

  /// Supprime un article par ID
  Wishlist removeItem(String itemId) {
    final newItems = items.where((item) => item.id != itemId).toList();
    return copyWith(
      items: newItems,
      updatedAt: DateTime.now(),
    );
  }

  /// Vide la liste
  Wishlist clear() {
    return copyWith(
      items: [],
      updatedAt: DateTime.now(),
    );
  }

  /// Conversion en Map pour sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'name': name,
      'description': description,
      'isPublic': isPublic,
      'isDefault': isDefault,
      'metadata': metadata,
    };
  }

  /// Création depuis Map
  factory Wishlist.fromJson(Map<String, dynamic> json) {
    return Wishlist(
      id: json['id'] as String,
      userId: json['userId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => WishlistItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      name: json['name'] as String? ?? 'My Wishlist',
      description: json['description'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      isDefault: json['isDefault'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Wishlist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Wishlist{id: $id, name: $name, itemCount: $itemCount}';
  }
}

/// Données de test pour la liste de souhaits
class MockWishlist {
  static final Wishlist sampleWishlist = Wishlist(
    id: 'wishlist_1',
    userId: 'user_1',
    name: 'My Favorites',
    description: 'My favorite products',
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    items: [
      WishlistItem(
        id: 'wishlist_item_1',
        userId: 'user_1',
        product: MockProducts.trendingProducts[0],
        addedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      WishlistItem(
        id: 'wishlist_item_2',
        userId: 'user_1',
        product: MockProducts.trendingProducts[1],
        addedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      WishlistItem(
        id: 'wishlist_item_3',
        userId: 'user_1',
        product: MockProducts.aeroRunShoe,
        addedAt: DateTime.now().subtract(const Duration(hours: 6)),
      ),
    ],
  );
}