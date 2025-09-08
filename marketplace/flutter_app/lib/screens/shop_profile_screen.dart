import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../models/shop.dart';
import '../models/product.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';
import '../widgets/product_card.dart';
import '../widgets/product_grid.dart';

/// Shop profile screen displaying shop information with custom branding
class ShopProfileScreen extends StatefulWidget {
  final Shop shop;

  const ShopProfileScreen({super.key, required this.shop});

  @override
  State<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends State<ShopProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 200 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 200 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildCustomAppBar(),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildShopHeader(),
                _buildShopStats(),
                _buildTabContent(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActions(),
    );
  }

  Widget _buildCustomAppBar() {
    final branding = widget.shop.branding;
    
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: _isScrolled 
          ? branding.primaryColor?.withOpacity(0.9) 
          : Colors.transparent,
      elevation: _isScrolled ? 4 : 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                branding.primaryColor ?? Theme.of(context).colorScheme.primary,
                branding.secondaryColor ?? Theme.of(context).colorScheme.secondary,
              ],
            ),
          ),
          child: branding.bannerUrl != null
              ? Stack(
                  children: [
                    Image.network(
                      branding.bannerUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : null,
        ),
        title: _isScrolled
            ? Row(
                children: [
                  if (branding.logoUrl != null)
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(branding.logoUrl!),
                    )
                  else
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: branding.accentColor,
                      child: Text(
                        widget.shop.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.shop.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : null,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareShop,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'follow',
              child: Row(
                children: [
                  Icon(Icons.favorite_border),
                  SizedBox(width: 8),
                  Text('Follow Shop'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'message',
              child: Row(
                children: [
                  Icon(Icons.message),
                  SizedBox(width: 8),
                  Text('Message Shop'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report),
                  SizedBox(width: 8),
                  Text('Report Shop'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShopHeader() {
    final branding = widget.shop.branding;
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Shop Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: branding.primaryColor?.withOpacity(0.3) ?? 
                           Theme.of(context).colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: branding.logoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          branding.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              _buildDefaultLogo(),
                        ),
                      )
                    : _buildDefaultLogo(),
              ),
              const SizedBox(width: AppConstants.spacingL),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.shop.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: branding.primaryColor,
                            ),
                          ),
                        ),
                        _buildVerificationBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.shop.category.displayName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildRatingRow(),
                    const SizedBox(height: 8),
                    _buildShopTierBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingL),
          
          // Shop Description
          if (widget.shop.description.isNotEmpty) ...[
            Text(
              widget.shop.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppConstants.spacingL),
          ],
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _followShop,
                  icon: const Icon(Icons.favorite_border),
                  label: const Text('Follow'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: branding.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _messageShop,
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: branding.primaryColor ?? Theme.of(context).colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultLogo() {
    final branding = widget.shop.branding;
    return Container(
      decoration: BoxDecoration(
        color: branding.primaryColor?.withOpacity(0.1) ?? 
               Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          widget.shop.name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: branding.primaryColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationBadge() {
    if (widget.shop.verificationStatus != ShopVerificationStatus.verified) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: 12),
          SizedBox(width: 2),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              Icons.star,
              size: 16,
              color: index < widget.shop.rating.floor()
                  ? Colors.amber
                  : Colors.grey[300],
            );
          }),
        ),
        const SizedBox(width: 4),
        Text(
          '${widget.shop.rating.toStringAsFixed(1)} (${widget.shop.totalReviews})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildShopTierBadge() {
    final tier = widget.shop.tier;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tier.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tier.color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 16, color: tier.color),
          const SizedBox(width: 4),
          Text(
            tier.displayName,
            style: TextStyle(
              color: tier.color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopStats() {
    final stats = widget.shop.statistics;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingL),
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingL),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Products',
                  widget.shop.totalProducts.toString(),
                  Icons.inventory,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Orders',
                  widget.shop.totalOrders.toString(),
                  Icons.shopping_cart,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Followers',
                  _formatNumber(stats.totalViews ~/ 100),
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Processing',
                  '${widget.shop.settings.processingDays}d',
                  Icons.schedule,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: widget.shop.branding.primaryColor ?? 
                 Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingL),
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Products'),
              Tab(text: 'Reviews'),
              Tab(text: 'About'),
              Tab(text: 'Policies'),
            ],
            labelColor: widget.shop.branding.primaryColor,
            indicatorColor: widget.shop.branding.primaryColor,
          ),
          SizedBox(
            height: 800, // Fixed height for tab content
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildReviewsTab(),
                _buildAboutTab(),
                _buildPoliciesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    // Mock products for demonstration
    final mockProducts = List.generate(6, (index) => 
        index < MockProducts.trendingProducts.length 
            ? MockProducts.trendingProducts[index] 
            : MockProducts.trendingProducts.first);
    
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.spacingM),
              IconButton(
                onPressed: _showProductFilters,
                icon: const Icon(Icons.filter_list),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingM),
          Expanded(
            child: ProductGrid(
              products: mockProducts,
              crossAxisCount: 2,
              onProductTap: _openProductDetails,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    // Mock reviews for demonstration
    final reviews = List.generate(5, (index) => ShopReview(
      id: 'review_$index',
      shopId: widget.shop.id,
      userId: 'user_$index',
      userName: 'Customer ${index + 1}',
      rating: 4.0 + (index % 2),
      comment: 'Great shop with excellent service and quality products!',
      createdAt: DateTime.now().subtract(Duration(days: index + 1)),
    ));
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
          child: GlassmorphicContainer.card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: Text(review.userName[0].toUpperCase()),
                      ),
                      const SizedBox(width: AppConstants.spacingM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              review.userName,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                Row(
                                  children: List.generate(5, (i) {
                                    return Icon(
                                      Icons.star,
                                      size: 14,
                                      color: i < review.rating
                                          ? Colors.amber
                                          : Colors.grey[300],
                                    );
                                  }),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  review.timeAgo,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (review.comment?.isNotEmpty == true) ...[
                    const SizedBox(height: AppConstants.spacingM),
                    Text(review.comment ?? ''),
                  ],
                  // Reviews don't include images in basic model
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    final settings = widget.shop.settings;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAboutSection('Location', [
            _buildInfoRow(Icons.location_on, 'Address not specified'),
            _buildInfoRow(Icons.phone, 'Phone not specified'),
            _buildInfoRow(Icons.email, 'Email not specified'),
          ]),
          
          _buildAboutSection('Business Hours', [
            _buildInfoRow(Icons.schedule, 'Mon-Fri: 9:00 AM - 6:00 PM'),
            _buildInfoRow(Icons.schedule, 'Sat-Sun: 10:00 AM - 4:00 PM'),
          ]),
          
          _buildAboutSection('Shop Information', [
            _buildInfoRow(Icons.calendar_today, 'Joined ${_formatDateTime(widget.shop.createdAt)}'),
            _buildInfoRow(Icons.inventory, '${widget.shop.totalProducts} Products'),
            _buildInfoRow(Icons.star, '${widget.shop.rating} Rating'),
          ]),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.spacingM),
        GlassmorphicContainer.card(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingL),
            child: Column(children: children),
          ),
        ),
        const SizedBox(height: AppConstants.spacingL),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppConstants.spacingM),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildPoliciesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.spacingL),
      child: Column(
        children: [
          _buildPolicyCard('Return Policy', 
            '30-day return policy. Items must be in original condition.'),
          _buildPolicyCard('Shipping Policy', 
            'Free shipping on orders over \$50. Standard delivery 3-5 business days.'),
          _buildPolicyCard('Exchange Policy', 
            'Free exchanges within 14 days of purchase.'),
          _buildPolicyCard('Warranty', 
            '1-year manufacturer warranty on all electronic items.'),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingM),
      child: GlassmorphicContainer.card(
        child: ExpansionTile(
          title: Text(title),
          children: [
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacingL),
              child: Text(content),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'message',
          onPressed: _messageShop,
          backgroundColor: widget.shop.branding.primaryColor,
          child: const Icon(Icons.message, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'call',
          onPressed: _callShop,
          backgroundColor: widget.shop.branding.secondaryColor,
          child: const Icon(Icons.phone, color: Colors.white),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }

  void _shareShop() {
    // Implement shop sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shop shared!')),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'follow':
        _followShop();
        break;
      case 'message':
        _messageShop();
        break;
      case 'report':
        _reportShop();
        break;
    }
  }

  void _followShop() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Following ${widget.shop.name}!')),
    );
  }

  void _messageShop() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening chat...')),
    );
  }

  void _callShop() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling shop...')),
    );
  }

  void _reportShop() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report submitted')),
    );
  }

  void _showProductFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Product Filters'),
            // Add filter options here
          ],
        ),
      ),
    );
  }

  void _openProductDetails(Product product) {
    // Navigate to product details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${product.name}')),
    );
  }
}