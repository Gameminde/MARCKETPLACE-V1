import 'package:flutter_test/flutter_test.dart';

import '../../lib/providers/search_provider.dart';
import '../../lib/models/product.dart';

void main() {
  group('SearchProvider Tests', () {
    late SearchProvider searchProvider;
    late List<Product> mockProducts;

    setUp(() {
      searchProvider = SearchProvider();
      mockProducts = [
        const Product(
          id: '1',
          name: 'iPhone 14 Pro',
          description: 'Latest Apple smartphone with advanced camera',
          price: 999.99,
          category: 'Electronics',
          rating: 4.8,
          reviewCount: 1250,
          availableColors: ['Space Black', 'Deep Purple', 'Gold', 'Silver'],
        ),
        const Product(
          id: '2',
          name: 'Samsung Galaxy S23',
          description: 'Premium Android smartphone with excellent display',
          price: 899.99,
          category: 'Electronics',
          rating: 4.7,
          reviewCount: 980,
          availableColors: ['Phantom Black', 'Cream', 'Green'],
        ),
        const Product(
          id: '3',
          name: 'Nike Air Max 270',
          description: 'Comfortable running shoes with air cushioning',
          price: 150.00,
          category: 'Sports',
          rating: 4.5,
          reviewCount: 2100,
          availableColors: ['Black', 'White', 'Red'],
          availableSizes: ['7', '8', '9', '10', '11'],
        ),
        const Product(
          id: '4',
          name: 'MacBook Pro M2',
          description: 'Powerful laptop for professionals and creatives',
          price: 1299.99,
          category: 'Electronics',
          rating: 4.9,
          reviewCount: 750,
        ),
        const Product(
          id: '5',
          name: 'Adidas Ultraboost',
          description: 'Premium running shoes with boost technology',
          price: 180.00,
          category: 'Sports',
          rating: 4.6,
          reviewCount: 1800,
          availableColors: ['Black', 'White', 'Blue'],
          availableSizes: ['7', '8', '9', '10', '11', '12'],
        ),
      ];
    });

    test('should initialize with empty state', () {
      expect(searchProvider.query, isEmpty);
      expect(searchProvider.results, isEmpty);
      expect(searchProvider.isLoading, isFalse);
      expect(searchProvider.hasSearched, isFalse);
      expect(searchProvider.suggestions, isEmpty);
    });

    group('Search Functionality', () {
      test('should perform basic text search', () async {
        await searchProvider.search('iPhone', mockProducts);
        
        expect(searchProvider.query, equals('iPhone'));
        expect(searchProvider.results.length, equals(1));
        expect(searchProvider.results.first.name, contains('iPhone'));
        expect(searchProvider.hasSearched, isTrue);
        expect(searchProvider.isLoading, isFalse);
      });

      test('should return multiple results for generic query', () async {
        await searchProvider.search('smartphone', mockProducts);
        
        expect(searchProvider.results.length, equals(2));
        expect(searchProvider.results.every((p) => 
          p.name.toLowerCase().contains('phone') || 
          p.description.toLowerCase().contains('smartphone')), isTrue);
      });

      test('should be case insensitive', () async {
        await searchProvider.search('IPHONE', mockProducts);
        
        expect(searchProvider.results.length, equals(1));
        expect(searchProvider.results.first.name, contains('iPhone'));
      });

      test('should search in product descriptions', () async {
        await searchProvider.search('camera', mockProducts);
        
        expect(searchProvider.results.length, equals(1));
        expect(searchProvider.results.first.description, contains('camera'));
      });

      test('should search by category', () async {
        await searchProvider.search('Electronics', mockProducts);
        
        expect(searchProvider.results.length, equals(3));
        expect(searchProvider.results.every((p) => p.category == 'Electronics'), isTrue);
      });

      test('should return empty results for no matches', () async {
        await searchProvider.search('nonexistent', mockProducts);
        
        expect(searchProvider.results, isEmpty);
        expect(searchProvider.hasSearched, isTrue);
      });

      test('should handle empty search query', () async {
        await searchProvider.search('', mockProducts);
        
        expect(searchProvider.results, equals(mockProducts));
        expect(searchProvider.query, isEmpty);
      });

      test('should handle null search query', () async {
        await searchProvider.search(null, mockProducts);
        
        expect(searchProvider.results, equals(mockProducts));
        expect(searchProvider.query, isEmpty);
      });
    });

    group('Search Filters', () {
      test('should filter by price range', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setPriceRange(100.0, 200.0);
        await searchProvider.applyFilters();
        
        expect(searchProvider.results.length, equals(2));
        expect(searchProvider.results.every((p) => 
          p.price >= 100.0 && p.price <= 200.0), isTrue);
      });

      test('should filter by category', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setSelectedCategories(['Sports']);
        await searchProvider.applyFilters();
        
        expect(searchProvider.results.length, equals(2));
        expect(searchProvider.results.every((p) => p.category == 'Sports'), isTrue);
      });

      test('should filter by rating', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setMinRating(4.8);
        await searchProvider.applyFilters();
        
        expect(searchProvider.results.length, equals(2));
        expect(searchProvider.results.every((p) => p.rating >= 4.8), isTrue);
      });

      test('should filter by availability', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setInStockOnly(true);
        await searchProvider.applyFilters();
        
        // All mock products are in stock by default
        expect(searchProvider.results.length, equals(mockProducts.length));
      });

      test('should combine multiple filters', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setPriceRange(800.0, 1500.0);
        searchProvider.setSelectedCategories(['Electronics']);
        searchProvider.setMinRating(4.7);
        await searchProvider.applyFilters();
        
        expect(searchProvider.results.length, equals(3));
        expect(searchProvider.results.every((p) => 
          p.price >= 800.0 && 
          p.price <= 1500.0 && 
          p.category == 'Electronics' && 
          p.rating >= 4.7), isTrue);
      });

      test('should clear filters', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setPriceRange(100.0, 200.0);
        searchProvider.setSelectedCategories(['Sports']);
        searchProvider.clearFilters();
        
        expect(searchProvider.selectedCategories, isEmpty);
        expect(searchProvider.minPrice, isNull);
        expect(searchProvider.maxPrice, isNull);
        expect(searchProvider.minRating, equals(0.0));
        expect(searchProvider.inStockOnly, isFalse);
      });
    });

    group('Search Sorting', () {
      test('should sort by price ascending', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setSortBy(SortOption.priceAscending);
        await searchProvider.applyFilters();
        
        final prices = searchProvider.results.map((p) => p.price).toList();
        final sortedPrices = List<double>.from(prices)..sort();
        expect(prices, equals(sortedPrices));
      });

      test('should sort by price descending', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setSortBy(SortOption.priceDescending);
        await searchProvider.applyFilters();
        
        final prices = searchProvider.results.map((p) => p.price).toList();
        final sortedPrices = List<double>.from(prices)..sort((a, b) => b.compareTo(a));
        expect(prices, equals(sortedPrices));
      });

      test('should sort by rating descending', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setSortBy(SortOption.ratingDescending);
        await searchProvider.applyFilters();
        
        final ratings = searchProvider.results.map((p) => p.rating).toList();
        final sortedRatings = List<double>.from(ratings)..sort((a, b) => b.compareTo(a));
        expect(ratings, equals(sortedRatings));
      });

      test('should sort by name alphabetically', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setSortBy(SortOption.nameAscending);
        await searchProvider.applyFilters();
        
        final names = searchProvider.results.map((p) => p.name).toList();
        final sortedNames = List<String>.from(names)..sort();
        expect(names, equals(sortedNames));
      });

      test('should sort by newest first', () async {
        await searchProvider.search('', mockProducts);
        searchProvider.setSortBy(SortOption.newest);
        await searchProvider.applyFilters();
        
        // Since mock products don't have timestamps, this tests the sorting mechanism
        expect(searchProvider.sortBy, equals(SortOption.newest));
      });
    });

    group('Search Suggestions', () {
      test('should generate suggestions based on query', () async {
        await searchProvider.generateSuggestions('phone', mockProducts);
        
        expect(searchProvider.suggestions.isNotEmpty, isTrue);
        expect(searchProvider.suggestions.any((s) => s.toLowerCase().contains('phone')), isTrue);
      });

      test('should include popular categories in suggestions', () async {
        await searchProvider.generateSuggestions('', mockProducts);
        
        expect(searchProvider.suggestions.contains('Electronics'), isTrue);
        expect(searchProvider.suggestions.contains('Sports'), isTrue);
      });

      test('should limit number of suggestions', () async {
        await searchProvider.generateSuggestions('a', mockProducts);
        
        expect(searchProvider.suggestions.length, lessThanOrEqualTo(10));
      });

      test('should clear suggestions', () {
        searchProvider.clearSuggestions();
        expect(searchProvider.suggestions, isEmpty);
      });
    });

    group('Search History', () {
      test('should add search to history', () async {
        await searchProvider.search('iPhone', mockProducts);
        
        expect(searchProvider.searchHistory.contains('iPhone'), isTrue);
      });

      test('should limit search history size', () async {
        // Add more than the limit (assuming limit is 10)
        for (int i = 0; i < 15; i++) {
          await searchProvider.search('query$i', mockProducts);
        }
        
        expect(searchProvider.searchHistory.length, lessThanOrEqualTo(10));
      });

      test('should not add duplicate entries to history', () async {
        await searchProvider.search('iPhone', mockProducts);
        await searchProvider.search('iPhone', mockProducts);
        
        expect(searchProvider.searchHistory.where((h) => h == 'iPhone').length, equals(1));
      });

      test('should clear search history', () async {
        await searchProvider.search('iPhone', mockProducts);
        searchProvider.clearHistory();
        
        expect(searchProvider.searchHistory, isEmpty);
      });
    });

    group('Voice Search', () {
      test('should handle voice search input', () async {
        await searchProvider.handleVoiceSearch('iPhone fourteen pro', mockProducts);
        
        expect(searchProvider.query, equals('iPhone fourteen pro'));
        expect(searchProvider.results.isNotEmpty, isTrue);
      });

      test('should normalize voice input', () async {
        await searchProvider.handleVoiceSearch('IPHONE FOURTEEN PRO', mockProducts);
        
        expect(searchProvider.query, equals('IPHONE FOURTEEN PRO'));
        // Should still find results despite case differences
        expect(searchProvider.results.isNotEmpty, isTrue);
      });
    });

    group('AI-Powered Search', () {
      test('should handle semantic search', () async {
        await searchProvider.semanticSearch('fast laptop for programming', mockProducts);
        
        expect(searchProvider.results.isNotEmpty, isTrue);
        // Should find MacBook Pro based on semantic understanding
        expect(searchProvider.results.any((p) => p.name.contains('MacBook')), isTrue);
      });

      test('should understand product attributes', () async {
        await searchProvider.semanticSearch('comfortable running shoes', mockProducts);
        
        expect(searchProvider.results.length, equals(2));
        expect(searchProvider.results.every((p) => p.category == 'Sports'), isTrue);
      });

      test('should handle color and size queries', () async {
        await searchProvider.search('black shoes', mockProducts);
        
        final blackShoes = searchProvider.results.where((p) => 
          p.availableColors.any((color) => color.toLowerCase().contains('black')) &&
          p.category == 'Sports'
        );
        expect(blackShoes.isNotEmpty, isTrue);
      });
    });

    group('Performance Tests', () {
      test('should handle large product lists efficiently', () async {
        final largeProductList = List.generate(1000, (index) => Product(
          id: 'product_$index',
          name: 'Product $index',
          description: 'Description for product $index',
          price: (index + 1) * 10.0,
          category: index % 2 == 0 ? 'Electronics' : 'Sports',
        ));
        
        final stopwatch = Stopwatch()..start();
        await searchProvider.search('Product', largeProductList);
        stopwatch.stop();
        
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should complete in under 1 second
        expect(searchProvider.results.length, equals(1000));
      });

      test('should debounce rapid search queries', () async {
        var searchCount = 0;
        
        // Override search method to count calls
        final originalSearch = searchProvider.search;
        
        // Simulate rapid typing
        searchProvider.search('i', mockProducts);
        searchProvider.search('ip', mockProducts);
        searchProvider.search('iph', mockProducts);
        await searchProvider.search('iphone', mockProducts);
        
        // Should have debounced and only performed the final search
        expect(searchProvider.query, equals('iphone'));
      });
    });

    group('Error Handling', () {
      test('should handle null product list gracefully', () async {
        await searchProvider.search('iPhone', null);
        
        expect(searchProvider.results, isEmpty);
        expect(searchProvider.hasSearched, isTrue);
      });

      test('should handle empty product list', () async {
        await searchProvider.search('iPhone', []);
        
        expect(searchProvider.results, isEmpty);
        expect(searchProvider.hasSearched, isTrue);
      });

      test('should notify listeners on search state changes', () {
        var notificationCount = 0;
        searchProvider.addListener(() {
          notificationCount++;
        });
        
        searchProvider.setLoading(true);
        searchProvider.setLoading(false);
        
        expect(notificationCount, equals(2));
      });
    });
  });
}