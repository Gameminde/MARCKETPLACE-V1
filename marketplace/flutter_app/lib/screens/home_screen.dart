import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/product.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/product_card.dart';
import 'product_detail_screen.dart';
import '../core/theme/dynamic_theme_manager.dart';
import '../widgets/particle_background.dart';
import '../widgets/glassmorphic_container.dart';
import 'package:provider/provider.dart';

/// Écran d'accueil de la marketplace
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;

  final List<CategoryItem> _categories = const [
    CategoryItem(
      icon: Icons.checkroom,
      label: AppStrings.fashion,
      color: AppConstants.secondaryColor,
    ),
    CategoryItem(
      icon: Icons.phone_android,
      label: AppStrings.electronics,
      color: AppConstants.textSecondary,
    ),
    CategoryItem(
      icon: Icons.laptop,
      label: AppStrings.computers,
      color: AppConstants.textSecondary,
    ),
    CategoryItem(
      icon: Icons.palette,
      label: AppStrings.beauty,
      color: AppConstants.textSecondary,
    ),
    CategoryItem(
      icon: Icons.sports_soccer,
      label: AppStrings.sports,
      color: AppConstants.textSecondary,
    ),
  ];

  final List<RecentItem> _recentItems = const [
    RecentItem(icon: Icons.headset, color: AppConstants.secondaryColor),
    RecentItem(icon: Icons.gamepad, color: AppConstants.dangerColor),
    RecentItem(icon: Icons.laptop, color: Color(0xFFFD79A8)),
    RecentItem(icon: Icons.print, color: Color(0xFF00B894)),
    RecentItem(icon: Icons.folder, color: AppConstants.warningColor),
    RecentItem(
        icon: Icons.account_balance_wallet, color: AppConstants.accentColor),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Consumer<DynamicThemeManager>(
          builder: (context, theme, _) => theme.backgroundContainer(
            child: ParticleBackground(
              child: CustomScrollView(
                slivers: [
                  // Header avec icônes de navigation
                  SliverToBoxAdapter(
                    child: HomeAppBar(
                      hasNotifications: true,
                      onSearchTap: () => _focusSearchBar(),
                      onNotificationTap: () => _showNotifications(),
                      onChatTap: () => _openChat(),
                      onProfileTap: () => _openProfile(),
                    ),
                  ),

                  // Barre de recherche
                  const SliverToBoxAdapter(child: SizedBox(height: 8)),
                  SliverToBoxAdapter(
                    child: _buildSearchBar(),
                  ),

                  // Catégories horizontales
                  SliverToBoxAdapter(
                    child: _buildCategoriesSection(),
                  ),

                  // Section "For You"
                  SliverToBoxAdapter(
                    child: _buildSectionTitle(AppStrings.forYou),
                  ),

                  // Section "Trending Products"
                  SliverToBoxAdapter(
                    child: _buildSectionTitle(AppStrings.trendingProducts),
                  ),

                  // Grille des produits tendances
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.defaultPadding),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: AppConstants.productCardAspectRatio,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = MockProducts.trendingProducts[index];
                          return ProductCard(
                            product: product,
                            onTap: () => _navigateToProductDetail(product),
                          );
                        },
                        childCount: MockProducts.trendingProducts.length,
                      ),
                    ),
                  ),

                  // Section "Recently Viewed"
                  SliverToBoxAdapter(
                    child: _buildRecentlyViewedSection(),
                  ),

                  // Espace en bas pour la navigation
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: GlassmorphicContainer(
        borderRadius: AppConstants.buttonBorderRadius,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: 50,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              hintStyle: TextStyle(color: Colors.grey.shade200),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade200),
              suffixIcon: Icon(Icons.mic, color: AppConstants.primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
                vertical: 15,
              ),
            ),
            onSubmitted: _performSearch,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SizedBox(
      height: AppConstants.categoryHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppConstants.defaultPadding),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategoryIndex == index;

          return GestureDetector(
            onTap: () => _selectCategory(index),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 15),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? category.color
                          : Colors.grey.shade300.withOpacity(0.4),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: category.color.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      category.icon,
                      color: isSelected ? Colors.white : Colors.grey.shade100,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: AppConstants.smallFontSize,
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildRecentlyViewedSection() {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.recentlyViewed,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recentItems.length,
              itemBuilder: (context, index) {
                final item = _recentItems[index];
                return GlassmorphicContainer(
                  borderRadius: AppConstants.borderRadius,
                  padding: const EdgeInsets.all(0),
                  child: Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(right: 15),
                    alignment: Alignment.center,
                    child: Icon(
                      item.icon,
                      color: item.color,
                      size: AppConstants.iconSize,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Actions des callbacks
  void _focusSearchBar() {}

  void _showNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifications clicked')),
    );
  }

  void _openChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat clicked')),
    );
  }

  void _openProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile clicked')),
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Searching for: $query')),
    );
  }

  void _selectCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
    });
    final category = _categories[index];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected category: ${category.label}')),
    );
  }

  void _navigateToProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }
}

/// Modèle pour les catégories
class CategoryItem {
  final IconData icon;
  final String label;
  final Color color;

  const CategoryItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}

/// Modèle pour les éléments récents
class RecentItem {
  final IconData icon;
  final Color color;

  const RecentItem({
    required this.icon,
    required this.color,
  });
}
