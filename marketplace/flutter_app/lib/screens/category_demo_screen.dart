import 'package:flutter/material.dart';

import '../models/category.dart';
import '../widgets/category_section.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/particle_background.dart';

/// Sample home screen demonstrating CategorySection widget usage
class CategoryDemoScreen extends StatefulWidget {
  const CategoryDemoScreen({super.key});

  @override
  State<CategoryDemoScreen> createState() => _CategoryDemoScreenState();
}

class _CategoryDemoScreenState extends State<CategoryDemoScreen> {
  Category? _selectedCategory;
  List<Category> _multiSelectedCategories = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar.home(
        onSearchTap: () {
          // Handle search tap
        },
        onNotificationTap: () {
          // Handle notification tap
        },
        hasNotifications: true,
        notificationCount: 3,
      ),
      body: ParticleBackground.subtle(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Horizontal chip style (default)
              CategorySection.chips(
                categories: MockCategories.featuredCategories,
                title: 'Featured Categories',
                selectedCategory: _selectedCategory,
                onCategoryTap: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: ${category.displayName}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                showProductCount: false,
                enableGlassmorphism: true,
              ),
              
              const SizedBox(height: 24),
              
              // Grid style
              CategorySection.grid(
                categories: MockCategories.featuredCategories.take(8).toList(),
                title: 'Shop by Category',
                selectedCategory: _selectedCategory,
                onCategoryTap: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: ${category.displayName}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // List style with multi-select
              CategorySection.list(
                categories: MockCategories.allCategories.take(6).toList(),
                title: 'All Categories',
                selectedCategory: _selectedCategory,
                onCategoryTap: (category) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: ${category.displayName}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Carousel style with multi-select
              CategorySection(
                categories: MockCategories.featuredCategories,
                title: 'Multi-Select Categories',
                style: CategoryStyle.chip,
                enableMultiSelect: true,
                selectedCategories: _multiSelectedCategories,
                onMultiSelectChanged: (categories) {
                  setState(() {
                    _multiSelectedCategories = categories;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected ${categories.length} categories'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                height: 50,
                showProductCount: true,
              ),
              
              const SizedBox(height: 24),
              
              // Loading state example
              const CategorySection(
                categories: [],
                title: 'Loading Categories',
                isLoading: true,
                height: 50,
              ),
              
              const SizedBox(height: 24),
              
              // Empty state example
              const CategorySection(
                categories: [],
                title: 'Empty Categories',
                emptyMessage: 'No categories found. Try refreshing.',
                height: 100,
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}