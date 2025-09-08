import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

import '../core/config/app_constants.dart';
import 'cache_service.dart';

/// Image cache configuration
class ImageCacheConfig {
  final int maxMemoryCacheSize; // in MB
  final int maxDiskCacheSize; // in MB
  final Duration diskCacheExpiry;
  final Duration memoryCacheExpiry;
  final int maxConcurrentDownloads;
  final bool enableDiskCache;
  final bool enableMemoryCache;
  final List<String> allowedDomains;
  
  const ImageCacheConfig({
    this.maxMemoryCacheSize = 50,
    this.maxDiskCacheSize = 200,
    this.diskCacheExpiry = const Duration(days: 30),
    this.memoryCacheExpiry = const Duration(hours: 6),
    this.maxConcurrentDownloads = 3,
    this.enableDiskCache = true,
    this.enableMemoryCache = true,
    this.allowedDomains = const [],
  });
}

/// Image cache entry with metadata
class ImageCacheEntry {
  final String url;
  final Uint8List data;
  final DateTime timestamp;
  final String etag;
  final String contentType;
  final int size;
  final Map<String, String> headers;
  
  const ImageCacheEntry({
    required this.url,
    required this.data,
    required this.timestamp,
    required this.etag,
    required this.contentType,
    required this.size,
    required this.headers,
  });
  
  bool isExpired(Duration expiry) {
    return DateTime.now().difference(timestamp) > expiry;
  }
  
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'data': base64Encode(data),
      'timestamp': timestamp.toIso8601String(),
      'etag': etag,
      'content_type': contentType,
      'size': size,
      'headers': headers,
    };
  }
  
  static ImageCacheEntry fromJson(Map<String, dynamic> json) {
    return ImageCacheEntry(
      url: json['url'],
      data: base64Decode(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      etag: json['etag'],
      contentType: json['content_type'],
      size: json['size'],
      headers: Map<String, String>.from(json['headers']),
    );
  }
}

/// Image loading priority
enum ImagePriority { low, normal, high }

/// Image loading request
class ImageRequest {
  final String url;
  final ImagePriority priority;
  final Map<String, String>? headers;
  final Duration? timeout;
  final String? cacheKey;
  final bool useCache;
  
  const ImageRequest({
    required this.url,
    this.priority = ImagePriority.normal,
    this.headers,
    this.timeout,
    this.cacheKey,
    this.useCache = true,
  });
  
  String get effectiveCacheKey => cacheKey ?? _generateCacheKey(url);
  
  static String _generateCacheKey(String url) {
    return md5.convert(utf8.encode(url)).toString();
  }
}

/// Image loading result
class ImageResult {
  final ui.Image? image;
  final Uint8List? data;
  final String? error;
  final bool fromCache;
  final ImageCacheEntry? cacheEntry;
  
  const ImageResult({
    this.image,
    this.data,
    this.error,
    this.fromCache = false,
    this.cacheEntry,
  });
  
  bool get isSuccess => image != null && error == null;
  bool get hasError => error != null;
}

/// Image cache statistics
class ImageCacheStats {
  final int memoryHits;
  final int diskHits;
  final int networkRequests;
  final int totalRequests;
  final int memoryCacheSize;
  final int diskCacheSize;
  final double memoryUsageMB;
  final double diskUsageMB;
  final List<String> recentErrors;
  
  const ImageCacheStats({
    required this.memoryHits,
    required this.diskHits,
    required this.networkRequests,
    required this.totalRequests,
    required this.memoryCacheSize,
    required this.diskCacheSize,
    required this.memoryUsageMB,
    required this.diskUsageMB,
    required this.recentErrors,
  });
  
  double get hitRate => totalRequests > 0 ? (memoryHits + diskHits) / totalRequests : 0.0;
  double get cacheEfficiency => totalRequests > 0 ? 1.0 - (networkRequests / totalRequests) : 0.0;
}

/// Comprehensive image cache service for optimized image loading
class ImageCacheService {
  static ImageCacheService? _instance;
  static ImageCacheService get instance => _instance ??= ImageCacheService._internal();
  
  ImageCacheService._internal();
  
  // Configuration
  ImageCacheConfig _config = const ImageCacheConfig();
  
  // Memory cache
  final Map<String, ImageCacheEntry> _memoryCache = {};
  final Map<String, ui.Image> _imageCache = {};
  int _memoryCacheSize = 0;
  
  // Disk cache
  Directory? _cacheDirectory;
  
  // Download management
  final Map<String, Future<ImageResult>> _downloadTasks = {};
  final Set<String> _downloadingUrls = {};
  int _activeDownloads = 0;
  
  // Statistics
  int _memoryHits = 0;
  int _diskHits = 0;
  int _networkRequests = 0;
  int _totalRequests = 0;
  final List<String> _recentErrors = [];
  
  /// Initialize the image cache service
  Future<void> initialize({ImageCacheConfig? config}) async {
    if (config != null) {
      _config = config;
    }
    
    try {
      // Initialize disk cache directory
      if (_config.enableDiskCache) {
        final appDir = await getApplicationCacheDirectory();
        _cacheDirectory = Directory('${appDir.path}/image_cache');
        
        if (!await _cacheDirectory!.exists()) {
          await _cacheDirectory!.create(recursive: true);
        }
        
        // Clean up expired cache files
        await _cleanupExpiredCache();
      }
      
      debugPrint('ImageCacheService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize ImageCacheService: $e');
      _addError('Initialization failed: $e');
    }
  }
  
  /// Load image with caching
  Future<ImageResult> loadImage(ImageRequest request) async {
    _totalRequests++;
    
    try {
      // Check if domain is allowed
      if (_config.allowedDomains.isNotEmpty && !_isDomainAllowed(request.url)) {
        return ImageResult(error: 'Domain not allowed: ${Uri.parse(request.url).host}');
      }
      
      // Check memory cache first
      if (_config.enableMemoryCache && request.useCache) {
        final memoryResult = await _loadFromMemoryCache(request);
        if (memoryResult.isSuccess) {
          _memoryHits++;
          return memoryResult;
        }
      }
      
      // Check disk cache
      if (_config.enableDiskCache && request.useCache) {
        final diskResult = await _loadFromDiskCache(request);
        if (diskResult.isSuccess) {
          _diskHits++;
          
          // Store in memory cache for faster access
          if (_config.enableMemoryCache && diskResult.cacheEntry != null) {
            await _storeInMemoryCache(request.effectiveCacheKey, diskResult.cacheEntry!);
          }
          
          return diskResult;
        }
      }
      
      // Download from network
      return await _downloadImage(request);
      
    } catch (e) {
      final error = 'Failed to load image ${request.url}: $e';
      _addError(error);
      return ImageResult(error: error);
    }
  }
  
  /// Preload images for better performance
  Future<void> preloadImages(List<String> urls, {ImagePriority priority = ImagePriority.low}) async {
    final futures = <Future<ImageResult>>[];
    
    for (final url in urls) {
      final request = ImageRequest(
        url: url,
        priority: priority,
        useCache: true,
      );
      
      futures.add(loadImage(request));
      
      // Limit concurrent preloading
      if (futures.length >= _config.maxConcurrentDownloads) {
        await Future.wait(futures);
        futures.clear();
      }
    }
    
    // Wait for remaining downloads
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }
  
  /// Clear specific image from cache
  Future<void> evictImage(String url) async {
    final cacheKey = ImageRequest._generateCacheKey(url);
    
    // Remove from memory cache
    _memoryCache.remove(cacheKey);
    _imageCache.remove(cacheKey);
    
    // Remove from disk cache
    if (_config.enableDiskCache && _cacheDirectory != null) {
      final file = File('${_cacheDirectory!.path}/$cacheKey');
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
  
  /// Clear all cached images
  Future<void> clearCache() async {
    // Clear memory cache
    _memoryCache.clear();
    _imageCache.clear();
    _memoryCacheSize = 0;
    
    // Clear disk cache
    if (_config.enableDiskCache && _cacheDirectory != null) {
      try {
        await _cacheDirectory!.delete(recursive: true);
        await _cacheDirectory!.create(recursive: true);
      } catch (e) {
        debugPrint('Error clearing disk cache: $e');
      }
    }
    
    // Reset statistics
    _memoryHits = 0;
    _diskHits = 0;
    _networkRequests = 0;
    _totalRequests = 0;
    _recentErrors.clear();
  }
  
  /// Get cache statistics
  ImageCacheStats getStats() {
    double memoryUsageMB = _memoryCacheSize / (1024 * 1024);
    double diskUsageMB = 0.0;
    
    // Calculate disk usage (this would be expensive in real implementation)
    // For demo purposes, we'll estimate based on number of cached files
    if (_config.enableDiskCache) {
      diskUsageMB = _memoryCache.length * 0.5; // Rough estimate
    }
    
    return ImageCacheStats(
      memoryHits: _memoryHits,
      diskHits: _diskHits,
      networkRequests: _networkRequests,
      totalRequests: _totalRequests,
      memoryCacheSize: _imageCache.length,
      diskCacheSize: _memoryCache.length,
      memoryUsageMB: memoryUsageMB,
      diskUsageMB: diskUsageMB,
      recentErrors: List.from(_recentErrors),
    );
  }
  
  /// Get cached image synchronously (memory only)
  ui.Image? getCachedImage(String url) {
    final cacheKey = ImageRequest._generateCacheKey(url);
    return _imageCache[cacheKey];
  }
  
  /// Check if image is cached (memory or disk)
  Future<bool> isCached(String url) async {
    final cacheKey = ImageRequest._generateCacheKey(url);
    
    // Check memory cache
    if (_imageCache.containsKey(cacheKey)) {
      return true;
    }
    
    // Check disk cache
    if (_config.enableDiskCache && _cacheDirectory != null) {
      final file = File('${_cacheDirectory!.path}/$cacheKey');
      return await file.exists();
    }
    
    return false;
  }
  
  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================
  
  /// Load image from memory cache
  Future<ImageResult> _loadFromMemoryCache(ImageRequest request) async {
    final cacheKey = request.effectiveCacheKey;
    final cacheEntry = _memoryCache[cacheKey];
    final cachedImage = _imageCache[cacheKey];
    
    if (cacheEntry != null && cachedImage != null) {
      // Check if expired
      if (!cacheEntry.isExpired(_config.memoryCacheExpiry)) {
        return ImageResult(
          image: cachedImage,
          data: cacheEntry.data,
          fromCache: true,
          cacheEntry: cacheEntry,
        );
      } else {
        // Remove expired entry
        _memoryCache.remove(cacheKey);
        _imageCache.remove(cacheKey);
        _memoryCacheSize -= cacheEntry.size;
      }
    }
    
    return const ImageResult();
  }
  
  /// Load image from disk cache
  Future<ImageResult> _loadFromDiskCache(ImageRequest request) async {
    if (_cacheDirectory == null) return const ImageResult();
    
    final cacheKey = request.effectiveCacheKey;
    final file = File('${_cacheDirectory!.path}/$cacheKey');
    final metaFile = File('${_cacheDirectory!.path}/$cacheKey.meta');
    
    try {
      if (await file.exists() && await metaFile.exists()) {
        // Read metadata
        final metaJson = await metaFile.readAsString();
        final metadata = jsonDecode(metaJson);
        
        final timestamp = DateTime.parse(metadata['timestamp']);
        
        // Check if expired
        if (DateTime.now().difference(timestamp) > _config.diskCacheExpiry) {
          await file.delete();
          await metaFile.delete();
          return const ImageResult();
        }
        
        // Read image data
        final data = await file.readAsBytes();
        
        // Decode image
        final image = await _decodeImage(data);
        if (image != null) {
          final cacheEntry = ImageCacheEntry(
            url: request.url,
            data: data,
            timestamp: timestamp,
            etag: metadata['etag'] ?? '',
            contentType: metadata['content_type'] ?? 'image/jpeg',
            size: data.length,
            headers: Map<String, String>.from(metadata['headers'] ?? {}),
          );
          
          return ImageResult(
            image: image,
            data: data,
            fromCache: true,
            cacheEntry: cacheEntry,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading from disk cache: $e');
    }
    
    return const ImageResult();
  }
  
  /// Download image from network
  Future<ImageResult> _downloadImage(ImageRequest request) async {
    final cacheKey = request.effectiveCacheKey;
    
    // Check if already downloading
    if (_downloadTasks.containsKey(cacheKey)) {
      return await _downloadTasks[cacheKey]!;
    }
    
    // Limit concurrent downloads
    if (_activeDownloads >= _config.maxConcurrentDownloads) {
      await _waitForDownloadSlot();
    }
    
    // Create download task
    final downloadFuture = _performDownload(request);
    _downloadTasks[cacheKey] = downloadFuture;
    
    try {
      final result = await downloadFuture;
      return result;
    } finally {
      _downloadTasks.remove(cacheKey);
    }
  }
  
  /// Perform the actual download
  Future<ImageResult> _performDownload(ImageRequest request) async {
    _activeDownloads++;
    _networkRequests++;
    
    try {
      final uri = Uri.parse(request.url);
      final httpRequest = http.Request('GET', uri);
      
      // Add headers
      if (request.headers != null) {
        httpRequest.headers.addAll(request.headers!);
      }
      
      // Add user agent
      httpRequest.headers['User-Agent'] = 'MarketplaceApp/1.0.0';
      
      // Send request
      final client = http.Client();
      final response = await client.send(httpRequest);
      
      if (response.statusCode == 200) {
        // Read response data
        final data = await response.stream.toBytes();
        
        // Decode image
        final image = await _decodeImage(data);
        if (image != null) {
          // Create cache entry
          final cacheEntry = ImageCacheEntry(
            url: request.url,
            data: data,
            timestamp: DateTime.now(),
            etag: response.headers['etag'] ?? '',
            contentType: response.headers['content-type'] ?? 'image/jpeg',
            size: data.length,
            headers: Map<String, String>.from(response.headers),
          );
          
          // Store in caches
          if (request.useCache) {
            if (_config.enableMemoryCache) {
              await _storeInMemoryCache(request.effectiveCacheKey, cacheEntry);
              _imageCache[request.effectiveCacheKey] = image;
            }
            
            if (_config.enableDiskCache) {
              await _storeToDiskCache(request.effectiveCacheKey, cacheEntry);
            }
          }
          
          return ImageResult(
            image: image,
            data: data,
            fromCache: false,
            cacheEntry: cacheEntry,
          );
        } else {
          return const ImageResult(error: 'Failed to decode image');
        }
      } else {
        return ImageResult(error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      final error = 'Download failed: $e';
      _addError(error);
      return ImageResult(error: error);
    } finally {
      _activeDownloads--;
    }
  }
  
  /// Decode image from bytes
  Future<ui.Image?> _decodeImage(Uint8List data) async {
    try {
      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Failed to decode image: $e');
      return null;
    }
  }
  
  /// Store image in memory cache
  Future<void> _storeInMemoryCache(String cacheKey, ImageCacheEntry entry) async {
    // Check memory limits
    await _enforceMemoryLimits(entry.size);
    
    _memoryCache[cacheKey] = entry;
    _memoryCacheSize += entry.size;
  }
  
  /// Store image in disk cache
  Future<void> _storeToDiskCache(String cacheKey, ImageCacheEntry entry) async {
    if (_cacheDirectory == null) return;
    
    try {
      final file = File('${_cacheDirectory!.path}/$cacheKey');
      final metaFile = File('${_cacheDirectory!.path}/$cacheKey.meta');
      
      // Write image data
      await file.writeAsBytes(entry.data);
      
      // Write metadata
      final metadata = {
        'url': entry.url,
        'timestamp': entry.timestamp.toIso8601String(),
        'etag': entry.etag,
        'content_type': entry.contentType,
        'size': entry.size,
        'headers': entry.headers,
      };
      
      await metaFile.writeAsString(jsonEncode(metadata));
    } catch (e) {
      debugPrint('Error storing to disk cache: $e');
    }
  }
  
  /// Enforce memory cache size limits
  Future<void> _enforceMemoryLimits(int newEntrySize) async {
    final maxSizeBytes = _config.maxMemoryCacheSize * 1024 * 1024;
    
    if (_memoryCacheSize + newEntrySize > maxSizeBytes) {
      // Remove oldest entries until we have enough space
      final entries = _memoryCache.entries.toList();
      entries.sort((a, b) => a.value.timestamp.compareTo(b.value.timestamp));
      
      for (final entry in entries) {
        _memoryCache.remove(entry.key);
        _imageCache.remove(entry.key);
        _memoryCacheSize -= entry.value.size;
        
        if (_memoryCacheSize + newEntrySize <= maxSizeBytes) {
          break;
        }
      }
    }
  }
  
  /// Wait for a download slot to become available
  Future<void> _waitForDownloadSlot() async {
    while (_activeDownloads >= _config.maxConcurrentDownloads) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
  
  /// Check if domain is allowed
  bool _isDomainAllowed(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      
      return _config.allowedDomains.any((domain) => 
        host == domain.toLowerCase() || 
        host.endsWith('.${domain.toLowerCase()}')
      );
    } catch (e) {
      return false;
    }
  }
  
  /// Clean up expired cache files
  Future<void> _cleanupExpiredCache() async {
    if (_cacheDirectory == null) return;
    
    try {
      final files = await _cacheDirectory!.list().toList();
      final now = DateTime.now();
      
      for (final file in files) {
        if (file is File && file.path.endsWith('.meta')) {
          try {
            final metaJson = await file.readAsString();
            final metadata = jsonDecode(metaJson);
            final timestamp = DateTime.parse(metadata['timestamp']);
            
            if (now.difference(timestamp) > _config.diskCacheExpiry) {
              // Delete both meta and data files
              await file.delete();
              final dataFile = File(file.path.substring(0, file.path.length - 5));
              if (await dataFile.exists()) {
                await dataFile.delete();
              }
            }
          } catch (e) {
            // Delete corrupted files
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error during cache cleanup: $e');
    }
  }
  
  /// Add error to recent errors list
  void _addError(String error) {
    _recentErrors.add(error);
    
    // Keep only last 10 errors
    if (_recentErrors.length > 10) {
      _recentErrors.removeAt(0);
    }
  }
}

/// Custom image widget that uses the image cache service
class CachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Map<String, String>? headers;
  final Duration? fadeInDuration;
  final ImagePriority priority;
  final bool useCache;
  
  const CachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.placeholder,
    this.errorWidget,
    this.fit,
    this.width,
    this.height,
    this.headers,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.priority = ImagePriority.normal,
    this.useCache = true,
  });

  @override
  State<CachedNetworkImage> createState() => _CachedNetworkImageState();
}

class _CachedNetworkImageState extends State<CachedNetworkImage>
    with SingleTickerProviderStateMixin {
  ImageResult? _imageResult;
  bool _isLoading = true;
  late AnimationController _fadeController;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: widget.fadeInDuration ?? const Duration(milliseconds: 300),
      vsync: this,
    );
    _loadImage();
  }
  
  @override
  void didUpdateWidget(CachedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _loadImage();
    }
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ?? 
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
    }
    
    if (_imageResult?.hasError == true) {
      return widget.errorWidget ?? 
        Container(
          width: widget.width,
          height: widget.height,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        );
    }
    
    if (_imageResult?.image != null) {
      return FadeTransition(
        opacity: _fadeController,
        child: RawImage(
          image: _imageResult!.image,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
        ),
      );
    }
    
    return widget.errorWidget ?? const SizedBox.shrink();
  }
  
  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _imageResult = null;
    });
    
    final request = ImageRequest(
      url: widget.imageUrl,
      priority: widget.priority,
      headers: widget.headers,
      useCache: widget.useCache,
    );
    
    final result = await ImageCacheService.instance.loadImage(request);
    
    if (mounted) {
      setState(() {
        _imageResult = result;
        _isLoading = false;
      });
      
      if (result.isSuccess && !result.fromCache) {
        _fadeController.forward();
      } else if (result.isSuccess) {
        _fadeController.value = 1.0;
      }
    }
  }
}