import 'package:flutter/material.dart';

import '../core/config/app_constants.dart';
import '../models/wishlist.dart';
import '../models/product.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';
import '../widgets/product_card.dart';

/// Comprehensive wishlist component with multiple display styles
class WishlistComponent extends StatefulWidget {
  final List<WishlistItem> items;
  final Function(WishlistItem)? onItemTap;
  final Function(String)? onRemoveItem;
  final Function(Product)? onAddToCart;
  final Function(Product)? onProductTap;
  final WishlistDisplayStyle style;
  final bool showTitle;
  final String title;
  final bool enableGlassmorphism;
  final bool isLoading;
  final String? emptyMessage;
  final bool shrinkWrap;
  final int? maxItems;
  
  const WishlistComponent({
    super.key,
    required this.items,
    this.onItemTap,
    this.onRemoveItem,
    this.onAddToCart,
    this.onProductTap,
    this.style = WishlistDisplayStyle.grid,
    this.showTitle = true,
    this.title = 'Wishlist',
    this.enableGlassmorphism = true,
    this.isLoading = false,
    this.emptyMessage,
    this.shrinkWrap = false,
    this.maxItems,
  });

  /// Factory constructor for grid display
  factory WishlistComponent.grid({
    Key? key,
    required List<WishlistItem> items,
    Function(WishlistItem)? onItemTap,
    Function(String)? onRemoveItem,
    Function(Product)? onAddToCart,
    bool showTitle = true,
    String title = 'My Wishlist',
  }) {
    return WishlistComponent(
      key: key,
      items: items,
      onItemTap: onItemTap,
      onRemoveItem: onRemoveItem,
      onAddToCart: onAddToCart,
      style: WishlistDisplayStyle.grid,
      showTitle: showTitle,
      title: title,
      shrinkWrap: true,
    );
  }

  /// Factory constructor for list display
  factory WishlistComponent.list({
    Key? key,
    required List<WishlistItem> items,
    Function(WishlistItem)? onItemTap,
    Function(String)? onRemoveItem,
    Function(Product)? onAddToCart,
    bool showTitle = true,
    String title = 'My Wishlist',
  }) {
    return WishlistComponent(
      key: key,
      items: items,
      onItemTap: onItemTap,
      onRemoveItem: onRemoveItem,
      onAddToCart: onAddToCart,
      style: WishlistDisplayStyle.list,
      showTitle: showTitle,
      title: title,
      shrinkWrap: true,
    );
  }

  @override
  State<WishlistComponent> createState() => _WishlistComponentState();
}

class _WishlistComponentState extends State<WishlistComponent> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState(context);
    }
    
    if (widget.items.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) _buildHeader(context),
        _buildContent(context),
      ],
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingS,
              vertical: AppConstants.spacingXS,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            child: Text(
              '${widget.items.length}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    switch (widget.style) {
      case WishlistDisplayStyle.grid:
        return _buildGridContent(context);
      case WishlistDisplayStyle.list:
        return _buildListContent(context);
      case WishlistDisplayStyle.carousel:
        return _buildCarouselContent(context);
      case WishlistDisplayStyle.compact:
        return _buildCompactContent(context);
    }
  }
  
  Widget _buildGridContent(BuildContext context) {
    final displayItems = widget.maxItems != null 
        ? widget.items.take(widget.maxItems!).toList()
        : widget.items;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: GridView.builder(
        shrinkWrap: widget.shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: AppConstants.spacingM,
          crossAxisSpacing: AppConstants.spacingM,
          childAspectRatio: 0.75,
        ),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return ProductCard.grid(
            product: item.product,
            isWishlisted: true,
            onTap: () => widget.onProductTap?.call(item.product),
            onWishlistTap: () => widget.onRemoveItem?.call(item.id),
            onAddToCart: () => widget.onAddToCart?.call(item.product),
            enableGlassmorphism: widget.enableGlassmorphism,
          );
        },
      ),
    );
  }
  
  Widget _buildListContent(BuildContext context) {
    final displayItems = widget.maxItems != null 
        ? widget.items.take(widget.maxItems!).toList()
        : widget.items;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: ListView.builder(
        shrinkWrap: widget.shrinkWrap,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
            child: widget.enableGlassmorphism
                ? GlassmorphicContainer.card(
                    child: _buildListItemContent(context, item),
                  )
                : Card(
                    child: _buildListItemContent(context, item),
                  ),
          );
        },
      ),
    );
  }
  
  Widget _buildCarouselContent(BuildContext context) {
    final displayItems = widget.maxItems != null 
        ? widget.items.take(widget.maxItems!).toList()
        : widget.items;
    
    return Container(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: AppConstants.spacingM),
            child: ProductCard.grid(
              product: item.product,
              isWishlisted: true,
              onTap: () => widget.onProductTap?.call(item.product),
              onWishlistTap: () => widget.onRemoveItem?.call(item.id),
              onAddToCart: () => widget.onAddToCart?.call(item.product),
              enableGlassmorphism: widget.enableGlassmorphism,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildCompactContent(BuildContext context) {
    final displayItems = widget.maxItems != null 
        ? widget.items.take(widget.maxItems!).toList()
        : widget.items;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
      child: Column(
        children: displayItems.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
            padding: const EdgeInsets.all(AppConstants.spacingS),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.product.category),
                    size: 20,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '\$${item.product.price.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => widget.onRemoveItem?.call(item.id),
                  icon: const Icon(Icons.close),
                  iconSize: 16,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildListItemContent(BuildContext context, WishlistItem item) {
    return ListTile(
      onTap: () => widget.onItemTap?.call(item),
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Icon(
          _getCategoryIcon(item.product.category),
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        item.product.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$${item.product.price.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Added ${item.addedDateFormatted}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => widget.onAddToCart?.call(item.product),
            icon: const Icon(Icons.add_shopping_cart),
          ),
          IconButton(
            onPressed: () => widget.onRemoveItem?.call(item.id),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: 200,
      child: const Center(
        child: LoadingStates(
          type: LoadingType.spinner,
          size: LoadingSize.medium,
          message: 'Loading wishlist...',
        ),
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConstants.spacingM),
            Text(
              widget.emptyMessage ?? 'Your wishlist is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              'Start adding products you love!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
      default:
        return Icons.shopping_bag;
    }
  }
}

/// Wishlist display styles
enum WishlistDisplayStyle {
  grid,
  list,
  carousel,
  compact,
}