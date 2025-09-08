import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../models/product.dart';
import '../models/search_result.dart';
import '../models/search_filter.dart';
import '../services/search_service.dart';
import '../core/config/app_constants.dart';

/// Search types supported by the provider
enum SearchType {
  text,
  voice,
  visual,
  barcode,
  ai,
}

/// Search sort options
enum SearchSortBy {
  relevance,
  priceAsc,
  priceDesc,
  ratingDesc,
  newest,
  popularity,
}

/// AI-powered Search Provider with advanced search capabilities,
/// filters, suggestions, and search history management
class SearchProvider extends ChangeNotifier {
  final SearchService _searchService = SearchService();
  
  // Search state
  String _currentQuery = '';
  SearchType _currentSearchType = SearchType.text;
  SearchSortBy _sortBy = SearchSortBy.relevance;
  List<Product> _searchResults = [];
  List<SearchSuggestion> _suggestions = [];
  List<String> _searchHistory = [];
  List<String> _popularSearches = [];
  SearchFilter _activeFilters = SearchFilter();
  
  // UI state
  bool _isLoading = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalResults = 0;
  
  // Search configuration
  Timer? _debounceTimer;
  int _debounceMs = AppConstants.searchDebounceMs;
  bool _autoSearchEnabled = true;
  bool _saveToHistory = true;
  
  // AI features
  bool _isAiSearchEnabled = true;
  bool _showAiSuggestions = true;
  List<String> _aiRecommendations = [];
  Map<String, dynamic>? _searchInsights;
  
  // Voice search
  bool _isVoiceSearchActive = false;
  String _voiceSearchQuery = '';
  
  // Visual search
  String? _visualSearchImagePath;
  bool _isVisualSearchActive = false;
  
  // Getters
  String get currentQuery => _currentQuery;
  SearchType get currentSearchType => _currentSearchType;
  SearchSortBy get sortBy => _sortBy;
  List<Product> get searchResults => List.unmodifiable(_searchResults);
  List<SearchSuggestion> get suggestions => List.unmodifiable(_suggestions);
  List<String> get searchHistory => List.unmodifiable(_searchHistory);
  List<String> get popularSearches => List.unmodifiable(_popularSearches);
  SearchFilter get activeFilters => _activeFilters;
  
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalResults => _totalResults;
  
  Timer? get debounceTimer => _debounceTimer;
  int get debounceMs => _debounceMs;
  bool get autoSearchEnabled => _autoSearchEnabled;
  bool get saveToHistory => _saveToHistory;
  
  bool get isAiSearchEnabled => _isAiSearchEnabled;
  bool get showAiSuggestions => _showAiSuggestions;
  List<String> get aiRecommendations => List.unmodifiable(_aiRecommendations);
  Map<String, dynamic>? get searchInsights => _searchInsights;
  
  bool get isVoiceSearchActive => _isVoiceSearchActive;
  String get voiceSearchQuery => _voiceSearchQuery;
  
  String? get visualSearchImagePath => _visualSearchImagePath;
  bool get isVisualSearchActive => _isVisualSearchActive;
  
  /// Check if there are active filters
  bool get hasActiveFilters => _activeFilters.hasActiveFilters;
  
  /// Check if search has results
  bool get hasResults => _searchResults.isNotEmpty;
  
  /// Check if search is empty
  bool get isSearchEmpty => _currentQuery.trim().isEmpty;
  
  /// Initialize search provider
  Future<void> initialize() async {
    await _loadSearchHistory();
    await _loadSearchPreferences();
    await _loadPopularSearches();
    
    if (_isAiSearchEnabled) {
      await _loadAiRecommendations();
    }
  }
  
  /// Perform text search with debouncing
  Future<void> search(String query, {bool immediate = false}) async {
    if (query.trim().isEmpty) {
      clearSearch();
      return;
    }
    
    _currentQuery = query.trim();
    _currentSearchType = SearchType.text;
    
    if (immediate) {
      _debounceTimer?.cancel();
      await _performSearch();
    } else if (_autoSearchEnabled) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: _debounceMs), () {
        _performSearch();
      });
    }
    
    // Load suggestions while user is typing
    await _loadSuggestions(query);
    
    notifyListeners();
  }
  
  /// Perform AI-powered search
  Future<void> aiSearch(String query) async {
    if (!_isAiSearchEnabled) {
      await search(query, immediate: true);
      return;
    }
    
    _setLoading(true);
    _clearError();
    _currentQuery = query.trim();
    _currentSearchType = SearchType.ai;
    
    try {
      final result = await _searchService.aiSearch(
        query: query,
        filters: _activeFilters,
        sortBy: _sortBy,
        page: 1,
      );
      
      if (result.success) {
        _searchResults = result.products;
        _totalResults = result.totalCount;
        _searchInsights = result.insights;
        _currentPage = 1;
        _hasMore = result.hasMore;
        
        await _addToSearchHistory(query);
        await _trackSearchEvent(query, SearchType.ai);
      } else {
        _setError(result.message ?? 'AI search failed');
      }
    } catch (e) {
      _setError('AI search error: $e');
    } finally {
      _setLoading(false);
    }
    
    notifyListeners();
  }
  
  /// Perform voice search
  Future<void> voiceSearch() async {
    _isVoiceSearchActive = true;
    _currentSearchType = SearchType.voice;
    notifyListeners();
    
    try {
      final voiceQuery = await _searchService.performVoiceSearch();
      
      if (voiceQuery != null && voiceQuery.isNotEmpty) {
        _voiceSearchQuery = voiceQuery;
        await search(voiceQuery, immediate: true);
      }
    } catch (e) {
      _setError('Voice search error: $e');
    } finally {
      _isVoiceSearchActive = false;
      notifyListeners();
    }
  }
  
  /// Perform visual search with image
  Future<void> visualSearch(String imagePath) async {
    _setLoading(true);
    _clearError();
    _isVisualSearchActive = true;
    _visualSearchImagePath = imagePath;
    _currentSearchType = SearchType.visual;
    
    try {
      final result = await _searchService.visualSearch(
        imagePath: imagePath,
        filters: _activeFilters,
        sortBy: _sortBy,
      );
      
      if (result.success) {
        _searchResults = result.products;
        _totalResults = result.totalCount;
        _currentPage = 1;
        _hasMore = result.hasMore;
        
        await _trackSearchEvent('visual_search', SearchType.visual);
      } else {
        _setError(result.message ?? 'Visual search failed');
      }
    } catch (e) {
      _setError('Visual search error: $e');
    } finally {
      _setLoading(false);
      _isVisualSearchActive = false;
      notifyListeners();
    }
  }
  
  /// Perform barcode search
  Future<void> barcodeSearch(String barcode) async {
    _setLoading(true);
    _clearError();
    _currentSearchType = SearchType.barcode;
    
    try {
      final result = await _searchService.barcodeSearch(barcode);
      
      if (result.success) {
        _searchResults = result.products;
        _totalResults = result.totalCount;
        _currentPage = 1;
        _hasMore = result.hasMore;
        
        await _trackSearchEvent(barcode, SearchType.barcode);
      } else {
        _setError(result.message ?? 'Product not found');
      }
    } catch (e) {
      _setError('Barcode search error: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }
  
  /// Load more search results (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    
    _isLoadingMore = true;
    notifyListeners();
    
    try {
      final nextPage = _currentPage + 1;
      final result = await _searchService.search(
        query: _currentQuery,
        filters: _activeFilters,
        sortBy: _sortBy,
        page: nextPage,
      );
      
      if (result.success) {
        _searchResults.addAll(result.products);
        _currentPage = nextPage;
        _hasMore = result.hasMore;
      }
    } catch (e) {
      debugPrint('Load more error: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }
  
  /// Apply search filters
  Future<void> applyFilters(SearchFilter filters) async {
    _activeFilters = filters;
    
    if (_currentQuery.isNotEmpty) {
      await _performSearch(resetPage: true);
    } else {
      notifyListeners();
    }
  }
  
  /// Clear all filters
  Future<void> clearFilters() async {
    _activeFilters = SearchFilter();
    
    if (_currentQuery.isNotEmpty) {
      await _performSearch(resetPage: true);
    } else {
      notifyListeners();
    }
  }
  
  /// Change sort order
  Future<void> setSortBy(SearchSortBy sortBy) async {
    _sortBy = sortBy;
    
    if (_currentQuery.isNotEmpty || hasActiveFilters) {
      await _performSearch(resetPage: true);
    } else {
      notifyListeners();
    }
  }
  
  /// Clear search results and query
  void clearSearch() {
    _currentQuery = '';
    _searchResults.clear();
    _suggestions.clear();
    _totalResults = 0;
    _currentPage = 1;
    _hasMore = true;
    _clearError();
    _visualSearchImagePath = null;
    _voiceSearchQuery = '';
    _searchInsights = null;
    
    _debounceTimer?.cancel();
    
    notifyListeners();
  }
  
  /// Add query to search history
  Future<void> addToHistory(String query) async {
    await _addToSearchHistory(query);
  }
  
  /// Remove query from search history
  Future<void> removeFromHistory(String query) async {
    _searchHistory.remove(query);
    await _saveSearchHistory();
    notifyListeners();
  }
  
  /// Clear all search history
  Future<void> clearHistory() async {
    _searchHistory.clear();
    await _saveSearchHistory();
    notifyListeners();
  }
  
  /// Get search suggestions based on query
  Future<void> getSuggestions(String query) async {
    await _loadSuggestions(query);
  }
  
  /// Set auto search enabled/disabled
  void setAutoSearchEnabled(bool enabled) {
    _autoSearchEnabled = enabled;
    notifyListeners();
  }
  
  /// Set search history saving enabled/disabled
  Future<void> setSaveToHistory(bool enabled) async {
    _saveToHistory = enabled;
    await _saveSearchPreferences();
    notifyListeners();
  }
  
  /// Set AI search enabled/disabled
  Future<void> setAiSearchEnabled(bool enabled) async {
    _isAiSearchEnabled = enabled;
    
    if (enabled) {
      await _loadAiRecommendations();
    }
    
    await _saveSearchPreferences();
    notifyListeners();
  }
  
  /// Set debounce duration
  void setDebounceMs(int ms) {
    _debounceMs = ms;
    notifyListeners();
  }
  
  /// Get trending searches
  Future<void> loadTrendingSearches() async {
    try {
      final trending = await _searchService.getTrendingSearches();
      _popularSearches = trending;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading trending searches: $e');
    }
  }
  
  /// Private methods
  Future<void> _performSearch({bool resetPage = true}) async {
    if (_currentQuery.trim().isEmpty) return;
    
    _setLoading(true);
    _clearError();
    
    if (resetPage) {
      _currentPage = 1;
      _hasMore = true;
    }
    
    try {
      SearchResult result;
      
      switch (_currentSearchType) {
        case SearchType.ai:
          result = await _searchService.aiSearch(
            query: _currentQuery,
            filters: _activeFilters,
            sortBy: _sortBy,
            page: _currentPage,
          );
          break;
        default:
          result = await _searchService.search(
            query: _currentQuery,
            filters: _activeFilters,
            sortBy: _sortBy,
            page: _currentPage,
          );
      }
      
      if (result.success) {
        if (resetPage) {
          _searchResults = result.products;
        } else {
          _searchResults.addAll(result.products);
        }
        
        _totalResults = result.totalCount;
        _hasMore = result.hasMore;
        _searchInsights = result.insights;
        
        await _addToSearchHistory(_currentQuery);
        await _trackSearchEvent(_currentQuery, _currentSearchType);
      } else {
        _setError(result.message ?? 'Search failed');
      }
    } catch (e) {
      _setError('Search error: $e');
    } finally {
      _setLoading(false);
    }
    
    notifyListeners();
  }
  
  Future<void> _loadSuggestions(String query) async {
    if (query.length < AppConstants.minSearchLength) {
      _suggestions.clear();
      return;
    }
    
    try {
      final suggestions = await _searchService.getSuggestions(query);
      _suggestions = suggestions.take(AppConstants.searchSuggestionLimit).toList();
    } catch (e) {
      debugPrint('Error loading suggestions: $e');
    }
  }
  
  Future<void> _addToSearchHistory(String query) async {
    if (!_saveToHistory || query.trim().isEmpty) return;
    
    // Remove if already exists to move to top
    _searchHistory.remove(query);
    
    // Add to beginning
    _searchHistory.insert(0, query);
    
    // Limit history size
    if (_searchHistory.length > AppConstants.searchHistoryLimit) {
      _searchHistory = _searchHistory.take(AppConstants.searchHistoryLimit).toList();
    }
    
    await _saveSearchHistory();
  }
  
  Future<void> _trackSearchEvent(String query, SearchType type) async {
    try {
      await _searchService.trackSearchEvent(
        query: query,
        searchType: type,
        resultCount: _totalResults,
        filters: _activeFilters,
      );
    } catch (e) {
      debugPrint('Error tracking search event: $e');
    }
  }
  
  Future<void> _loadAiRecommendations() async {
    try {
      final recommendations = await _searchService.getAiRecommendations();
      _aiRecommendations = recommendations;
    } catch (e) {
      debugPrint('Error loading AI recommendations: $e');
    }
  }
  
  /// Storage methods
  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('search_history');
      
      if (historyJson != null) {
        final historyList = json.decode(historyJson) as List<dynamic>;
        _searchHistory = historyList.cast<String>();
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
    }
  }
  
  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = json.encode(_searchHistory);
      await prefs.setString('search_history', historyJson);
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }
  
  Future<void> _loadSearchPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoSearchEnabled = prefs.getBool('auto_search_enabled') ?? true;
      _saveToHistory = prefs.getBool('save_search_history') ?? true;
      _isAiSearchEnabled = prefs.getBool('ai_search_enabled') ?? true;
      _showAiSuggestions = prefs.getBool('show_ai_suggestions') ?? true;
      _debounceMs = prefs.getInt('search_debounce_ms') ?? AppConstants.searchDebounceMs;
    } catch (e) {
      debugPrint('Error loading search preferences: $e');
    }
  }
  
  Future<void> _saveSearchPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_search_enabled', _autoSearchEnabled);
      await prefs.setBool('save_search_history', _saveToHistory);
      await prefs.setBool('ai_search_enabled', _isAiSearchEnabled);
      await prefs.setBool('show_ai_suggestions', _showAiSuggestions);
      await prefs.setInt('search_debounce_ms', _debounceMs);
    } catch (e) {
      debugPrint('Error saving search preferences: $e');
    }
  }
  
  Future<void> _loadPopularSearches() async {
    try {
      final popular = await _searchService.getPopularSearches();
      _popularSearches = popular;
    } catch (e) {
      debugPrint('Error loading popular searches: $e');
    }
  }
  
  /// Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _clearError();
  }
  
  void _setError(String message) {
    _errorMessage = message;
    _isLoading = false;
  }
  
  void _clearError() {
    _errorMessage = null;
  }
  
  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}