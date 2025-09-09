import 'dart:math';
import 'package:flutter/foundation.dart';

/// Comprehensive A/B testing framework for feature experimentation
/// 
/// This service enables controlled experiments to test different features,
/// UI variations, and user experiences to optimize conversion and engagement.
/// 
/// Features:
/// - Feature flag management
/// - A/B test variants with targeting
/// - Statistical significance tracking
/// - User segment targeting
/// - Real-time experiment results
/// - Gradual rollout capabilities
/// - Multi-variate testing support
/// 
/// Usage:
/// ```dart
/// ABTestingService.instance.initialize();
/// final variant = ABTestingService.instance.getVariant('checkout_flow');
/// ABTestingService.instance.trackConversion('checkout_flow', 'purchase_completed');
/// ```
class ABTestingService {
  static ABTestingService? _instance;
  static ABTestingService get instance {
    _instance ??= ABTestingService._internal();
    return _instance!;
  }

  ABTestingService._internal();

  final Map<String, ABTest> _activeTests = {};
  final Map<String, String> _userVariants = {};
  final Map<String, ABTestResult> _testResults = {};
  final List<ExperimentEvent> _events = [];
  
  String? _userId;
  Map<String, dynamic> _userAttributes = {};
  bool _initialized = false;

  /// Initialize A/B testing service
  void initialize({
    String? userId,
    Map<String, dynamic>? userAttributes,
  }) {
    if (_initialized) return;

    _userId = userId;
    _userAttributes = userAttributes ?? {};

    // Load active tests (in production, this would come from a remote config)
    _loadActiveTests();
    
    // Assign user to test variants
    _assignUserToVariants();

    _initialized = true;
    debugPrint('🧪 ABTestingService initialized');
  }

  /// Get variant for a specific test
  String getVariant(String testName, {String defaultVariant = 'control'}) {
    if (!_initialized) {
      debugPrint('⚠️ A/B Testing service not initialized');
      return defaultVariant;
    }

    final test = _activeTests[testName];
    if (test == null || !test.isActive) {
      return defaultVariant;
    }

    // Check if user already has a variant assigned
    if (_userVariants.containsKey(testName)) {
      return _userVariants[testName]!;
    }

    // Assign variant based on targeting rules
    final variant = _assignVariant(test);
    _userVariants[testName] = variant;

    // Track assignment event
    _trackEvent(ExperimentEvent(
      testName: testName,
      variant: variant,
      eventType: ExperimentEventType.assignment,
      timestamp: DateTime.now(),
      userId: _userId,
      userAttributes: Map.from(_userAttributes),
    ));

    debugPrint('🎯 User assigned to variant "$variant" for test "$testName"');
    return variant;
  }

  /// Check if a feature is enabled for the user
  bool isFeatureEnabled(String featureName, {bool defaultValue = false}) {
    final variant = getVariant(featureName, defaultVariant: defaultValue ? 'enabled' : 'disabled');
    return variant == 'enabled' || variant == 'true';
  }

  /// Get feature configuration
  Map<String, dynamic>? getFeatureConfig(String featureName) {
    final test = _activeTests[featureName];
    if (test == null) return null;

    final variant = getVariant(featureName);
    return test.variants[variant]?.config;
  }

  /// Track conversion event for a test
  void trackConversion(
    String testName,
    String conversionType, {
    double? value,
    Map<String, dynamic>? properties,
  }) {
    final variant = _userVariants[testName];
    if (variant == null) {
      debugPrint('⚠️ No variant assigned for test "$testName"');
      return;
    }

    _trackEvent(ExperimentEvent(
      testName: testName,
      variant: variant,
      eventType: ExperimentEventType.conversion,
      conversionType: conversionType,
      value: value,
      timestamp: DateTime.now(),
      userId: _userId,
      userAttributes: Map.from(_userAttributes),
      properties: properties,
    ));

    debugPrint('✅ Conversion tracked: $testName -> $conversionType');
  }

  /// Track custom event for a test
  void trackEvent(
    String testName,
    String eventName, {
    Map<String, dynamic>? properties,
  }) {
    final variant = _userVariants[testName];
    if (variant == null) return;

    _trackEvent(ExperimentEvent(
      testName: testName,
      variant: variant,
      eventType: ExperimentEventType.custom,
      customEventName: eventName,
      timestamp: DateTime.now(),
      userId: _userId,
      userAttributes: Map.from(_userAttributes),
      properties: properties,
    ));
  }

  /// Update user attributes for targeting
  void updateUserAttributes(Map<String, dynamic> attributes) {
    _userAttributes.addAll(attributes);
    
    // Re-evaluate variants if targeting rules changed
    _reevaluateVariants();
  }

  /// Set user ID
  void setUserId(String userId) {
    _userId = userId;
    
    // Reassign variants for new user
    _assignUserToVariants();
  }

  /// Create a new A/B test
  void createTest(ABTest test) {
    _activeTests[test.name] = test;
    
    // Assign user to variant if they match targeting
    if (_shouldUserParticipate(test)) {
      final variant = _assignVariant(test);
      _userVariants[test.name] = variant;
    }
  }

  /// Get test results for analysis
  ABTestResult getTestResults(String testName) {
    if (_testResults.containsKey(testName)) {
      return _testResults[testName]!;
    }

    final result = _calculateTestResults(testName);
    _testResults[testName] = result;
    return result;
  }

  /// Get all active tests
  Map<String, ABTest> getActiveTests() {
    return Map.unmodifiable(_activeTests);
  }

  /// Get user's variant assignments
  Map<String, String> getUserVariants() {
    return Map.unmodifiable(_userVariants);
  }

  /// Force user into specific variant
  void forceVariant(String testName, String variant) {
    _userVariants[testName] = variant;
    
    _trackEvent(ExperimentEvent(
      testName: testName,
      variant: variant,
      eventType: ExperimentEventType.forced,
      timestamp: DateTime.now(),
      userId: _userId,
      userAttributes: Map.from(_userAttributes),
    ));

    debugPrint('🔧 User forced into variant "$variant" for test "$testName"');
  }

  /// Export experiment data
  Map<String, dynamic> exportExperimentData() {
    return {
      'active_tests': _activeTests.map((k, v) => MapEntry(k, v.toJson())),
      'user_variants': _userVariants,
      'test_results': _testResults.map((k, v) => MapEntry(k, v.toJson())),
      'events': _events.map((e) => e.toJson()).toList(),
      'user_id': _userId,
      'user_attributes': _userAttributes,
      'export_timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Load active tests (mock implementation)
  void _loadActiveTests() {
    // In production, this would load from remote config service
    _activeTests.addAll({
      'checkout_flow': ABTest(
        name: 'checkout_flow',
        description: 'Test different checkout flow designs',
        isActive: true,
        trafficAllocation: 1.0,
        variants: {
          'control': const ABTestVariant(
            name: 'control',
            allocation: 0.5,
            config: {'layout': 'single_page'},
          ),
          'multi_step': const ABTestVariant(
            name: 'multi_step',
            allocation: 0.5,
            config: {'layout': 'multi_step', 'steps': 3},
          ),
        },
        targetingRules: [
          const TargetingRule(
            attribute: 'platform',
            operator: TargetingOperator.equals,
            value: 'mobile',
          ),
        ],
        conversionGoals: ['purchase_completed', 'checkout_started'],
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now().add(const Duration(days: 30)),
      ),
      
      'product_card_design': ABTest(
        name: 'product_card_design',
        description: 'Test different product card layouts',
        isActive: true,
        trafficAllocation: 0.8,
        variants: {
          'control': const ABTestVariant(
            name: 'control',
            allocation: 0.33,
            config: {'design': 'standard'},
          ),
          'compact': const ABTestVariant(
            name: 'compact',
            allocation: 0.33,
            config: {'design': 'compact', 'show_rating': false},
          ),
          'detailed': const ABTestVariant(
            name: 'detailed',
            allocation: 0.34,
            config: {'design': 'detailed', 'show_description': true},
          ),
        },
        conversionGoals: ['product_viewed', 'add_to_cart'],
        startDate: DateTime.now().subtract(const Duration(days: 3)),
        endDate: DateTime.now().add(const Duration(days: 14)),
      ),

      'onboarding_flow': ABTest(
        name: 'onboarding_flow',
        description: 'Test simplified vs detailed onboarding',
        isActive: true,
        trafficAllocation: 0.6,
        variants: {
          'control': const ABTestVariant(
            name: 'control',
            allocation: 0.5,
            config: {'steps': 5, 'skip_allowed': true},
          ),
          'simplified': const ABTestVariant(
            name: 'simplified',
            allocation: 0.5,
            config: {'steps': 3, 'skip_allowed': false},
          ),
        },
        targetingRules: [
          const TargetingRule(
            attribute: 'is_new_user',
            operator: TargetingOperator.equals,
            value: true,
          ),
        ],
        conversionGoals: ['onboarding_completed', 'first_purchase'],
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 21)),
      ),
    });
  }

  /// Assign user to variants for all active tests
  void _assignUserToVariants() {
    for (final test in _activeTests.values) {
      if (test.isActive && _shouldUserParticipate(test)) {
        final variant = _assignVariant(test);
        _userVariants[test.name] = variant;
      }
    }
  }

  /// Check if user should participate in test
  bool _shouldUserParticipate(ABTest test) {
    // Check traffic allocation
    final userHash = _getUserHash(test.name);
    if (userHash > test.trafficAllocation) {
      return false;
    }

    // Check targeting rules
    for (final rule in test.targetingRules) {
      if (!_evaluateTargetingRule(rule)) {
        return false;
      }
    }

    // Check date range
    final now = DateTime.now();
    if (test.startDate != null && now.isBefore(test.startDate!)) {
      return false;
    }
    if (test.endDate != null && now.isAfter(test.endDate!)) {
      return false;
    }

    return true;
  }

  /// Assign variant based on allocation
  String _assignVariant(ABTest test) {
    final userHash = _getUserHash('${test.name}_variant');
    double cumulative = 0.0;
    
    for (final variant in test.variants.values) {
      cumulative += variant.allocation;
      if (userHash <= cumulative) {
        return variant.name;
      }
    }

    // Fallback to first variant
    return test.variants.keys.first;
  }

  /// Evaluate targeting rule
  bool _evaluateTargetingRule(TargetingRule rule) {
    final userValue = _userAttributes[rule.attribute];
    
    switch (rule.operator) {
      case TargetingOperator.equals:
        return userValue == rule.value;
      case TargetingOperator.notEquals:
        return userValue != rule.value;
      case TargetingOperator.contains:
        return userValue?.toString().contains(rule.value.toString()) ?? false;
      case TargetingOperator.greaterThan:
        if (userValue is num && rule.value is num) {
          return userValue > rule.value;
        }
        return false;
      case TargetingOperator.lessThan:
        if (userValue is num && rule.value is num) {
          return userValue < rule.value;
        }
        return false;
      case TargetingOperator.inList:
        if (rule.value is List) {
          return (rule.value as List).contains(userValue);
        }
        return false;
    }
  }

  /// Get consistent hash for user
  double _getUserHash(String key) {
    final seed = _userId ?? 'anonymous';
    final combined = '$seed:$key';
    final hash = combined.hashCode.abs();
    return (hash % 10000) / 10000.0;
  }

  /// Re-evaluate variants when user attributes change
  void _reevaluateVariants() {
    final previousVariants = Map<String, String>.from(_userVariants);
    _userVariants.clear();
    _assignUserToVariants();
    
    // Track variant changes
    for (final testName in _activeTests.keys) {
      final previousVariant = previousVariants[testName];
      final newVariant = _userVariants[testName];
      
      if (previousVariant != null && 
          newVariant != null && 
          previousVariant != newVariant) {
        _trackEvent(ExperimentEvent(
          testName: testName,
          variant: newVariant,
          eventType: ExperimentEventType.reassignment,
          timestamp: DateTime.now(),
          userId: _userId,
          userAttributes: Map.from(_userAttributes),
          properties: {'previous_variant': previousVariant},
        ));
      }
    }
  }

  /// Track experiment event
  void _trackEvent(ExperimentEvent event) {
    _events.add(event);
    
    // Keep only recent events to prevent memory issues
    if (_events.length > 1000) {
      _events.removeAt(0);
    }
    
    // In production, send to analytics service
    debugPrint('📊 Experiment event: ${event.testName} -> ${event.eventType.name}');
  }

  /// Calculate test results
  ABTestResult _calculateTestResults(String testName) {
    final testEvents = _events.where((e) => e.testName == testName).toList();
    final variantStats = <String, VariantStatistics>{};
    
    // Group events by variant
    final eventsByVariant = <String, List<ExperimentEvent>>{};
    for (final event in testEvents) {
      eventsByVariant.putIfAbsent(event.variant, () => []).add(event);
    }
    
    // Calculate statistics for each variant
    for (final entry in eventsByVariant.entries) {
      final variant = entry.key;
      final events = entry.value;
      
      final assignments = events.where((e) => 
          e.eventType == ExperimentEventType.assignment).length;
      final conversions = events.where((e) => 
          e.eventType == ExperimentEventType.conversion).length;
      
      final conversionRate = assignments > 0 ? conversions / assignments : 0.0;
      
      variantStats[variant] = VariantStatistics(
        variant: variant,
        assignments: assignments,
        conversions: conversions,
        conversionRate: conversionRate,
        totalValue: events
            .where((e) => e.value != null)
            .fold(0.0, (sum, e) => sum + e.value!),
      );
    }
    
    // Calculate statistical significance (simplified)
    double? significance;
    if (variantStats.length >= 2) {
      significance = _calculateStatisticalSignificance(variantStats);
    }
    
    return ABTestResult(
      testName: testName,
      variantStatistics: variantStats,
      statisticalSignificance: significance,
      winningVariant: _determineWinningVariant(variantStats),
      sampleSize: testEvents.length,
      generatedAt: DateTime.now(),
    );
  }

  /// Calculate statistical significance (simplified z-test)
  double _calculateStatisticalSignificance(Map<String, VariantStatistics> stats) {
    if (stats.length < 2) return 0.0;
    
    final variants = stats.values.toList();
    final control = variants[0];
    final treatment = variants[1];
    
    if (control.assignments == 0 || treatment.assignments == 0) return 0.0;
    
    // Simplified z-test calculation
    final p1 = control.conversionRate;
    final p2 = treatment.conversionRate;
    final n1 = control.assignments.toDouble();
    final n2 = treatment.assignments.toDouble();
    
    final pooledP = (control.conversions + treatment.conversions) / (n1 + n2);
    final se = sqrt(pooledP * (1 - pooledP) * (1/n1 + 1/n2));
    
    if (se == 0) return 0.0;
    
    final zScore = (p2 - p1).abs() / se;
    
    // Convert z-score to confidence level (approximation)
    return min(0.99, 1 - exp(-zScore * zScore / 2));
  }

  /// Determine winning variant
  String? _determineWinningVariant(Map<String, VariantStatistics> stats) {
    if (stats.isEmpty) return null;
    
    return stats.entries
        .reduce((a, b) => a.value.conversionRate > b.value.conversionRate ? a : b)
        .key;
  }
}

/// A/B test configuration
class ABTest {
  final String name;
  final String description;
  final bool isActive;
  final double trafficAllocation;
  final Map<String, ABTestVariant> variants;
  final List<TargetingRule> targetingRules;
  final List<String> conversionGoals;
  final DateTime? startDate;
  final DateTime? endDate;

  const ABTest({
    required this.name,
    required this.description,
    required this.isActive,
    required this.trafficAllocation,
    required this.variants,
    this.targetingRules = const [],
    this.conversionGoals = const [],
    this.startDate,
    this.endDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'is_active': isActive,
      'traffic_allocation': trafficAllocation,
      'variants': variants.map((k, v) => MapEntry(k, v.toJson())),
      'targeting_rules': targetingRules.map((r) => r.toJson()).toList(),
      'conversion_goals': conversionGoals,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
    };
  }
}

/// A/B test variant configuration
class ABTestVariant {
  final String name;
  final double allocation;
  final Map<String, dynamic>? config;

  const ABTestVariant({
    required this.name,
    required this.allocation,
    this.config,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'allocation': allocation,
      'config': config,
    };
  }
}

/// Targeting rule for user segmentation
class TargetingRule {
  final String attribute;
  final TargetingOperator operator;
  final dynamic value;

  const TargetingRule({
    required this.attribute,
    required this.operator,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    return {
      'attribute': attribute,
      'operator': operator.name,
      'value': value,
    };
  }
}

/// Targeting operators
enum TargetingOperator {
  equals,
  notEquals,
  contains,
  greaterThan,
  lessThan,
  inList,
}

/// Experiment event tracking
class ExperimentEvent {
  final String testName;
  final String variant;
  final ExperimentEventType eventType;
  final String? conversionType;
  final String? customEventName;
  final double? value;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic> userAttributes;
  final Map<String, dynamic>? properties;

  const ExperimentEvent({
    required this.testName,
    required this.variant,
    required this.eventType,
    this.conversionType,
    this.customEventName,
    this.value,
    required this.timestamp,
    this.userId,
    this.userAttributes = const {},
    this.properties,
  });

  Map<String, dynamic> toJson() {
    return {
      'test_name': testName,
      'variant': variant,
      'event_type': eventType.name,
      'conversion_type': conversionType,
      'custom_event_name': customEventName,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'user_attributes': userAttributes,
      'properties': properties,
    };
  }
}

/// Experiment event types
enum ExperimentEventType {
  assignment,
  conversion,
  custom,
  forced,
  reassignment,
}

/// A/B test results
class ABTestResult {
  final String testName;
  final Map<String, VariantStatistics> variantStatistics;
  final double? statisticalSignificance;
  final String? winningVariant;
  final int sampleSize;
  final DateTime generatedAt;

  const ABTestResult({
    required this.testName,
    required this.variantStatistics,
    this.statisticalSignificance,
    this.winningVariant,
    required this.sampleSize,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'test_name': testName,
      'variant_statistics': variantStatistics.map((k, v) => MapEntry(k, v.toJson())),
      'statistical_significance': statisticalSignificance,
      'winning_variant': winningVariant,
      'sample_size': sampleSize,
      'generated_at': generatedAt.toIso8601String(),
    };
  }
}

/// Variant statistics
class VariantStatistics {
  final String variant;
  final int assignments;
  final int conversions;
  final double conversionRate;
  final double totalValue;

  const VariantStatistics({
    required this.variant,
    required this.assignments,
    required this.conversions,
    required this.conversionRate,
    required this.totalValue,
  });

  Map<String, dynamic> toJson() {
    return {
      'variant': variant,
      'assignments': assignments,
      'conversions': conversions,
      'conversion_rate': conversionRate,
      'total_value': totalValue,
    };
  }
}