import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../providers/api_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/product.dart';
import '../../models/shop.dart';
import '../../core/theme/glass_theme.dart';
import '../../core/widgets/3d_animations/particle_system.dart';
import '../../core/widgets/glass_components/premium_3d_product_card.dart';
import 'hero_3d_section.dart';
import 'glass_bottom_navigation.dart';

/// Modern Home Screen avec animations 3D révolutionnaires
/// Transformation complète du HomeScreen existant avec glassmorphisme
class Modern3DHomeScreen extends StatefulWidget {
  const Modern3DHomeScreen({super.key});

  @override
  State<Modern3DHomeScreen> createState() => _Modern3DHomeScreenState();
}

class _Modern3DHomeScreenState extends State<Modern3DHomeScreen>
    with TickerProviderStateMixin {
  
  // Providers
  late final ApiProvider _apiProvider;
  late final AuthProvider _authProvider;
  
  // Data
  List<Product> _featuredProducts = [];
  List<Shop> _popularShops = [];
  bool _isLoading = true;
  String? _error;
  
  // Animation Controllers
  late AnimationController _parallaxController;
  late AnimationController _scrollController;
  late ScrollController _mainScrollController;
  
  // Animations
  late Animation<double> _parallaxOffset;
  
  @override
  void initState() {
    super.initState();
    _initializeProviders();
    _initializeAnimations();
    _setupScrollListener();
    _loadHomeData();
  }
  
  void _initializeProviders() {
    _apiProvider = Provider.of<ApiProvider>(context, listen: false);
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }
  
  void _initializeAnimations() {
    // Contrôleur pour parallax effect
    _parallaxController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Contrôleur pour scroll animations
    _scrollController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Animation de parallax
    _parallaxOffset = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _parallaxController,
      curve: GlassTheme.easeSignature,
    ));
    
    // Scroll controller principal
    _mainScrollController = ScrollController();
  }
  
  void _setupScrollListener() {
    _mainScrollController.addListener(() {
      final offset = _mainScrollController.offset;
      final maxOffset = _mainScrollController.position.maxScrollExtent;
      
      if (maxOffset > 0) {
        final progress = (offset / maxOffset).clamp(0.0, 1.0);
        _parallaxController.value = progress;
      }
    });
  }
  
  Future<void> _loadHomeData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Chargement parallèle pour performance optimale
      final results = await Future.wait([
        _apiProvider.getFeaturedProducts(),
        _apiProvider.getPopularShops(),
      ]);

      if (mounted) {
        setState(() {
          _featuredProducts = results[0] as List<Product>;
          _popularShops = results[1] as List<Shop>;
          _isLoading = false;
        });
        
        // Animation d'entrée
        _scrollController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load home data: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _parallaxController.dispose();
    _scrollController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(),
      body: _buildBody(),
      bottomNavigationBar: const GlassBottomNavigation(),
    );
  }
  
  PreferredSizeWidget _buildGlassAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTheme.primaryBlur,
            sigmaY: GlassTheme.primaryBlur,
          ),
          child: AppBar(
            backgroundColor: Colors.white.withOpacity(0.1),
            elevation: 0,
            scrolledUnderElevation: 0,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.2),
                    Colors.white.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
            ),
            title: Text(
              'Marketplace',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            actions: [
              _buildGlassIconButton(
                icon: Icons.search,
                onPressed: () => context.go('/search'),
                tooltip: 'Search products',
              ),
              _buildGlassIconButton(
                icon: Icons.notifications_outlined,
                onPressed: () => context.go('/notifications'),
                tooltip: 'Notifications',
              ),
              _buildGlassIconButton(
                icon: Icons.person_outline,
                onPressed: () => context.go('/profile'),
                tooltip: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGlassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        tooltip: tooltip,
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return _buildContent();
  }
  
  Widget _buildLoadingState() {
    return OptimizedParticleSystem(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Loading animation avec glassmorphisme
            Container(
              width: 80,
              height: 80,
              decoration: GlassTheme.createGlassDecoration(
                color: GlassTheme.luxuryPrimary,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading marketplace magic...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return OptimizedParticleSystem(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: GlassTheme.createGlassDecoration(
            color: GlassTheme.urgencyDanger,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Oops! Something went wrong',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadHomeData,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: GlassTheme.urgencyDanger,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    return OptimizedParticleSystem(
      child: RefreshIndicator(
        onRefresh: _loadHomeData,
        child: CustomScrollView(
          controller: _mainScrollController,
          slivers: [
            // Hero Section 3D avec parallax
            SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _parallaxOffset,
                builder: (context, child) {
                  return Hero3DSection(
                    parallaxOffset: _parallaxOffset.value,
                    user: _authProvider.user,
                    onSearchTap: () => context.go('/search'),
                  );
                },
              ),
            ),
            
            // Categories Section avec glassmorphisme
            SliverToBoxAdapter(
              child: _buildCategoriesSection(),
            ),
            
            // Featured Products 3D Grid
            SliverToBoxAdapter(
              child: _buildFeaturedProductsSection(),
            ),
            
            // Popular Shops Section
            SliverToBoxAdapter(
              child: _buildPopularShopsSection(),
            ),
            
            // Bottom padding pour navigation
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoriesSection() {
    final categories = [
      {
        'name': 'Electronics',
        'icon': Icons.devices,
        'color': GlassTheme.trustSecondary,
        'category': ProductCategory.tech,
      },
      {
        'name': 'Fashion',
        'icon': Icons.checkroom,
        'color': GlassTheme.energyWarning,
        'category': ProductCategory.fashion,
      },
      {
        'name': 'Luxury',
        'icon': Icons.diamond,
        'color': GlassTheme.luxuryPrimary,
        'category': ProductCategory.luxury,
      },
      {
        'name': 'Home',
        'icon': Icons.home,
        'color': GlassTheme.actionAccent,
        'category': ProductCategory.neutral,
      },
      {
        'name': 'Sports',
        'icon': Icons.sports,
        'color': GlassTheme.urgencyDanger,
        'category': ProductCategory.action,
      },
      {
        'name': 'More',
        'icon': Icons.more_horiz,
        'color': Colors.grey,
        'category': ProductCategory.neutral,
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Categories',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Container(
                  width: 90,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildCategoryCard(category, index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryCard(Map<String, dynamic> category, int index) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _scrollController.value) * 50),
          child: Opacity(
            opacity: _scrollController.value,
            child: Container(
              decoration: GlassTheme.createGlassDecoration(
                color: category['color'] as Color,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Navigation vers catégorie
                        context.go('/category/${category['name']}');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              category['icon'] as IconData,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFeaturedProductsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Featured Products',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/products'),
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: _featuredProducts.isEmpty
                ? _buildEmptyState('No featured products available')
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _featuredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _featuredProducts[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: Premium3DProductCard(
                          product: product,
                          animationDelay: index * 100,
                          category: _getProductCategory(product),
                          onTap: () => context.go('/product/${product.id}'),
                          onFavorite: () {
                            // Logique de favori
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPopularShopsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Shops',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/shops'),
                  child: const Text(
                    'See All',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _popularShops.isEmpty
                ? _buildEmptyState('No popular shops available')
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _popularShops.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: _buildShopCard(_popularShops[index], index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShopCard(Shop shop, int index) {
    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _scrollController.value) * 30),
          child: Opacity(
            opacity: _scrollController.value,
            child: Container(
              width: 160,
              decoration: GlassTheme.createGlassDecoration(
                color: GlassTheme.luxuryPalette[index % GlassTheme.luxuryPalette.length],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/shop/${shop.id}'),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              color: Colors.white.withOpacity(0.1),
                              child: shop.logoUrl != null
                                  ? Image.network(
                                      shop.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(
                                        Icons.store,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.store,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Text(
                                  shop.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${shop.productCount ?? 0} products',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: GlassTheme.createGlassDecoration(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  ProductCategory _getProductCategory(Product product) {
    // Logique pour déterminer la catégorie psychologique
    if (product.price > 1000) return ProductCategory.luxury;
    if (product.category?.toLowerCase().contains('tech') == true) return ProductCategory.tech;
    if (product.category?.toLowerCase().contains('fashion') == true) return ProductCategory.fashion;
    if (product.isOnSale == true) return ProductCategory.urgent;
    return ProductCategory.neutral;
  }
}