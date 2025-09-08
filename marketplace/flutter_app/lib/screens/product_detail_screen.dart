import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../core/config/app_constants.dart';
import '../models/product.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/loading_states.dart';
import '../widgets/particle_background.dart';

/// Comprehensive product detail screen with image gallery, reviews,
/// and glassmorphic design integration
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onShare;
  final bool isWishlisted;
  final String? heroTag;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onWishlistTap,
    this.onShare,
    this.isWishlisted = false,
    this.heroTag,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late PageController _imagePageController;
  
  int _currentImageIndex = 0;
  int _selectedColorIndex = 0;
  int _selectedSizeIndex = 0;
  int _quantity = 1;
  bool _isAddingToCart = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _imagePageController = PageController();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar.detail(
        title: widget.product.name,
        actions: [
          IconButton(
            onPressed: widget.onShare,
            icon: const Icon(Icons.share),
          ),
          IconButton(
            onPressed: widget.onWishlistTap,
            icon: Icon(
              widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: widget.isWishlisted 
                  ? Theme.of(context).colorScheme.error 
                  : null,
            ),
          ),
        ],
      ),
      body: ParticleBackground.subtle(
        child: CustomScrollView(
          slivers: [
            // Image gallery
            SliverToBoxAdapter(
              child: _buildImageGallery(context),
            ),
            
            // Product info
            SliverToBoxAdapter(
              child: _buildProductInfo(context),
            ),
            
            // Tabs for details, reviews, etc.
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyTabBarDelegate(
                child: _buildTabBar(context),
              ),
            ),
            
            // Tab content
            SliverFillRemaining(
              child: _buildTabContent(context),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }
  
  Widget _buildImageGallery(BuildContext context) {
    final images = widget.product.images.isNotEmpty 
        ? widget.product.images 
        : [widget.product.imageUrl].where((e) => e != null).cast<String>().toList();
    
    if (images.isEmpty) {
      return _buildPlaceholderGallery(context);
    }
    
    return Container(
      height: 400,
      margin: const EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top,
        left: AppConstants.spacingM,
        right: AppConstants.spacingM,
        bottom: AppConstants.spacingM,
      ),
      child: GlassmorphicContainer.card(
        child: Stack(
          children: [
            // Main image viewer
            Hero(
              tag: widget.heroTag ?? 'product_${widget.product.id}',
              child: PageView.builder(
                controller: _imagePageController,
                onPageChanged: (index) {
                  setState(() => _currentImageIndex = index);
                },
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return _buildImagePage(context, images[index]);
                },
              ),
            ),
            
            // Navigation buttons
            if (images.length > 1) ...[
              _buildNavigationButton(
                context,
                Icons.chevron_left,
                () => _previousImage(images.length),
                isLeft: true,
              ),
              _buildNavigationButton(
                context,
                Icons.chevron_right,
                () => _nextImage(images.length),
                isLeft: false,
              ),
            ],
            
            // Image indicators
            if (images.length > 1)
              Positioned(
                bottom: AppConstants.spacingM,
                left: 0,
                right: 0,
                child: _buildImageIndicators(context, images.length),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImagePage(BuildContext context, String imageUrl) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const LoadingStates(
              type: LoadingType.shimmer,
              size: LoadingSize.large,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(context);
          },
        ),
      ),
    );
  }
  
  Widget _buildPlaceholderGallery(BuildContext context) {
    return Container(
      height: 400,
      margin: const EdgeInsets.only(
        top: kToolbarHeight + MediaQuery.of(context).padding.top,
        left: AppConstants.spacingM,
        right: AppConstants.spacingM,
        bottom: AppConstants.spacingM,
      ),
      child: GlassmorphicContainer.card(
        child: _buildImagePlaceholder(context),
      ),
    );
  }
  
  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        _getCategoryIcon(widget.product.category),
        size: 80,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
  
  Widget _buildNavigationButton(
    BuildContext context,
    IconData icon,
    VoidCallback onTap, {
    required bool isLeft,
  }) {
    return Positioned(
      left: isLeft ? AppConstants.spacingM : null,
      right: isLeft ? null : AppConstants.spacingM,
      top: 0,
      bottom: 0,
      child: Center(
        child: GlassmorphicContainer.button(
          onTap: onTap,
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
  
  Widget _buildImageIndicators(BuildContext context, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: index == _currentImageIndex
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
  
  Widget _buildProductInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name and category
              Text(
                widget.product.category,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppConstants.spacingXS),
              Text(
                widget.product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: AppConstants.spacingM),
              
              // Rating and reviews
              if (widget.product.rating > 0)
                _buildRatingSection(context),
              
              const SizedBox(height: AppConstants.spacingM),
              
              // Price section
              _buildPriceSection(context),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Color selection
              if (widget.product.availableColors.isNotEmpty)
                _buildColorSelection(context),
              
              // Size selection
              if (widget.product.availableSizes.isNotEmpty)
                _buildSizeSelection(context),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Quantity selector
              _buildQuantitySelector(context),
              
              const SizedBox(height: AppConstants.spacingL),
              
              // Stock status
              _buildStockStatus(context),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildRatingSection(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          if (index < widget.product.rating.floor()) {
            return const Icon(
              Icons.star,
              size: 16,
              color: Colors.amber,
            );
          } else if (index < widget.product.rating) {
            return const Icon(
              Icons.star_half,
              size: 16,
              color: Colors.amber,
            );
          } else {
            return Icon(
              Icons.star_border,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            );
          }
        }),
        const SizedBox(width: AppConstants.spacingS),
        Text(
          '${widget.product.rating}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppConstants.spacingXS),
        Text(
          '(${widget.product.reviewCount} reviews)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriceSection(BuildContext context) {
    return Row(
      children: [
        if (widget.product.isOnSale && widget.product.originalPrice != null) ...[
          Text(
            '\$${widget.product.originalPrice!.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
        ],
        Text(
          '\$${widget.product.price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: widget.product.isOnSale
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (widget.product.isOnSale) ...[
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
              '-${widget.product.discountPercentage!.round()}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onError,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildColorSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Color',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Wrap(
          spacing: AppConstants.spacingS,
          children: widget.product.availableColors.asMap().entries.map((entry) {
            final index = entry.key;
            final colorName = entry.value;
            final isSelected = index == _selectedColorIndex;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedColorIndex = index),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getColorFromName(colorName),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                    width: isSelected ? 3 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.spacingM),
      ],
    );
  }
  
  Widget _buildSizeSelection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Size',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Wrap(
          spacing: AppConstants.spacingS,
          children: widget.product.availableSizes.asMap().entries.map((entry) {
            final index = entry.key;
            final size = entry.value;
            final isSelected = index == _selectedSizeIndex;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedSizeIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  size,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppConstants.spacingM),
      ],
    );
  }
  
  Widget _buildQuantitySelector(BuildContext context) {
    return Row(
      children: [
        Text(
          'Quantity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            IconButton(
              onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
              icon: const Icon(Icons.remove),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
            ),
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
              child: Text(
                _quantity.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _quantity++),
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStockStatus(BuildContext context) {
    return Row(
      children: [
        Icon(
          widget.product.inStock ? Icons.check_circle : Icons.cancel,
          color: widget.product.inStock
              ? Colors.green
              : Theme.of(context).colorScheme.error,
          size: 20,
        ),
        const SizedBox(width: AppConstants.spacingS),
        Text(
          widget.product.inStock ? 'In Stock' : 'Out of Stock',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: widget.product.inStock
                ? Colors.green
                : Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildTabBar(BuildContext context) {
    return GlassmorphicContainer.navigation(
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Details'),
          Tab(text: 'Reviews'),
          Tab(text: 'Shipping'),
        ],
      ),
    );
  }
  
  Widget _buildTabContent(BuildContext context) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDetailsTab(context),
        _buildReviewsTab(context),
        _buildShippingTab(context),
      ],
    );
  }
  
  Widget _buildDetailsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                widget.product.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildReviewsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${widget.product.rating}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < widget.product.rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 20,
                          );
                        }),
                      ),
                      Text(
                        '${widget.product.reviewCount} reviews',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildShippingTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Shipping Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.spacingM),
              Text(
                'Standard Shipping: 5-7 business days - \$5.99',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppConstants.spacingS),
              Text(
                'Express Shipping: 2-3 business days - \$12.99',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppConstants.spacingM,
        right: AppConstants.spacingM,
        top: AppConstants.spacingM,
        bottom: AppConstants.spacingM + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onWishlistTap,
              icon: Icon(
                widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
                color: widget.isWishlisted 
                    ? Theme.of(context).colorScheme.error 
                    : null,
              ),
              label: Text(widget.isWishlisted ? 'Remove' : 'Wishlist'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: widget.product.inStock && !_isAddingToCart
                  ? () => _handleAddToCart(context)
                  : null,
              icon: _isAddingToCart
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_shopping_cart),
              label: Text(_isAddingToCart ? 'Adding...' : 'Add to Cart'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _previousImage(int imageCount) {
    if (_currentImageIndex > 0) {
      _imagePageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _nextImage(int imageCount) {
    if (_currentImageIndex < imageCount - 1) {
      _imagePageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  Future<void> _handleAddToCart(BuildContext context) async {
    setState(() => _isAddingToCart = true);
    
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1000));
    
    setState(() => _isAddingToCart = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Added to cart successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      
      widget.onAddToCart?.call();
    }
  }
  
  Color _getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fashion':
        return Icons.checkroom;
      case 'electronics':
        return Icons.devices;
      case 'computers':
        return Icons.laptop;
      case 'beauty':
        return Icons.palette;
      case 'sports':
        return Icons.sports;
      case 'home':
        return Icons.home;
      case 'books':
        return Icons.book;
      default:
        return Icons.shopping_bag;
    }
  }
}

/// Sticky tab bar delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  
  _StickyTabBarDelegate({required this.child});
  
  @override
  double get minExtent => 50;
  
  @override
  double get maxExtent => 50;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }
  
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}