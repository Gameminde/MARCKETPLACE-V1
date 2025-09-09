import 'package:flutter/material.dart';

import '../core/config/app_constants.dart';
import '../models/product.dart';
import 'glassmorphic_container.dart';
import 'loading_states.dart';

/// Comprehensive product card widget with glassmorphic design,
/// animations, wishlist support, and various layouts
class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onWishlistTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onQuickView;
  final bool showDiscount;
  final bool showWishlist;
  final bool showAddToCart;
  final bool showQuickView;
  final bool isWishlisted;
  final ProductCardStyle style;
  final double? width;
  final double? height;
  final bool enableGlassmorphism;
  final bool enableAnimations;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final String? heroTag;
  
  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onWishlistTap,
    this.onAddToCart,
    this.onQuickView,
    this.showDiscount = true,
    this.showWishlist = true,
    this.showAddToCart = true,
    this.showQuickView = false,
    this.isWishlisted = false,
    this.style = ProductCardStyle.standard,
    this.width,
    this.height,
    this.enableGlassmorphism = true,
    this.enableAnimations = true,
    this.margin,
    this.borderRadius,
    this.heroTag,
  });

  /// Factory constructor for grid layout
  factory ProductCard.grid({
    Key? key,
    required Product product,
    VoidCallback? onTap,
    VoidCallback? onWishlistTap,
    VoidCallback? onAddToCart,
    bool isWishlisted = false,
    bool enableGlassmorphism = true,
  }) {
    return ProductCard(
      key: key,
      product: product,
      onTap: onTap,
      onWishlistTap: onWishlistTap,
      onAddToCart: onAddToCart,
      isWishlisted: isWishlisted,
      style: ProductCardStyle.grid,
      enableGlassmorphism: enableGlassmorphism,
      height: AppConstants.productCardHeight,
    );
  }

  /// Factory constructor for list layout
  factory ProductCard.list({
    Key? key,
    required Product product,
    VoidCallback? onTap,
    VoidCallback? onWishlistTap,
    VoidCallback? onAddToCart,
    bool isWishlisted = false,
    bool enableGlassmorphism = true,
  }) {
    return ProductCard(
      key: key,
      product: product,
      onTap: onTap,
      onWishlistTap: onWishlistTap,
      onAddToCart: onAddToCart,
      isWishlisted: isWishlisted,
      style: ProductCardStyle.list,
      enableGlassmorphism: enableGlassmorphism,
      height: 120,
    );
  }

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;
  final bool _isPressed = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTap() {
    if (widget.enableAnimations) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget card = _buildCardContent(context);
    
    if (widget.enableAnimations) {
      card = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: card,
      );
    }
    
    return GestureDetector(
      onTap: _handleTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          child: card,
        ),
      ),
    );
  }
  
  Widget _buildCardContent(BuildContext context) {
    switch (widget.style) {
      case ProductCardStyle.grid:
        return _buildGridCard(context);
      case ProductCardStyle.list:
        return _buildListCard(context);
      case ProductCardStyle.standard:
      default:
        return _buildStandardCard(context);
    }
  }
  
  Widget _buildStandardCard(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image section
        Expanded(
          flex: 3,
          child: _buildProductImage(context),
        ),
        // Product info section
        Expanded(
          flex: 2,
          child: _buildProductInfo(context),
        ),
      ],
    );
    
    if (widget.enableGlassmorphism) {
      return GlassmorphicContainer.card(
        child: content,
      );
    }
    
    return Card(
      elevation: _isHovered ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: content,
    );
  }
  
  Widget _buildGridCard(BuildContext context) {
    return _buildStandardCard(context);
  }
  
  Widget _buildListCard(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          // Product image
          SizedBox(
            width: 80,
            height: 80,
            child: _buildProductImage(context, isCompact: true),
          ),
          const SizedBox(width: AppConstants.spacingM),
          // Product info
          Expanded(
            child: _buildProductInfo(context, isCompact: true),
          ),
          // Actions
          if (widget.showWishlist || widget.showAddToCart)
            _buildActionButtons(context),
        ],
      ),
    );
    
    if (widget.enableGlassmorphism) {
      return GlassmorphicContainer.card(
        child: content,
      );
    }
    
    return Card(
      child: content,
    );
  }
  
  Widget _buildProductImage(BuildContext context, {bool isCompact = false}) {
    final borderRadius = widget.style == ProductCardStyle.list 
        ? BorderRadius.circular(AppConstants.borderRadius)
        : const BorderRadius.vertical(
            top: Radius.circular(AppConstants.cardBorderRadius),
          );
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: borderRadius,
      ),
      child: Stack(
        children: [
          // Main image
          ClipRRect(
            borderRadius: borderRadius,
            child: widget.product.imageUrl != null
                ? _buildNetworkImage()
                : _buildPlaceholderImage(context),
          ),
          
          // Discount badge
          if (widget.showDiscount && widget.product.isOnSale && !isCompact)
            _buildDiscountBadge(context),
          
          // Wishlist button
          if (widget.showWishlist && !isCompact)
            _buildWishlistButton(context),
          
          // Stock status
          if (!widget.product.inStock)
            _buildOutOfStockOverlay(context),
        ],
      ),
    );
  }
  
  Widget _buildNetworkImage() {
    return Image.network(
      widget.product.imageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: LoadingStates(
            type: LoadingType.shimmer,
            size: LoadingSize.small,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderImage(context);
      },
    );
  }
  
  Widget _buildPlaceholderImage(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        _getCategoryIcon(widget.product.category),
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
  
  Widget _buildDiscountBadge(BuildContext context) {
    return Positioned(
      top: AppConstants.spacingS,
      left: AppConstants.spacingS,
      child: Container(
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
    );
  }
  
  Widget _buildWishlistButton(BuildContext context) {
    return Positioned(
      top: AppConstants.spacingS,
      right: AppConstants.spacingS,
      child: GlassmorphicContainer.button(
        onTap: widget.onWishlistTap ?? () {},
        padding: const EdgeInsets.all(AppConstants.spacingS),
        child: Icon(
          widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
          size: AppConstants.iconSizeS,
          color: widget.isWishlisted 
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
  
  Widget _buildOutOfStockOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppConstants.cardBorderRadius),
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Text(
              'Out of Stock',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildProductInfo(BuildContext context, {bool isCompact = false}) {
    return Padding(
      padding: EdgeInsets.all(isCompact ? AppConstants.spacingS : AppConstants.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Product details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category
                if (!isCompact)
                  Text(
                    widget.product.category,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                if (!isCompact) const SizedBox(height: AppConstants.spacingXS),
                
                // Product name
                Text(
                  widget.product.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: isCompact ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Rating (for non-compact layouts)
                if (!isCompact && widget.product.rating > 0) ...[
                  const SizedBox(height: AppConstants.spacingXS),
                  _buildRatingRow(context),
                ],
              ],
            ),
          ),
          
          // Price and actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildPriceRow(context, isCompact: isCompact),
              ),
              if (widget.showAddToCart && !isCompact)
                _buildAddToCartButton(context),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRatingRow(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) {
          if (index < widget.product.rating.floor()) {
            return const Icon(
              Icons.star,
              size: 12,
              color: Colors.amber,
            );
          } else if (index < widget.product.rating) {
            return const Icon(
              Icons.star_half,
              size: 12,
              color: Colors.amber,
            );
          } else {
            return Icon(
              Icons.star_border,
              size: 12,
              color: Theme.of(context).colorScheme.outline,
            );
          }
        }),
        const SizedBox(width: AppConstants.spacingXS),
        Text(
          '(${widget.product.reviewCount})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPriceRow(BuildContext context, {bool isCompact = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.product.isOnSale && widget.product.originalPrice != null) ...[
          Text(
            '\$${widget.product.originalPrice!.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              decoration: TextDecoration.lineThrough,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (!isCompact) const SizedBox(height: 2),
        ],
        Text(
          '\$${widget.product.price.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: widget.product.isOnSale
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAddToCartButton(BuildContext context) {
    return GlassmorphicContainer.button(
      onTap: widget.onAddToCart ?? () {},
      child: Icon(
        Icons.add_shopping_cart,
        size: AppConstants.iconSizeS,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  
  Widget _buildActionButtons(BuildContext context) {
    final buttons = <Widget>[];
    
    if (widget.showWishlist) {
      buttons.add(
        IconButton(
          onPressed: widget.onWishlistTap,
          icon: Icon(
            widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
            color: widget.isWishlisted 
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    
    if (widget.showAddToCart) {
      buttons.add(
        IconButton(
          onPressed: widget.onAddToCart,
          icon: Icon(
            Icons.add_shopping_cart,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
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
      case 'toys':
        return Icons.toys;
      case 'automotive':
        return Icons.directions_car;
      case 'food':
        return Icons.restaurant;
      default:
        return Icons.shopping_bag;
    }
  }
}

/// Product card styles enumeration
enum ProductCardStyle {
  standard,
  grid,
  list,
}