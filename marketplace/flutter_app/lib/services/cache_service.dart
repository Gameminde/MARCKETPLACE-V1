import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';
import '../models/user.dart';
import '../models/cart_item.dart';
import '../models/order.dart';

/// Cache priority levels for data management
enum CachePriority { low, medium, high, critical }

/// Cache entry model with metadata
class CacheEntry<T> {
  final String key;
  final T data;
  final DateTime timestamp;
  final Duration? expiry;
  final CachePriority priority;
  final int accessCount;
  final DateTime lastAccessed;
  final String? etag;
  final Map<String, dynamic>? metadata;
  
  const CacheEntry({
    required this.key,
    required this.data,
    required this.timestamp,
    this.expiry,
    this.priority = CachePriority.medium,
    this.accessCount = 0,
    required this.lastAccessed,
    this.etag,
    this.metadata,
  });
  
  bool get isExpired {
    if (expiry == null) return false;
    return DateTime.now().difference(timestamp) > expiry!;
  }
  
  bool get isStale {
    // Consider data stale if it's older than the configured stale threshold
    final staleThreshold = _getStaleThreshold(priority);
    return DateTime.now().difference(timestamp) > staleThreshold;
  }
  
  Duration _getStaleThreshold(CachePriority priority) {
    switch (priority) {
      case CachePriority.critical:
        return const Duration(minutes: 5);
      case CachePriority.high:
        return const Duration(minutes: 15);
      case CachePriority.medium:
        return const Duration(hours: 1);
      case CachePriority.low:
        return const Duration(hours: 6);
    }
  }
  
  CacheEntry<T> copyWith({
    String? key,
    T? data,
    DateTime? timestamp,
    Duration? expiry,
    CachePriority? priority,
    int? accessCount,
    DateTime? lastAccessed,
    String? etag,
    Map<String, dynamic>? metadata,
  }) {
    return CacheEntry<T>(
      key: key ?? this.key,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      expiry: expiry ?? this.expiry,
      priority: priority ?? this.priority,
      accessCount: accessCount ?? this.accessCount,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      etag: etag ?? this.etag,
      metadata: metadata ?? this.metadata,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': _serializeData(data),
      'timestamp': timestamp.toIso8601String(),
      'expiry': expiry?.inMilliseconds,
      'priority': priority.name,
      'access_count': accessCount,
      'last_accessed': lastAccessed.toIso8601String(),
      'etag': etag,
      'metadata': metadata,
    };
  }
  
  static CacheEntry<T> fromJson<T>(Map<String, dynamic> json, T Function(dynamic) fromJsonCallback) {
    return CacheEntry<T>(
      key: json['key'],
      data: fromJsonCallback(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      expiry: json['expiry'] != null ? Duration(milliseconds: json['expiry']) : null,
      priority: CachePriority.values.firstWhere((e) => e.name == json['priority']),
      accessCount: json['access_count'] ?? 0,
      lastAccessed: DateTime.parse(json['last_accessed']),
      etag: json['etag'],
      metadata: json['metadata'],
    );
  }
  
  dynamic _serializeData(T data) {
    if (data is String || data is num || data is bool || data == null) {
      return data;
    } else if (data is List) {
      return data.map((item) => _serializeData(item)).toList();
    } else if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), _serializeData(value)));
    } else {
      // Try to convert to JSON if the object has a toJson method
      try {
        return (data as dynamic).toJson();
      } catch (e) {
        return data.toString();
      }
    }
  }
}

/// Cache statistics for monitoring
class CacheStats {
  final int totalEntries;
  final int totalSize;
  final double hitRate;
  final double missRate;
  final int evictions;
  final Map<CachePriority, int> entriesByPriority;
  final DateTime lastCleanup;
  
  const CacheStats({
    required this.totalEntries,
    required this.totalSize,
    required this.hitRate,
    required this.missRate,
    required this.evictions,
    required this.entriesByPriority,
    required this.lastCleanup,
  });
}

/// Comprehensive cache service for offline support and performance optimization
class CacheService {
  static CacheService? _instance;
  static CacheService get instance => _instance ??= CacheService._internal();
  
  CacheService._internal();
  
  // Cache storage
  final Map<String, CacheEntry> _memoryCache = {};
  SharedPreferences? _prefs;
  
  // Cache configuration
  static const int _maxMemoryCacheSize = 100; // MB
  static const int _maxMemoryCacheEntries = 1000;
  static const Duration _defaultExpiry = Duration(hours: 24);
  static const Duration _cleanupInterval = Duration(hours: 6);
  
  // Cache statistics
  int _hits = 0;
  int _misses = 0;
  int _evictions = 0;
  DateTime _lastCleanup = DateTime.now();
  
  // Cache categories
  static const String _userDataPrefix = 'user_';
  static const String _productDataPrefix = 'product_';
  static const String _cartDataPrefix = 'cart_';
  static const String _orderDataPrefix = 'order_';
  static const String _searchDataPrefix = 'search_';
  static const String _apiResponsePrefix = 'api_';
  static const String _imageDataPrefix = 'image_';
  
  /// Initialize cache service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadPersistentCache();
      await _scheduleCleanup();
      debugPrint('CacheService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize CacheService: $e');
    }
  }
  
  /// Store data in cache with optional expiry and priority
  Future<void> put<T>(
    String key,
    T data, {
    Duration? expiry,
    CachePriority priority = CachePriority.medium,
    String? etag,
    Map<String, dynamic>? metadata,
    bool persistent = false,
  }) async {
    try {
      final entry = CacheEntry<T>(
        key: key,
        data: data,
        timestamp: DateTime.now(),
        expiry: expiry ?? _defaultExpiry,
        priority: priority,
        accessCount: 0,
        lastAccessed: DateTime.now(),
        etag: etag,
        metadata: metadata,
      );
      
      // Store in memory cache
      _memoryCache[key] = entry;
      
      // Store in persistent cache if requested
      if (persistent && _prefs != null) {
        await _saveToPersistentCache(key, entry);
      }
      
      // Cleanup if cache is too large
      await _enforceMemoryLimits();
      
    } catch (e) {
      debugPrint('Error storing cache entry for key $key: $e');
    }
  }
  
  /// Retrieve data from cache
  Future<T?> get<T>(String key, {T Function(dynamic)? fromJsonCallback}) async {
    try {
      // Check memory cache first
      CacheEntry? entry = _memoryCache[key];
      
      // Check persistent cache if not in memory
      if (entry == null && _prefs != null) {
        entry = await _loadFromPersistentCache<T>(key, fromJsonCallback);
        if (entry != null) {
          _memoryCache[key] = entry;
        }
      }
      
      if (entry != null) {
        // Check if entry is expired
        if (entry.isExpired) {
          await remove(key);
          _misses++;
          return null;
        }
        
        // Update access statistics
        _memoryCache[key] = entry.copyWith(
          accessCount: entry.accessCount + 1,
          lastAccessed: DateTime.now(),
        );
        
        _hits++;
        return entry.data as T?;
      }
      
      _misses++;
      return null;
      
    } catch (e) {
      debugPrint('Error retrieving cache entry for key $key: $e');
      _misses++;
      return null;
    }
  }
  
  /// Check if key exists and is not expired
  Future<bool> contains(String key) async {
    final entry = _memoryCache[key];
    if (entry != null && !entry.isExpired) {
      return true;
    }
    
    if (_prefs != null) {
      final persistentEntry = await _loadFromPersistentCache(key, null);
      return persistentEntry != null && !persistentEntry.isExpired;
    }
    
    return false;
  }
  
  /// Remove entry from cache
  Future<void> remove(String key) async {
    _memoryCache.remove(key);
    
    if (_prefs != null) {
      await _prefs!.remove('cache_$key');
    }
  }
  
  /// Clear all cache entries
  Future<void> clear() async {
    _memoryCache.clear();
    
    if (_prefs != null) {
      final keys = _prefs!.getKeys().where((key) => key.startsWith('cache_'));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
    }
    
    _hits = 0;
    _misses = 0;
    _evictions = 0;
  }
  
  /// Clear cache entries by prefix
  Future<void> clearByPrefix(String prefix) async {
    final keysToRemove = _memoryCache.keys
        .where((key) => key.startsWith(prefix))
        .toList();
    
    for (final key in keysToRemove) {
      await remove(key);
    }
  }
  
  /// Get cache statistics
  CacheStats getStats() {
    final totalRequests = _hits + _misses;
    final hitRate = totalRequests > 0 ? _hits / totalRequests : 0.0;
    final missRate = totalRequests > 0 ? _misses / totalRequests : 0.0;
    
    final entriesByPriority = <CachePriority, int>{};
    for (final priority in CachePriority.values) {
      entriesByPriority[priority] = _memoryCache.values
          .where((entry) => entry.priority == priority)
          .length;
    }
    
    return CacheStats(
      totalEntries: _memoryCache.length,
      totalSize: _estimateCacheSize(),
      hitRate: hitRate,
      missRate: missRate,
      evictions: _evictions,
      entriesByPriority: entriesByPriority,
      lastCleanup: _lastCleanup,
    );
  }
  
  // =============================================================================
  // SPECIALIZED CACHE METHODS
  // =============================================================================
  
  /// Cache user data
  Future<void> cacheUser(User user) async {
    await put(
      '$_userDataPrefix${user.id}',
      user,
      priority: CachePriority.high,
      persistent: true,
    );
  }
  
  /// Get cached user
  Future<User?> getCachedUser(String userId) async {
    return await get<User>(
      '$_userDataPrefix$userId',
      fromJsonCallback: (json) => User.fromJson(json),
    );
  }
  
  /// Cache product data
  Future<void> cacheProduct(Product product) async {
    await put(
      '$_productDataPrefix${product.id}',
      product,
      priority: CachePriority.medium,
      persistent: true,
    );
  }
  
  /// Get cached product
  Future<Product?> getCachedProduct(String productId) async {
    return await get<Product>(
      '$_productDataPrefix$productId',
      fromJsonCallback: (json) => Product.fromJson(json),
    );
  }
  
  /// Cache cart data
  Future<void> cacheCart(List<CartItem> cartItems) async {
    await put(
      '${_cartDataPrefix}current',
      cartItems,
      priority: CachePriority.high,
      persistent: true,
    );
  }
  
  /// Get cached cart
  Future<List<CartItem>?> getCachedCart() async {
    return await get<List<CartItem>>(
      '${_cartDataPrefix}current',
      fromJsonCallback: (json) => (json as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
    );
  }
  
  /// Cache order data
  Future<void> cacheOrder(Order order) async {
    await put(
      '$_orderDataPrefix${order.id}',
      order,
      priority: CachePriority.high,
      persistent: true,
    );
  }
  
  /// Get cached order
  Future<Order?> getCachedOrder(String orderId) async {
    return await get<Order>(
      '$_orderDataPrefix$orderId',
      fromJsonCallback: (json) => Order.fromJson(json),
    );
  }
  
  /// Cache search results
  Future<void> cacheSearchResults(String query, List<Product> products) async {
    final key = '$_searchDataPrefix${_hashString(query)}';
    await put(
      key,
      products,
      expiry: const Duration(hours: 2),
      priority: CachePriority.low,
    );
  }
  
  /// Get cached search results
  Future<List<Product>?> getCachedSearchResults(String query) async {
    final key = '$_searchDataPrefix${_hashString(query)}';
    return await get<List<Product>>(
      key,
      fromJsonCallback: (json) => (json as List)
          .map((item) => Product.fromJson(item))
          .toList(),
    );
  }
  
  /// Cache API response
  Future<void> cacheApiResponse(
    String endpoint,
    Map<String, dynamic> response, {
    Duration? expiry,
    String? etag,
  }) async {
    final key = '$_apiResponsePrefix${_hashString(endpoint)}';
    await put(
      key,
      response,
      expiry: expiry ?? const Duration(minutes: 30),
      priority: CachePriority.medium,
      etag: etag,
    );
  }
  
  /// Get cached API response
  Future<Map<String, dynamic>?> getCachedApiResponse(String endpoint) async {
    final key = '$_apiResponsePrefix${_hashString(endpoint)}';
    return await get<Map<String, dynamic>>(key);
  }
  
  /// Check if API response is stale (should be refreshed)
  Future<bool> isApiResponseStale(String endpoint) async {
    final key = '$_apiResponsePrefix${_hashString(endpoint)}';
    final entry = _memoryCache[key];
    return entry?.isStale ?? true;
  }
  
  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================
  
  /// Load persistent cache from SharedPreferences
  Future<void> _loadPersistentCache() async {
    if (_prefs == null) return;
    
    try {
      final keys = _prefs!.getKeys().where((key) => key.startsWith('cache_'));
      
      for (final key in keys) {
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          final json = jsonDecode(jsonString);
          final cacheKey = key.substring(6); // Remove 'cache_' prefix
          
          // Only load if not expired
          final timestamp = DateTime.parse(json['timestamp']);
          final expiry = json['expiry'] != null 
              ? Duration(milliseconds: json['expiry']) 
              : null;
          
          if (expiry == null || DateTime.now().difference(timestamp) <= expiry) {
            final entry = CacheEntry<dynamic>(
              key: cacheKey,
              data: json['data'],
              timestamp: timestamp,
              expiry: expiry,
              priority: CachePriority.values.firstWhere((e) => e.name == json['priority']),
              accessCount: json['access_count'] ?? 0,
              lastAccessed: DateTime.parse(json['last_accessed']),
              etag: json['etag'],
              metadata: json['metadata'],
            );
            
            _memoryCache[cacheKey] = entry;
          } else {
            // Remove expired entry
            await _prefs!.remove(key);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading persistent cache: $e');
    }
  }
  
  /// Load single entry from persistent cache
  Future<CacheEntry<T>?> _loadFromPersistentCache<T>(
    String key,
    T Function(dynamic)? fromJsonCallback,
  ) async {
    if (_prefs == null) return null;
    
    try {
      final jsonString = _prefs!.getString('cache_$key');
      if (jsonString != null) {
        final json = jsonDecode(jsonString);
        
        final timestamp = DateTime.parse(json['timestamp']);
        final expiry = json['expiry'] != null 
            ? Duration(milliseconds: json['expiry']) 
            : null;
        
        // Check if expired
        if (expiry != null && DateTime.now().difference(timestamp) > expiry) {
          await _prefs!.remove('cache_$key');
          return null;
        }
        
        return CacheEntry<T>(
          key: key,
          data: fromJsonCallback != null ? fromJsonCallback(json['data']) : json['data'],
          timestamp: timestamp,
          expiry: expiry,
          priority: CachePriority.values.firstWhere((e) => e.name == json['priority']),
          accessCount: json['access_count'] ?? 0,
          lastAccessed: DateTime.parse(json['last_accessed']),
          etag: json['etag'],
          metadata: json['metadata'],
        );
      }
    } catch (e) {
      debugPrint('Error loading persistent cache entry for key $key: $e');
    }
    
    return null;
  }
  
  /// Save entry to persistent cache
  Future<void> _saveToPersistentCache(String key, CacheEntry entry) async {
    if (_prefs == null) return;
    
    try {
      final jsonString = jsonEncode(entry.toJson());
      await _prefs!.setString('cache_$key', jsonString);
    } catch (e) {
      debugPrint('Error saving persistent cache entry for key $key: $e');
    }
  }
  
  /// Enforce memory cache size limits
  Future<void> _enforceMemoryLimits() async {
    if (_memoryCache.length <= _maxMemoryCacheEntries) return;
    
    // Remove entries based on LRU and priority
    final entries = _memoryCache.entries.toList();
    entries.sort((a, b) {
      // First sort by priority (lower priority = higher eviction chance)
      final priorityCompare = a.value.priority.index.compareTo(b.value.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      
      // Then sort by last accessed time (older = higher eviction chance)
      return a.value.lastAccessed.compareTo(b.value.lastAccessed);
    });
    
    // Remove 20% of entries
    final entriesToRemove = (entries.length * 0.2).round();
    for (int i = 0; i < entriesToRemove; i++) {
      _memoryCache.remove(entries[i].key);
      _evictions++;
    }
  }
  
  /// Schedule periodic cache cleanup
  Future<void> _scheduleCleanup() async {
    // In a real app, you might use a timer or background service
    // For now, we'll just mark when cleanup should happen
    _lastCleanup = DateTime.now();
  }
  
  /// Perform cache cleanup
  Future<void> cleanup() async {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    // Find expired entries
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }
    
    // Remove expired entries
    for (final key in keysToRemove) {
      await remove(key);
    }
    
    _lastCleanup = now;
    debugPrint('Cache cleanup completed. Removed ${keysToRemove.length} expired entries.');
  }
  
  /// Estimate total cache size in bytes
  int _estimateCacheSize() {
    int totalSize = 0;
    for (final entry in _memoryCache.values) {
      try {
        final jsonString = jsonEncode(entry.toJson());
        totalSize += jsonString.length * 2; // Rough estimate (UTF-16)
      } catch (e) {
        // Fallback estimation
        totalSize += 1024; // 1KB fallback
      }
    }
    return totalSize;
  }
  
  /// Simple string hashing for cache keys
  String _hashString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xffffffff;
    }
    return hash.abs().toString();
  }
}