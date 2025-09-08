/// Search filter model for advanced filtering
class SearchFilter {
  final double? minPrice;
  final double? maxPrice;
  final List<String>? categories;
  final List<String>? brands;
  final double? minRating;
  final bool? inStock;
  final List<String>? colors;
  final List<String>? sizes;
  final String? location;
  final double? maxDistance;
  final bool? freeShipping;
  final bool? onSale;
  final Map<String, dynamic>? customFilters;
  
  SearchFilter({
    this.minPrice,
    this.maxPrice,
    this.categories,
    this.brands,
    this.minRating,
    this.inStock,
    this.colors,
    this.sizes,
    this.location,
    this.maxDistance,
    this.freeShipping,
    this.onSale,
    this.customFilters,
  });
  
  /// Check if any filters are active
  bool get hasActiveFilters {
    return minPrice != null ||
           maxPrice != null ||
           (categories?.isNotEmpty ?? false) ||
           (brands?.isNotEmpty ?? false) ||
           minRating != null ||
           inStock != null ||
           (colors?.isNotEmpty ?? false) ||
           (sizes?.isNotEmpty ?? false) ||
           location != null ||
           maxDistance != null ||
           freeShipping != null ||
           onSale != null ||
           (customFilters?.isNotEmpty ?? false);
  }
  
  /// Get count of active filters
  int get activeFilterCount {
    int count = 0;
    if (minPrice != null || maxPrice != null) count++;
    if (categories?.isNotEmpty ?? false) count++;
    if (brands?.isNotEmpty ?? false) count++;
    if (minRating != null) count++;
    if (inStock != null) count++;
    if (colors?.isNotEmpty ?? false) count++;
    if (sizes?.isNotEmpty ?? false) count++;
    if (location != null || maxDistance != null) count++;
    if (freeShipping != null) count++;
    if (onSale != null) count++;
    if (customFilters?.isNotEmpty ?? false) count++;
    return count;
  }
  
  /// Copy with modifications
  SearchFilter copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? categories,
    List<String>? brands,
    double? minRating,
    bool? inStock,
    List<String>? colors,
    List<String>? sizes,
    String? location,
    double? maxDistance,
    bool? freeShipping,
    bool? onSale,
    Map<String, dynamic>? customFilters,
  }) {
    return SearchFilter(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      categories: categories ?? this.categories,
      brands: brands ?? this.brands,
      minRating: minRating ?? this.minRating,
      inStock: inStock ?? this.inStock,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      location: location ?? this.location,
      maxDistance: maxDistance ?? this.maxDistance,
      freeShipping: freeShipping ?? this.freeShipping,
      onSale: onSale ?? this.onSale,
      customFilters: customFilters ?? this.customFilters,
    );
  }
  
  /// Clear all filters
  SearchFilter clear() {
    return SearchFilter();
  }
  
  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'categories': categories,
      'brands': brands,
      'minRating': minRating,
      'inStock': inStock,
      'colors': colors,
      'sizes': sizes,
      'location': location,
      'maxDistance': maxDistance,
      'freeShipping': freeShipping,
      'onSale': onSale,
      'customFilters': customFilters,
    };
  }
  
  /// Create from JSON
  factory SearchFilter.fromJson(Map<String, dynamic> json) {
    return SearchFilter(
      minPrice: (json['minPrice'] as num?)?.toDouble(),
      maxPrice: (json['maxPrice'] as num?)?.toDouble(),
      categories: (json['categories'] as List<dynamic>?)?.cast<String>(),
      brands: (json['brands'] as List<dynamic>?)?.cast<String>(),
      minRating: (json['minRating'] as num?)?.toDouble(),
      inStock: json['inStock'] as bool?,
      colors: (json['colors'] as List<dynamic>?)?.cast<String>(),
      sizes: (json['sizes'] as List<dynamic>?)?.cast<String>(),
      location: json['location'] as String?,
      maxDistance: (json['maxDistance'] as num?)?.toDouble(),
      freeShipping: json['freeShipping'] as bool?,
      onSale: json['onSale'] as bool?,
      customFilters: json['customFilters'] as Map<String, dynamic>?,
    );
  }
  
  @override
  String toString() {
    return 'SearchFilter{activeFilters: $activeFilterCount}';
  }
}