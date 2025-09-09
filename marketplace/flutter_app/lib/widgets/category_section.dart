import 'package:flutter/material.dart';

import '../core/config/app_constants.dart';
import '../models/category.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';

/// Comprehensive category section widget with horizontal scrollable chips,
/// glassmorphic design, animations, and multiple display styles
class CategorySection extends StatefulWidget {
  final List<Category> categories;
  final Function(Category)? onCategoryTap;
  final Category? selectedCategory;
  final CategoryStyle style;
  final bool showTitle;
  final String title;
  final bool enableGlassmorphism;
  final bool enableAnimations;
  final bool showProductCount;
  final bool showIcons;
  final bool enableMultiSelect;
  final List<Category> selectedCategories;
  final Function(List<Category>)? onMultiSelectChanged;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final bool showViewAll;
  final VoidCallback? onViewAllTap;
  final bool isLoading;
  final String? emptyMessage;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;
  final int maxDisplayCount;
  
  const CategorySection({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.selectedCategory,
    this.style = CategoryStyle.chip,
    this.showTitle = true,
    this.title = 'Categories',
    this.enableGlassmorphism = true,
    this.enableAnimations = true,
    this.showProductCount = true,
    this.showIcons = true,
    this.enableMultiSelect = false,
    this.selectedCategories = const [],
    this.onMultiSelectChanged,
    this.padding,
    this.height,
    this.showViewAll = false,
    this.onViewAllTap,
    this.isLoading = false,
    this.emptyMessage,
    this.scrollController,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.horizontal,
    this.maxDisplayCount = 20,
  });

  /// Factory constructor for horizontal chips layout
  factory CategorySection.chips({
    Key? key,
    required List<Category> categories,
    Function(Category)? onCategoryTap,
    Category? selectedCategory,
    bool showTitle = true,
    String title = 'Categories',
    bool showProductCount = false,
    bool enableGlassmorphism = true,
  }) {
    return CategorySection(
      key: key,
      categories: categories,
      onCategoryTap: onCategoryTap,
      selectedCategory: selectedCategory,
      style: CategoryStyle.chip,
      showTitle: showTitle,
      title: title,
      showProductCount: showProductCount,
      enableGlassmorphism: enableGlassmorphism,
      height: 50,
    );
  }

  /// Factory constructor for grid layout
  factory CategorySection.grid({
    Key? key,
    required List<Category> categories,
    Function(Category)? onCategoryTap,
    Category? selectedCategory,
    bool showTitle = true,
    String title = 'Categories',
    bool enableGlassmorphism = true,
    int maxDisplayCount = 8,
  }) {
    return CategorySection(
      key: key,
      categories: categories,
      onCategoryTap: onCategoryTap,
      selectedCategory: selectedCategory,
      style: CategoryStyle.grid,
      showTitle: showTitle,
      title: title,
      enableGlassmorphism: enableGlassmorphism,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
      maxDisplayCount: maxDisplayCount,
    );
  }

  /// Factory constructor for list layout
  factory CategorySection.list({
    Key? key,
    required List<Category> categories,
    Function(Category)? onCategoryTap,
    Category? selectedCategory,
    bool showTitle = true,
    String title = 'Categories',
    bool enableGlassmorphism = true,
  }) {
    return CategorySection(
      key: key,
      categories: categories,
      onCategoryTap: onCategoryTap,
      selectedCategory: selectedCategory,
      style: CategoryStyle.list,
      showTitle: showTitle,
      title: title,
      enableGlassmorphism: enableGlassmorphism,
      scrollDirection: Axis.vertical,
      shrinkWrap: true,
    );
  }

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController = widget.scrollController ?? ScrollController();
    
    if (widget.enableAnimations) {
      _animationController.forward();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingState(context);
    }
    
    if (widget.categories.isEmpty) {
      return _buildEmptyState(context);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle) _buildHeader(context),
        _buildCategoryContent(context),
      ],
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(AppConstants.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.showViewAll)
            TextButton(
              onPressed: widget.onViewAllTap,
              child: Text(
                'View All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryContent(BuildContext context) {
    switch (widget.style) {
      case CategoryStyle.chip:
        return _buildChipStyle(context);
      case CategoryStyle.grid:
        return _buildGridStyle(context);
      case CategoryStyle.list:
        return _buildListStyle(context);
      case CategoryStyle.carousel:
        return _buildCarouselStyle(context);
    }
  }
  
  Widget _buildChipStyle(BuildContext context) {
    final displayCategories = widget.categories.take(widget.maxDisplayCount).toList();
    
    return SizedBox(
      height: widget.height ?? 50,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: widget.scrollDirection,
        physics: widget.physics ?? const BouncingScrollPhysics(),
        padding: widget.padding ?? const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
        ),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          return _buildCategoryChip(context, category, index);
        },
      ),
    );
  }
  
  Widget _buildGridStyle(BuildContext context) {
    final displayCategories = widget.categories.take(widget.maxDisplayCount).toList();
    
    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
      ),
      child: GridView.builder(
        controller: _scrollController,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics ?? const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: AppConstants.spacingM,
          crossAxisSpacing: AppConstants.spacingM,
          childAspectRatio: 0.8,
        ),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          return _buildCategoryCard(context, category, index);
        },
      ),
    );
  }
  
  Widget _buildListStyle(BuildContext context) {
    final displayCategories = widget.categories.take(widget.maxDisplayCount).toList();
    
    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
      ),
      child: ListView.builder(
        controller: _scrollController,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics ?? const NeverScrollableScrollPhysics(),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          return _buildCategoryListItem(context, category, index);
        },
      ),
    );
  }
  
  Widget _buildCarouselStyle(BuildContext context) {
    final displayCategories = widget.categories.take(widget.maxDisplayCount).toList();
    
    return SizedBox(
      height: widget.height ?? 120,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        physics: widget.physics ?? const BouncingScrollPhysics(),
        itemCount: displayCategories.length,
        itemBuilder: (context, index) {
          final category = displayCategories[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: AppConstants.spacingS),
            child: _buildCategoryCard(context, category, index),
          );
        },
      ),
    );
  }
  
  Widget _buildCategoryChip(BuildContext context, Category category, int index) {
    final isSelected = widget.enableMultiSelect 
        ? widget.selectedCategories.contains(category)
        : widget.selectedCategory == category;
    
    Widget chip = Container(
      margin: const EdgeInsets.only(right: AppConstants.spacingS),
      child: widget.enableGlassmorphism
          ? GlassmorphicContainer.chip(
              isSelected: isSelected,
              onTap: () => _handleCategoryTap(category),
              child: _buildChipContent(context, category, isSelected),
            )
          : FilterChip(
              selected: isSelected,
              onSelected: (_) => _handleCategoryTap(category),
              label: _buildChipContent(context, category, isSelected),
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            ),
    );
    
    if (widget.enableAnimations) {
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
                curve: Curves.easeOutBack,
              ),
            )),
            child: child,
          );
        },
        child: chip,
      );
    }
    
    return chip;
  }
  
  Widget _buildChipContent(BuildContext context, Category category, bool isSelected) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcons) ...[
          Icon(
            category.icon,
            size: 16,
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppConstants.spacingXS),
        ],
        Text(
          category.displayName,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        if (widget.showProductCount) ...[
          const SizedBox(width: AppConstants.spacingXS),
          Text(
            '(${category.productCount})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
  
  Widget _buildCategoryCard(BuildContext context, Category category, int index) {
    final isSelected = widget.enableMultiSelect 
        ? widget.selectedCategories.contains(category)
        : widget.selectedCategory == category;
    
    Widget card = GestureDetector(
      onTap: () => _handleCategoryTap(category),
      child: widget.enableGlassmorphism
          ? GlassmorphicContainer.card(
              child: _buildCardContent(context, category, isSelected),
            )
          : Card(
              elevation: isSelected ? 8 : 2,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null,
              child: _buildCardContent(context, category, isSelected),
            ),
    );
    
    if (widget.enableAnimations) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return ScaleTransition(
            scale: Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * 0.1,
                (index * 0.1) + 0.5,
                curve: Curves.elasticOut,
              ),
            )),
            child: child,
          );
        },
        child: card,
      );
    }
    
    return card;
  }
  
  Widget _buildCardContent(BuildContext context, Category category, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.showIcons) ...[
            Container(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : category.categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Icon(
                category.icon,
                size: 24,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : category.categoryColor,
              ),
            ),
            const SizedBox(height: AppConstants.spacingS),
          ],
          Text(
            category.displayName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.showProductCount) ...[
            const SizedBox(height: AppConstants.spacingXS),
            Text(
              '${category.productCount} items',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCategoryListItem(BuildContext context, Category category, int index) {
    final isSelected = widget.enableMultiSelect 
        ? widget.selectedCategories.contains(category)
        : widget.selectedCategory == category;
    
    Widget item = Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      child: widget.enableGlassmorphism
          ? GlassmorphicContainer.card(
              child: _buildListItemContent(context, category, isSelected),
            )
          : Card(
              elevation: isSelected ? 4 : 1,
              child: _buildListItemContent(context, category, isSelected),
            ),
    );
    
    if (widget.enableAnimations) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * 0.1,
                (index * 0.1) + 0.5,
                curve: Curves.easeOutCubic,
              ),
            )),
            child: child,
          );
        },
        child: item,
      );
    }
    
    return item;
  }
  
  Widget _buildListItemContent(BuildContext context, Category category, bool isSelected) {
    return ListTile(
      onTap: () => _handleCategoryTap(category),
      leading: widget.showIcons
          ? Container(
              padding: const EdgeInsets.all(AppConstants.spacingS),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : category.categoryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Icon(
                category.icon,
                size: 20,
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : category.categoryColor,
              ),
            )
          : null,
      title: Text(
        category.displayName,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
      subtitle: category.description.isNotEmpty
          ? Text(
              category.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: widget.showProductCount
          ? Text(
              '${category.productCount}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            )
          : const Icon(Icons.chevron_right),
    );
  }
  
  Widget _buildLoadingState(BuildContext context) {
    return Container(
      height: widget.height ?? 50,
      padding: widget.padding ?? const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
      ),
      child: ListView.builder(
        scrollDirection: widget.scrollDirection,
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: AppConstants.spacingS),
            child: const LoadingStates(
              type: LoadingType.shimmer,
              size: LoadingSize.small,
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: widget.height ?? 100,
      padding: widget.padding ?? const EdgeInsets.all(AppConstants.spacingM),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(
              widget.emptyMessage ?? 'No categories available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _handleCategoryTap(Category category) {
    if (widget.enableMultiSelect) {
      final selectedList = List<Category>.from(widget.selectedCategories);
      if (selectedList.contains(category)) {
        selectedList.remove(category);
      } else {
        selectedList.add(category);
      }
      widget.onMultiSelectChanged?.call(selectedList);
    } else {
      widget.onCategoryTap?.call(category);
    }
  }
}

/// Category display styles
enum CategoryStyle {
  chip,
  grid,
  list,
  carousel,
}