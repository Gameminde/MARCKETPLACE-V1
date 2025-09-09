import 'product.dart';

/// Search result container
class SearchResult {
  final bool success;
  final String? message;
  final List<Product> products;
  final int totalCount;
  final bool hasMore;
  final Map<String, dynamic>? insights;
  final List<SearchSuggestion>? suggestions;

  SearchResult({
    required this.success,
    this.message,
    this.products = const [],
    this.totalCount = 0,
    this.hasMore = false,
    this.insights,
    this.suggestions,
  });

  factory SearchResult.success({
    required List<Product> products,
    required int totalCount,
    bool hasMore = false,
    Map<String, dynamic>? insights,
    List<SearchSuggestion>? suggestions,
  }) {
    return SearchResult(
      success: true,
      products: products,
      totalCount: totalCount,
      hasMore: hasMore,
      insights: insights,
      suggestions: suggestions,
    );
  }

  factory SearchResult.error(String message) {
    return SearchResult(
      success: false,
      message: message,
    );
  }

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      products: (json['products'] as List<dynamic>?)
              ?.map((item) => Product.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] as int? ?? 0,
      hasMore: json['hasMore'] as bool? ?? false,
      insights: json['insights'] as Map<String, dynamic>?,
      suggestions: (json['suggestions'] as List<dynamic>?)
          ?.map(
              (item) => SearchSuggestion.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Search suggestion model
class SearchSuggestion {
  final String text;
  final String? category;
  final int? count;
  final bool isPopular;
  final bool isFromHistory;

  SearchSuggestion({
    required this.text,
    this.category,
    this.count,
    this.isPopular = false,
    this.isFromHistory = false,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      text: json['text'] as String,
      category: json['category'] as String?,
      count: json['count'] as int?,
      isPopular: json['isPopular'] as bool? ?? false,
      isFromHistory: json['isFromHistory'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'category': category,
      'count': count,
      'isPopular': isPopular,
      'isFromHistory': isFromHistory,
    };
  }
}

/// Search analytics data
class SearchAnalytics {
  final String query;
  final DateTime timestamp;
  final int resultCount;
  final String searchType;
  final Map<String, dynamic>? filters;
  final Duration? responseTime;

  SearchAnalytics({
    required this.query,
    required this.timestamp,
    required this.resultCount,
    required this.searchType,
    this.filters,
    this.responseTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'timestamp': timestamp.toIso8601String(),
      'resultCount': resultCount,
      'searchType': searchType,
      'filters': filters,
      'responseTime': responseTime?.inMilliseconds,
    };
  }
}
