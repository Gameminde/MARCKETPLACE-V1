import 'package:flutter/material.dart';

import '../models/wishlist.dart';
import '../widgets/wishlist_component.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/particle_background.dart';

/// Sample wishlist demo screen demonstrating WishlistComponent usage
class WishlistDemoScreen extends StatefulWidget {
  const WishlistDemoScreen({super.key});

  @override
  State<WishlistDemoScreen> createState() => _WishlistDemoScreenState();
}

class _WishlistDemoScreenState extends State<WishlistDemoScreen> {
  final List<WishlistItem> _wishlistItems = MockWishlist.sampleWishlist.items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.detail(
        title: 'Wishlist Demo',
      ),
      body: ParticleBackground.subtle(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Grid style (default)
              WishlistComponent.grid(
                items: _wishlistItems,
                title: 'My Wishlist (Grid)',
                onItemTap: (item) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tapped: ${item.product.name}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onRemoveItem: (itemId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Item removed from wishlist'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onAddToCart: (product) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // List style
              WishlistComponent.list(
                items: _wishlistItems.take(2).toList(),
                title: 'Wishlist (List Style)',
                onItemTap: (item) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Tapped: ${item.product.name}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onRemoveItem: (itemId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Item removed from wishlist'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onAddToCart: (product) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Carousel style
              WishlistComponent(
                items: _wishlistItems,
                style: WishlistDisplayStyle.carousel,
                title: 'Recent Favorites',
                maxItems: 5,
                onRemoveItem: (itemId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Item removed from wishlist'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                onAddToCart: (product) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Compact style
              WishlistComponent(
                items: _wishlistItems,
                style: WishlistDisplayStyle.compact,
                title: 'Quick View',
                maxItems: 3,
                shrinkWrap: true,
                onRemoveItem: (itemId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Item removed from wishlist'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Loading state example
              const WishlistComponent(
                items: [],
                title: 'Loading Wishlist',
                isLoading: true,
              ),
              
              const SizedBox(height: 24),
              
              // Empty state example
              const WishlistComponent(
                items: [],
                title: 'Empty Wishlist',
                emptyMessage: 'No items in your wishlist yet. Start shopping!',
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}