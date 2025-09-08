import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Comprehensive conversion tracking and funnel analysis service
/// 
/// This service provides detailed tracking of user conversion events and
/// analyzes user behavior through various conversion funnels to optimize
/// the marketplace application's business metrics.
/// 
/// Features:
/// - Custom conversion event tracking
/// - Multi-step funnel analysis
/// - Conversion rate optimization insights
/// - User segment analysis
/// - Attribution modeling
/// - Cohort analysis
/// - Revenue tracking
/// - Real-time conversion monitoring
/// 
/// Usage:
/// ```dart
/// ConversionTrackingService.instance.initialize();
/// ConversionTrackingService.instance.trackConversion('purchase', value: 99.99);
/// ConversionTrackingService.instance.createFunnel('checkout_flow', steps);
/// final analysis = ConversionTrackingService.instance.analyzeFunnel('checkout_flow');
/// ```
class ConversionTrackingService {
  static ConversionTrackingService? _instance;
  static ConversionTrackingService get instance {
    _instance ??= ConversionTrackingService._internal();
    return _instance!;
  }

  ConversionTrackingService._internal();

  final List<ConversionEvent> _conversions = [];
  final Map<String, ConversionFunnel> _funnels = {};
  final Map<String, List<FunnelStep>> _userFunnelProgress = {};
  final Map<String, UserCohort> _cohorts = {};
  
  String? _userId;
  DateTime? _sessionStart;
  Map<String, dynamic> _userAttributes = {};
  bool _initialized = false;

  /// Initialize conversion tracking service
  void initialize({
    String? userId,
    Map<String, dynamic>? userAttributes,
  }) {
    if (_initialized) return;

    _userId = userId;
    _sessionStart = DateTime.now();
    _userAttributes = userAttributes ?? {};

    // Create default funnels
    _createDefaultFunnels();

    _initialized = true;
    debugPrint('💰 ConversionTrackingService initialized');
  }

  /// Track a conversion event
  void trackConversion(
    String conversionType, {
    double? value,
    String? currency,
    String? orderId,
    Map<String, dynamic>? properties,
    String? source,
    String? medium,
    String? campaign,
  }) {
    final event = ConversionEvent(
      id: _generateEventId(),
      userId: _userId,
      conversionType: conversionType,
      value: value,
      currency: currency ?? 'USD',
      orderId: orderId,
      timestamp: DateTime.now(),
      properties: properties,
      source: source,
      medium: medium,
      campaign: campaign,
      userAttributes: Map.from(_userAttributes),
    );

    _conversions.add(event);
    
    // Update funnel progress
    _updateFunnelProgress(conversionType);
    
    // Update cohort data
    _updateCohortData(event);

    debugPrint('💸 Conversion tracked: $conversionType (${value != null ? '$currency$value' : 'no value'})');
  }

  /// Track funnel step
  void trackFunnelStep(
    String funnelName,
    String stepName, {
    Map<String, dynamic>? properties,
  }) {
    final step = FunnelStep(
      funnelName: funnelName,
      stepName: stepName,
      userId: _userId,
      timestamp: DateTime.now(),
      properties: properties,
    );

    _userFunnelProgress.putIfAbsent(_userId ?? 'anonymous', () => []).add(step);

    debugPrint('🔄 Funnel step tracked: $funnelName -> $stepName');
  }

  /// Create a custom conversion funnel
  void createFunnel(
    String funnelName, {
    required List<String> steps,
    String? description,
    Duration? timeWindow,
  }) {
    final funnel = ConversionFunnel(
      name: funnelName,
      description: description,
      steps: steps,
      timeWindow: timeWindow ?? const Duration(days: 30),
      createdAt: DateTime.now(),
    );

    _funnels[funnelName] = funnel;
    debugPrint('🎯 Funnel created: $funnelName with ${steps.length} steps');
  }

  /// Analyze funnel performance
  FunnelAnalysis analyzeFunnel(String funnelName, {Duration? period}) {
    final funnel = _funnels[funnelName];
    if (funnel == null) {
      throw ArgumentError('Funnel "$funnelName" not found');
    }

    final now = DateTime.now();
    final startTime = period != null ? now.subtract(period) : null;

    // Get relevant user sessions
    final userSessions = _getUserSessions(startTime);
    
    // Calculate step conversions
    final stepAnalysis = <String, FunnelStepAnalysis>{};
    int previousStepUsers = 0;

    for (int i = 0; i < funnel.steps.length; i++) {
      final step = funnel.steps[i];
      final usersInStep = _getUsersInStep(userSessions, funnelName, step);
      
      stepAnalysis[step] = FunnelStepAnalysis(
        stepName: step,
        stepIndex: i,
        userCount: usersInStep,
        conversionRate: i == 0 ? 1.0 : (previousStepUsers > 0 ? usersInStep / previousStepUsers : 0.0),
        dropoffRate: i == 0 ? 0.0 : (previousStepUsers > 0 ? (previousStepUsers - usersInStep) / previousStepUsers : 0.0),
      );

      if (i == 0) {
        previousStepUsers = usersInStep;
      } else {
        previousStepUsers = usersInStep;
      }
    }

    // Calculate overall funnel metrics
    final totalUsers = stepAnalysis.isNotEmpty ? stepAnalysis.values.first.userCount : 0;
    final completedUsers = stepAnalysis.isNotEmpty ? stepAnalysis.values.last.userCount : 0;
    final overallConversionRate = totalUsers > 0 ? completedUsers / totalUsers : 0.0;

    return FunnelAnalysis(
      funnelName: funnelName,
      period: period,
      totalUsers: totalUsers,
      completedUsers: completedUsers,
      overallConversionRate: overallConversionRate,
      stepAnalysis: stepAnalysis,
      averageTimeToConvert: _calculateAverageTimeToConvert(funnelName),
      generatedAt: now,
    );
  }

  /// Get conversion metrics
  ConversionMetrics getConversionMetrics({Duration? period}) {
    final now = DateTime.now();
    final startTime = period != null ? now.subtract(period) : null;

    final filteredConversions = startTime != null
        ? _conversions.where((c) => c.timestamp.isAfter(startTime)).toList()
        : _conversions;

    // Calculate metrics by conversion type
    final conversionsByType = <String, List<ConversionEvent>>{};
    for (final conversion in filteredConversions) {
      conversionsByType.putIfAbsent(conversion.conversionType, () => [])
          .add(conversion);
    }

    final typeMetrics = <String, ConversionTypeMetrics>{};
    for (final entry in conversionsByType.entries) {
      final type = entry.key;
      final conversions = entry.value;
      
      final totalValue = conversions
          .where((c) => c.value != null)
          .fold(0.0, (sum, c) => sum + c.value!);
      
      typeMetrics[type] = ConversionTypeMetrics(
        conversionType: type,
        count: conversions.length,
        totalValue: totalValue,
        averageValue: conversions.isNotEmpty ? totalValue / conversions.length : 0.0,
        uniqueUsers: conversions.map((c) => c.userId).toSet().length,
      );
    }

    // Calculate revenue metrics
    final revenueConversions = filteredConversions
        .where((c) => c.value != null && c.value! > 0)
        .toList();
    
    final totalRevenue = revenueConversions
        .fold(0.0, (sum, c) => sum + c.value!);
    
    final averageOrderValue = revenueConversions.isNotEmpty
        ? totalRevenue / revenueConversions.length
        : 0.0;

    return ConversionMetrics(
      period: period,
      totalConversions: filteredConversions.length,
      uniqueConverters: filteredConversions.map((c) => c.userId).toSet().length,
      totalRevenue: totalRevenue,
      averageOrderValue: averageOrderValue,
      conversionsByType: typeMetrics,
      generatedAt: now,
    );
  }

  /// Analyze user cohorts
  CohortAnalysis analyzeCohorts({
    required Duration cohortSize,
    int? numberOfCohorts,
  }) {
    final now = DateTime.now();
    final maxCohorts = numberOfCohorts ?? 12;
    
    final cohortData = <String, CohortData>{};
    
    for (int i = 0; i < maxCohorts; i++) {
      final cohortStart = now.subtract(Duration(
        days: cohortSize.inDays * (i + 1),
      ));
      final cohortEnd = cohortStart.add(cohortSize);
      final cohortName = _getCohortName(cohortStart, cohortSize);
      
      // Get users who first converted in this period
      final cohortUsers = _conversions
          .where((c) => c.timestamp.isAfter(cohortStart) && 
                       c.timestamp.isBefore(cohortEnd))
          .map((c) => c.userId)
          .toSet();
      
      if (cohortUsers.isEmpty) continue;
      
      // Calculate retention rates
      final retentionRates = <int, double>{};
      for (int period = 1; period <= 12; period++) {
        final periodStart = cohortEnd.add(Duration(
          days: cohortSize.inDays * (period - 1),
        ));
        final periodEnd = periodStart.add(cohortSize);
        
        final activeUsers = _conversions
            .where((c) => c.timestamp.isAfter(periodStart) && 
                         c.timestamp.isBefore(periodEnd) &&
                         cohortUsers.contains(c.userId))
            .map((c) => c.userId)
            .toSet()
            .length;
        
        retentionRates[period] = cohortUsers.isNotEmpty 
            ? activeUsers / cohortUsers.length 
            : 0.0;
      }
      
      cohortData[cohortName] = CohortData(
        cohortName: cohortName,
        cohortStart: cohortStart,
        cohortEnd: cohortEnd,
        totalUsers: cohortUsers.length,
        retentionRates: retentionRates,
      );
    }
    
    return CohortAnalysis(
      cohortSize: cohortSize,
      cohorts: cohortData,
      generatedAt: now,
    );
  }

  /// Get attribution analysis
  AttributionAnalysis getAttributionAnalysis({Duration? period}) {
    final now = DateTime.now();
    final startTime = period != null ? now.subtract(period) : null;

    final filteredConversions = startTime != null
        ? _conversions.where((c) => c.timestamp.isAfter(startTime)).toList()
        : _conversions;

    // Analyze by source
    final sourceAttribution = <String, AttributionData>{};
    final mediumAttribution = <String, AttributionData>{};
    final campaignAttribution = <String, AttributionData>{};

    for (final conversion in filteredConversions) {
      // Source attribution
      final source = conversion.source ?? 'direct';
      _updateAttributionData(sourceAttribution, source, conversion);
      
      // Medium attribution
      final medium = conversion.medium ?? 'none';
      _updateAttributionData(mediumAttribution, medium, conversion);
      
      // Campaign attribution
      if (conversion.campaign != null) {
        _updateAttributionData(campaignAttribution, conversion.campaign!, conversion);
      }
    }

    return AttributionAnalysis(
      period: period,
      sourceAttribution: sourceAttribution,
      mediumAttribution: mediumAttribution,
      campaignAttribution: campaignAttribution,
      generatedAt: now,
    );
  }

  /// Export conversion data
  Map<String, dynamic> exportConversionData() {
    return {
      'conversions': _conversions.map((c) => c.toJson()).toList(),
      'funnels': _funnels.map((k, v) => MapEntry(k, v.toJson())),
      'user_funnel_progress': _userFunnelProgress.map(
        (k, v) => MapEntry(k, v.map((s) => s.toJson()).toList()),
      ),
      'cohorts': _cohorts.map((k, v) => MapEntry(k, v.toJson())),
      'metrics': getConversionMetrics().toJson(),
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Set user ID
  void setUserId(String userId) {
    _userId = userId;
  }

  /// Update user attributes
  void updateUserAttributes(Map<String, dynamic> attributes) {
    _userAttributes.addAll(attributes);
  }

  /// Create default conversion funnels
  void _createDefaultFunnels() {
    // E-commerce funnel
    createFunnel(
      'ecommerce_funnel',
      steps: [
        'product_view',
        'add_to_cart',
        'checkout_start',
        'payment_info',
        'purchase_complete',
      ],
      description: 'Complete e-commerce conversion funnel',
    );

    // User onboarding funnel
    createFunnel(
      'onboarding_funnel',
      steps: [
        'app_install',
        'registration_start',
        'email_verification',
        'profile_setup',
        'first_purchase',
      ],
      description: 'User onboarding to first purchase',
    );

    // Search to purchase funnel
    createFunnel(
      'search_to_purchase',
      steps: [
        'search_performed',
        'search_result_click',
        'product_view',
        'add_to_cart',
        'purchase_complete',
      ],
      description: 'Search behavior to purchase conversion',
    );
  }

  /// Update funnel progress for user
  void _updateFunnelProgress(String conversionType) {
    for (final funnel in _funnels.values) {
      if (funnel.steps.contains(conversionType)) {
        trackFunnelStep(funnel.name, conversionType);
      }
    }
  }

  /// Update cohort data with new conversion
  void _updateCohortData(ConversionEvent event) {
    if (event.userId == null) return;

    final cohortKey = _getCohortKey(event.timestamp);
    
    if (!_cohorts.containsKey(cohortKey)) {
      _cohorts[cohortKey] = UserCohort(
        id: cohortKey,
        createdAt: DateTime(event.timestamp.year, event.timestamp.month),
        userIds: {},
      );
    }
    
    _cohorts[cohortKey]!.userIds.add(event.userId!);
  }

  /// Get user sessions for analysis
  Map<String, List<FunnelStep>> _getUserSessions(DateTime? startTime) {
    if (startTime == null) {
      return Map.from(_userFunnelProgress);
    }
    
    final filteredSessions = <String, List<FunnelStep>>{};
    for (final entry in _userFunnelProgress.entries) {
      final filteredSteps = entry.value
          .where((step) => step.timestamp.isAfter(startTime))
          .toList();
      if (filteredSteps.isNotEmpty) {
        filteredSessions[entry.key] = filteredSteps;
      }
    }
    
    return filteredSessions;
  }

  /// Get users who completed a specific funnel step
  int _getUsersInStep(
    Map<String, List<FunnelStep>> sessions,
    String funnelName,
    String stepName,
  ) {
    final usersInStep = <String>{};
    
    for (final entry in sessions.entries) {
      final userId = entry.key;
      final steps = entry.value;
      
      if (steps.any((step) => 
          step.funnelName == funnelName && 
          step.stepName == stepName)) {
        usersInStep.add(userId);
      }
    }
    
    return usersInStep.length;
  }

  /// Calculate average time to convert through funnel
  Duration _calculateAverageTimeToConvert(String funnelName) {
    final funnel = _funnels[funnelName];
    if (funnel == null) return Duration.zero;

    final completionTimes = <Duration>[];
    
    for (final entry in _userFunnelProgress.entries) {
      final steps = entry.value
          .where((step) => step.funnelName == funnelName)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      if (steps.length == funnel.steps.length) {
        final duration = steps.last.timestamp.difference(steps.first.timestamp);
        completionTimes.add(duration);
      }
    }
    
    if (completionTimes.isEmpty) return Duration.zero;
    
    final averageMs = completionTimes
        .fold(0, (sum, duration) => sum + duration.inMilliseconds) ~/
        completionTimes.length;
    
    return Duration(milliseconds: averageMs);
  }

  /// Update attribution data
  void _updateAttributionData(
    Map<String, AttributionData> attribution,
    String key,
    ConversionEvent conversion,
  ) {
    if (!attribution.containsKey(key)) {
      attribution[key] = AttributionData(
        source: key,
        conversions: 0,
        revenue: 0.0,
        uniqueUsers: <String>{},
      );
    }
    
    final data = attribution[key]!;
    data.conversions++;
    if (conversion.value != null) {
      data.revenue += conversion.value!;
    }
    if (conversion.userId != null) {
      data.uniqueUsers.add(conversion.userId!);
    }
  }

  /// Get cohort key from timestamp
  String _getCohortKey(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}';
  }

  /// Get cohort name for display
  String _getCohortName(DateTime start, Duration size) {
    if (size.inDays >= 30) {
      return '${start.year}-${start.month.toString().padLeft(2, '0')}';
    } else if (size.inDays >= 7) {
      return 'Week ${start.day ~/ 7 + 1}, ${start.year}-${start.month.toString().padLeft(2, '0')}';
    } else {
      return '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    }
  }

  /// Generate unique event ID
  String _generateEventId() {
    return 'conv_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }
}

/// Conversion event model
class ConversionEvent {
  final String id;
  final String? userId;
  final String conversionType;
  final double? value;
  final String currency;
  final String? orderId;
  final DateTime timestamp;
  final Map<String, dynamic>? properties;
  final String? source;
  final String? medium;
  final String? campaign;
  final Map<String, dynamic> userAttributes;

  const ConversionEvent({
    required this.id,
    this.userId,
    required this.conversionType,
    this.value,
    required this.currency,
    this.orderId,
    required this.timestamp,
    this.properties,
    this.source,
    this.medium,
    this.campaign,
    this.userAttributes = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'conversion_type': conversionType,
      'value': value,
      'currency': currency,
      'order_id': orderId,
      'timestamp': timestamp.toIso8601String(),
      'properties': properties,
      'source': source,
      'medium': medium,
      'campaign': campaign,
      'user_attributes': userAttributes,
    };
  }
}

/// Conversion funnel model
class ConversionFunnel {
  final String name;
  final String? description;
  final List<String> steps;
  final Duration timeWindow;
  final DateTime createdAt;

  const ConversionFunnel({
    required this.name,
    this.description,
    required this.steps,
    required this.timeWindow,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'steps': steps,
      'time_window_ms': timeWindow.inMilliseconds,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Funnel step model
class FunnelStep {
  final String funnelName;
  final String stepName;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? properties;

  const FunnelStep({
    required this.funnelName,
    required this.stepName,
    this.userId,
    required this.timestamp,
    this.properties,
  });

  Map<String, dynamic> toJson() {
    return {
      'funnel_name': funnelName,
      'step_name': stepName,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'properties': properties,
    };
  }
}

/// Funnel analysis result
class FunnelAnalysis {
  final String funnelName;
  final Duration? period;
  final int totalUsers;
  final int completedUsers;
  final double overallConversionRate;
  final Map<String, FunnelStepAnalysis> stepAnalysis;
  final Duration averageTimeToConvert;
  final DateTime generatedAt;

  const FunnelAnalysis({
    required this.funnelName,
    this.period,
    required this.totalUsers,
    required this.completedUsers,
    required this.overallConversionRate,
    required this.stepAnalysis,
    required this.averageTimeToConvert,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'funnel_name': funnelName,
      'period_ms': period?.inMilliseconds,
      'total_users': totalUsers,
      'completed_users': completedUsers,
      'overall_conversion_rate': overallConversionRate,
      'step_analysis': stepAnalysis.map((k, v) => MapEntry(k, v.toJson())),
      'average_time_to_convert_ms': averageTimeToConvert.inMilliseconds,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// Funnel step analysis
class FunnelStepAnalysis {
  final String stepName;
  final int stepIndex;
  final int userCount;
  final double conversionRate;
  final double dropoffRate;

  const FunnelStepAnalysis({
    required this.stepName,
    required this.stepIndex,
    required this.userCount,
    required this.conversionRate,
    required this.dropoffRate,
  });

  Map<String, dynamic> toJson() {
    return {
      'step_name': stepName,
      'step_index': stepIndex,
      'user_count': userCount,
      'conversion_rate': conversionRate,
      'dropoff_rate': dropoffRate,
    };
  }
}

/// Conversion metrics
class ConversionMetrics {
  final Duration? period;
  final int totalConversions;
  final int uniqueConverters;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, ConversionTypeMetrics> conversionsByType;
  final DateTime generatedAt;

  const ConversionMetrics({
    this.period,
    required this.totalConversions,
    required this.uniqueConverters,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.conversionsByType,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'period_ms': period?.inMilliseconds,
      'total_conversions': totalConversions,
      'unique_converters': uniqueConverters,
      'total_revenue': totalRevenue,
      'average_order_value': averageOrderValue,
      'conversions_by_type': conversionsByType.map((k, v) => MapEntry(k, v.toJson())),
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// Conversion type metrics
class ConversionTypeMetrics {
  final String conversionType;
  final int count;
  final double totalValue;
  final double averageValue;
  final int uniqueUsers;

  const ConversionTypeMetrics({
    required this.conversionType,
    required this.count,
    required this.totalValue,
    required this.averageValue,
    required this.uniqueUsers,
  });

  Map<String, dynamic> toJson() {
    return {
      'conversion_type': conversionType,
      'count': count,
      'total_value': totalValue,
      'average_value': averageValue,
      'unique_users': uniqueUsers,
    };
  }
}

/// User cohort model
class UserCohort {
  final String id;
  final DateTime createdAt;
  final Set<String> userIds;

  UserCohort({
    required this.id,
    required this.createdAt,
    required this.userIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'user_count': userIds.length,
      'user_ids': userIds.toList(),
    };
  }
}

/// Cohort analysis result
class CohortAnalysis {
  final Duration cohortSize;
  final Map<String, CohortData> cohorts;
  final DateTime generatedAt;

  const CohortAnalysis({
    required this.cohortSize,
    required this.cohorts,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'cohort_size_days': cohortSize.inDays,
      'cohorts': cohorts.map((k, v) => MapEntry(k, v.toJson())),
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// Cohort data
class CohortData {
  final String cohortName;
  final DateTime cohortStart;
  final DateTime cohortEnd;
  final int totalUsers;
  final Map<int, double> retentionRates;

  const CohortData({
    required this.cohortName,
    required this.cohortStart,
    required this.cohortEnd,
    required this.totalUsers,
    required this.retentionRates,
  });

  Map<String, dynamic> toJson() {
    return {
      'cohort_name': cohortName,
      'cohort_start': cohortStart.toIso8601String(),
      'cohort_end': cohortEnd.toIso8601String(),
      'total_users': totalUsers,
      'retention_rates': retentionRates.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
}

/// Attribution analysis result
class AttributionAnalysis {
  final Duration? period;
  final Map<String, AttributionData> sourceAttribution;
  final Map<String, AttributionData> mediumAttribution;
  final Map<String, AttributionData> campaignAttribution;
  final DateTime generatedAt;

  const AttributionAnalysis({
    this.period,
    required this.sourceAttribution,
    required this.mediumAttribution,
    required this.campaignAttribution,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'period_ms': period?.inMilliseconds,
      'source_attribution': sourceAttribution.map((k, v) => MapEntry(k, v.toJson())),
      'medium_attribution': mediumAttribution.map((k, v) => MapEntry(k, v.toJson())),
      'campaign_attribution': campaignAttribution.map((k, v) => MapEntry(k, v.toJson())),
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// Attribution data
class AttributionData {
  final String source;
  int conversions;
  double revenue;
  final Set<String> uniqueUsers;

  AttributionData({
    required this.source,
    required this.conversions,
    required this.revenue,
    required this.uniqueUsers,
  });

  double get averageOrderValue => conversions > 0 ? revenue / conversions : 0.0;

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'conversions': conversions,
      'revenue': revenue,
      'unique_users': uniqueUsers.length,
      'average_order_value': averageOrderValue,
    };
  }
}