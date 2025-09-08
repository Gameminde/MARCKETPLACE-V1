import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Comprehensive performance monitoring service for the marketplace app
/// 
/// This service tracks various performance metrics including:
/// - App startup time
/// - Screen navigation performance
/// - Memory usage
/// - Network request performance
/// - Widget build times
/// - User interaction response times
/// 
/// Usage:
/// ```dart
/// PerformanceService.instance.trackScreenNavigation('HomeScreen');
/// PerformanceService.instance.startOperation('loadProducts');
/// // ... operation
/// PerformanceService.instance.endOperation('loadProducts');
/// ```
class PerformanceService {
  static PerformanceService? _instance;
  static PerformanceService get instance {
    _instance ??= PerformanceService._internal();
    return _instance!;
  }

  PerformanceService._internal();

  final Map<String, DateTime> _operationStartTimes = {};
  final List<PerformanceMetric> _metrics = [];
  final Map<String, int> _screenViews = {};
  final Map<String, Duration> _screenLoadTimes = {};
  late DateTime _appStartTime;
  Timer? _memoryMonitorTimer;
  
  /// Initialize performance monitoring
  void initialize() {
    _appStartTime = DateTime.now();
    _startMemoryMonitoring();
    _setupErrorHandling();
    
    debugPrint('🚀 PerformanceService initialized');
  }

  /// Track app startup completion
  void trackAppStartup() {
    final startupTime = DateTime.now().difference(_appStartTime);
    recordMetric(PerformanceMetric(
      name: 'app_startup_time',
      value: startupTime.inMilliseconds.toDouble(),
      unit: MetricUnit.milliseconds,
      type: MetricType.timing,
      timestamp: DateTime.now(),
    ));
    
    debugPrint('📊 App startup completed in ${startupTime.inMilliseconds}ms');
  }

  /// Track screen navigation performance
  void trackScreenNavigation(String screenName, {Map<String, dynamic>? parameters}) {
    final now = DateTime.now();
    
    // Track screen view count
    _screenViews[screenName] = (_screenViews[screenName] ?? 0) + 1;
    
    // Start timing screen load
    _operationStartTimes['screen_load_$screenName'] = now;
    
    recordMetric(PerformanceMetric(
      name: 'screen_navigation',
      value: 1,
      unit: MetricUnit.count,
      type: MetricType.counter,
      timestamp: now,
      metadata: {
        'screen_name': screenName,
        'view_count': _screenViews[screenName],
        ...?parameters,
      },
    ));
  }

  /// Track screen load completion
  void trackScreenLoadComplete(String screenName) {
    final operationKey = 'screen_load_$screenName';
    final startTime = _operationStartTimes[operationKey];
    
    if (startTime != null) {
      final loadTime = DateTime.now().difference(startTime);
      _screenLoadTimes[screenName] = loadTime;
      _operationStartTimes.remove(operationKey);
      
      recordMetric(PerformanceMetric(
        name: 'screen_load_time',
        value: loadTime.inMilliseconds.toDouble(),
        unit: MetricUnit.milliseconds,
        type: MetricType.timing,
        timestamp: DateTime.now(),
        metadata: {
          'screen_name': screenName,
        },
      ));
      
      debugPrint('📱 Screen $screenName loaded in ${loadTime.inMilliseconds}ms');
    }
  }

  /// Start tracking an operation
  void startOperation(String operationName, {Map<String, dynamic>? metadata}) {
    _operationStartTimes[operationName] = DateTime.now();
    
    recordMetric(PerformanceMetric(
      name: 'operation_start',
      value: 1,
      unit: MetricUnit.count,
      type: MetricType.counter,
      timestamp: DateTime.now(),
      metadata: {
        'operation_name': operationName,
        ...?metadata,
      },
    ));
  }

  /// End tracking an operation
  void endOperation(String operationName, {bool success = true, String? error}) {
    final startTime = _operationStartTimes[operationName];
    
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _operationStartTimes.remove(operationName);
      
      recordMetric(PerformanceMetric(
        name: 'operation_duration',
        value: duration.inMilliseconds.toDouble(),
        unit: MetricUnit.milliseconds,
        type: MetricType.timing,
        timestamp: DateTime.now(),
        metadata: {
          'operation_name': operationName,
          'success': success,
          'error': error,
        },
      ));
      
      if (success) {
        debugPrint('✅ Operation $operationName completed in ${duration.inMilliseconds}ms');
      } else {
        debugPrint('❌ Operation $operationName failed after ${duration.inMilliseconds}ms: $error');
      }
    }
  }

  /// Track network request performance
  void trackNetworkRequest({
    required String url,
    required String method,
    required int statusCode,
    required Duration duration,
    int? requestSize,
    int? responseSize,
    String? error,
  }) {
    recordMetric(PerformanceMetric(
      name: 'network_request',
      value: duration.inMilliseconds.toDouble(),
      unit: MetricUnit.milliseconds,
      type: MetricType.timing,
      timestamp: DateTime.now(),
      metadata: {
        'url': url,
        'method': method,
        'status_code': statusCode,
        'request_size': requestSize,
        'response_size': responseSize,
        'error': error,
        'success': statusCode >= 200 && statusCode < 300,
      },
    ));
  }

  /// Track user interaction performance
  void trackUserInteraction({
    required String interactionType,
    required String elementId,
    required Duration responseTime,
    Map<String, dynamic>? additionalData,
  }) {
    recordMetric(PerformanceMetric(
      name: 'user_interaction',
      value: responseTime.inMilliseconds.toDouble(),
      unit: MetricUnit.milliseconds,
      type: MetricType.timing,
      timestamp: DateTime.now(),
      metadata: {
        'interaction_type': interactionType,
        'element_id': elementId,
        ...?additionalData,
      },
    ));
  }

  /// Track widget build performance
  void trackWidgetBuild({
    required String widgetName,
    required Duration buildTime,
    int? childCount,
  }) {
    recordMetric(PerformanceMetric(
      name: 'widget_build_time',
      value: buildTime.inMicroseconds.toDouble(),
      unit: MetricUnit.microseconds,
      type: MetricType.timing,
      timestamp: DateTime.now(),
      metadata: {
        'widget_name': widgetName,
        'child_count': childCount,
      },
    ));
  }

  /// Track memory usage
  void trackMemoryUsage() {
    // Get current memory info (platform-specific)
    double memoryUsage = 0;
    
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Use platform channel to get memory info
        // This would require native implementation
        memoryUsage = _getCurrentMemoryUsage();
      }
    } catch (e) {
      debugPrint('Failed to get memory usage: $e');
    }

    recordMetric(PerformanceMetric(
      name: 'memory_usage',
      value: memoryUsage,
      unit: MetricUnit.bytes,
      type: MetricType.gauge,
      timestamp: DateTime.now(),
    ));
  }

  /// Track frame rate performance
  void trackFrameRate(double fps) {
    recordMetric(PerformanceMetric(
      name: 'frame_rate',
      value: fps,
      unit: MetricUnit.fps,
      type: MetricType.gauge,
      timestamp: DateTime.now(),
    ));
    
    if (fps < 30) {
      debugPrint('⚠️ Low frame rate detected: ${fps.toStringAsFixed(1)} FPS');
    }
  }

  /// Record a custom performance metric
  void recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Keep only last 1000 metrics to prevent memory issues
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }
    
    // Send to analytics if configured
    _sendToAnalytics(metric);
  }

  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    final now = DateTime.now();
    final timingMetrics = _metrics.where((m) => m.type == MetricType.timing).toList();
    
    // Calculate averages for different operation types
    final operationDurations = <String, List<double>>{};
    final screenLoadTimes = <String, List<double>>{};
    
    for (final metric in timingMetrics) {
      if (metric.name == 'operation_duration') {
        final operationName = metric.metadata?['operation_name'] as String? ?? 'unknown';
        operationDurations.putIfAbsent(operationName, () => []).add(metric.value);
      } else if (metric.name == 'screen_load_time') {
        final screenName = metric.metadata?['screen_name'] as String? ?? 'unknown';
        screenLoadTimes.putIfAbsent(screenName, () => []).add(metric.value);
      }
    }
    
    return PerformanceSummary(
      totalMetrics: _metrics.length,
      operationAverages: operationDurations.map(
        (key, values) => MapEntry(key, values.reduce((a, b) => a + b) / values.length),
      ),
      screenLoadAverages: screenLoadTimes.map(
        (key, values) => MapEntry(key, values.reduce((a, b) => a + b) / values.length),
      ),
      screenViews: Map.from(_screenViews),
      generatedAt: now,
    );
  }

  /// Export performance data for external analysis
  Map<String, dynamic> exportPerformanceData() {
    final summary = getPerformanceSummary();
    
    return {
      'summary': summary.toJson(),
      'metrics': _metrics.map((m) => m.toJson()).toList(),
      'export_timestamp': DateTime.now().toIso8601String(),
      'app_version': _getAppVersion(),
      'platform': Platform.operatingSystem,
    };
  }

  /// Clear all performance data
  void clearData() {
    _metrics.clear();
    _operationStartTimes.clear();
    _screenViews.clear();
    _screenLoadTimes.clear();
    debugPrint('🗑️ Performance data cleared');
  }

  /// Start monitoring memory usage periodically
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      trackMemoryUsage();
    });
  }

  /// Stop memory monitoring
  void dispose() {
    _memoryMonitorTimer?.cancel();
  }

  /// Setup error handling for performance issues
  void _setupErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      recordMetric(PerformanceMetric(
        name: 'flutter_error',
        value: 1,
        unit: MetricUnit.count,
        type: MetricType.counter,
        timestamp: DateTime.now(),
        metadata: {
          'error': details.exception.toString(),
          'stack_trace': details.stack.toString(),
          'library': details.library,
        },
      ));
      
      // Call original error handler
      FlutterError.presentError(details);
    };
  }

  /// Get current memory usage (platform-specific implementation needed)
  double _getCurrentMemoryUsage() {
    // This would require platform channel implementation
    // For now, return a placeholder value
    return 0.0;
  }

  /// Send metric to analytics service
  void _sendToAnalytics(PerformanceMetric metric) {
    // Implementation would depend on your analytics provider
    // e.g., Firebase Analytics, Mixpanel, etc.
    if (kDebugMode) {
      debugPrint('📊 Metric: ${metric.name} = ${metric.value} ${metric.unit.name}');
    }
  }

  /// Get app version for context
  String _getAppVersion() {
    // This would typically come from package info
    return '1.0.0'; // Placeholder
  }
}

/// Performance metric data model
class PerformanceMetric {
  final String name;
  final double value;
  final MetricUnit unit;
  final MetricType type;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.type,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'unit': unit.name,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      name: json['name'],
      value: json['value'].toDouble(),
      unit: MetricUnit.values.firstWhere((u) => u.name == json['unit']),
      type: MetricType.values.firstWhere((t) => t.name == json['type']),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }
}

/// Performance summary data model
class PerformanceSummary {
  final int totalMetrics;
  final Map<String, double> operationAverages;
  final Map<String, double> screenLoadAverages;
  final Map<String, int> screenViews;
  final DateTime generatedAt;

  const PerformanceSummary({
    required this.totalMetrics,
    required this.operationAverages,
    required this.screenLoadAverages,
    required this.screenViews,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_metrics': totalMetrics,
      'operation_averages': operationAverages,
      'screen_load_averages': screenLoadAverages,
      'screen_views': screenViews,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// Metric unit types
enum MetricUnit {
  milliseconds,
  microseconds,
  seconds,
  bytes,
  kilobytes,
  megabytes,
  count,
  percentage,
  fps,
}

/// Metric type categories
enum MetricType {
  timing,    // Duration measurements
  counter,   // Event counts
  gauge,     // Point-in-time values
  histogram, // Distribution of values
}

/// Performance monitoring widget wrapper
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String? screenName;
  final bool trackBuildTime;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.screenName,
    this.trackBuildTime = false,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final Stopwatch _buildStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    
    if (widget.screenName != null) {
      PerformanceService.instance.trackScreenNavigation(widget.screenName!);
      
      // Track screen load completion after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PerformanceService.instance.trackScreenLoadComplete(widget.screenName!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trackBuildTime) {
      _buildStopwatch.start();
    }

    final child = widget.child;

    if (widget.trackBuildTime) {
      _buildStopwatch.stop();
      PerformanceService.instance.trackWidgetBuild(
        widgetName: widget.runtimeType.toString(),
        buildTime: _buildStopwatch.elapsed,
      );
      _buildStopwatch.reset();
    }

    return child;
  }
}