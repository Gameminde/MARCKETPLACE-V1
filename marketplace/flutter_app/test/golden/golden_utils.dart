import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Utilities for golden tests to ensure consistent testing environments
/// and helper functions for visual regression testing
class GoldenTestUtils {
  /// Standard test widget wrapper with theme and providers
  static Widget createTestWidget({
    required Widget child,
    ThemeData? theme,
    Size? size,
    double? devicePixelRatio,
  }) {
    return MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(
          size: size ?? const Size(400, 600),
          devicePixelRatio: devicePixelRatio ?? 1.0,
        ),
        child: Scaffold(
          body: child,
        ),
      ),
    );
  }

  /// Set custom device size for responsive testing
  static void setDeviceSize(
    WidgetTester tester, {
    required Size size,
    double devicePixelRatio = 2.0,
  }) {
    tester.binding.window.physicalSizeTestValue = size;
    tester.binding.window.devicePixelRatioTestValue = devicePixelRatio;
  }

  /// Clean up device size settings
  static void clearDeviceSize(WidgetTester tester) {
    tester.binding.window.clearPhysicalSizeTestValue();
    tester.binding.window.clearDevicePixelRatioTestValue();
  }

  /// Common device sizes for responsive testing
  static const Size mobileSize = Size(375, 667); // iPhone SE
  static const Size tabletSize = Size(768, 1024); // iPad
  static const Size desktopSize = Size(1920, 1080); // Desktop

  /// Pump widget and wait for animations to settle
  static Future<void> pumpAndSettle(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  /// Match golden file with custom threshold
  static Future<void> expectGoldenMatch(
    Finder finder,
    String goldenPath, {
    double threshold = 0.0,
  }) async {
    await expectLater(
      finder,
      matchesGoldenFile(goldenPath),
    );
  }

  /// Create a test scenario for different themes
  static List<TestScenario> createThemeScenarios({
    required String testName,
    required Widget Function(ThemeData theme) widgetBuilder,
  }) {
    return [
      TestScenario(
        name: '${testName}_light',
        widget: widgetBuilder(ThemeData.light()),
        goldenPath: 'goldens/${testName}_light.png',
      ),
      TestScenario(
        name: '${testName}_dark',
        widget: widgetBuilder(ThemeData.dark()),
        goldenPath: 'goldens/${testName}_dark.png',
      ),
    ];
  }

  /// Create test scenarios for different device sizes
  static List<DeviceTestScenario> createDeviceScenarios({
    required String testName,
    required Widget widget,
  }) {
    return [
      DeviceTestScenario(
        name: '${testName}_mobile',
        widget: widget,
        size: mobileSize,
        goldenPath: 'goldens/${testName}_mobile.png',
      ),
      DeviceTestScenario(
        name: '${testName}_tablet',
        widget: widget,
        size: tabletSize,
        goldenPath: 'goldens/${testName}_tablet.png',
      ),
      DeviceTestScenario(
        name: '${testName}_desktop',
        widget: widget,
        size: desktopSize,
        goldenPath: 'goldens/${testName}_desktop.png',
      ),
    ];
  }

  /// Generate screenshots for documentation
  static Future<void> generateScreenshotForDocs(
    WidgetTester tester,
    Finder finder,
    String filename,
  ) async {
    await tester.pumpAndSettle();
    
    // Save screenshot for documentation
    await expectLater(
      finder,
      matchesGoldenFile('screenshots/$filename'),
    );
  }

  /// Test widget in loading state
  static Widget wrapInLoadingState(Widget child) {
    return Stack(
      children: [
        child,
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  /// Test widget in error state
  static Widget wrapInErrorState(Widget child, String errorMessage) {
    return Stack(
      children: [
        child,
        Container(
          color: Colors.red.withOpacity(0.8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Test widget accessibility
  static Future<void> verifyAccessibility(
    WidgetTester tester,
    Widget widget,
  ) async {
    await tester.pumpWidget(widget);
    
    // Check for semantic labels
    final semanticFinder = find.bySemanticsLabel(RegExp(r'.+'));
    expect(semanticFinder, findsAtLeastNWidgets(1));
    
    // Verify tap targets are large enough (minimum 48x48)
    final gestureFinder = find.byType(GestureDetector);
    for (final element in tester.elementList(gestureFinder)) {
      final renderObject = element.renderObject;
      if (renderObject is RenderBox) {
        expect(renderObject.size.width, greaterThanOrEqualTo(48.0));
        expect(renderObject.size.height, greaterThanOrEqualTo(48.0));
      }
    }
  }
}

/// Test scenario for theme variations
class TestScenario {
  final String name;
  final Widget widget;
  final String goldenPath;

  const TestScenario({
    required this.name,
    required this.widget,
    required this.goldenPath,
  });
}

/// Test scenario for device size variations
class DeviceTestScenario {
  final String name;
  final Widget widget;
  final Size size;
  final String goldenPath;

  const DeviceTestScenario({
    required this.name,
    required this.widget,
    required this.size,
    required this.goldenPath,
  });
}

/// Extensions for easier golden testing
extension GoldenTestExtensions on WidgetTester {
  /// Pump widget and capture golden
  Future<void> pumpAndCapture(
    Widget widget,
    String goldenPath, {
    Duration? duration,
  }) async {
    await pumpWidget(widget);
    await pumpAndSettle(duration ?? const Duration(seconds: 2));
    
    await expectLater(
      find.byType(widget.runtimeType),
      matchesGoldenFile(goldenPath),
    );
  }

  /// Test multiple device sizes
  Future<void> testMultipleDevices(
    Widget widget,
    String baseGoldenPath,
    List<Size> deviceSizes,
  ) async {
    for (int i = 0; i < deviceSizes.size; i++) {
      final size = deviceSizes[i];
      final deviceName = _getDeviceName(size);
      
      GoldenTestUtils.setDeviceSize(this, size: size);
      
      await pumpAndCapture(
        widget,
        '${baseGoldenPath}_$deviceName.png',
      );
      
      GoldenTestUtils.clearDeviceSize(this);
    }
  }

  String _getDeviceName(Size size) {
    if (size == GoldenTestUtils.mobileSize) return 'mobile';
    if (size == GoldenTestUtils.tabletSize) return 'tablet';
    if (size == GoldenTestUtils.desktopSize) return 'desktop';
    return 'custom_${size.width.toInt()}x${size.height.toInt()}';
  }
}

extension ListExtensions<T> on List<T> {
  int get size => length;
}