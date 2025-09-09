import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Comprehensive analytics service for tracking user behavior in the marketplace app
/// 
/// This service provides detailed tracking of user interactions, events, and behavior
/// patterns to help understand user engagement and optimize the application experience.
/// 
/// Features:
/// - Event tracking with custom properties
/// - User journey mapping
/// - Screen time analytics
/// - E-commerce tracking (purchases, cart events)
/// - Custom funnel analysis
/// - User segmentation
/// - Real-time event batching and sending
/// 
/// Usage:
/// ```dart
/// AnalyticsService.instance.initialize(userId: 'user123');
/// AnalyticsService.instance.trackEvent('product_viewed', {'product_id': 'abc123'});
/// AnalyticsService.instance.trackScreen('ProductDetailScreen');
/// AnalyticsService.instance.trackPurchase('order123', 99.99, 'USD');
/// ```
class AnalyticsService {
  static AnalyticsService? _instance;
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._internal();
    return _instance!;
  }

  AnalyticsService._internal();

  final List<AnalyticsEvent> _eventQueue = [];
  final Map<String, dynamic> _userProperties = {};
  final Map<String, DateTime> _screenStartTimes = {};
  final Map<String, Duration> _screenDurations = {};
  final List<UserJourneyStep> _userJourney = [];
  
  Timer? _batchTimer;
  String? _userId;
  String? _sessionId;
  DateTime? _sessionStart;
  bool _initialized = false;

  /// Initialize analytics service
  void initialize({
    String? userId,
    Map<String, dynamic>? userProperties,
    bool enableInDebugMode = true,
  }) {
    if (_initialized) return;

    _userId = userId;
    _sessionId = _generateSessionId();
    _sessionStart = DateTime.now();

    if (userProperties != null) {
      _userProperties.addAll(userProperties);
    }

    _startBatchTimer();
    _trackSessionStart();
    
    _initialized = true;
    debugPrint('📊 AnalyticsService initialized for user: ${userId ?? 'anonymous'}');
  }

  /// Track a custom event
  void trackEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    EventCategory category = EventCategory.interaction,
  }) {
    final event = AnalyticsEvent(
      name: eventName,
      category: category,
      properties: properties,
      timestamp: DateTime.now(),
      userId: _userId,
      sessionId: _sessionId,
    );

    _eventQueue.add(event);
    _addToUserJourney(UserJourneyStep(
      type: JourneyStepType.event,
      name: eventName,
      timestamp: DateTime.now(),
      properties: properties,
    ));

    debugPrint('📈 Event tracked: $eventName');
  }

  /// Track screen/page view
  void trackScreen(
    String screenName, {
    Map<String, dynamic>? properties,
  }) {
    // End previous screen timing
    _endScreenTiming();
    
    // Start new screen timing
    _screenStartTimes[screenName] = DateTime.now();
    
    trackEvent(
      'screen_view',
      properties: {
        'screen_name': screenName,
        ...?properties,
      },
      category: EventCategory.navigation,
    );

    _addToUserJourney(UserJourneyStep(
      type: JourneyStepType.screen,
      name: screenName,
      timestamp: DateTime.now(),
      properties: properties,
    ));
  }

  /// Track user interaction with UI elements
  void trackInteraction(
    String elementType,
    String elementId, {
    String? action,
    Map<String, dynamic>? properties,
  }) {
    trackEvent(
      'ui_interaction',
      properties: {
        'element_type': elementType,
        'element_id': elementId,
        'action': action ?? 'tap',
        ...?properties,
      },
      category: EventCategory.interaction,
    );
  }

  /// Track search behavior
  void trackSearch({
    required String query,
    String? category,
    int? resultsCount,
    List<String>? filters,
    String? sortBy,
  }) {
    trackEvent(
      'search_performed',
      properties: {
        'query': query,
        'category': category,
        'results_count': resultsCount,
        'filters': filters,
        'sort_by': sortBy,
      },
      category: EventCategory.search,
    );
  }

  /// Track product interactions
  void trackProductView(
    String productId, {
    String? productName,
    String? category,
    double? price,
    String? currency,
  }) {
    trackEvent(
      'product_view',
      properties: {
        'product_id': productId,
        'product_name': productName,
        'category': category,
        'price': price,
        'currency': currency,
      },
      category: EventCategory.ecommerce,
    );
  }

  /// Track add to cart events
  void trackAddToCart(
    String productId, {
    String? productName,
    String? category,
    double? price,
    String? currency,
    int quantity = 1,
  }) {
    trackEvent(
      'add_to_cart',
      properties: {
        'product_id': productId,
        'product_name': productName,
        'category': category,
        'price': price,
        'currency': currency,
        'quantity': quantity,
        'cart_value': (price ?? 0) * quantity,
      },
      category: EventCategory.ecommerce,
    );
  }

  /// Track remove from cart events
  void trackRemoveFromCart(
    String productId, {
    String? productName,
    int quantity = 1,
  }) {
    trackEvent(
      'remove_from_cart',
      properties: {
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
      },
      category: EventCategory.ecommerce,
    );
  }

  /// Track checkout initiated
  void trackCheckoutStart({
    required double cartValue,
    required String currency,
    required int itemCount,
    List<Map<String, dynamic>>? items,
  }) {
    trackEvent(
      'checkout_start',
      properties: {
        'cart_value': cartValue,
        'currency': currency,
        'item_count': itemCount,
        'items': items,
      },
      category: EventCategory.ecommerce,
    );
  }

  /// Track purchase completion
  void trackPurchase(
    String orderId,
    double totalAmount,
    String currency, {
    List<Map<String, dynamic>>? items,
    String? paymentMethod,
    double? tax,
    double? shipping,
    String? couponCode,
  }) {
    trackEvent(
      'purchase_completed',
      properties: {
        'order_id': orderId,
        'total_amount': totalAmount,
        'currency': currency,
        'items': items,
        'payment_method': paymentMethod,
        'tax': tax,
        'shipping': shipping,
        'coupon_code': couponCode,
        'item_count': items?.length ?? 0,
      },
      category: EventCategory.ecommerce,
    );
  }

  /// Track user registration
  void trackSignUp(
    String method, {
    Map<String, dynamic>? properties,
  }) {
    trackEvent(
      'sign_up',
      properties: {
        'method': method,
        ...?properties,
      },
      category: EventCategory.authentication,
    );
  }

  /// Track user login
  void trackLogin(
    String method, {
    Map<String, dynamic>? properties,
  }) {
    trackEvent(
      'login',
      properties: {
        'method': method,
        ...?properties,
      },
      category: EventCategory.authentication,
    );
  }

  /// Track user logout
  void trackLogout() {
    trackEvent(
      'logout',
      category: EventCategory.authentication,
    );
  }

  /// Track errors and exceptions
  void trackError(
    String errorType,
    String errorMessage, {
    String? stackTrace,
    Map<String, dynamic>? properties,
  }) {
    trackEvent(
      'error_occurred',
      properties: {
        'error_type': errorType,
        'error_message': errorMessage,
        'stack_trace': stackTrace,
        ...?properties,
      },
      category: EventCategory.error,
    );
  }

  /// Track app performance metrics
  void trackPerformance(
    String metricName,
    double value, {
    String? unit,
    Map<String, dynamic>? properties,
  }) {
    trackEvent(
      'performance_metric',
      properties: {
        'metric_name': metricName,
        'value': value,
        'unit': unit,
        ...?properties,
      },
      category: EventCategory.performance,
    );
  }

  /// Track custom funnel step
  void trackFunnelStep(
    String funnelName,
    String stepName, {
    int? stepIndex,
    Map<String, dynamic>? properties,
  }) {
    trackEvent(
      'funnel_step',
      properties: {
        'funnel_name': funnelName,
        'step_name': stepName,
        'step_index': stepIndex,
        ...?properties,
      },
      category: EventCategory.funnel,
    );
  }

  /// Set user properties
  void setUserProperties(Map<String, dynamic> properties) {
    _userProperties.addAll(properties);
    
    trackEvent(
      'user_properties_updated',
      properties: properties,
      category: EventCategory.user,
    );
  }

  /// Set user ID
  void setUserId(String userId) {
    final previousUserId = _userId;
    _userId = userId;
    _userProperties['user_id'] = userId;
    
    if (previousUserId != userId) {
      trackEvent(
        'user_id_changed',
        properties: {
          'previous_user_id': previousUserId,
          'new_user_id': userId,
        },
        category: EventCategory.user,
      );
    }
  }

  /// Get current session analytics
  UserSession getCurrentSession() {
    final now = DateTime.now();
    final sessionDuration = _sessionStart != null 
        ? now.difference(_sessionStart!)
        : Duration.zero;
        
    return UserSession(
      sessionId: _sessionId!,
      userId: _userId,
      startTime: _sessionStart!,
      duration: sessionDuration,
      eventCount: _eventQueue.length,
      screenViews: _screenDurations.length,
      userJourney: List.from(_userJourney),
    );
  }

  /// Get analytics summary
  AnalyticsSummary getAnalyticsSummary({Duration? period}) {
    final now = DateTime.now();
    final startTime = period != null ? now.subtract(period) : null;
    
    final filteredEvents = startTime != null 
        ? _eventQueue.where((e) => e.timestamp.isAfter(startTime)).toList()
        : _eventQueue;

    // Calculate event counts by category
    final eventsByCategory = <EventCategory, int>{};
    for (final event in filteredEvents) {
      eventsByCategory[event.category] = 
          (eventsByCategory[event.category] ?? 0) + 1;
    }

    // Calculate most popular events
    final eventCounts = <String, int>{};
    for (final event in filteredEvents) {
      eventCounts[event.name] = (eventCounts[event.name] ?? 0) + 1;
    }

    return AnalyticsSummary(
      totalEvents: filteredEvents.length,
      eventsByCategory: eventsByCategory,
      topEvents: eventCounts.entries
          .toList()
          ..sort((a, b) => b.value.compareTo(a.value)),
      uniqueScreens: _screenDurations.keys.toList(),
      averageSessionDuration: _calculateAverageSessionDuration(),
      period: period,
      generatedAt: now,
    );
  }

  /// Export analytics data
  Map<String, dynamic> exportAnalyticsData() {
    return {
      'session': getCurrentSession().toJson(),
      'events': _eventQueue.map((e) => e.toJson()).toList(),
      'user_properties': _userProperties,
      'screen_durations': _screenDurations.map(
        (k, v) => MapEntry(k, v.inMilliseconds),
      ),
      'user_journey': _userJourney.map((s) => s.toJson()).toList(),
      'summary': getAnalyticsSummary().toJson(),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// End current screen timing
  void _endScreenTiming() {
    final currentScreen = _screenStartTimes.keys.lastOrNull;
    if (currentScreen != null) {
      final startTime = _screenStartTimes[currentScreen];
      if (startTime != null) {
        final duration = DateTime.now().difference(startTime);
        _screenDurations[currentScreen] = duration;
        
        trackEvent(
          'screen_time',
          properties: {
            'screen_name': currentScreen,
            'duration_ms': duration.inMilliseconds,
          },
          category: EventCategory.navigation,
        );
      }
    }
  }

  /// Track session start
  void _trackSessionStart() {
    trackEvent(
      'session_start',
      properties: {
        'session_id': _sessionId,
        'user_id': _userId,
      },
      category: EventCategory.session,
    );
  }

  /// Add step to user journey
  void _addToUserJourney(UserJourneyStep step) {
    _userJourney.add(step);
    
    // Keep only last 100 steps to prevent memory issues
    if (_userJourney.length > 100) {
      _userJourney.removeAt(0);
    }
  }

  /// Start batch timer for sending events
  void _startBatchTimer() {
    _batchTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _sendEventBatch();
    });
  }

  /// Send event batch to analytics service
  void _sendEventBatch() {
    if (_eventQueue.isEmpty) return;

    // In a real implementation, this would send events to:
    // - Firebase Analytics
    // - Google Analytics
    // - Mixpanel
    // - Custom analytics endpoint

    debugPrint('📡 Sending ${_eventQueue.length} analytics events');
    
    // Clear sent events (in real implementation, only clear after successful send)
    if (_eventQueue.length > 1000) {
      // Keep only recent events to prevent memory issues
      _eventQueue.removeRange(0, _eventQueue.length - 500);
    }
  }

  /// Calculate average session duration
  Duration _calculateAverageSessionDuration() {
    // This would typically calculate based on historical data
    return const Duration(minutes: 8, seconds: 45); // Mock value
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  /// Dispose analytics service
  void dispose() {
    _endScreenTiming();
    _batchTimer?.cancel();
    
    trackEvent(
      'session_end',
      properties: {
        'session_id': _sessionId,
        'session_duration': _sessionStart != null
            ? DateTime.now().difference(_sessionStart!).inMilliseconds
            : 0,
      },
      category: EventCategory.session,
    );
    
    // Send final batch
    _sendEventBatch();
  }
}

/// Analytics event data model
class AnalyticsEvent {
  final String name;
  final EventCategory category;
  final Map<String, dynamic>? properties;
  final DateTime timestamp;
  final String? userId;
  final String? sessionId;

  const AnalyticsEvent({
    required this.name,
    required this.category,
    this.properties,
    required this.timestamp,
    this.userId,
    this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category.name,
      'properties': properties,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'session_id': sessionId,
    };
  }

  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name'],
      category: EventCategory.values.firstWhere((c) => c.name == json['category']),
      properties: json['properties'] != null
          ? Map<String, dynamic>.from(json['properties'])
          : null,
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['user_id'],
      sessionId: json['session_id'],
    );
  }
}

/// Event categories for better organization
enum EventCategory {
  interaction,
  navigation,
  ecommerce,
  authentication,
  search,
  social,
  performance,
  error,
  funnel,
  user,
  session,
  custom,
}

/// User session data model
class UserSession {
  final String sessionId;
  final String? userId;
  final DateTime startTime;
  final Duration duration;
  final int eventCount;
  final int screenViews;
  final List<UserJourneyStep> userJourney;

  const UserSession({
    required this.sessionId,
    this.userId,
    required this.startTime,
    required this.duration,
    required this.eventCount,
    required this.screenViews,
    required this.userJourney,
  });

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'start_time': startTime.toIso8601String(),
      'duration_ms': duration.inMilliseconds,
      'event_count': eventCount,
      'screen_views': screenViews,
      'user_journey': userJourney.map((s) => s.toJson()).toList(),
    };
  }
}

/// User journey step
class UserJourneyStep {
  final JourneyStepType type;
  final String name;
  final DateTime timestamp;
  final Map<String, dynamic>? properties;

  const UserJourneyStep({
    required this.type,
    required this.name,
    required this.timestamp,
    this.properties,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'properties': properties,
    };
  }

  factory UserJourneyStep.fromJson(Map<String, dynamic> json) {
    return UserJourneyStep(
      type: JourneyStepType.values.firstWhere((t) => t.name == json['type']),
      name: json['name'],
      timestamp: DateTime.parse(json['timestamp']),
      properties: json['properties'] != null
          ? Map<String, dynamic>.from(json['properties'])
          : null,
    );
  }
}

/// Journey step types
enum JourneyStepType {
  screen,
  event,
  interaction,
  purchase,
  error,
}

/// Analytics summary
class AnalyticsSummary {
  final int totalEvents;
  final Map<EventCategory, int> eventsByCategory;
  final List<MapEntry<String, int>> topEvents;
  final List<String> uniqueScreens;
  final Duration averageSessionDuration;
  final Duration? period;
  final DateTime generatedAt;

  const AnalyticsSummary({
    required this.totalEvents,
    required this.eventsByCategory,
    required this.topEvents,
    required this.uniqueScreens,
    required this.averageSessionDuration,
    this.period,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_events': totalEvents,
      'events_by_category': eventsByCategory.map(
        (k, v) => MapEntry(k.name, v),
      ),
      'top_events': topEvents.map((e) => {
        'name': e.key,
        'count': e.value,
      }).toList(),
      'unique_screens': uniqueScreens,
      'average_session_duration_ms': averageSessionDuration.inMilliseconds,
      'period_ms': period?.inMilliseconds,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

extension _ListExtensions<T> on List<T> {
  T? get lastOrNull => isEmpty ? null : last;
}