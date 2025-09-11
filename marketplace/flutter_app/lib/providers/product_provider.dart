import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/search_result.dart';
import '../services/product_api_service.dart';
// MockProducts est défini dans product.dart, pas besoin d'import supplémentaire

/// Product Provider for managing product state
class ProductProvider extends ChangeNotifier {
  final ProductApiService _productService;

  // State
  List<Product> _products = [];
  List<Product> _trendingProducts = [];
  List<Product> _recommendedProducts = [];
  List<Product> _recentlyViewedProducts = [];
  List<Product> _wishlistProducts = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _brands = [];

  // Search state
  SearchResult? _searchResult;
  String _searchQuery = '';
  bool _isSearching = false;

  // Pagination
  int _currentPage = 1;
  bool _hasMoreProducts = true;
  bool _isLoadingMore = false;

  // Filters
  String? _selectedCategory;
  String? _selectedBrand;
  String? _sortBy;
  String _sortOrder = 'asc';
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  bool? _inStock;

  // Error state
  String? _errorMessage;
  bool _isLoading = false;

  ProductProvider({required ProductApiService productService})
      : _productService = productService {
    _initializeData();
  }

  // Getters
  List<Product> get products => _products;
  List<Product> get trendingProducts => _trendingProducts;
  List<Product> get recommendedProducts => _recommendedProducts;
  List<Product> get recentlyViewedProducts => _recentlyViewedProducts;
  List<Product> get wishlistProducts => _wishlistProducts;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get brands => _brands;

  SearchResult? get searchResult => _searchResult;
  String get searchQuery => _searchQuery;
  bool get isSearching => _isSearching;

  int get currentPage => _currentPage;
  bool get hasMoreProducts => _hasMoreProducts;
  bool get isLoadingMore => _isLoadingMore;

  String? get selectedCategory => _selectedCategory;
  String? get selectedBrand => _selectedBrand;
  String? get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  double? get minRating => _minRating;
  bool? get inStock => _inStock;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  /// Initialize data
  Future<void> _initializeData() async {
    await Future.wait([
      loadProducts(),
      loadTrendingProducts(),
      loadCategories(),
      loadBrands(),
    ]);
  }

  /// Load products with current filters
  Future<void> loadProducts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreProducts = true;
      _products.clear();
    }

    if (_isLoading || (!_hasMoreProducts && !refresh)) return;

    _setLoading(true);
    _clearError();

    try {
      final newProducts = await _productService.getProducts(
        page: _currentPage,
        category: _selectedCategory,
        brand: _selectedBrand,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        inStock: _inStock,
      );

      if (refresh) {
        _products = newProducts;
      } else {
        _products.addAll(newProducts);
      }

      _hasMoreProducts = newProducts.length >= 20; // Assuming 20 items per page
      _currentPage++;
    } catch (e) {
      _setError('Failed to load products: ${e.toString()}');
      // Utiliser les données mockées en cas d'échec
      if (_products.isEmpty) {
        _products = MockProducts.trendingProducts;
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMoreProducts) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final newProducts = await _productService.getProducts(
        page: _currentPage,
        category: _selectedCategory,
        brand: _selectedBrand,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        inStock: _inStock,
      );

      _products.addAll(newProducts);
      _hasMoreProducts = newProducts.length >= 20;
      _currentPage++;
    } catch (e) {
      _setError('Failed to load more products: ${e.toString()}');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Load trending products
  Future<void> loadTrendingProducts() async {
    try {
      _trendingProducts = await _productService.getTrendingProducts();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load trending products: $e');
      // Utiliser les données mockées en cas d'échec
      _trendingProducts = MockProducts.trendingProducts;
      notifyListeners();
    }
  }

  /// Load recommended products
  Future<void> loadRecommendedProducts({String? userId}) async {
    try {
      _recommendedProducts = await _productService.getRecommendations(
        userId: userId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recommended products: $e');
    }
  }

  /// Load recently viewed products
  Future<void> loadRecentlyViewedProducts() async {
    try {
      _recentlyViewedProducts = await _productService.getRecentlyViewed();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load recently viewed products: $e');
    }
  }

  /// Load wishlist products
  Future<void> loadWishlistProducts() async {
    try {
      _wishlistProducts = await _productService.getWishlist();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load wishlist products: $e');
    }
  }

  /// Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _productService.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load categories: $e');
      // Utiliser des catégories par défaut en cas d'échec
      _categories = [
        {'id': '1', 'name': 'Chaussures'},
        {'id': '2', 'name': 'Vêtements'},
        {'id': '3', 'name': 'Accessoires'},
        {'id': '4', 'name': 'Électronique'}
      ];
      notifyListeners();
    }
  }

  /// Load brands
  Future<void> loadBrands() async {
    try {
      _brands = await _productService.getBrands();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load brands: $e');
      // Utiliser des marques par défaut en cas d'échec
      _brands = [
        {'id': '1', 'name': 'Nike'},
        {'id': '2', 'name': 'Adidas'},
        {'id': '3', 'name': 'Puma'},
        {'id': '4', 'name': 'Samsung'},
        {'id': '5', 'name': 'Apple'}
      ];
      notifyListeners();
    }
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    if (query.isEmpty) {
      _searchResult = null;
      _searchQuery = '';
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    _clearError();
    notifyListeners();

    try {
      _searchResult = await _productService.searchProducts(
        query: query,
        category: _selectedCategory,
        brand: _selectedBrand,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
      );
    } catch (e) {
      _setError('Search failed: ${e.toString()}');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search
  void clearSearch() {
    _searchResult = null;
    _searchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  /// Apply filters
  void applyFilters({
    String? category,
    String? brand,
    String? sortBy,
    String? sortOrder,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    bool? inStock,
  }) {
    _selectedCategory = category;
    _selectedBrand = brand;
    _sortBy = sortBy;
    _sortOrder = sortOrder ?? 'asc';
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    _minRating = minRating;
    _inStock = inStock;

    // Reset pagination and reload products
    _currentPage = 1;
    _hasMoreProducts = true;
    loadProducts(refresh: true);
  }

  /// Clear filters
  void clearFilters() {
    _selectedCategory = null;
    _selectedBrand = null;
    _sortBy = null;
    _sortOrder = 'asc';
    _minPrice = null;
    _maxPrice = null;
    _minRating = null;
    _inStock = null;

    // Reset pagination and reload products
    _currentPage = 1;
    _hasMoreProducts = true;
    loadProducts(refresh: true);
  }

  /// Add to wishlist
  Future<bool> addToWishlist(String productId) async {
    try {
      final success = await _productService.addToWishlist(productId);
      if (success) {
        await loadWishlistProducts();
      }
      return success;
    } catch (e) {
      _setError('Failed to add to wishlist: ${e.toString()}');
      return false;
    }
  }

  /// Remove from wishlist
  Future<bool> removeFromWishlist(String productId) async {
    try {
      final success = await _productService.removeFromWishlist(productId);
      if (success) {
        await loadWishlistProducts();
      }
      return success;
    } catch (e) {
      _setError('Failed to remove from wishlist: ${e.toString()}');
      return false;
    }
  }

  /// Track product view
  Future<void> trackProductView(String productId) async {
    try {
      await _productService.trackProductView(productId);
    } catch (e) {
      debugPrint('Failed to track product view: $e');
    }
  }

  /// Get product by ID
  Product? getProductById(String productId) {
    try {
      return _products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _wishlistProducts.any((product) => product.id == productId);
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Refresh all data
  Future<void> refresh() async {
    await _initializeData();
  }
}
