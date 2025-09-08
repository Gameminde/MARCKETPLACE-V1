import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

import '../core/config/app_constants.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/particle_background.dart';
import '../widgets/loading_states.dart';
import 'checkout_screen.dart';

/// Comprehensive enhanced cart screen with glassmorphic design,
/// quantity controls, guest checkout, and multi-currency support
class CartScreen extends StatefulWidget {
  final bool enableGuestCheckout;
  final Function()? onContinueShopping;
  final Function()? onCheckoutSuccess;
  
  const CartScreen({
    super.key,
    this.enableGuestCheckout = true,
    this.onContinueShopping,
    this.onCheckoutSuccess,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isProcessingCheckout = false;
  bool _showGuestCheckoutOptions = false;
  final CurrencyService _currencyService = CurrencyService();
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar.home(
        title: 'Shopping Cart',
        onSearchTap: () {},
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, child) {
              if (cartProvider.isEmpty) return const SizedBox();
              
              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value, cartProvider),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'save_all',
                    child: Row(
                      children: [
                        Icon(Icons.favorite_border),
                        SizedBox(width: 8),
                        Text('Save all for later'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share),
                        SizedBox(width: 8),
                        Text('Share cart'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear cart'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: ParticleBackground.subtle(
        child: Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            if (cartProvider.isLoading) {
              return const Center(
                child: LoadingStates(
                  type: LoadingType.spinner,
                  size: LoadingSize.large,
                  message: 'Loading your cart...',
                ),
              );
            }
            
            if (cartProvider.isEmpty) {
              return _buildEmptyCart(context);
            }
            
            return _buildCartWithItems(context, cartProvider);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _animationController.value,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GlassmorphicContainer.card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacingXL),
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: AppConstants.spacingL),
                          Text(
                            'Your cart is empty',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.spacingM),
                          Text(
                            'Add products you love to start building your perfect order',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppConstants.spacingXL),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onContinueShopping?.call() ?? Navigator.pop(context),
                              icon: const Icon(Icons.explore),
                              label: const Text('Start Shopping'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(0, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartWithItems(BuildContext context, CartProvider cartProvider) {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.spacingM,
                  AppConstants.spacingXL + kToolbarHeight,
                  AppConstants.spacingM,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: _buildCartHeader(context, cartProvider),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingM),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = cartProvider.items[index];
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                index * 0.1,
                                (index * 0.1) + 0.5,
                                curve: Curves.easeOutCubic,
                              ),
                            )),
                            child: _buildEnhancedCartItem(context, item, cartProvider),
                          );
                        },
                      );
                    },
                    childCount: cartProvider.items.length,
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: AppConstants.spacingXL),
              ),
            ],
          ),
        ),
        _buildEnhancedCartSummary(context, cartProvider),
      ],
    );
  }
  
  Widget _buildCartHeader(BuildContext context, CartProvider cartProvider) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Icon(
                Icons.shopping_cart,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppConstants.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${cartProvider.itemCount} items in cart',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Consumer<CurrencyService>(
                    builder: (context, currency, child) {
                      return Text(
                        'Estimated total: ${currency.formatPrice(cartProvider.totalPrice)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            if (cartProvider.isGuestCheckout)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: AppConstants.spacingXS,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Text(
                  'Guest',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemCard(BuildContext context, CartItem item, CartProvider cartProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: AppConstants.defaultShadow,
      ),
      child: Row(
        children: [
          // Image du produit
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(AppConstants.smallPadding),
            ),
            child: item.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.smallPadding),
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(),
                    ),
                  )
                : _buildPlaceholderIcon(),
          ),
          const SizedBox(width: 15),
          
          // Informations du produit
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                if (item.description != null) ...[
                  Text(
                    item.description!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                ],
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppConstants.textSecondary,
                  ),
                ),
                if (item.attributes != null && item.attributes!.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    _formatAttributes(item.attributes!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppConstants.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Contrôles de quantité
          Column(
            children: [
              Row(
                children: [
                  _buildQuantityButton(
                    Icons.remove,
                    () => cartProvider.decrementQuantity(item.id),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(AppConstants.smallPadding),
                    ),
                    child: Center(
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _buildQuantityButton(
                    Icons.add,
                    () => cartProvider.incrementQuantity(item.id),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                '\$${item.totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Icon(
      Icons.shopping_bag,
      color: Colors.grey.shade400,
      size: 30,
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 35,
        height: 35,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: AppConstants.smallIconSize,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cartProvider) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.largeBorderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Save for Later
            Row(
              children: [
                Icon(Icons.favorite_border, color: Colors.grey.shade400),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  AppStrings.saveForLater,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Résumé des prix
            _buildPriceSummaryRow(
              context,
              'Subtotal (${cartProvider.itemCount} items)',
              '\$${cartProvider.totalPrice.toStringAsFixed(2)}',
            ),
            _buildPriceSummaryRow(
              context,
              'Shipping',
              cartProvider.shippingCost > 0 
                  ? '\$${cartProvider.shippingCost.toStringAsFixed(2)}'
                  : 'Free',
            ),
            _buildPriceSummaryRow(
              context,
              'Taxes',
              '\$${cartProvider.taxAmount.toStringAsFixed(2)}',
            ),
            const Divider(height: AppConstants.defaultPadding),
            
            // Total
            Text(
              '\$${cartProvider.finalTotal.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: AppConstants.largeFontSize,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            
            // Bouton Checkout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _navigateToCheckout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.warningColor,
                  foregroundColor: Colors.black,
                ),
                child: const Text(AppStrings.proceedToCheckout),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            
            // Continue Shopping
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppStrings.continueShopping,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.spacingM),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.favorite_outline,
                    label: 'Wishlist',
                    onTap: () => Navigator.pushNamed(context, '/wishlist'),
                  ),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: _buildQuickActionButton(
                    context,
                    icon: Icons.history,
                    label: 'Order History',
                    onTap: () => Navigator.pushNamed(context, '/orders'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingL,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAttributes(Map<String, dynamic> attributes) {
    return attributes.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Cart'),
          content: const Text('Are you sure you want to remove all items from your cart?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<CartProvider>().clearCart();
                Navigator.of(context).pop();
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showCartOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Save all for later'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share cart'),
                onTap: () => Navigator.pop(context),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Clear cart'),
                onTap: () {
                  Navigator.pop(context);
                  _showClearCartDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToCheckout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutScreen(),
      ),
    );
  }
}
