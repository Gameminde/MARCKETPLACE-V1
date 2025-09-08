import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/product.dart';
import '../models/search_result.dart';
import '../models/search_filter.dart';
import '../providers/search_provider.dart';
import '../core/config/environment.dart';

/// Search service for API communication
class SearchService {
  final String _baseUrl = Environment.baseUrl;
  
  /// Perform regular text search
  Future<SearchResult> search({
    required String query,
    SearchFilter? filters,
    SearchSortBy sortBy = SearchSortBy.relevance,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = {
        'q': query,
        'page': page.toString(),
        'limit': limit.toString(),
        'sort': _sortByToString(sortBy),
      };
      
      // Add filters to params
      if (filters != null) {
        params.addAll(_filtersToParams(filters));
      }
      
      final uri = Uri.parse('${_baseUrl}${Environment.ApiEndpoints.productSearch}')
          .replace(queryParameters: params);
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        final products = (data['products'] as List<dynamic>)
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();
        
        return SearchResult.success(
          products: products,
          totalCount: data['totalCount'] as int? ?? 0,
          hasMore: data['hasMore'] as bool? ?? false,
          insights: data['insights'] as Map<String, dynamic>?,
        );
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        return SearchResult.error(error['message'] as String? ?? 'Search failed');
      }
    } catch (e) {
      return SearchResult.error('Network error: $e');
    }
  }
  
  /// Perform AI-powered search
  Future<SearchResult> aiSearch({
    required String query,
    SearchFilter? filters,
    SearchSortBy sortBy = SearchSortBy.relevance,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final requestBody = {
        'query': query,
        'page': page,
        'limit': limit,
        'sortBy': _sortByToString(sortBy),
        'filters': filters?.toJson(),
        'useAI': true,
      };
      
      final response = await http.post(
        Uri.parse('${_baseUrl}${Environment.ApiEndpoints.aiSearch}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        final products = (data['products'] as List<dynamic>)
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();
        
        return SearchResult.success(
          products: products,
          totalCount: data['totalCount'] as int? ?? 0,
          hasMore: data['hasMore'] as bool? ?? false,
          insights: data['insights'] as Map<String, dynamic>?,
        );
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        return SearchResult.error(error['message'] as String? ?? 'AI search failed');
      }
    } catch (e) {
      return SearchResult.error('AI search error: $e');
    }
  }
  
  /// Perform visual search with image
  Future<SearchResult> visualSearch({
    required String imagePath,
    SearchFilter? filters,
    SearchSortBy sortBy = SearchSortBy.relevance,
  }) async {
    try {
      // This would typically upload an image and perform visual search
      // For now, return a mock result
      await Future.delayed(const Duration(seconds: 2)); // Simulate processing
      
      return SearchResult.success(
        products: [],
        totalCount: 0,
        insights: {'message': 'Visual search processed'},
      );
    } catch (e) {
      return SearchResult.error('Visual search error: $e');
    }
  }
  
  /// Perform barcode search
  Future<SearchResult> barcodeSearch(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}/search/barcode/$barcode'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        final products = (data['products'] as List<dynamic>)
            .map((p) => Product.fromJson(p as Map<String, dynamic>))
            .toList();
        
        return SearchResult.success(
          products: products,
          totalCount: data['totalCount'] as int? ?? 0,
        );
      } else {
        return SearchResult.error('Product not found');
      }
    } catch (e) {
      return SearchResult.error('Barcode search error: $e');
    }
  }
  
  /// Get search suggestions
  Future<List<SearchSuggestion>> getSuggestions(String query) async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}/search/suggestions?q=${Uri.encodeComponent(query)}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final suggestions = (data['suggestions'] as List<dynamic>)
            .map((s) => SearchSuggestion.fromJson(s as Map<String, dynamic>))
            .toList();
        
        return suggestions;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Get popular searches
  Future<List<String>> getPopularSearches() async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}/search/popular'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return (data['searches'] as List<dynamic>).cast<String>();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Get trending searches
  Future<List<String>> getTrendingSearches() async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}/search/trending'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return (data['searches'] as List<dynamic>).cast<String>();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Get AI recommendations
  Future<List<String>> getAiRecommendations() async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}/search/ai-recommendations'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return (data['recommendations'] as List<dynamic>).cast<String>();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  /// Perform voice search (mock implementation)
  Future<String?> performVoiceSearch() async {
    try {
      // This would typically integrate with speech_to_text package
      // For now, return a mock result
      await Future.delayed(const Duration(seconds: 2));
      return 'voice search query'; // Mock result
    } catch (e) {
      throw Exception('Voice search error: $e');
    }
  }
  
  /// Track search event for analytics
  Future<void> trackSearchEvent({
    required String query,
    required SearchType searchType,
    required int resultCount,
    SearchFilter? filters,
  }) async {
    try {
      await http.post(
        Uri.parse('${_baseUrl}${Environment.ApiEndpoints.trackEvent}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'event': 'search',
          'query': query,
          'searchType': searchType.name,
          'resultCount': resultCount,
          'filters': filters?.toJson(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      // Analytics tracking failure should not break the app
      print('Failed to track search event: $e');
    }
  }
  
  /// Helper methods
  String _sortByToString(SearchSortBy sortBy) {
    switch (sortBy) {
      case SearchSortBy.relevance:
        return 'relevance';
      case SearchSortBy.priceAsc:
        return 'price_asc';
      case SearchSortBy.priceDesc:
        return 'price_desc';
      case SearchSortBy.ratingDesc:
        return 'rating_desc';
      case SearchSortBy.newest:
        return 'newest';
      case SearchSortBy.popularity:
        return 'popularity';
    }
  }
  
  Map<String, String> _filtersToParams(SearchFilter filters) {
    final params = <String, String>{};
    
    if (filters.minPrice != null) {
      params['minPrice'] = filters.minPrice.toString();
    }
    if (filters.maxPrice != null) {
      params['maxPrice'] = filters.maxPrice.toString();
    }
    if (filters.categories?.isNotEmpty ?? false) {
      params['categories'] = filters.categories!.join(',');
    }
    if (filters.brands?.isNotEmpty ?? false) {
      params['brands'] = filters.brands!.join(',');
    }
    if (filters.minRating != null) {
      params['minRating'] = filters.minRating.toString();
    }
    if (filters.inStock != null) {
      params['inStock'] = filters.inStock.toString();
    }
    if (filters.colors?.isNotEmpty ?? false) {
      params['colors'] = filters.colors!.join(',');
    }
    if (filters.sizes?.isNotEmpty ?? false) {
      params['sizes'] = filters.sizes!.join(',');
    }
    if (filters.freeShipping != null) {
      params['freeShipping'] = filters.freeShipping.toString();
    }
    if (filters.onSale != null) {
      params['onSale'] = filters.onSale.toString();
    }
    
    return params;
  }
}