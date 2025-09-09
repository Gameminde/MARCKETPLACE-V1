import 'package:flutter/material.dart';

import '../core/config/app_constants.dart';
import '../models/category.dart';
import '../widgets/glassmorphic_container.dart';

/// Comprehensive search filters component with multiple criteria
class SearchFilters extends StatefulWidget {
  final SearchFilterData filterData;
  final Function(SearchFilterData)? onFiltersChanged;
  final Function()? onResetFilters;
  final bool enableGlassmorphism;
  final bool showTitle;
  final String title;
  final SearchFilterStyle style;
  final bool expanded;
  final EdgeInsetsGeometry? padding;
  final List<String> availableBrands;
  final List<Category> availableCategories;
  final double minPrice;
  final double maxPrice;

  const SearchFilters({
    super.key,
    required this.filterData,
    this.onFiltersChanged,
    this.onResetFilters,
    this.enableGlassmorphism = true,
    this.showTitle = true,
    this.title = 'Filters',
    this.style = SearchFilterStyle.panel,
    this.expanded = false,
    this.padding,
    this.availableBrands = const [],
    this.availableCategories = const [],
    this.minPrice = 0.0,
    this.maxPrice = 1000.0,
  });

  /// Factory constructor for bottom sheet style
  factory SearchFilters.bottomSheet({
    Key? key,
    required SearchFilterData filterData,
    Function(SearchFilterData)? onFiltersChanged,
    Function()? onResetFilters,
    List<String> availableBrands = const [],
    List<Category> availableCategories = const [],
    double minPrice = 0.0,
    double maxPrice = 1000.0,
  }) {
    return SearchFilters(
      key: key,
      filterData: filterData,
      onFiltersChanged: onFiltersChanged,
      onResetFilters: onResetFilters,
      style: SearchFilterStyle.bottomSheet,
      availableBrands: availableBrands,
      availableCategories: availableCategories,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  /// Factory constructor for sidebar style
  factory SearchFilters.sidebar({
    Key? key,
    required SearchFilterData filterData,
    Function(SearchFilterData)? onFiltersChanged,
    Function()? onResetFilters,
    List<String> availableBrands = const [],
    List<Category> availableCategories = const [],
    double minPrice = 0.0,
    double maxPrice = 1000.0,
  }) {
    return SearchFilters(
      key: key,
      filterData: filterData,
      onFiltersChanged: onFiltersChanged,
      onResetFilters: onResetFilters,
      style: SearchFilterStyle.sidebar,
      expanded: true,
      availableBrands: availableBrands,
      availableCategories: availableCategories,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  @override
  State<SearchFilters> createState() => _SearchFiltersState();
}

class _SearchFiltersState extends State<SearchFilters>
    with TickerProviderStateMixin {
  late SearchFilterData _filterData;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _filterData = widget.filterData.copyWith();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    if (widget.expanded) {
      _animationController.forward();
    }
  }
  
  @override
  void didUpdateWidget(SearchFilters oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterData != widget.filterData) {
      setState(() {
        _filterData = widget.filterData.copyWith();
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case SearchFilterStyle.bottomSheet:
        return _buildBottomSheetStyle(context);
      case SearchFilterStyle.sidebar:
        return _buildSidebarStyle(context);
      case SearchFilterStyle.panel:
      default:
        return _buildPanelStyle(context);
    }
  }
  
  Widget _buildBottomSheetStyle(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(context),
          
          // Filters content
          Flexible(
            child: SingleChildScrollView(
              padding: widget.padding ?? const EdgeInsets.all(AppConstants.spacingM),
              child: _buildFiltersContent(context),
            ),
          ),
          
          // Actions
          _buildActions(context),
        ],
      ),
    );
  }
  
  Widget _buildSidebarStyle(BuildContext context) {
    return Container(
      width: 300,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),
          
          // Filters content
          Expanded(
            child: SingleChildScrollView(
              padding: widget.padding ?? const EdgeInsets.all(AppConstants.spacingM),
              child: _buildFiltersContent(context),
            ),
          ),
          
          // Actions
          _buildActions(context),
        ],
      ),
    );
  }
  
  Widget _buildPanelStyle(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) _buildHeader(context),
        _buildFiltersContent(context),
        _buildActions(context),
      ],
    );
    
    if (widget.enableGlassmorphism) {
      return GlassmorphicContainer.card(
        padding: widget.padding,
        child: content,
      );
    }
    
    return Container(
      padding: widget.padding ?? const EdgeInsets.all(AppConstants.spacingM),
      child: content,
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_filterData.hasActiveFilters)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingS,
                vertical: AppConstants.spacingXS,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Text(
                '${_filterData.activeFilterCount}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFiltersContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Price range filter
        _buildPriceRangeFilter(context),
        
        const SizedBox(height: AppConstants.spacingL),
        
        // Category filter
        if (widget.availableCategories.isNotEmpty)
          _buildCategoryFilter(context),
        
        const SizedBox(height: AppConstants.spacingL),
        
        // Brand filter
        if (widget.availableBrands.isNotEmpty)
          _buildBrandFilter(context),
        
        const SizedBox(height: AppConstants.spacingL),
        
        // Rating filter
        _buildRatingFilter(context),
        
        const SizedBox(height: AppConstants.spacingL),
        
        // Quick filters
        _buildQuickFilters(context),
        
        const SizedBox(height: AppConstants.spacingL),
        
        // Sort options
        _buildSortOptions(context),
      ],
    );
  }
  
  Widget _buildPriceRangeFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        // Price range slider
        RangeSlider(
          values: RangeValues(
            _filterData.minPrice,
            _filterData.maxPrice,
          ),
          min: widget.minPrice,
          max: widget.maxPrice,
          divisions: 20,
          labels: RangeLabels(
            '\$${_filterData.minPrice.round()}',
            '\$${_filterData.maxPrice.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _filterData = _filterData.copyWith(
                minPrice: values.start,
                maxPrice: values.end,
              );
            });
            _notifyFiltersChanged();
          },
        ),
        
        // Price range text inputs
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _filterData.minPrice.round().toString(),
                decoration: InputDecoration(
                  labelText: 'Min Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null && price >= widget.minPrice && price <= _filterData.maxPrice) {
                    setState(() {
                      _filterData = _filterData.copyWith(minPrice: price);
                    });
                    _notifyFiltersChanged();
                  }
                },
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: TextFormField(
                initialValue: _filterData.maxPrice.round().toString(),
                decoration: InputDecoration(
                  labelText: 'Max Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
                  ),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null && price <= widget.maxPrice && price >= _filterData.minPrice) {
                    setState(() {
                      _filterData = _filterData.copyWith(maxPrice: price);
                    });
                    _notifyFiltersChanged();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildCategoryFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Categories',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        // Category chips
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: widget.availableCategories.map((category) {
            final isSelected = _filterData.selectedCategories.contains(category.id);
            return FilterChip(
              label: Text(category.displayName),
              avatar: Icon(
                category.icon,
                size: 16,
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary
                    : category.categoryColor,
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _filterData = _filterData.copyWith(
                      selectedCategories: [..._filterData.selectedCategories, category.id],
                    );
                  } else {
                    _filterData = _filterData.copyWith(
                      selectedCategories: _filterData.selectedCategories
                          .where((id) => id != category.id)
                          .toList(),
                    );
                  }
                });
                _notifyFiltersChanged();
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildBrandFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brands',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        // Brand search
        TextFormField(
          decoration: InputDecoration(
            hintText: 'Search brands...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.inputBorderRadius),
            ),
          ),
          onChanged: (value) {
            // Filter brands based on search
          },
        ),
        
        const SizedBox(height: AppConstants.spacingM),
        
        // Brand list
        ...widget.availableBrands.take(10).map((brand) {
          final isSelected = _filterData.selectedBrands.contains(brand);
          return CheckboxListTile(
            title: Text(brand),
            value: isSelected,
            onChanged: (selected) {
              setState(() {
                if (selected == true) {
                  _filterData = _filterData.copyWith(
                    selectedBrands: [..._filterData.selectedBrands, brand],
                  );
                } else {
                  _filterData = _filterData.copyWith(
                    selectedBrands: _filterData.selectedBrands
                        .where((b) => b != brand)
                        .toList(),
                  );
                }
              });
              _notifyFiltersChanged();
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildRatingFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Minimum Rating',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        Row(
          children: List.generate(5, (index) {
            final rating = index + 1;
            final isSelected = _filterData.minRating >= rating;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _filterData = _filterData.copyWith(
                    minRating: rating.toDouble(),
                  );
                });
                _notifyFiltersChanged();
              },
              child: Container(
                padding: const EdgeInsets.all(AppConstants.spacingS),
                child: Icon(
                  isSelected ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
            );
          }),
        ),
        
        if (_filterData.minRating > 0)
          Text(
            '${_filterData.minRating.toInt()} stars and above',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
  
  Widget _buildQuickFilters(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Filters',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        Wrap(
          spacing: AppConstants.spacingS,
          runSpacing: AppConstants.spacingS,
          children: [
            FilterChip(
              label: const Text('In Stock'),
              selected: _filterData.inStockOnly,
              onSelected: (selected) {
                setState(() {
                  _filterData = _filterData.copyWith(inStockOnly: selected);
                });
                _notifyFiltersChanged();
              },
            ),
            FilterChip(
              label: const Text('On Sale'),
              selected: _filterData.onSaleOnly,
              onSelected: (selected) {
                setState(() {
                  _filterData = _filterData.copyWith(onSaleOnly: selected);
                });
                _notifyFiltersChanged();
              },
            ),
            FilterChip(
              label: const Text('Free Shipping'),
              selected: _filterData.freeShippingOnly,
              onSelected: (selected) {
                setState(() {
                  _filterData = _filterData.copyWith(freeShippingOnly: selected);
                });
                _notifyFiltersChanged();
              },
            ),
            FilterChip(
              label: const Text('New Arrivals'),
              selected: _filterData.newArrivalsOnly,
              onSelected: (selected) {
                setState(() {
                  _filterData = _filterData.copyWith(newArrivalsOnly: selected);
                });
                _notifyFiltersChanged();
              },
            ),
            FilterChip(
              label: const Text('Best Sellers'),
              selected: _filterData.bestSellersOnly,
              onSelected: (selected) {
                setState(() {
                  _filterData = _filterData.copyWith(bestSellersOnly: selected);
                });
                _notifyFiltersChanged();
              },
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSortOptions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort By',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        
        ...SearchSortOption.values.map((option) {
          return RadioListTile<SearchSortOption>(
            title: Text(_getSortOptionName(option)),
            value: option,
            groupValue: _filterData.sortBy,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _filterData = _filterData.copyWith(sortBy: value);
                });
                _notifyFiltersChanged();
              }
            },
          );
        }),
      ],
    );
  }
  
  Widget _buildActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _filterData.hasActiveFilters ? _resetFilters : null,
              icon: const Icon(Icons.clear),
              label: const Text('Reset'),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onFiltersChanged?.call(_filterData);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: Text('Apply ${_filterData.hasActiveFilters ? '(${_filterData.activeFilterCount})' : ''}'),
            ),
          ),
        ],
      ),
    );
  }
  
  void _resetFilters() {
    setState(() {
      _filterData = const SearchFilterData();
    });
    widget.onResetFilters?.call();
    _notifyFiltersChanged();
  }
  
  void _notifyFiltersChanged() {
    widget.onFiltersChanged?.call(_filterData);
  }
  
  String _getSortOptionName(SearchSortOption option) {
    switch (option) {
      case SearchSortOption.relevance:
        return 'Relevance';
      case SearchSortOption.priceAsc:
        return 'Price: Low to High';
      case SearchSortOption.priceDesc:
        return 'Price: High to Low';
      case SearchSortOption.ratingDesc:
        return 'Highest Rated';
      case SearchSortOption.newest:
        return 'Newest First';
      case SearchSortOption.popularity:
        return 'Most Popular';
      case SearchSortOption.nameAsc:
        return 'Name: A to Z';
      case SearchSortOption.nameDesc:
        return 'Name: Z to A';
    }
  }
}

/// Search filter data model
class SearchFilterData {
  final double minPrice;
  final double maxPrice;
  final List<String> selectedCategories;
  final List<String> selectedBrands;
  final double minRating;
  final bool inStockOnly;
  final bool onSaleOnly;
  final bool freeShippingOnly;
  final bool newArrivalsOnly;
  final bool bestSellersOnly;
  final SearchSortOption sortBy;

  const SearchFilterData({
    this.minPrice = 0.0,
    this.maxPrice = 1000.0,
    this.selectedCategories = const [],
    this.selectedBrands = const [],
    this.minRating = 0.0,
    this.inStockOnly = false,
    this.onSaleOnly = false,
    this.freeShippingOnly = false,
    this.newArrivalsOnly = false,
    this.bestSellersOnly = false,
    this.sortBy = SearchSortOption.relevance,
  });

  /// Check if any filters are active
  bool get hasActiveFilters {
    return minPrice > 0.0 ||
           maxPrice < 1000.0 ||
           selectedCategories.isNotEmpty ||
           selectedBrands.isNotEmpty ||
           minRating > 0.0 ||
           inStockOnly ||
           onSaleOnly ||
           freeShippingOnly ||
           newArrivalsOnly ||
           bestSellersOnly ||
           sortBy != SearchSortOption.relevance;
  }

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (minPrice > 0.0 || maxPrice < 1000.0) count++;
    if (selectedCategories.isNotEmpty) count++;
    if (selectedBrands.isNotEmpty) count++;
    if (minRating > 0.0) count++;
    if (inStockOnly) count++;
    if (onSaleOnly) count++;
    if (freeShippingOnly) count++;
    if (newArrivalsOnly) count++;
    if (bestSellersOnly) count++;
    if (sortBy != SearchSortOption.relevance) count++;
    return count;
  }

  /// Copy with modifications
  SearchFilterData copyWith({
    double? minPrice,
    double? maxPrice,
    List<String>? selectedCategories,
    List<String>? selectedBrands,
    double? minRating,
    bool? inStockOnly,
    bool? onSaleOnly,
    bool? freeShippingOnly,
    bool? newArrivalsOnly,
    bool? bestSellersOnly,
    SearchSortOption? sortBy,
  }) {
    return SearchFilterData(
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      minRating: minRating ?? this.minRating,
      inStockOnly: inStockOnly ?? this.inStockOnly,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      freeShippingOnly: freeShippingOnly ?? this.freeShippingOnly,
      newArrivalsOnly: newArrivalsOnly ?? this.newArrivalsOnly,
      bestSellersOnly: bestSellersOnly ?? this.bestSellersOnly,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchFilterData &&
           other.minPrice == minPrice &&
           other.maxPrice == maxPrice &&
           other.selectedCategories == selectedCategories &&
           other.selectedBrands == selectedBrands &&
           other.minRating == minRating &&
           other.inStockOnly == inStockOnly &&
           other.onSaleOnly == onSaleOnly &&
           other.freeShippingOnly == freeShippingOnly &&
           other.newArrivalsOnly == newArrivalsOnly &&
           other.bestSellersOnly == bestSellersOnly &&
           other.sortBy == sortBy;
  }

  @override
  int get hashCode {
    return Object.hash(
      minPrice,
      maxPrice,
      selectedCategories,
      selectedBrands,
      minRating,
      inStockOnly,
      onSaleOnly,
      freeShippingOnly,
      newArrivalsOnly,
      bestSellersOnly,
      sortBy,
    );
  }
}

/// Search filter display styles
enum SearchFilterStyle {
  panel,
  bottomSheet,
  sidebar,
}

/// Search sort options
enum SearchSortOption {
  relevance,
  priceAsc,
  priceDesc,
  ratingDesc,
  newest,
  popularity,
  nameAsc,
  nameDesc,
}