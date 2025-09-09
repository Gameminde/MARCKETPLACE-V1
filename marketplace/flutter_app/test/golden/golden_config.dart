import 'package:flutter/foundation.dart';

/// Configuration for golden tests in the marketplace application
/// 
/// This file contains configuration settings, test groups, and utilities
/// specifically designed for visual regression testing of UI components.
class GoldenTestConfig {
  /// Whether golden tests should run on this platform
  static bool get shouldRun => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  
  /// Base directory for golden files
  static const String goldenDirectory = 'test/golden/goldens/';
  
  /// Base directory for screenshots
  static const String screenshotDirectory = 'test/golden/screenshots/';
  
  /// Tolerance for golden file comparisons (0.0 = exact match, 1.0 = any difference allowed)
  static const double comparisonTolerance = 0.01;
  
  /// Standard device configurations for testing
  static const List<DeviceConfig> testDevices = [
    DeviceConfig(
      name: 'mobile',
      size: Size(375, 667), // iPhone SE
      pixelRatio: 2.0,
    ),
    DeviceConfig(
      name: 'tablet',
      size: Size(768, 1024), // iPad
      pixelRatio: 2.0,
    ),
    DeviceConfig(
      name: 'desktop',
      size: Size(1920, 1080), // Desktop
      pixelRatio: 1.0,
    ),
  ];
  
  /// Test categories for organizing golden tests
  static const List<TestCategory> testCategories = [
    TestCategory(
      name: 'components',
      description: 'Individual UI components',
      priority: TestPriority.high,
    ),
    TestCategory(
      name: 'screens',
      description: 'Complete screen layouts',
      priority: TestPriority.high,
    ),
    TestCategory(
      name: 'layouts',
      description: 'Complex layout arrangements',
      priority: TestPriority.medium,
    ),
    TestCategory(
      name: 'themes',
      description: 'Theme and styling variations',
      priority: TestPriority.medium,
    ),
    TestCategory(
      name: 'responsive',
      description: 'Responsive design variations',
      priority: TestPriority.low,
    ),
  ];
  
  /// Components that should be tested across all themes
  static const List<String> criticalComponents = [
    'ProductCard',
    'CustomAppBar',
    'GlassmorphicContainer',
    'LoadingStates',
    'CategorySection',
  ];
  
  /// Screens that should be tested across all device sizes
  static const List<String> criticalScreens = [
    'LoginScreen',
    'HomeScreen',
    'ProductDetailScreen',
    'CartScreen',
    'CheckoutScreen',
  ];
  
  /// Animation duration to wait before capturing screenshots
  static const Duration animationSettleTime = Duration(milliseconds: 500);
  
  /// Maximum time to wait for widgets to render
  static const Duration renderTimeout = Duration(seconds: 10);
  
  /// Golden file naming conventions
  static String getGoldenFileName({
    required String testName,
    String? variant,
    String? device,
    String? theme,
  }) {
    final parts = <String>[testName];
    
    if (variant != null) parts.add(variant);
    if (device != null) parts.add(device);
    if (theme != null) parts.add(theme);
    
    return '${parts.join('_')}.png';
  }
  
  /// Get golden file path
  static String getGoldenPath(String fileName) {
    return '$goldenDirectory$fileName';
  }
  
  /// Get screenshot file path
  static String getScreenshotPath(String fileName) {
    return '$screenshotDirectory$fileName';
  }
}

/// Device configuration for golden tests
class DeviceConfig {
  final String name;
  final Size size;
  final double pixelRatio;
  
  const DeviceConfig({
    required this.name,
    required this.size,
    required this.pixelRatio,
  });
  
  @override
  String toString() => 'DeviceConfig($name, ${size.width}x${size.height}, ${pixelRatio}x)';
}

/// Test category configuration
class TestCategory {
  final String name;
  final String description;
  final TestPriority priority;
  
  const TestCategory({
    required this.name,
    required this.description,
    required this.priority,
  });
  
  @override
  String toString() => 'TestCategory($name: $description, priority: ${priority.name})';
}

/// Test priority levels
enum TestPriority {
  high('High Priority - Critical for release'),
  medium('Medium Priority - Important for quality'),
  low('Low Priority - Nice to have');
  
  const TestPriority(this.description);
  final String description;
}

/// Test execution modes
enum TestMode {
  generate('Generate new golden files'),
  compare('Compare against existing golden files'),
  update('Update existing golden files');
  
  const TestMode(this.description);
  final String description;
}

/// Golden test metadata
class GoldenTestMetadata {
  final String testName;
  final String description;
  final TestCategory category;
  final List<String> tags;
  final DateTime createdAt;
  final String? author;
  
  const GoldenTestMetadata({
    required this.testName,
    required this.description,
    required this.category,
    this.tags = const [],
    required this.createdAt,
    this.author,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'testName': testName,
      'description': description,
      'category': category.name,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'author': author,
    };
  }
  
  factory GoldenTestMetadata.fromJson(Map<String, dynamic> json) {
    return GoldenTestMetadata(
      testName: json['testName'],
      description: json['description'],
      category: GoldenTestConfig.testCategories
          .firstWhere((c) => c.name == json['category']),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      author: json['author'],
    );
  }
}