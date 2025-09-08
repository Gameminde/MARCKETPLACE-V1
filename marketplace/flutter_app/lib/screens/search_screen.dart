import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../core/config/app_constants.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../providers/search_provider.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';
import '../widgets/product_card.dart';
import '../widgets/category_section.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/particle_background.dart';

/// Advanced search screen with AI-powered search functionality
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final Category? initialCategory;
  final SearchType? initialSearchType;

  const SearchScreen({
    super.key,
    this.initialQuery,
    this.initialCategory,
    this.initialSearchType,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _animationController;
  
  Timer? _debounceTimer;
  bool _showFilters = false;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Initialize search if there's an initial query
    if (widget.initialQuery?.isNotEmpty == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final searchProvider = Provider.of<SearchProvider>(context, listen: false);
        searchProvider.search(widget.initialQuery!, immediate: true);
      });
    }
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.search(
        searchController: _searchController,
        searchHint: 'Search products, brands, categories...',
        onSearchChanged: _handleSearchChanged,
        onNotificationTap: () {
          // Handle notifications
        },
        hasNotifications: true,
      ),
      body: ParticleBackground.subtle(
        child: Consumer<SearchProvider>(
          builder: (context, searchProvider, child) {
            return Column(
              children: [
                // Search controls
                _buildSearchControls(context, searchProvider),
                
                // Search results content
                Expanded(
                  child: _buildSearchContent(context, searchProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildSearchControls(BuildContext context, SearchProvider searchProvider) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          )),
          child: child,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          children: [
            // Search type selection
            _buildSearchTypeSelector(context, searchProvider),
            
            const SizedBox(height: AppConstants.spacingM),
            
            // Filter controls
            _buildFilterControls(context, searchProvider),
            
            // Basic filters panel
            if (_showFilters)
              _buildBasicFiltersPanel(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchTypeSelector(BuildContext context, SearchProvider searchProvider) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: SearchType.values.map((type) {
            final isSelected = searchProvider.currentSearchType == type;
            return GestureDetector(
              onTap: () => _handleSearchTypeChanged(searchProvider, type),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: isSelected
                      ? Border.all(color: Theme.of(context).colorScheme.primary)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getSearchTypeIcon(type),
                      size: 20,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    Text(
                      _getSearchTypeName(type),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget _buildFilterControls(BuildContext context, SearchProvider searchProvider) {
    return Row(
      children: [
        // Filter toggle button
        Expanded(
          child: GlassmorphicContainer.button(
            onTap: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showFilters ? Icons.filter_list_off : Icons.filter_list,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.spacingS),
                Text('Filters'),
                if (searchProvider.hasActiveFilters) ...[
                  const SizedBox(width: AppConstants.spacingS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacingS,
                      vertical: AppConstants.spacingXS,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    child: Text(
                      'Active',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        const SizedBox(width: AppConstants.spacingS),
        
        // Sort button
        GlassmorphicContainer.button(
          onTap: () => _showSortOptions(context, searchProvider),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sort,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingXS),
              Text(_getSortName(searchProvider.sortBy)),
            ],
          ),
        ),
        
        const SizedBox(width: AppConstants.spacingS),
        
        // AI suggestions button
        GlassmorphicContainer.button(
          onTap: () => _showAISuggestions(context, searchProvider),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppConstants.spacingXS),
              Text(
                'AI',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBasicFiltersPanel(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: AppConstants.spacingM),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'Advanced filtering options will be available in the next version. For now, use the search bar and categories to find products.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFilters = false;
                    });
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSearchContent(BuildContext context, SearchProvider searchProvider) {
    if (_searchController.text.isEmpty) {
      return _buildEmptySearchState(context, searchProvider);
    }
    
    if (searchProvider.isLoading) {
      return _buildLoadingState(context);
    }
    
    if (searchProvider.searchResults.isEmpty) {
      return _buildNoResultsState(context, searchProvider);
    }
    
    return _buildSearchResults(context, searchProvider);
  }
  
  Widget _buildEmptySearchState(BuildContext context, SearchProvider searchProvider) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Popular categories
          CategorySection.chips(
            categories: MockCategories.featuredCategories,
            title: 'Popular Categories',
            onCategoryTap: (category) {
              _searchController.text = category.displayName;
              _handleSearchChanged(category.displayName);
            },
          ),
          
          const SizedBox(height: AppConstants.spacingL),
          
          // Search history
          if (searchProvider.searchHistory.isNotEmpty)
            _buildSearchHistory(context, searchProvider),
          
          const SizedBox(height: AppConstants.spacingL),
          
          // Trending searches
          _buildTrendingSearches(context),
        ],
      ),
    );
  }
  
  Widget _buildSearchHistory(BuildContext context, SearchProvider searchProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Clear search history
                },
                child: Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          ...searchProvider.searchHistory.take(5).map((query) {
            return ListTile(
              leading: const Icon(Icons.history),
              title: Text(query),
              trailing: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  // Remove from history
                },
              ),
              onTap: () {
                _searchController.text = query;
                _handleSearchChanged(query);
              },
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildTrendingSearches(BuildContext context) {
    final trendingSearches = [
      'wireless headphones',
      'gaming laptop',
      'smart watch',
      'running shoes',
      'coffee maker',
    ];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trending Searches',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.spacingM),
          Wrap(
            spacing: AppConstants.spacingS,
            runSpacing: AppConstants.spacingS,
            children: trendingSearches.map((search) {
              return GlassmorphicContainer.chip(
                onTap: () {
                  _searchController.text = search;
                  _handleSearchChanged(search);
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.spacingXS),
                    Text(search),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: LoadingStates(
        type: LoadingType.shimmer,
        size: LoadingSize.large,
        message: 'Searching products...',
      ),
    );
  }
  
  Widget _buildNoResultsState(BuildContext context, SearchProvider searchProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'No results found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Try different keywords or categories',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingL),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {});
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults(BuildContext context, SearchProvider searchProvider) {
    return Column(
      children: [
        // Results summary
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${searchProvider.searchResults.length} results for "${searchProvider.currentQuery}"',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (searchProvider.searchResults.length > 1)
                IconButton(
                  onPressed: () {
                    // Toggle grid/list view
                  },
                  icon: const Icon(Icons.view_module),
                ),
            ],
          ),
        ),
        
        // Results grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppConstants.spacingM,
              crossAxisSpacing: AppConstants.spacingM,
              childAspectRatio: 0.75,
            ),
            itemCount: searchProvider.searchResults.length,
            itemBuilder: (context, index) {
              final product = searchProvider.searchResults[index];
              return ProductCard.grid(
                product: product,
                onTap: () {
                  // Navigate to product detail
                },
                onWishlistTap: () {
                  // Toggle wishlist
                },
                onAddToCart: () {
                  // Add to cart
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  void _handleSearchChanged(String query) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) return;
    
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final searchProvider = Provider.of<SearchProvider>(context, listen: false);
      searchProvider.search(query, immediate: true);
    });
  }
  
  void _handleSearchTypeChanged(SearchProvider searchProvider, SearchType type) {
    switch (type) {
      case SearchType.voice:
        searchProvider.voiceSearch();
        break;
      case SearchType.visual:
        // Would open camera/gallery picker
        break;
      case SearchType.ai:
        if (_searchController.text.isNotEmpty) {
          searchProvider.aiSearch(_searchController.text);
        }
        break;
      default:
        if (_searchController.text.isNotEmpty) {
          searchProvider.search(_searchController.text, immediate: true);
        }
        break;
    }
  }
  
  void _showSortOptions(BuildContext context, SearchProvider searchProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort Results',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              ...SearchSortBy.values.map((sortBy) {
                return ListTile(
                  title: Text(_getSortName(sortBy)),
                  leading: Radio<SearchSortBy>(
                    value: sortBy,
                    groupValue: searchProvider.sortBy,
                    onChanged: (value) {
                      if (value != null) {
                        // Note: SearchProvider doesn't have setSortBy method
                        // This would need to be implemented in the provider
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
  
  void _showAISuggestions(BuildContext context, SearchProvider searchProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppConstants.spacingS),
                  Text(
                    'AI Suggestions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.spacingM),
              ...searchProvider.suggestions.take(5).map((suggestion) {
                return ListTile(
                  leading: const Icon(Icons.lightbulb_outline),
                  title: Text(suggestion.text),
                  onTap: () {
                    _searchController.text = suggestion.text;
                    _handleSearchChanged(suggestion.text);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
  
  IconData _getSearchTypeIcon(SearchType type) {
    switch (type) {
      case SearchType.text:
        return Icons.text_fields;
      case SearchType.voice:
        return Icons.mic;
      case SearchType.visual:
        return Icons.camera_alt;
      case SearchType.barcode:
        return Icons.qr_code_scanner;
      case SearchType.ai:
        return Icons.auto_awesome;
    }
  }
  
  String _getSearchTypeName(SearchType type) {
    switch (type) {
      case SearchType.text:
        return 'Text';
      case SearchType.voice:
        return 'Voice';
      case SearchType.visual:
        return 'Visual';
      case SearchType.barcode:
        return 'Barcode';
      case SearchType.ai:
        return 'AI';
    }
  }
  
  String _getSortName(SearchSortBy sortBy) {
    switch (sortBy) {
      case SearchSortBy.relevance:
        return 'Relevance';
      case SearchSortBy.priceAsc:
        return 'Price: Low to High';
      case SearchSortBy.priceDesc:
        return 'Price: High to Low';
      case SearchSortBy.ratingDesc:
        return 'Highest Rated';
      case SearchSortBy.newest:
        return 'Newest';
      case SearchSortBy.popularity:
        return 'Most Popular';
    }
  }
}