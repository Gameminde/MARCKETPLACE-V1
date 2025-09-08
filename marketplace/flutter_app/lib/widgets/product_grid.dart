import 'package:flutter/material.dart';
import 'dart:async';

import '../core/config/app_constants.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/loading_states.dart';
import '../widgets/glassmorphic_container.dart';

/// Comprehensive responsive product grid with infinite scroll,
/// filtering, sorting, and various layout options
class ProductGrid extends StatefulWidget {
  final List<Product> products;
  final Future<List<Product>> Function(int page, int limit)? onLoadMore;
  final VoidCallback? onRefresh;
  final Function(Product)? onProductTap;
  final Function(Product)? onWishlistTap;
  final Function(Product)? onAddToCart;
  final Function(Product)? onQuickView;
  final Set<String> wishlistedProducts;
  final ProductGridLayout layout;
  final ProductCardStyle cardStyle;
  final int crossAxisCount;
  final double childAspectRatio;
  final bool enableInfiniteScroll;
  final bool enablePullToRefresh;
  final bool enableSearch;
  final bool enableFilters;
  final bool enableSorting;
  final bool enableGlassmorphism;
  final String? emptyMessage;
  final Widget? emptyWidget;
  final EdgeInsetsGeometry? padding;
  final double? spacing;
  final String? searchQuery;
  final Function(String)? onSearchChanged;
  final ProductSortOption sortOption;
  final Function(ProductSortOption)? onSortChanged;
  final Map<String, dynamic>? filters;
  final Function(Map<String, dynamic>)? onFiltersChanged;
  
  const ProductGrid({
    super.key,
    required this.products,
    this.onLoadMore,
    this.onRefresh,
    this.onProductTap,
    this.onWishlistTap,
    this.onAddToCart,
    this.onQuickView,
    this.wishlistedProducts = const {},
    this.layout = ProductGridLayout.grid,
    this.cardStyle = ProductCardStyle.grid,
    this.crossAxisCount = 2,
    this.childAspectRatio = 0.75,
    this.enableInfiniteScroll = true,
    this.enablePullToRefresh = true,
    this.enableSearch = false,
    this.enableFilters = false,
    this.enableSorting = false,
    this.enableGlassmorphism = true,
    this.emptyMessage,
    this.emptyWidget,
    this.padding,
    this.spacing,
    this.searchQuery,
    this.onSearchChanged,
    this.sortOption = ProductSortOption.none,
    this.onSortChanged,
    this.filters,
    this.onFiltersChanged,
  });

  /// Factory constructor for responsive grid
  factory ProductGrid.responsive({
    Key? key,
    required List<Product> products,
    Future<List<Product>> Function(int page, int limit)? onLoadMore,
    Function(Product)? onProductTap,
    Function(Product)? onWishlistTap,
    Function(Product)? onAddToCart,
    Set<String> wishlistedProducts = const {},
    bool enableInfiniteScroll = true,
  }) {
    return ProductGrid(
      key: key,
      products: products,
      onLoadMore: onLoadMore,
      onProductTap: onProductTap,
      onWishlistTap: onWishlistTap,
      onAddToCart: onAddToCart,
      wishlistedProducts: wishlistedProducts,
      layout: ProductGridLayout.responsiveGrid,
      enableInfiniteScroll: enableInfiniteScroll,
    );
  }

  /// Factory constructor for list layout
  factory ProductGrid.list({
    Key? key,
    required List<Product> products,
    Future<List<Product>> Function(int page, int limit)? onLoadMore,
    Function(Product)? onProductTap,
    Function(Product)? onWishlistTap,
    Function(Product)? onAddToCart,
    Set<String> wishlistedProducts = const {},
    bool enableInfiniteScroll = true,
  }) {
    return ProductGrid(
      key: key,
      products: products,
      onLoadMore: onLoadMore,
      onProductTap: onProductTap,
      onWishlistTap: onWishlistTap,
      onAddToCart: onAddToCart,
      wishlistedProducts: wishlistedProducts,
      layout: ProductGridLayout.list,
      cardStyle: ProductCardStyle.list,
      crossAxisCount: 1,
      childAspectRatio: 3.0,
      enableInfiniteScroll: enableInfiniteScroll,
    );
  }

  @override
  State<ProductGrid> createState() => _ProductGridState();
}

class _ProductGridState extends State<ProductGrid> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  String _searchQuery = '';
  Timer? _searchDebouncer;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.text = widget.searchQuery ?? '';
    _searchQuery = widget.searchQuery ?? '';
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebouncer?.cancel();
    super.dispose();
  }
  
  void _onScroll() {
    if (!widget.enableInfiniteScroll || !_hasMoreData || _isLoading) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // Trigger at 80% scroll
    
    if (currentScroll >= threshold) {
      _loadMoreProducts();
    }
  }
  
  Future<void> _loadMoreProducts() async {
    if (_isLoading || !_hasMoreData || widget.onLoadMore == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newProducts = await widget.onLoadMore!(_currentPage, 20);
      
      if (newProducts.isEmpty) {
        setState(() => _hasMoreData = false);
      } else {
        setState(() => _currentPage++);
      }
    } catch (e) {
      // Handle error
      debugPrint('Error loading more products: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _onSearchChanged(String query) {
    if (_searchDebouncer?.isActive ?? false) _searchDebouncer!.cancel();
    
    _searchDebouncer = Timer(const Duration(milliseconds: 500), () {
      setState(() => _searchQuery = query);
      widget.onSearchChanged?.call(query);
    });
  }
  
  Future<void> _onRefresh() async {
    setState(() {
      _currentPage = 1;
      _hasMoreData = true;
    });
    
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and filters bar
        if (widget.enableSearch || widget.enableSorting || widget.enableFilters)
          _buildSearchAndFiltersBar(context),
        
        // Product grid content
        Expanded(
          child: _buildContent(context),
        ),
      ],
    );
  }
  
  Widget _buildSearchAndFiltersBar(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        children: [
          // Search bar
          if (widget.enableSearch)
            _buildSearchBar(context),
          
          if (widget.enableSearch && (widget.enableSorting || widget.enableFilters))
            const SizedBox(height: AppConstants.spacingM),
          
          // Sort and filter buttons
          if (widget.enableSorting || widget.enableFilters)
            _buildSortAndFilterRow(context),
        ],
      ),
    );
    
    if (widget.enableGlassmorphism) {
      return GlassmorphicContainer.card(
        margin: const EdgeInsets.all(AppConstants.spacingM),
        child: content,
      );
    }
    
    return Card(
      margin: const EdgeInsets.all(AppConstants.spacingM),
      child: content,
    );
  }
  
  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search products...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
  
  Widget _buildSortAndFilterRow(BuildContext context) {
    return Row(
      children: [
        // Sort button
        if (widget.enableSorting)
          Expanded(
            child: _buildSortButton(context),
          ),
        
        if (widget.enableSorting && widget.enableFilters)
          const SizedBox(width: AppConstants.spacingM),
        
        // Filter button
        if (widget.enableFilters)
          Expanded(
            child: _buildFilterButton(context),
          ),
      ],
    );
  }
  
  Widget _buildSortButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showSortOptions(context),
      icon: const Icon(Icons.sort),
      label: Text(_getSortOptionText(widget.sortOption)),
    );
  }
  
  Widget _buildFilterButton(BuildContext context) {
    final hasActiveFilters = widget.filters?.isNotEmpty ?? false;
    
    return OutlinedButton.icon(
      onPressed: () => _showFilterOptions(context),
      icon: Icon(
        Icons.filter_list,
        color: hasActiveFilters ? Theme.of(context).colorScheme.primary : null,
      ),
      label: Text(
        hasActiveFilters ? 'Filters (${widget.filters!.length})' : 'Filters',
        style: TextStyle(
          color: hasActiveFilters ? Theme.of(context).colorScheme.primary : null,
        ),
      ),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    if (widget.products.isEmpty) {
      return _buildEmptyState(context);
    }
    
    Widget gridContent = _buildProductGrid(context);
    
    if (widget.enablePullToRefresh) {
      gridContent = RefreshIndicator(
        onRefresh: _onRefresh,
        child: gridContent,
      );
    }
    
    return gridContent;
  }
  
  Widget _buildProductGrid(BuildContext context) {
    final padding = widget.padding ?? const EdgeInsets.all(AppConstants.spacingM);
    final spacing = widget.spacing ?? AppConstants.gridSpacing;
    
    switch (widget.layout) {
      case ProductGridLayout.list:
        return _buildListView(context, padding);
      case ProductGridLayout.responsiveGrid:
        return _buildResponsiveGrid(context, padding, spacing);
      case ProductGridLayout.staggered:
        return _buildStaggeredGrid(context, padding, spacing);
      case ProductGridLayout.grid:
      default:
        return _buildFixedGrid(context, padding, spacing);
    }
  }
  
  Widget _buildListView(BuildContext context, EdgeInsetsGeometry padding) {
    return ListView.builder(
      controller: _scrollController,
      padding: padding,
      itemCount: widget.products.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= widget.products.length) {
          return _buildLoadingIndicator();
        }
        
        final product = widget.products[index];
        return _buildProductCard(product, index);
      },
    );
  }
  
  Widget _buildFixedGrid(BuildContext context, EdgeInsetsGeometry padding, double spacing) {
    return GridView.builder(
      controller: _scrollController,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: widget.products.length + (_isLoading ? widget.crossAxisCount : 0),
      itemBuilder: (context, index) {
        if (index >= widget.products.length) {
          return _buildLoadingIndicator();
        }
        
        final product = widget.products[index];
        return _buildProductCard(product, index);
      },
    );
  }
  
  Widget _buildResponsiveGrid(BuildContext context, EdgeInsetsGeometry padding, double spacing) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        
        if (width < 600) {
          crossAxisCount = 2;
        } else if (width < 900) {
          crossAxisCount = 3;
        } else if (width < 1200) {
          crossAxisCount = 4;
        } else {
          crossAxisCount = 5;
        }
        
        return GridView.builder(
          controller: _scrollController,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: widget.childAspectRatio,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
          ),
          itemCount: widget.products.length + (_isLoading ? crossAxisCount : 0),
          itemBuilder: (context, index) {
            if (index >= widget.products.length) {
              return _buildLoadingIndicator();
            }
            
            final product = widget.products[index];
            return _buildProductCard(product, index);
          },
        );
      },
    );
  }
  
  Widget _buildStaggeredGrid(BuildContext context, EdgeInsetsGeometry padding, double spacing) {
    // For now, use regular grid. In a real app, you'd use flutter_staggered_grid_view
    return _buildFixedGrid(context, padding, spacing);
  }
  
  Widget _buildProductCard(Product product, int index) {
    final isWishlisted = widget.wishlistedProducts.contains(product.id);
    
    return ProductCard(
      product: product,
      style: widget.cardStyle,
      isWishlisted: isWishlisted,
      enableGlassmorphism: widget.enableGlassmorphism,
      onTap: () => widget.onProductTap?.call(product),
      onWishlistTap: () => widget.onWishlistTap?.call(product),
      onAddToCart: () => widget.onAddToCart?.call(product),
      onQuickView: () => widget.onQuickView?.call(product),
      heroTag: 'product_${product.id}_$index',
    );
  }
  
  Widget _buildLoadingIndicator() {
    return const Center(
      child: LoadingStates(
        type: LoadingType.shimmer,
        size: LoadingSize.medium,
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    if (widget.emptyWidget != null) {
      return widget.emptyWidget!;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.spacingL),
          Text(
            widget.emptyMessage ?? 'No products found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: AppConstants.spacingM),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _SortOptionsBottomSheet(
        currentOption: widget.sortOption,
        onOptionSelected: (option) {
          widget.onSortChanged?.call(option);
          Navigator.pop(context);
        },
      ),
    );
  }
  
  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterOptionsBottomSheet(
        currentFilters: widget.filters ?? {},
        onFiltersChanged: (filters) {
          widget.onFiltersChanged?.call(filters);
          Navigator.pop(context);
        },
      ),
    );
  }
  
  String _getSortOptionText(ProductSortOption option) {
    switch (option) {
      case ProductSortOption.priceAsc:
        return 'Price: Low to High';
      case ProductSortOption.priceDesc:
        return 'Price: High to Low';
      case ProductSortOption.nameAsc:
        return 'Name: A to Z';
      case ProductSortOption.nameDesc:
        return 'Name: Z to A';
      case ProductSortOption.ratingDesc:
        return 'Highest Rated';
      case ProductSortOption.newest:
        return 'Newest First';
      case ProductSortOption.none:
      default:
        return 'Sort';
    }
  }
}

/// Product grid layouts enumeration
enum ProductGridLayout {
  grid,
  list,
  responsiveGrid,
  staggered,
}

/// Product sort options enumeration
enum ProductSortOption {
  none,
  priceAsc,
  priceDesc,
  nameAsc,
  nameDesc,
  ratingDesc,
  newest,
}

/// Sort options bottom sheet
class _SortOptionsBottomSheet extends StatelessWidget {
  final ProductSortOption currentOption;
  final Function(ProductSortOption) onOptionSelected;
  
  const _SortOptionsBottomSheet({
    required this.currentOption,
    required this.onOptionSelected,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort By',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppConstants.spacingL),
          ...ProductSortOption.values.map((option) {
            return RadioListTile<ProductSortOption>(
              title: Text(_getSortOptionText(option)),
              value: option,
              groupValue: currentOption,
              onChanged: (value) {
                if (value != null) {
                  onOptionSelected(value);
                }
              },
            );
          }),
          const SizedBox(height: AppConstants.spacingL),
        ],
      ),
    );
  }
  
  String _getSortOptionText(ProductSortOption option) {
    switch (option) {
      case ProductSortOption.priceAsc:
        return 'Price: Low to High';
      case ProductSortOption.priceDesc:
        return 'Price: High to Low';
      case ProductSortOption.nameAsc:
        return 'Name: A to Z';
      case ProductSortOption.nameDesc:
        return 'Name: Z to A';
      case ProductSortOption.ratingDesc:
        return 'Highest Rated';
      case ProductSortOption.newest:
        return 'Newest First';
      case ProductSortOption.none:
      default:
        return 'Default';
    }
  }
}

/// Filter options bottom sheet
class _FilterOptionsBottomSheet extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onFiltersChanged;
  
  const _FilterOptionsBottomSheet({
    required this.currentFilters,
    required this.onFiltersChanged,
  });
  
  @override
  State<_FilterOptionsBottomSheet> createState() => _FilterOptionsBottomSheetState();
}

class _FilterOptionsBottomSheetState extends State<_FilterOptionsBottomSheet> {
  late Map<String, dynamic> _filters;
  
  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextButton(
                onPressed: () {
                  setState(() => _filters.clear());
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPriceRangeFilter(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildCategoryFilter(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildRatingFilter(),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildAvailabilityFilter(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onFiltersChanged(_filters),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPriceRangeFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppConstants.spacingM),
        RangeSlider(
          values: RangeValues(
            (_filters['minPrice'] as double?) ?? 0.0,
            (_filters['maxPrice'] as double?) ?? 1000.0,
          ),
          min: 0.0,
          max: 1000.0,
          divisions: 20,
          labels: RangeLabels(
            '\$${(_filters['minPrice'] as double?) ?? 0.0}',
            '\$${(_filters['maxPrice'] as double?) ?? 1000.0}',
          ),
          onChanged: (values) {
            setState(() {
              _filters['minPrice'] = values.start;
              _filters['maxPrice'] = values.end;
            });
          },
        ),
      ],
    );
  }
  
  Widget _buildCategoryFilter() {
    final categories = ['Fashion', 'Electronics', 'Sports', 'Home', 'Beauty'];
    final selectedCategories = (_filters['categories'] as List<String>?) ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppConstants.spacingM),
        ...categories.map((category) {
          return CheckboxListTile(
            title: Text(category),
            value: selectedCategories.contains(category),
            onChanged: (checked) {
              setState(() {
                final newCategories = List<String>.from(selectedCategories);
                if (checked == true) {
                  newCategories.add(category);
                } else {
                  newCategories.remove(category);
                }
                _filters['categories'] = newCategories;
              });
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildRatingFilter() {
    final minRating = (_filters['minRating'] as double?) ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppConstants.spacingM),
        Slider(
          value: minRating,
          min: 0.0,
          max: 5.0,
          divisions: 10,
          label: '${minRating.toStringAsFixed(1)} stars',
          onChanged: (value) {
            setState(() => _filters['minRating'] = value);
          },
        ),
      ],
    );
  }
  
  Widget _buildAvailabilityFilter() {
    return CheckboxListTile(
      title: const Text('In Stock Only'),
      value: (_filters['inStockOnly'] as bool?) ?? false,
      onChanged: (checked) {
        setState(() => _filters['inStockOnly'] = checked ?? false);
      },
    );
  }
}