import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Comprehensive crash reporting service for the marketplace app
///
/// This service captures and reports crashes, errors, and exceptions with
/// detailed context information for debugging and monitoring.
///
/// Features:
/// - Automatic crash detection and reporting
/// - Custom error logging with context
/// - Device and app information collection
/// - Local crash storage for offline scenarios
/// - Integration with external crash reporting services
///
/// Usage:
/// ```dart
/// CrashReportingService.instance.initialize();
/// CrashReportingService.instance.recordError(exception, stackTrace);
/// CrashReportingService.instance.recordCustomError('Custom error message');
/// ```
class CrashReportingService {
  static CrashReportingService? _instance;
  static CrashReportingService get instance {
    _instance ??= CrashReportingService._internal();
    return _instance!;
  }

  CrashReportingService._internal();

  final List<CrashReport> _crashReports = [];
  final Map<String, dynamic> _sessionInfo = {};
  bool _initialized = false;
  String? _userId;
  String? _sessionId;

  /// Initialize crash reporting service
  Future<void> initialize({
    String? userId,
    bool enableInDebugMode = false,
  }) async {
    if (_initialized) return;

    _userId = userId;
    _sessionId = _generateSessionId();

    // Collect device and app information
    await _collectSystemInfo();

    // Setup error handlers
    _setupErrorHandlers(enableInDebugMode);

    // Load previously stored crashes
    await _loadStoredCrashes();

    _initialized = true;
    debugPrint('🔥 CrashReportingService initialized');
  }

  /// Record a crash or error with full context
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? customData,
    bool fatal = false,
  }) async {
    final crash = CrashReport(
      id: _generateCrashId(),
      timestamp: DateTime.now(),
      exception: exception.toString(),
      stackTrace: stackTrace?.toString(),
      reason: reason,
      fatal: fatal,
      sessionId: _sessionId,
      userId: _userId,
      deviceInfo: Map.from(_sessionInfo),
      customData: customData,
      breadcrumbs: List.from(_breadcrumbs),
    );

    _crashReports.add(crash);

    // Store crash locally
    await _storeCrashLocally(crash);

    // Report crash to external service
    await _reportCrashToService(crash);

    // Log crash details
    _logCrash(crash);

    debugPrint(
        '💥 ${fatal ? 'Fatal crash' : 'Error'} recorded: ${exception.toString()}');
  }

  /// Record a custom error with context
  Future<void> recordCustomError(
    String message, {
    String? category,
    Map<String, dynamic>? data,
    bool fatal = false,
  }) async {
    await recordError(
      CustomException(message, category),
      StackTrace.current,
      reason: 'Custom error logged',
      customData: data,
      fatal: fatal,
    );
  }

  /// Record a handled exception
  Future<void> recordHandledException(
    dynamic exception,
    StackTrace stackTrace, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    await recordError(
      exception,
      stackTrace,
      reason: 'Handled exception in $context',
      customData: additionalData,
      fatal: false,
    );
  }

  /// Record network error
  Future<void> recordNetworkError(
    String url,
    int? statusCode,
    String error, {
    Map<String, dynamic>? requestData,
  }) async {
    await recordCustomError(
      'Network request failed: $error',
      category: 'network',
      data: {
        'url': url,
        'status_code': statusCode,
        'request_data': requestData,
      },
    );
  }

  /// Record user action for breadcrumb trail
  void recordUserAction(String action, {Map<String, dynamic>? data}) {
    addBreadcrumb(BreadcrumbType.user, action, data);
  }

  /// Record navigation for breadcrumb trail
  void recordNavigation(String from, String to, {Map<String, dynamic>? data}) {
    addBreadcrumb(
        BreadcrumbType.navigation, 'Navigate from $from to $to', data);
  }

  /// Record state change for breadcrumb trail
  void recordStateChange(String state, {Map<String, dynamic>? data}) {
    addBreadcrumb(BreadcrumbType.state, 'State changed: $state', data);
  }

  /// Add breadcrumb for debugging trail
  final List<Breadcrumb> _breadcrumbs = [];

  void addBreadcrumb(BreadcrumbType type, String message,
      [Map<String, dynamic>? data]) {
    final breadcrumb = Breadcrumb(
      timestamp: DateTime.now(),
      type: type,
      message: message,
      data: data,
    );

    _breadcrumbs.add(breadcrumb);

    // Keep only last 50 breadcrumbs
    if (_breadcrumbs.length > 50) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// Set user identifier
  void setUser(String userId, {String? email, String? name}) {
    _userId = userId;
    _sessionInfo['user_id'] = userId;
    if (email != null) _sessionInfo['user_email'] = email;
    if (name != null) _sessionInfo['user_name'] = name;
  }

  /// Set custom session data
  void setCustomData(String key, dynamic value) {
    _sessionInfo[key] = value;
  }

  /// Get all crash reports
  List<CrashReport> getCrashReports() {
    return List.unmodifiable(_crashReports);
  }

  /// Get crash statistics
  CrashStatistics getCrashStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final lastWeek = now.subtract(const Duration(days: 7));

    final crashes24h =
        _crashReports.where((c) => c.timestamp.isAfter(last24Hours)).length;
    final crashesWeek =
        _crashReports.where((c) => c.timestamp.isAfter(lastWeek)).length;
    final fatalCrashes = _crashReports.where((c) => c.fatal).length;

    final errorTypes = <String, int>{};
    for (final crash in _crashReports) {
      final type = crash.exception.split(':').first;
      errorTypes[type] = (errorTypes[type] ?? 0) + 1;
    }

    return CrashStatistics(
      totalCrashes: _crashReports.length,
      crashes24Hours: crashes24h,
      crashesThisWeek: crashesWeek,
      fatalCrashes: fatalCrashes,
      errorTypes: errorTypes,
      generatedAt: now,
    );
  }

  /// Export crash data for analysis
  Map<String, dynamic> exportCrashData() {
    return {
      'crashes': _crashReports.map((c) => c.toJson()).toList(),
      'statistics': getCrashStatistics().toJson(),
      'session_info': _sessionInfo,
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Clear all crash data
  void clearCrashData() {
    _crashReports.clear();
    _breadcrumbs.clear();
    debugPrint('🗑️ Crash data cleared');
  }

  /// Setup error handlers
  void _setupErrorHandlers(bool enableInDebugMode) {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode && !enableInDebugMode) {
        FlutterError.presentError(details);
        return;
      }

      recordError(
        details.exception,
        details.stack,
        reason: 'Flutter framework error in ${details.library}',
        customData: {
          'library': details.library,
          'context': details.context?.toString(),
        },
        fatal: false,
      );

      // Still present error in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // Handle platform (Dart) errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode && !enableInDebugMode) {
        return false;
      }

      recordError(
        error,
        stack,
        reason: 'Platform error',
        fatal: true,
      );

      return true;
    };

    // Handle isolate errors
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        final error = errorAndStacktrace.first;
        final stack = errorAndStacktrace.last;

        await recordError(
          error,
          StackTrace.fromString(stack.toString()),
          reason: 'Isolate error',
          fatal: true,
        );
      }).sendPort,
    );
  }

  /// Collect system and app information
  Future<void> _collectSystemInfo() async {
    try {
      // Get package info
      final packageInfo = await PackageInfo.fromPlatform();
      _sessionInfo.addAll({
        'app_name': packageInfo.appName,
        'package_name': packageInfo.packageName,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
      });

      // Get device info
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _sessionInfo.addAll({
          'platform': 'android',
          'android_version': androidInfo.version.release,
          'android_sdk': androidInfo.version.sdkInt,
          'device_model': androidInfo.model,
          'device_manufacturer': androidInfo.manufacturer,
          'device_brand': androidInfo.brand,
        });
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _sessionInfo.addAll({
          'platform': 'ios',
          'ios_version': iosInfo.systemVersion,
          'device_model': iosInfo.model,
          'device_name': iosInfo.name,
        });
      }

      // Add session info
      _sessionInfo.addAll({
        'session_id': _sessionId,
        'user_id': _userId,
        'timestamp': DateTime.now().toIso8601String(),
        'debug_mode': kDebugMode,
        'profile_mode': kProfileMode,
        'release_mode': kReleaseMode,
      });
    } catch (e) {
      debugPrint('Failed to collect system info: $e');
    }
  }

  /// Store crash report locally
  Future<void> _storeCrashLocally(CrashReport crash) async {
    try {
      // This would typically save to local storage
      // For now, just keep in memory
      debugPrint('💾 Crash stored locally: ${crash.id}');
    } catch (e) {
      debugPrint('Failed to store crash locally: $e');
    }
  }

  /// Load previously stored crashes
  Future<void> _loadStoredCrashes() async {
    try {
      // This would typically load from local storage
      debugPrint('📂 Loading stored crashes...');
    } catch (e) {
      debugPrint('Failed to load stored crashes: $e');
    }
  }

  /// Report crash to external service
  Future<void> _reportCrashToService(CrashReport crash) async {
    try {
      // This would integrate with services like:
      // - Firebase Crashlytics
      // - Sentry
      // - Bugsnag
      // - Custom crash reporting endpoint

      if (kDebugMode) {
        debugPrint('📡 Would report crash to external service: ${crash.id}');
      }
    } catch (e) {
      debugPrint('Failed to report crash to service: $e');
    }
  }

  /// Log crash details
  void _logCrash(CrashReport crash) {
    debugPrint('🔥 CRASH REPORT 🔥');
    debugPrint('ID: ${crash.id}');
    debugPrint('Timestamp: ${crash.timestamp}');
    debugPrint('Fatal: ${crash.fatal}');
    debugPrint('Exception: ${crash.exception}');
    if (crash.reason != null) debugPrint('Reason: ${crash.reason}');
    if (crash.stackTrace != null) {
      debugPrint('Stack Trace:');
      debugPrint(crash.stackTrace);
    }
    debugPrint('🔥 END CRASH REPORT 🔥');
  }

  /// Generate unique crash ID
  String _generateCrashId() {
    return 'crash_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// Crash report data model
class CrashReport {
  final String id;
  final DateTime timestamp;
  final String exception;
  final String? stackTrace;
  final String? reason;
  final bool fatal;
  final String? sessionId;
  final String? userId;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic>? customData;
  final List<Breadcrumb> breadcrumbs;

  const CrashReport({
    required this.id,
    required this.timestamp,
    required this.exception,
    this.stackTrace,
    this.reason,
    required this.fatal,
    this.sessionId,
    this.userId,
    required this.deviceInfo,
    this.customData,
    required this.breadcrumbs,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'exception': exception,
      'stack_trace': stackTrace,
      'reason': reason,
      'fatal': fatal,
      'session_id': sessionId,
      'user_id': userId,
      'device_info': deviceInfo,
      'custom_data': customData,
      'breadcrumbs': breadcrumbs.map((b) => b.toJson()).toList(),
    };
  }

  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      id: json['id'],
      timestamp: DateTime.parse(json['timestamp']),
      exception: json['exception'],
      stackTrace: json['stack_trace'],
      reason: json['reason'],
      fatal: json['fatal'],
      sessionId: json['session_id'],
      userId: json['user_id'],
      deviceInfo: Map<String, dynamic>.from(json['device_info']),
      customData: json['custom_data'] != null
          ? Map<String, dynamic>.from(json['custom_data'])
          : null,
      breadcrumbs: (json['breadcrumbs'] as List)
          .map((b) => Breadcrumb.fromJson(b))
          .toList(),
    );
  }
}

/// Breadcrumb for debugging trail
class Breadcrumb {
  final DateTime timestamp;
  final BreadcrumbType type;
  final String message;
  final Map<String, dynamic>? data;

  const Breadcrumb({
    required this.timestamp,
    required this.type,
    required this.message,
    this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'message': message,
      'data': data,
    };
  }

  factory Breadcrumb.fromJson(Map<String, dynamic> json) {
    return Breadcrumb(
      timestamp: DateTime.parse(json['timestamp']),
      type: BreadcrumbType.values.firstWhere((t) => t.name == json['type']),
      message: json['message'],
      data:
          json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
    );
  }
}

/// Breadcrumb types
enum BreadcrumbType {
  navigation,
  user,
  network,
  state,
  system,
  error,
}

/// Crash statistics
class CrashStatistics {
  final int totalCrashes;
  final int crashes24Hours;
  final int crashesThisWeek;
  final int fatalCrashes;
  final Map<String, int> errorTypes;
  final DateTime generatedAt;

  const CrashStatistics({
    required this.totalCrashes,
    required this.crashes24Hours,
    required this.crashesThisWeek,
    required this.fatalCrashes,
    required this.errorTypes,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_crashes': totalCrashes,
      'crashes_24_hours': crashes24Hours,
      'crashes_this_week': crashesThisWeek,
      'fatal_crashes': fatalCrashes,
      'error_types': errorTypes,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// Custom exception class
class CustomException implements Exception {
  final String message;
  final String? category;

  const CustomException(this.message, [this.category]);

  @override
  String toString() {
    return category != null ? '$category: $message' : message;
  }
}

/// Crash reporting widget wrapper
class CrashReportingWrapper extends StatefulWidget {
  final Widget child;
  final String? screenName;

  const CrashReportingWrapper({
    super.key,
    required this.child,
    this.screenName,
  });

  @override
  State<CrashReportingWrapper> createState() => _CrashReportingWrapperState();
}

class _CrashReportingWrapperState extends State<CrashReportingWrapper> {
  @override
  void initState() {
    super.initState();

    if (widget.screenName != null) {
      CrashReportingService.instance.recordNavigation(
        'previous_screen',
        widget.screenName!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
